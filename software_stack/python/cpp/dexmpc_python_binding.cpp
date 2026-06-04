#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include "dexmpc/runtime/operator.hpp"

#include <cstdint>
#include <exception>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#ifndef DEXMPC_PY_MODULE_NAME
#error "DEXMPC_PY_MODULE_NAME must be defined"
#endif

#define DEXMPC_PY_CONCAT2(a, b) a##b
#define DEXMPC_PY_CONCAT(a, b) DEXMPC_PY_CONCAT2(a, b)
#define DEXMPC_PY_INIT(name) DEXMPC_PY_CONCAT(PyInit_, name)

namespace {

using dexmpc::runtime::Device;
using dexmpc::runtime::OperatorRuntime;
using dexmpc::runtime::OperatorTensor;
using dexmpc::runtime::StatusRegisters;
using dexmpc::runtime::Transport;
using dexmpc::runtime::Word128;

PyObject* g_device_type = nullptr;
PyObject* g_tensor_type = nullptr;

struct PyDevice {
    PyObject_HEAD
    Device* device = nullptr;
    OperatorRuntime* runtime = nullptr;
};

struct PyTensor {
    PyObject_HEAD
    OperatorTensor* tensor = nullptr;
    PyObject* owner = nullptr;
};

bool set_error_from_exception() {
    try {
        throw;
    } catch (const std::exception& e) {
        PyErr_SetString(PyExc_RuntimeError, e.what());
    } catch (...) {
        PyErr_SetString(PyExc_RuntimeError, "unknown DexMPC runtime error");
    }
    return false;
}

bool require_device(PyObject* obj) {
    if (!PyObject_TypeCheck(obj, reinterpret_cast<PyTypeObject*>(g_device_type))) {
        PyErr_SetString(PyExc_TypeError, "expected dexmpc Device");
        return false;
    }
    auto* self = reinterpret_cast<PyDevice*>(obj);
    if (self->runtime == nullptr || self->device == nullptr) {
        PyErr_SetString(PyExc_RuntimeError, "DexMPC device is closed");
        return false;
    }
    return true;
}

bool require_tensor(PyObject* obj) {
    if (!PyObject_TypeCheck(obj, reinterpret_cast<PyTypeObject*>(g_tensor_type))) {
        PyErr_SetString(PyExc_TypeError, "expected dexmpc Tensor");
        return false;
    }
    auto* self = reinterpret_cast<PyTensor*>(obj);
    if (self->tensor == nullptr || !self->tensor->valid()) {
        PyErr_SetString(PyExc_RuntimeError, "DexMPC tensor is not live");
        return false;
    }
    return true;
}

std::string optional_name(PyObject* obj) {
    if (obj == nullptr || obj == Py_None) return {};
    if (!PyUnicode_Check(obj)) throw std::runtime_error("name must be str or None");
    Py_ssize_t size = 0;
    const char* text = PyUnicode_AsUTF8AndSize(obj, &size);
    if (text == nullptr) throw std::runtime_error("failed to decode name");
    return std::string(text, static_cast<std::size_t>(size));
}

std::uint16_t py_u16(PyObject* obj, const char* label) {
    const unsigned long value = PyLong_AsUnsignedLong(obj);
    if (PyErr_Occurred()) throw std::runtime_error(std::string(label) + " must be an integer");
    if (value > 0xfffful) throw std::runtime_error(std::string(label) + " exceeds uint16");
    return static_cast<std::uint16_t>(value);
}

std::uint32_t py_u32(PyObject* obj, const char* label) {
    const unsigned long value = PyLong_AsUnsignedLong(obj);
    if (PyErr_Occurred()) throw std::runtime_error(std::string(label) + " must be an integer");
    if (value > 0xfffffffful) throw std::runtime_error(std::string(label) + " exceeds uint32");
    return static_cast<std::uint32_t>(value);
}

dexsim::Matrix py_matrix(PyObject* obj) {
    PyObject* rows = PySequence_Fast(obj, "matrix must be a sequence of rows");
    if (rows == nullptr) throw std::runtime_error("matrix must be a sequence of rows");
    std::unique_ptr<PyObject, decltype(&Py_DECREF)> rows_guard(rows, Py_DECREF);

    const Py_ssize_t row_count = PySequence_Fast_GET_SIZE(rows);
    if (row_count <= 0) throw std::runtime_error("matrix must not be empty");

    dexsim::Matrix matrix;
    matrix.reserve(static_cast<std::size_t>(row_count));
    Py_ssize_t expected_cols = -1;
    for (Py_ssize_t r = 0; r < row_count; ++r) {
        PyObject* row_obj = PySequence_Fast_GET_ITEM(rows, r);
        PyObject* cols = PySequence_Fast(row_obj, "matrix row must be a sequence");
        if (cols == nullptr) throw std::runtime_error("matrix row must be a sequence");
        std::unique_ptr<PyObject, decltype(&Py_DECREF)> cols_guard(cols, Py_DECREF);
        const Py_ssize_t col_count = PySequence_Fast_GET_SIZE(cols);
        if (col_count <= 0) throw std::runtime_error("matrix rows must not be empty");
        if (expected_cols < 0) {
            expected_cols = col_count;
        } else if (expected_cols != col_count) {
            throw std::runtime_error("matrix rows must be rectangular");
        }

        std::vector<std::uint16_t> row;
        row.reserve(static_cast<std::size_t>(col_count));
        for (Py_ssize_t c = 0; c < col_count; ++c) {
            row.push_back(py_u16(PySequence_Fast_GET_ITEM(cols, c), "matrix element"));
        }
        matrix.push_back(std::move(row));
    }
    return matrix;
}

std::vector<std::uint16_t> py_vector(PyObject* obj) {
    PyObject* seq = PySequence_Fast(obj, "vector must be a sequence");
    if (seq == nullptr) throw std::runtime_error("vector must be a sequence");
    std::unique_ptr<PyObject, decltype(&Py_DECREF)> guard(seq, Py_DECREF);
    const Py_ssize_t count = PySequence_Fast_GET_SIZE(seq);
    if (count <= 0) throw std::runtime_error("vector must not be empty");
    std::vector<std::uint16_t> out;
    out.reserve(static_cast<std::size_t>(count));
    for (Py_ssize_t i = 0; i < count; ++i) {
        out.push_back(py_u16(PySequence_Fast_GET_ITEM(seq, i), "vector element"));
    }
    return out;
}

std::vector<Word128> py_words(PyObject* obj) {
    PyObject* seq = PySequence_Fast(obj, "words must be a sequence");
    if (seq == nullptr) throw std::runtime_error("words must be a sequence");
    std::unique_ptr<PyObject, decltype(&Py_DECREF)> guard(seq, Py_DECREF);
    const Py_ssize_t count = PySequence_Fast_GET_SIZE(seq);
    if (count <= 0) throw std::runtime_error("words must not be empty");
    std::vector<Word128> out;
    out.reserve(static_cast<std::size_t>(count));
    for (Py_ssize_t i = 0; i < count; ++i) {
        PyObject* tuple = PySequence_Fast(PySequence_Fast_GET_ITEM(seq, i), "word must contain four uint32 values");
        if (tuple == nullptr) throw std::runtime_error("word must contain four uint32 values");
        std::unique_ptr<PyObject, decltype(&Py_DECREF)> tuple_guard(tuple, Py_DECREF);
        if (PySequence_Fast_GET_SIZE(tuple) != 4) throw std::runtime_error("word must contain four uint32 values");
        out.push_back(Word128{
            py_u32(PySequence_Fast_GET_ITEM(tuple, 0), "word lane"),
            py_u32(PySequence_Fast_GET_ITEM(tuple, 1), "word lane"),
            py_u32(PySequence_Fast_GET_ITEM(tuple, 2), "word lane"),
            py_u32(PySequence_Fast_GET_ITEM(tuple, 3), "word lane"),
        });
    }
    return out;
}

PyObject* py_matrix_from_cpp(const dexsim::Matrix& matrix) {
    PyObject* rows = PyList_New(static_cast<Py_ssize_t>(matrix.size()));
    if (rows == nullptr) return nullptr;
    for (std::size_t r = 0; r < matrix.size(); ++r) {
        PyObject* row = PyList_New(static_cast<Py_ssize_t>(matrix[r].size()));
        if (row == nullptr) {
            Py_DECREF(rows);
            return nullptr;
        }
        for (std::size_t c = 0; c < matrix[r].size(); ++c) {
            PyList_SET_ITEM(row, static_cast<Py_ssize_t>(c), PyLong_FromUnsignedLong(matrix[r][c]));
        }
        PyList_SET_ITEM(rows, static_cast<Py_ssize_t>(r), row);
    }
    return rows;
}

PyObject* py_vector_from_cpp(const std::vector<std::uint16_t>& values) {
    PyObject* out = PyList_New(static_cast<Py_ssize_t>(values.size()));
    if (out == nullptr) return nullptr;
    for (std::size_t i = 0; i < values.size(); ++i) {
        PyList_SET_ITEM(out, static_cast<Py_ssize_t>(i), PyLong_FromUnsignedLong(values[i]));
    }
    return out;
}

PyObject* py_words_from_cpp(const std::vector<Word128>& words) {
    PyObject* out = PyList_New(static_cast<Py_ssize_t>(words.size()));
    if (out == nullptr) return nullptr;
    for (std::size_t i = 0; i < words.size(); ++i) {
        PyObject* word = Py_BuildValue("(kkkk)", words[i][0], words[i][1], words[i][2], words[i][3]);
        if (word == nullptr) {
            Py_DECREF(out);
            return nullptr;
        }
        PyList_SET_ITEM(out, static_cast<Py_ssize_t>(i), word);
    }
    return out;
}

PyObject* py_status_from_cpp(const StatusRegisters& status) {
    return Py_BuildValue("{s:I,s:I,s:I,s:I,s:I,s:I,s:I,s:I}",
                         "cmd_status", status.cmd_status,
                         "done_count", status.done_count,
                         "last_done", status.last_done,
                         "add_reduce", status.add_reduce,
                         "cmp_reduce0", status.cmp_reduce0,
                         "cmp_reduce1", status.cmp_reduce1,
                         "engine_status", status.engine_status,
                         "all_done", status.all_done);
}

PyObject* make_tensor(PyObject* owner, OperatorTensor tensor) {
    auto* obj = PyObject_New(PyTensor, reinterpret_cast<PyTypeObject*>(g_tensor_type));
    if (obj == nullptr) return nullptr;
    obj->tensor = new OperatorTensor(std::move(tensor));
    obj->owner = owner;
    Py_INCREF(owner);
    return reinterpret_cast<PyObject*>(obj);
}

void tensor_dealloc(PyObject* self_obj) {
    auto* self = reinterpret_cast<PyTensor*>(self_obj);
    delete self->tensor;
    self->tensor = nullptr;
    Py_XDECREF(self->owner);
    self->owner = nullptr;
    PyObject_Free(self_obj);
}

PyObject* tensor_valid(PyObject* self_obj, PyObject*) {
    if (!PyObject_TypeCheck(self_obj, reinterpret_cast<PyTypeObject*>(g_tensor_type))) {
        PyErr_SetString(PyExc_TypeError, "expected Tensor");
        return nullptr;
    }
    auto* self = reinterpret_cast<PyTensor*>(self_obj);
    if (self->tensor != nullptr && self->tensor->valid()) Py_RETURN_TRUE;
    Py_RETURN_FALSE;
}

PyObject* tensor_info(PyObject* self_obj, PyObject*) {
    if (!require_tensor(self_obj)) return nullptr;
    auto* self = reinterpret_cast<PyTensor*>(self_obj);
    const auto& t = *self->tensor;
    return Py_BuildValue("{s:s,s:i,s:i,s:i,s:i,s:i,s:i,s:O}",
                         "name", t.name().c_str(),
                         "mem_id", t.mem_id(),
                         "word_addr", t.word_addr(),
                         "word_count", t.word_count(),
                         "elem_count", t.elem_count(),
                         "rows", t.rows(),
                         "cols", t.cols(),
                         "is_matrix", t.is_matrix() ? Py_True : Py_False);
}

PyObject* tensor_word_addr(PyObject* self_obj, PyObject*) {
    if (!require_tensor(self_obj)) return nullptr;
    return PyLong_FromLong(reinterpret_cast<PyTensor*>(self_obj)->tensor->word_addr());
}

void device_dealloc(PyObject* self_obj) {
    auto* self = reinterpret_cast<PyDevice*>(self_obj);
    delete self->runtime;
    delete self->device;
    self->runtime = nullptr;
    self->device = nullptr;
    PyObject_Free(self_obj);
}

PyObject* device_open(PyObject*, PyObject* args, PyObject* kwargs) {
    int timeout = 1200000;
    static const char* kwlist[] = {"timeout_cycles", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "|i", const_cast<char**>(kwlist), &timeout)) return nullptr;

    try {
        char arg0[] = "dexmpc_python";
        char* argv[] = {arg0};
        auto* obj = PyObject_New(PyDevice, reinterpret_cast<PyTypeObject*>(g_device_type));
        if (obj == nullptr) return nullptr;
        obj->device = nullptr;
        obj->runtime = nullptr;
#if defined(DEX_TOPCHIP_TRANSPORT_D2D)
        obj->device = new Device(Device::open_sim(1, argv, Transport::D2D));
#elif defined(DEX_TOPCHIP_TRANSPORT_SPI)
        obj->device = new Device(Device::open_sim(1, argv, Transport::SPI));
#else
#error "DEX_TOPCHIP_TRANSPORT_D2D or DEX_TOPCHIP_TRANSPORT_SPI must be defined"
#endif
        obj->runtime = new OperatorRuntime(*obj->device, timeout);
        return reinterpret_cast<PyObject*>(obj);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_reset_program(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    unsigned int first = 0;
    if (!PyArg_ParseTuple(args, "|I", &first)) return nullptr;
    try {
        reinterpret_cast<PyDevice*>(self_obj)->runtime->reset_program(first);
        Py_RETURN_NONE;
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_reset_device(PyObject* self_obj, PyObject*) {
    if (!require_device(self_obj)) return nullptr;
    try {
        reinterpret_cast<PyDevice*>(self_obj)->runtime->reset_device();
        Py_RETURN_NONE;
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_cycle(PyObject* self_obj, PyObject*) {
    if (!require_device(self_obj)) return nullptr;
    return PyLong_FromUnsignedLongLong(reinterpret_cast<PyDevice*>(self_obj)->device->cycle());
}

PyObject* device_backend_kind(PyObject* self_obj, PyObject*) {
    if (!require_device(self_obj)) return nullptr;
    const auto text = dexmpc::runtime::to_string(reinterpret_cast<PyDevice*>(self_obj)->device->backend_kind());
    return PyUnicode_FromStringAndSize(text.data(), static_cast<Py_ssize_t>(text.size()));
}

PyObject* device_transport(PyObject* self_obj, PyObject*) {
    if (!require_device(self_obj)) return nullptr;
    const auto text = dexmpc::runtime::to_string(reinterpret_cast<PyDevice*>(self_obj)->device->transport());
    return PyUnicode_FromStringAndSize(text.data(), static_cast<Py_ssize_t>(text.size()));
}

PyObject* device_read_status(PyObject* self_obj, PyObject*) {
    if (!require_device(self_obj)) return nullptr;
    try {
        return py_status_from_cpp(reinterpret_cast<PyDevice*>(self_obj)->device->read_status());
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_upload_matrix(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* matrix_obj = nullptr;
    int mem_id = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"matrix", "mem_id", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "Oi|O", const_cast<char**>(kwlist),
                                     &matrix_obj, &mem_id, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->upload_matrix(
            py_matrix(matrix_obj), mem_id, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_upload_vector(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* vector_obj = nullptr;
    int mem_id = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"values", "mem_id", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "Oi|O", const_cast<char**>(kwlist),
                                     &vector_obj, &mem_id, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->upload_vector(
            py_vector(vector_obj), mem_id, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_upload_words(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* words_obj = nullptr;
    int mem_id = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"words", "mem_id", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "Oi|O", const_cast<char**>(kwlist),
                                     &words_obj, &mem_id, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->upload_words(
            py_words(words_obj), mem_id, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_empty_matrix(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int rows = 0;
    int cols = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"mem_id", "rows", "cols", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "iii|O", const_cast<char**>(kwlist),
                                     &mem_id, &rows, &cols, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->empty_matrix(
            mem_id, rows, cols, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_empty_vector(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int elem_count = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"mem_id", "elem_count", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "ii|O", const_cast<char**>(kwlist),
                                     &mem_id, &elem_count, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->empty_vector(
            mem_id, elem_count, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_empty_words(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int word_count = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"mem_id", "word_count", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "ii|O", const_cast<char**>(kwlist),
                                     &mem_id, &word_count, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->empty_words(
            mem_id, word_count, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_download_matrix(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    if (!PyArg_ParseTuple(args, "O", &tensor_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        auto matrix = reinterpret_cast<PyDevice*>(self_obj)->runtime->download_matrix(
            *reinterpret_cast<PyTensor*>(tensor_obj)->tensor);
        return py_matrix_from_cpp(matrix);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_download_vector(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    if (!PyArg_ParseTuple(args, "O", &tensor_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        auto values = reinterpret_cast<PyDevice*>(self_obj)->runtime->download_vector(
            *reinterpret_cast<PyTensor*>(tensor_obj)->tensor);
        return py_vector_from_cpp(values);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_download_words(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    if (!PyArg_ParseTuple(args, "O", &tensor_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        auto words = reinterpret_cast<PyDevice*>(self_obj)->runtime->download_words(
            *reinterpret_cast<PyTensor*>(tensor_obj)->tensor);
        return py_words_from_cpp(words);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_write_words(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    PyObject* words_obj = nullptr;
    if (!PyArg_ParseTuple(args, "OO", &tensor_obj, &words_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        reinterpret_cast<PyDevice*>(self_obj)->runtime->write_words(
            *reinterpret_cast<PyTensor*>(tensor_obj)->tensor, py_words(words_obj));
        Py_RETURN_NONE;
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_write_register(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    int reg_idx = 0;
    unsigned int value = 0;
    if (!PyArg_ParseTuple(args, "iI", &reg_idx, &value)) return nullptr;
    try {
        reinterpret_cast<PyDevice*>(self_obj)->runtime->write_register(reg_idx, value);
        Py_RETURN_NONE;
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_read_register(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    int reg_idx = 0;
    if (!PyArg_ParseTuple(args, "i", &reg_idx)) return nullptr;
    try {
        return PyLong_FromUnsignedLong(reinterpret_cast<PyDevice*>(self_obj)->runtime->read_register(reg_idx));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_write_memory(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int word_addr = 0;
    PyObject* words_obj = nullptr;
    if (!PyArg_ParseTuple(args, "iiO", &mem_id, &word_addr, &words_obj)) return nullptr;
    try {
        reinterpret_cast<PyDevice*>(self_obj)->runtime->write_memory(mem_id, word_addr, py_words(words_obj));
        Py_RETURN_NONE;
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_read_memory(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int word_addr = 0;
    int word_count = 0;
    if (!PyArg_ParseTuple(args, "iii", &mem_id, &word_addr, &word_count)) return nullptr;
    try {
        auto words = reinterpret_cast<PyDevice*>(self_obj)->runtime->read_memory(mem_id, word_addr, word_count);
        return py_words_from_cpp(words);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_bind_existing_matrix(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int word_addr = 0;
    int rows = 0;
    int cols = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"mem_id", "word_addr", "rows", "cols", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "iiii|O", const_cast<char**>(kwlist),
                                     &mem_id, &word_addr, &rows, &cols, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->bind_existing_matrix(
            mem_id, word_addr, rows, cols, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_bind_existing_vector(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int word_addr = 0;
    int elem_count = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"mem_id", "word_addr", "elem_count", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "iii|O", const_cast<char**>(kwlist),
                                     &mem_id, &word_addr, &elem_count, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->bind_existing_vector(
            mem_id, word_addr, elem_count, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_bind_existing_words(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    int mem_id = 0;
    int word_addr = 0;
    int word_count = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"mem_id", "word_addr", "word_count", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "iii|O", const_cast<char**>(kwlist),
                                     &mem_id, &word_addr, &word_count, &name_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->bind_existing_words(
            mem_id, word_addr, word_count, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

template <typename Fn>
PyObject* unary_matrix_op(PyObject* self_obj, PyObject* args, PyObject* kwargs, Fn fn) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    int dst_mem = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"src", "dst_mem", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "Oi|O", const_cast<char**>(kwlist),
                                     &tensor_obj, &dst_mem, &name_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        auto* runtime = reinterpret_cast<PyDevice*>(self_obj)->runtime;
        auto tensor = (runtime->*fn)(*reinterpret_cast<PyTensor*>(tensor_obj)->tensor,
                                    dst_mem, optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_abs(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    return unary_matrix_op(self_obj, args, kwargs, &OperatorRuntime::abs);
}

PyObject* device_transpose(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    return unary_matrix_op(self_obj, args, kwargs, &OperatorRuntime::layout_transpose);
}

PyObject* device_lut_sin(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    return unary_matrix_op(self_obj, args, kwargs, &OperatorRuntime::lut_sin);
}

PyObject* device_lut_cos(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    return unary_matrix_op(self_obj, args, kwargs, &OperatorRuntime::lut_cos);
}

PyObject* device_lut_softplus(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    return unary_matrix_op(self_obj, args, kwargs, &OperatorRuntime::lut_softplus);
}

PyObject* device_layout_assemble(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* src_obj = nullptr;
    int dst_mem = 0;
    int dst_rows = 0;
    int dst_cols = 0;
    int offset_row = 0;
    int offset_col = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {
        "src", "dst_mem", "dst_rows", "dst_cols", "offset_row", "offset_col", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "Oiiiii|O", const_cast<char**>(kwlist),
                                     &src_obj, &dst_mem, &dst_rows, &dst_cols,
                                     &offset_row, &offset_col, &name_obj)) return nullptr;
    if (!require_tensor(src_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->layout_assemble(
            *reinterpret_cast<PyTensor*>(src_obj)->tensor,
            dst_mem,
            dst_rows,
            dst_cols,
            offset_row,
            offset_col,
            optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_layout_assemble_into(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* src_obj = nullptr;
    PyObject* dst_obj = nullptr;
    int offset_row = 0;
    int offset_col = 0;
    if (!PyArg_ParseTuple(args, "OOii", &src_obj, &dst_obj, &offset_row, &offset_col)) return nullptr;
    if (!require_tensor(src_obj) || !require_tensor(dst_obj)) return nullptr;
    try {
        reinterpret_cast<PyDevice*>(self_obj)->runtime->layout_assemble_into(
            *reinterpret_cast<PyTensor*>(src_obj)->tensor,
            *reinterpret_cast<PyTensor*>(dst_obj)->tensor,
            offset_row,
            offset_col);
        Py_RETURN_NONE;
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_gemm(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* a_obj = nullptr;
    PyObject* b_obj = nullptr;
    int dst_mem = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"a", "b", "dst_mem", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "OOi|O", const_cast<char**>(kwlist),
                                     &a_obj, &b_obj, &dst_mem, &name_obj)) return nullptr;
    if (!require_tensor(a_obj) || !require_tensor(b_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->gemm(
            *reinterpret_cast<PyTensor*>(a_obj)->tensor,
            *reinterpret_cast<PyTensor*>(b_obj)->tensor,
            dst_mem,
            optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_add(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* a_obj = nullptr;
    PyObject* b_obj = nullptr;
    int dst_mem = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"a", "b", "dst_mem", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "OOi|O", const_cast<char**>(kwlist),
                                     &a_obj, &b_obj, &dst_mem, &name_obj)) return nullptr;
    if (!require_tensor(a_obj) || !require_tensor(b_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->add(
            *reinterpret_cast<PyTensor*>(a_obj)->tensor,
            *reinterpret_cast<PyTensor*>(b_obj)->tensor,
            dst_mem,
            optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_mul(PyObject* self_obj, PyObject* args, PyObject* kwargs) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* a_obj = nullptr;
    unsigned int alpha = 0;
    int dst_mem = 0;
    PyObject* name_obj = Py_None;
    static const char* kwlist[] = {"a", "alpha", "dst_mem", "name", nullptr};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "OIi|O", const_cast<char**>(kwlist),
                                     &a_obj, &alpha, &dst_mem, &name_obj)) return nullptr;
    if (!require_tensor(a_obj)) return nullptr;
    try {
        auto tensor = reinterpret_cast<PyDevice*>(self_obj)->runtime->mul(
            *reinterpret_cast<PyTensor*>(a_obj)->tensor,
            static_cast<std::uint16_t>(alpha),
            dst_mem,
            optional_name(name_obj));
        return make_tensor(self_obj, std::move(tensor));
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_reduce_add(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    if (!PyArg_ParseTuple(args, "O", &tensor_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        const auto result = reinterpret_cast<PyDevice*>(self_obj)->runtime->reduce_add(
            *reinterpret_cast<PyTensor*>(tensor_obj)->tensor);
        return Py_BuildValue("{s:I,s:I}", "value", result.value, "index", result.index);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyObject* device_reduce_cmp(PyObject* self_obj, PyObject* args) {
    if (!require_device(self_obj)) return nullptr;
    PyObject* tensor_obj = nullptr;
    if (!PyArg_ParseTuple(args, "O", &tensor_obj)) return nullptr;
    if (!require_tensor(tensor_obj)) return nullptr;
    try {
        const auto result = reinterpret_cast<PyDevice*>(self_obj)->runtime->reduce_cmp(
            *reinterpret_cast<PyTensor*>(tensor_obj)->tensor);
        return Py_BuildValue("{s:I,s:I}", "value", result.value, "index", result.index);
    } catch (...) {
        set_error_from_exception();
        return nullptr;
    }
}

PyMethodDef tensor_methods[] = {
    {"valid", tensor_valid, METH_NOARGS, nullptr},
    {"info", tensor_info, METH_NOARGS, nullptr},
    {"word_addr", tensor_word_addr, METH_NOARGS, nullptr},
    {nullptr, nullptr, 0, nullptr},
};

PyMethodDef device_methods[] = {
    {"reset_program", device_reset_program, METH_VARARGS, nullptr},
    {"reset_device", device_reset_device, METH_NOARGS, nullptr},
    {"cycle", device_cycle, METH_NOARGS, nullptr},
    {"backend_kind", device_backend_kind, METH_NOARGS, nullptr},
    {"transport", device_transport, METH_NOARGS, nullptr},
    {"read_status", device_read_status, METH_NOARGS, nullptr},
    {"upload_matrix", reinterpret_cast<PyCFunction>(device_upload_matrix), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"upload_vector", reinterpret_cast<PyCFunction>(device_upload_vector), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"upload_words", reinterpret_cast<PyCFunction>(device_upload_words), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"empty_matrix", reinterpret_cast<PyCFunction>(device_empty_matrix), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"empty_vector", reinterpret_cast<PyCFunction>(device_empty_vector), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"empty_words", reinterpret_cast<PyCFunction>(device_empty_words), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"download_matrix", device_download_matrix, METH_VARARGS, nullptr},
    {"download_vector", device_download_vector, METH_VARARGS, nullptr},
    {"download_words", device_download_words, METH_VARARGS, nullptr},
    {"write_words", device_write_words, METH_VARARGS, nullptr},
    {"write_register", device_write_register, METH_VARARGS, nullptr},
    {"read_register", device_read_register, METH_VARARGS, nullptr},
    {"write_memory", device_write_memory, METH_VARARGS, nullptr},
    {"read_memory", device_read_memory, METH_VARARGS, nullptr},
    {"bind_existing_matrix", reinterpret_cast<PyCFunction>(device_bind_existing_matrix), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"bind_existing_vector", reinterpret_cast<PyCFunction>(device_bind_existing_vector), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"bind_existing_words", reinterpret_cast<PyCFunction>(device_bind_existing_words), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"abs", reinterpret_cast<PyCFunction>(device_abs), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"transpose", reinterpret_cast<PyCFunction>(device_transpose), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"layout_assemble", reinterpret_cast<PyCFunction>(device_layout_assemble), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"layout_assemble_into", device_layout_assemble_into, METH_VARARGS, nullptr},
    {"gemm", reinterpret_cast<PyCFunction>(device_gemm), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"add", reinterpret_cast<PyCFunction>(device_add), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"mul", reinterpret_cast<PyCFunction>(device_mul), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"lut_sin", reinterpret_cast<PyCFunction>(device_lut_sin), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"lut_cos", reinterpret_cast<PyCFunction>(device_lut_cos), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"lut_softplus", reinterpret_cast<PyCFunction>(device_lut_softplus), METH_VARARGS | METH_KEYWORDS, nullptr},
    {"reduce_add", device_reduce_add, METH_VARARGS, nullptr},
    {"reduce_cmp", device_reduce_cmp, METH_VARARGS, nullptr},
    {nullptr, nullptr, 0, nullptr},
};

PyType_Slot tensor_slots[] = {
    {Py_tp_dealloc, reinterpret_cast<void*>(tensor_dealloc)},
    {Py_tp_methods, reinterpret_cast<void*>(tensor_methods)},
    {0, nullptr},
};

PyType_Spec tensor_spec = {
    "dexmpc._native.Tensor",
    sizeof(PyTensor),
    0,
    Py_TPFLAGS_DEFAULT,
    tensor_slots,
};

PyType_Slot device_slots[] = {
    {Py_tp_dealloc, reinterpret_cast<void*>(device_dealloc)},
    {Py_tp_methods, reinterpret_cast<void*>(device_methods)},
    {0, nullptr},
};

PyType_Spec device_spec = {
    "dexmpc._native.Device",
    sizeof(PyDevice),
    0,
    Py_TPFLAGS_DEFAULT,
    device_slots,
};

PyMethodDef module_methods[] = {
    {"open_sim", reinterpret_cast<PyCFunction>(device_open), METH_VARARGS | METH_KEYWORDS, nullptr},
    {nullptr, nullptr, 0, nullptr},
};

PyModuleDef module_def = {
    PyModuleDef_HEAD_INIT,
    "dexmpc native binding",
    nullptr,
    -1,
    module_methods,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
};

} // namespace

extern "C" PyMODINIT_FUNC DEXMPC_PY_INIT(DEXMPC_PY_MODULE_NAME)() {
    PyObject* module = PyModule_Create(&module_def);
    if (module == nullptr) return nullptr;

    g_device_type = PyType_FromSpec(&device_spec);
    if (g_device_type == nullptr) {
        Py_DECREF(module);
        return nullptr;
    }
    g_tensor_type = PyType_FromSpec(&tensor_spec);
    if (g_tensor_type == nullptr) {
        Py_DECREF(g_device_type);
        Py_DECREF(module);
        return nullptr;
    }

    Py_INCREF(g_device_type);
    Py_INCREF(g_tensor_type);
    PyModule_AddObject(module, "Device", g_device_type);
    PyModule_AddObject(module, "Tensor", g_tensor_type);

    PyModule_AddIntConstant(module, "MEM_GLOBAL", dexsim::kMemGlobal);
    PyModule_AddIntConstant(module, "MEM_LOCAL0", dexsim::kMemLocal0);
    PyModule_AddIntConstant(module, "MEM_TEMP0", dexsim::kMemTemp0);
    return module;
}
