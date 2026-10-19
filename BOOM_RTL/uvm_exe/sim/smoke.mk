#==============================================================================
# sim/smoke.mk — Verilator build of the UVM-free golden-model cross-check
#   make -f smoke.mk            # build + run (N=200 per op)
#   make -f smoke.mk run N=1000 SEED=3
#==============================================================================
N        ?= 200
SEED     ?= 1
TB_DIR   := $(abspath ..)
export BOOM_RTL ?= $(abspath ../..)
SF_DIR   := $(TB_DIR)/dpi/softfloat
DPI_CFLAGS := -O2 -DSOFTFLOAT_FAST_INT64 -DSOFTFLOAT_FAST_DIV64TO32 -DSOFTFLOAT_ROUND_ODD -DINLINE_LEVEL=5 -I$(SF_DIR)/include -I$(SF_DIR)/RISCV -I$(SF_DIR)
SRCS := $(TB_DIR)/tb/smoke/shim/uvm_pkg.sv $(TB_DIR)/tb/boom_exe_defs_pkg.sv $(TB_DIR)/tb/boom_exu_if.sv $(TB_DIR)/tb/boom_iq_if.sv $(TB_DIR)/tb/boom_csr_if.sv \
        $(TB_DIR)/tb/smoke/boom_exe_smoke_pkg.sv $(TB_DIR)/tb/smoke/smoke_top.sv
OBJ := build/smoke
SVDPI_INC := $(shell verilator --getenv VERILATOR_ROOT)/include/vltstd
DPI_A := build/libboom_fp_ref.a

$(DPI_A): $(TB_DIR)/dpi/boom_fp_ref.c $(TB_DIR)/dpi/boom_spike_trace.c $(wildcard $(SF_DIR)/*.c) $(wildcard $(SF_DIR)/RISCV/*.c)
	@mkdir -p build/dpi_obj
	cd build/dpi_obj && $(CC) -c $(DPI_CFLAGS) -I$(SVDPI_INC) $^
	ar rcs $@ build/dpi_obj/*.o

build/smoke/Vsmoke_top: $(SRCS) $(DPI_A)
	verilator --binary --timing -j 4 -O2 --top-module smoke_top -Mdir $(OBJ) \
	    -Wno-fatal -Wno-lint -Wno-style -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-MULTIDRIVEN --timescale 1ns/1ps \
	    +define+BOOM_EXU_IF_NO_SVA +define+BOOM_IQ_IF_NO_SVA +define+BOOM_CSR_IF_NO_SVA \
	    +incdir+$(TB_DIR)/tb/smoke/shim +incdir+$(TB_DIR)/tb \
	    -f $(TB_DIR)/dut/boom_exe_dut.f $(SRCS) \
	    $(abspath $(DPI_A)) 2>&1 | tail -20

run: build/smoke/Vsmoke_top
	build/smoke/Vsmoke_top +n=$(N) +seed=$(SEED)

# replay Spike commit logs through the RTL (phase 4 only): make -f smoke.mk spike LOGS=spike_logs/rv64ui-p-add.log[,...]
LOGS ?= $(shell ls spike_logs/*.log 2>/dev/null | tr '\n' ',' | sed 's/,$$//')
spike: build/smoke/Vsmoke_top
	build/smoke/Vsmoke_top +spike_only +spike_log=$(LOGS) +seed=$(SEED)

.PHONY: spike

.PHONY: run
