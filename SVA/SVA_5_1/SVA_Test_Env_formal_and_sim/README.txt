Michael Avery
Cadence Design Systems
15th September 2022
V3.0

This provides a minimal test harness for experimenting with SVA properties in both Simulation (Cadence Xcelium Simulator) and Formal (Cadence Jasper).
 
 Working examples are provided for both simulation and for formal.
 The expectation is that you modify what is provided to experiment with your own properties.

 Formal and Jasper
 ======================
 To run:
 $> cd ./jg_equiv
 $> ./RUNME.sh
 
 ====================================================
 Observe how the test runs to see how you can cover an example of your property passing, failing and use WaveEdit feature 
 to change what you want to observe. Note as the design only contain wires, signals are effectively driven follwing any constraints/assumptions which you give.  One can check the equivalence of properties by asserting one of them and 
 assuming the other, taking care it works both ways around, namely flip the assert to an assume and vice-versa.
 One can observe the effects of assumptions on the traces witnessed, and whatever else one wishes.
 JasperGold is probably more useful for learning SVA properties than simulation is. 

 Simulation.
 =================
 To run:
 $> cd ./sim
 $> ./RUNME.sh
 
 Observe how the test runs to see how you can define stimulus for your own properties.
 Modify the environment by editing seqtest_asserted1.v :
 a) Write your own properties
 b) Make calls to do_test() to create stimulus, for example
 do_test(";;;AF;BG;CH;I;;;;;"); means, where ; is the cycle seperator......
 the call above means no signals are true for the first three cycles, 
 then only A and F high for that cycle, 
 then only B and G are high for that cycle, and so on.
 Subsequent calls to do_test continue from where the previous one left off.
 
 
 Contact mavery@cadence.com to report any bugs or suggest improvements.
