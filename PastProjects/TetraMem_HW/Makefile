# =====================================================================
# Makefile - build & run the TetraMem systolic-array testbenches
# with Verilator (needs 5.x for --binary --timing).
#
#   make pe       # PE unit test
#   make array    # systolic_array module-level test (N=4 by default)
#   make array2   # systolic_array with N=2 (matches the PDF 2x2 example)
#   make subsys    # sub-system (two-clock) test
#   make all       # run everything
#   make waves     # rebuild the array test dumping tb_array.vcd
#   make clean
# =====================================================================
VERILATOR ?= verilator
VFLAGS = --binary --timing --trace -Wall \
         -Wno-fatal -Wno-UNUSED -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
         -Wno-PROCASSINIT -Wno-TIMESCALEMOD -Wno-IMPORTSTAR -Wno-CASEINCOMPLETE \
         -j 0

RTL   = rtl
TB    = tb
PKG   = $(TB)/matmul_pkg.sv

LOGDIR = logs

.PHONY: all pe array array2 subsys waves clean dirs

all: pe array array2 subsys

dirs:
	@mkdir -p $(LOGDIR)

# ---------------- PE ----------------
pe: dirs
	$(VERILATOR) $(VFLAGS) --top-module tb_pe --Mdir obj_dir_pe -o sim_pe \
	    $(RTL)/pe.sv $(TB)/tb_pe.sv
	@./obj_dir_pe/sim_pe | tee $(LOGDIR)/tb_pe.log

# ------------- systolic_array (N=4) -------------
array: dirs
	$(VERILATOR) $(VFLAGS) --top-module tb_systolic_array --Mdir obj_dir_arr -o sim_arr \
	    $(PKG) $(RTL)/pe.sv $(RTL)/systolic_array.sv $(TB)/tb_systolic_array.sv
	@./obj_dir_arr/sim_arr | tee $(LOGDIR)/tb_systolic_array.log

# ------------- systolic_array (N=2, PDF example size) -------------
array2: dirs
	$(VERILATOR) $(VFLAGS) --top-module tb_systolic_array -GN=2 --Mdir obj_dir_arr2 -o sim_arr2 \
	    $(PKG) $(RTL)/pe.sv $(RTL)/systolic_array.sv $(TB)/tb_systolic_array.sv
	@./obj_dir_arr2/sim_arr2 | tee $(LOGDIR)/tb_systolic_array_n2.log

# ------------- sub-system -------------
subsys: dirs
	$(VERILATOR) $(VFLAGS) --top-module tb_sub_sys --Mdir obj_dir_sub -o sim_sub \
	    $(PKG) $(RTL)/pe.sv $(RTL)/systolic_array.sv $(RTL)/async_fifo.sv \
	    $(RTL)/data_align.sv $(RTL)/systolic_ctrl.sv $(RTL)/sub_sys.sv \
	    $(TB)/tb_sub_sys.sv
	@./obj_dir_sub/sim_sub | tee $(LOGDIR)/tb_sub_sys.log

# ------------- waveforms -------------
# Dumps tb_array.vcd (2x2, easy to read) and tb_sub_sys.vcd
waves: dirs
	$(VERILATOR) $(VFLAGS) --top-module tb_systolic_array -GN=2 --Mdir obj_dir_arr2 -o sim_arr2 \
	    $(PKG) $(RTL)/pe.sv $(RTL)/systolic_array.sv $(TB)/tb_systolic_array.sv
	@./obj_dir_arr2/sim_arr2 +dump | tee $(LOGDIR)/tb_array_waves.log
	$(VERILATOR) $(VFLAGS) --top-module tb_sub_sys --Mdir obj_dir_sub -o sim_sub \
	    $(PKG) $(RTL)/pe.sv $(RTL)/systolic_array.sv $(RTL)/async_fifo.sv \
	    $(RTL)/data_align.sv $(RTL)/systolic_ctrl.sv $(RTL)/sub_sys.sv $(TB)/tb_sub_sys.sv
	@./obj_dir_sub/sim_sub +dump | tee $(LOGDIR)/tb_sub_sys_waves.log
	@echo "Wrote tb_array.vcd and tb_sub_sys.vcd (open with gtkwave/surfer)"

clean:
	rm -rf obj_dir_* logs *.vcd sim_*
