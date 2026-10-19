# ---------------------------------------------------------------------------
# Makefile -- BOOM execute-pipeline UVM testbench
#
#   make questa  TEST=boom_fp_ieee754_test     # Questa/ModelSim
#   make vcs     TEST=boom_csr_ral_test        # Synopsys VCS
#   make xcelium TEST=boom_full_test           # Cadence Xcelium
#   make lint                                  # slang syntax lint (no UVM run)
#
# TEST defaults to boom_full_test.  Add WAVES=1 for VCD dumping.
# ---------------------------------------------------------------------------

TEST   ?= boom_full_test
SEED   ?= 1
WAVES  ?= 0

RTL_DIR := ../rtl
TB_DIR  := ../tb

SRCS := $(RTL_DIR)/boom_exe_types_pkg.sv \
        $(RTL_DIR)/boom_exe_dut.sv       \
        $(TB_DIR)/boom_exe_if.sv         \
        $(TB_DIR)/boom_exe_pkg.sv        \
        $(TB_DIR)/tb_top.sv

INC   := +incdir+$(TB_DIR)

PLUS  := +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM
ifeq ($(WAVES),1)
PLUS  += +dump
endif

# ---------------------------------------------------------------- Questa ---
questa:
	vlib work
	vlog -sv $(INC) +define+UVM_NO_DPI -L mtiUvm $(SRCS)
	vsim -c -voptargs=+acc work.tb_top -L mtiUvm \
	     -sv_seed $(SEED) $(PLUS) -do "run -all; quit -f"

# ------------------------------------------------------------------- VCS ---
vcs:
	vcs -full64 -sverilog -ntb_opts uvm-1.2 $(INC) $(SRCS) \
	    -timescale=1ns/1ps -l comp.log
	./simv +ntb_random_seed=$(SEED) $(PLUS) -l sim.log

# --------------------------------------------------------------- Xcelium ---
xcelium:
	xrun -64bit -uvm -sv $(INC) $(SRCS) \
	     -timescale 1ns/1ps -svseed $(SEED) $(PLUS)

# ------------------------------------------------------------------ lint ---
# Structural syntax check with slang (https://github.com/MikePopoloski/slang)
# UVM_HOME must point at a uvm-core source tree.
lint:
	slang --lint-only $(INC) +incdir+$(UVM_HOME)/src \
	      $(UVM_HOME)/src/uvm_pkg.sv $(SRCS)

clean:
	rm -rf work transcript *.wlf csrc simv* *.log *.vcd xcelium.d xrun.*
.PHONY: questa vcs xcelium lint clean
