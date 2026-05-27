all: vcscompile simv verdi

OUTPUT = simv
WORK_DIR = ./work
DESIGN_NAME = tb_TopChipTop_macarray_d2d

# compile command
VCS = vcs -full64 -sverilog +v2k -v2k_generate \
	+libext+.v+.sv+ \
	-debug_access+all \
	-debug_region+cell \
	-kdb \
	+warn=noRWSI\
	+vcs+flush+all \
	-Mdir=${WORK_DIR}/csrc \
	-o ${WORK_DIR}/${OUTPUT} \
	-l ${WORK_DIR}/compile.log \
	-fgp \
	+notimingcheck \
	-sdfretain \
	+lint=TFIPC-L\
	-assert svaext \
	-f filelist.f \
	-top ${DESIGN_NAME} 

VERDI = verdi -sverilog -f filelist.f -ssf ./${DESIGN_NAME}.fsdb

SIM_NUM_THREAD = 16
FSDB_NUM_THREAD = 0

VCS_FLAG =
VERDI_FLAG =
ASIC_CLOCK_GATING = 0 
FLOW_ASIC = 1
ifeq ($(ASIC_CLOCK_GATING), 1)
	VCS_FLAG += +define+ASIC_CLOCK_GATING
endif
#before apr sdf use unit delay, especially for tsmc sram 
ifeq ($(FLOW_ASIC), 1)
	VCS_FLAG += +define+FLOW_ASIC
	VERDI_FLAG += +define+FLOW_ASIC
	VCS_FLAG += +define+TSMC_CM_UNIT_DELAY 
	VERDI_FLAG += +define+TSMC_CM_UNIT_DELAY
endif
# VCS_FLAG += +define+SDF_ANNOTATE
VCS_FLAG += +define+VCS-BASE-COMPILE
VCS_FLAG += +warn=noOBSV2G

# start compile
vcscompile:
	mkdir -p ${WORK_DIR}
	${VCS} $(VCS_FLAG)

# run simulation
simv:
	cd ${WORK_DIR}; ./${OUTPUT} -l ${OUTPUT}.log -fgp=num_threads:$(SIM_NUM_THREAD),num_fsdb_threads:$(FSDB_NUM_THREAD)

# debug with Verdi
verdi:
	cd ${WORK_DIR}; ${VERDI} ${VERDI_FLAG}

# clean some file
clean:
	rm -rf ${WORK_DIR}
