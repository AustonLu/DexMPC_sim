cmake_minimum_required(VERSION 3.20)
project(dexsim_runtime VERSION 0.4.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_program(VERILATOR_EXECUTABLE verilator REQUIRED)
find_program(MAKE_EXECUTABLE make REQUIRED)
find_package(Threads REQUIRED)

execute_process(
    COMMAND ${VERILATOR_EXECUTABLE} --getenv VERILATOR_ROOT
    OUTPUT_VARIABLE VERILATOR_ROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)

set(DEXSIM_VERILATED_DIR "${CMAKE_BINARY_DIR}/verilated")
file(MAKE_DIRECTORY "${DEXSIM_VERILATED_DIR}")

execute_process(
    COMMAND ${VERILATOR_EXECUTABLE}
        -sv --cc --top-module TopChipTopD2dHarness
        -f verification/verilator/filelists/topchip_top_d2d_harness.f
        --Mdir "${DEXSIM_VERILATED_DIR}"
        -CFLAGS -fPIC
        --output-groups 0
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMAND_ERROR_IS_FATAL ANY
)

set(DEXSIM_MODEL VTopChipTopD2dHarness)
execute_process(
    COMMAND ${MAKE_EXECUTABLE} -C "${DEXSIM_VERILATED_DIR}"
        -f ${DEXSIM_MODEL}.mk
        -j 8
        OBJCACHE=
        ${DEXSIM_MODEL}__ALL.a
        verilated.o
        verilated_threads.o
    COMMAND_ERROR_IS_FATAL ANY
)

set(DEXSIM_VERILATED_OBJECTS
    "${DEXSIM_VERILATED_DIR}/verilated.o"
    "${DEXSIM_VERILATED_DIR}/verilated_threads.o"
)
set_source_files_properties(${DEXSIM_VERILATED_OBJECTS}
    PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)

add_library(dexsim_runtime SHARED
    runtime/src/session.cpp
    runtime/src/c_api.cpp
    ${DEXSIM_VERILATED_OBJECTS}
)

target_compile_definitions(dexsim_runtime PRIVATE DEX_TOPCHIP_TRANSPORT_D2D)
target_include_directories(dexsim_runtime PRIVATE
    "${CMAKE_SOURCE_DIR}"
    "${CMAKE_SOURCE_DIR}/runtime/include"
    "${DEXSIM_VERILATED_DIR}"
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
)
target_link_libraries(dexsim_runtime PRIVATE
    "${DEXSIM_VERILATED_DIR}/${DEXSIM_MODEL}__ALL.a"
    Threads::Threads
    atomic
)

set_target_properties(dexsim_runtime PROPERTIES
    OUTPUT_NAME dexsim_runtime
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)
