# __*NOTE:*__
~~I am well aware there are bugs to be fixed features to be implemented to handle negative numbers properly. I am worrking on these code updates.~~

The code has gone through some overhauling. Fixed some bugs and applied some optimizations so it is now resource and timming friendlier. The test bench still needs work but it is enough to stimulate the design a see a waveform. But don't trust the transaction comparisons because the predictor needs work.

Documentation needs to be--almost--completly update. This will be the next step. After this I'll circle back to the test bench.

-------------------------------------------

# Abstract

A Goldschmidt integer divider written in verilog. Similar to Newton-Raphson but the two division steps can be pipelined or parallel. There are two sources/designs in this repo, a one clock per step and a two clocks per step implementations. The one clock per step uses twice the amount of multipliers or dsp blocks. The two step per clock uses only one set of multipliers or dsp to perform the division but also takes a higher amount of clock cycles to reach the result.

When originally designed it was intended for a RISC-V implementation therefore it conforms with the RISC-V ISA corner cases (in terms of the expected values when dividing by zero and such).

On average the two clock per step implementation can take ~16 clocks to reach the result, the one per step version will take ~9 clocks.

# Features
 - Two implementations(1 clock per step and 2 clock per step)
 - Wishbone 4 Interfaces
 - Parameterized factors
 - Parameterized round accuracy(the amount of steps to reach the result it not fixed).
 - Automatic Look Up Table generation for the decimal conversion

# Usage

To get this repository:

      git clone --recursive https://github.com/jg-fossh/Goldschmidt_Integer_Divider.git

The **GID_User_Guide.pdf** in the /docs directory provides more insight to the design, simulation and usage.
