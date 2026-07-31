# EDAPLAGROUND settings

| Setting | Value |
|---------|-------|
| Testbench + Design | `SystemVerilog/Verilog` |
| UVM / OVM          | `UVM 1.2` |
| Tools & Simulators | `Cadence Xcelium` |
| Run Options        | `-access +rw -coverage all +UVM_TESTNAME=ss_multichannel_test` |
| Open EPWave after run | (tb_top dumps `dump.vcd`) |

## Files to be selected

If you would like to reproduce the run on edaplayground, drop `design.sv`, two interfaces `ss_if.sv`, `sa_if.sv`, two DUTs `sub_sys.sv`, `systolic_array.sv` into design files panel. All other UVM components goes to left panel.

## Choose a test, the ultimate coverage test will be `coverage_test`

Change the `+UVM_TESTNAME=` value:

`sa_smoke_test`, `sa_random_test`, `ss_smoke_test`,
`ss_multichannel_test`, `ss_param_test`, `ss_backpressure_test`,
`ss_random_test`, `regression_test`, `coverage_test`

## This folder is designed for convinient copying

The actual file tree is under /uvm folder, which is normal setting when I design uvm testbenches. To copy over the files and update this folder, run `make copy`.