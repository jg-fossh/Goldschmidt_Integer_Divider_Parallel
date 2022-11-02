# __*NOTE:*__

The code has gone through some overhauling. Fixed some bugs and applied some optimizations so it is now resource and timming friendlier. The test bench still needs work but it is enough to stimulate the design a see a waveform. But don't trust the transaction comparisons because the predictor needs work.

I need to circle back to the test bench.

-------------------------------------------

# Abstract

A Goldschmidt integer divider written in verilog. Similar to Newton-Raphson but the multiplications are performed in parallel. 

When originally designed it was intended for a RISC-V implementation therefore it conforms with the RISC-V ISA corner cases (in terms of the expected values when dividing by zero and such).

On average the two clock per step implementation can take ~16 clocks to reach the result, the one per step version will take ~9 clocks.

# Features
 - 1 clock per step
 - Wishbone4 Interfaces
 - Parameterized factors lengths
 - Automatic Look Up Table generation for the decimal conversion

# Usage

To get this repository:

      git clone --recursive https://github.com/jg-fossh/Goldschmidt_Integer_Divider.git

The **GID_User_Guide.pdf** in the /docs directory provides more insight to the design, simulation and usage.
