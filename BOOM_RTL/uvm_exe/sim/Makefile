#==============================================================================
# sim/Makefile — build & run the BOOM execute-pipeline UVM testbench
#------------------------------------------------------------------------------
#   make SIM=vcs      TEST=t10_int_all_random SEED=1
#   make SIM=questa   TEST=t43_fp_all_random  SEED=7 PLUS="+ll_ready_pct=50"
#   make SIM=xcelium  TEST=t76_full_random
#   make lint                          # slang / verilator parse of the whole TB
#   make regress                       # sim/regress.py over sim/tests.yml
#   make dpi                           # just build the SoftFloat golden model + Spike trace bridge
#   make spike-logs                    # (re)generate sim/spike_logs from riscv-tests with Spike
#   make smoke N=300 SEED=2            # Verilator, UVM-free golden-model cross-check (no licence needed)
#
# Knobs: SIM (vcs|questa|xcelium), TEST, SEED, VERB (UVM_LOW..), PLUS (extra
# +args), WAVES=1, COV=1, BOOM_RTL (path to the elaborated RTL; default ..)
#==============================================================================
SIM      ?= vcs
TEST     ?= t01_alu_rr_smoke
SEED     ?= 1
VERB     ?= UVM_LOW
PLUS     ?=
WAVES    ?= 0
COV      ?= 0

TB_DIR   := $(abspath ..)
export BOOM_RTL ?= $(abspath ../..)
UVM_HOME ?= $(VCS_HOME)/etc/uvm-1.2
RUN_DIR  := $(abspath run/$(TEST)_$(SEED))

#------------------------------------------------------------------------------
# sources
#------------------------------------------------------------------------------
RTL_F    := $(TB_DIR)/dut/boom_exe_dut.f
TB_SRCS  := $(TB_DIR)/tb/boom_exe_defs_pkg.sv \
            $(TB_DIR)/tb/boom_exu_if.sv \
            $(TB_DIR)/tb/boom_iq_if.sv \
            $(TB_DIR)/tb/boom_csr_if.sv \
            $(TB_DIR)/tb/boom_exe_pkg.sv \
            $(TB_DIR)/tb/tb_top.sv
INCDIRS  := +incdir+$(TB_DIR)/tb
DEFINES  := +define+BOOM_EXE_UVM

# DPI golden model (Berkeley SoftFloat-3e, RISC-V specialisation — same code Spike uses)
DPI_DIR  := $(TB_DIR)/dpi
SF_DIR   := $(DPI_DIR)/softfloat
SF_SRCS  := $(wildcard $(SF_DIR)/*.c) $(wildcard $(SF_DIR)/RISCV/*.c)
DPI_SRCS := $(DPI_DIR)/boom_fp_ref.c $(DPI_DIR)/boom_spike_trace.c $(SF_SRCS)
DPI_CFLAGS := -O2 -fPIC -DSOFTFLOAT_FAST_INT64 -DSOFTFLOAT_FAST_DIV64TO32 -DSOFTFLOAT_ROUND_ODD -DINLINE_LEVEL=5 \
              -I$(SF_DIR)/include -I$(SF_DIR)/RISCV -I$(SF_DIR)
DPI_LIB  := $(abspath build/libboom_fp_ref.so)
# svdpi.h lives with the simulator
ifeq ($(SIM),vcs)
SVDPI_INC ?= $(VCS_HOME)/include
else ifeq ($(SIM),questa)
SVDPI_INC ?= $(QUESTA_HOME)/include
else ifeq ($(SIM),xcelium)
SVDPI_INC ?= $(XCELIUM_HOME)/tools/include
else
SVDPI_INC ?= $(shell verilator --getenv VERILATOR_ROOT 2>/dev/null)/include/vltstd
endif
DPI_CFLAGS += -I$(SVDPI_INC)

SPIKE_LOG_DIR ?= $(abspath spike_logs)
PLUSARGS := +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERB) +ntb_random_seed=$(SEED) +spike_dir=$(SPIKE_LOG_DIR) $(PLUS)
ifeq ($(WAVES),1)
PLUSARGS += +dump
endif

#------------------------------------------------------------------------------
# DPI library
#------------------------------------------------------------------------------
.PHONY: dpi
dpi: $(DPI_LIB)
$(DPI_LIB): $(DPI_SRCS)
	@mkdir -p build
	$(CC) -shared $(DPI_CFLAGS) -o $@ $(DPI_SRCS)

#------------------------------------------------------------------------------
# VCS
#------------------------------------------------------------------------------
ifeq ($(SIM),vcs)
COMP_OPTS := -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 -debug_access+all -lca -kdb \
             +lint=TFIPC-L -assert svaext $(INCDIRS) $(DEFINES) -f $(RTL_F) $(TB_SRCS) \
             -CFLAGS "$(DPI_CFLAGS)" $(DPI_SRCS) -o build/simv
ifeq ($(COV),1)
COMP_OPTS += -cm line+cond+fsm+tgl+branch+assert -cm_dir build/cov.vdb
RUN_OPTS  += -cm line+cond+fsm+tgl+branch+assert -cm_dir $(abspath build/cov.vdb) -cm_name $(TEST)_$(SEED)
endif
compile:
	@mkdir -p build
	vcs $(COMP_OPTS) -l build/compile.log
run: compile
	@mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && $(abspath build/simv) $(RUN_OPTS) $(PLUSARGS) -l sim.log
endif

#------------------------------------------------------------------------------
# Questa
#------------------------------------------------------------------------------
ifeq ($(SIM),questa)
compile: dpi
	@mkdir -p build && cd build && vlib work && vmap work work
	cd build && vlog -sv -timescale 1ns/1ps +acc -L $(QUESTA_HOME)/uvm-1.2 $(INCDIRS) $(DEFINES) -f $(RTL_F) $(TB_SRCS) -l compile.log
run: compile
	@mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && vsim -c -lib $(abspath build/work) tb_top -sv_lib $(basename $(DPI_LIB)) \
	    -sv_seed $(SEED) $(PLUSARGS) $(if $(filter 1,$(COV)),-coverage,) -do "run -all; quit -f" -l sim.log
endif

#------------------------------------------------------------------------------
# Xcelium
#------------------------------------------------------------------------------
ifeq ($(SIM),xcelium)
# the DPI library is built once with gcc (make dpi) and loaded with -sv_lib: xrun's own C compile step
# would need the SoftFloat include paths passed through -Wcc, which is easy to get wrong
compile: dpi
	@mkdir -p build
run: compile
	@mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && xrun -64bit -sv -uvm -uvmhome CDNS-1.2 -timescale 1ns/1ps -access +rwc $(INCDIRS) $(DEFINES) \
	    -f $(RTL_F) $(TB_SRCS) -top tb_top -sv_lib $(DPI_LIB) -svseed $(SEED) $(PLUSARGS) \
	    $(if $(filter 1,$(COV)),-coverage all -covoverwrite,) -l sim.log
endif

#------------------------------------------------------------------------------
# lint (no simulator needed): slang parses the full TB + RTL against uvm-core
#------------------------------------------------------------------------------
UVM_CORE ?= $(TB_DIR)/../../uvm-core
lint:
	UVM_CORE=$(UVM_CORE) python3 lint_slang.py

verilator-lint:
	verilator --lint-only -Wno-fatal -Wno-lint -Wno-style --timescale 1ns/1ps -f $(RTL_F) \
	    +incdir+$(UVM_CORE)/src $(UVM_CORE)/src/uvm_pkg.sv $(INCDIRS) $(TB_SRCS) --top-module tb_top

#------------------------------------------------------------------------------
# regression
#------------------------------------------------------------------------------
regress:
	python3 regress.py --sim $(SIM) --jobs 8 $(if $(filter 1,$(COV)),--cov,)

smoke:
	$(MAKE) -f smoke.mk run N=$(or $(N),200) SEED=$(SEED)

cov-report:
ifeq ($(SIM),vcs)
	urg -full64 -dir build/cov.vdb -report build/cov_report
endif

clean:
	rm -rf build run

.PHONY: compile run lint verilator-lint regress smoke cov-report clean

#------------------------------------------------------------------------------
# Spike commit logs for the trace-replay tests (t95..t100): riscv-tests ISA suite on Spike
#------------------------------------------------------------------------------
RISCV_TESTS_ISA ?= $(RISCV)/riscv64-unknown-elf/share/riscv-tests/isa
spike-logs:
	./gen_spike_logs.sh $(RISCV_TESTS_ISA) spike_logs

# same replay through the RTL under Verilator, no UVM / no licence (sim/smoke.mk phase 4)
smoke-spike:
	$(MAKE) -f smoke.mk spike
.PHONY: spike-logs smoke-spike
