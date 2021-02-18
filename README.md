# Goldschmidt Integer Divider Synthesizable Unit Specification

Document        | Metadata
:-------------- | :------------------
_Version_       | v01.1.0
_Prepared by_   | Jose R Garcia
_Created_       | 2020/12/25 13:39:12
_Last modified_ | 2021/01/07 00:52:39
_Project_       | Goldschmidt_Integer_Divider

## Abstract

A Goldschmidt integer divider written in verilog. Similar to Newton-Raphson but the division step can be pipelined. This implementation's architecture target the ORC_R32IM V1.0.0 therefore it only implements a reduce subset of the Wishbone signals.

## Table Of Contents

<!-- TOC -->

- [Goldschmidt Integer Divider Synthesizable Unit Specification](#goldschmidt-integer-divider-synthesizable-unit-specification)
  - [Abstract](#abstract)
  - [Table Of Contents](#table-of-contents)
  - [1 Syntax and Abbreviations](#1-syntax-and-abbreviations)
  - [2 Design](#2-design)
  - [3 Clocks and Resets](#3-clocks-and-resets)
  - [4 Interfaces](#4-interfaces)
    - [4.1 WB Write Slave](#41-wb-write-slave)
    - [4.2 Data WB Read Master](#42-data-wb-read-master)
    - [4.3 Data WB Write Master](#43-data-wb-write-master)
  - [5 Configurable Parameters](#5-configurable-parameters)
  - [6 Memory Map](#6-memory-map)
  - [7 Test Bench and Simulation](#7-test-bench-and-simulation)
    - [7.1 Test Bench](#71-test-bench)
    - [7.2 Simulation](#72-simulation)
      - [7.3 Prerequisites](#73-prerequisites)
      - [7.4 Execution](#74-execution)

<!-- /TOC -->

## 1 Syntax and Abbreviations

Term        | Definition
:---------- | :---------------------------------------------
0b0         | Binary number syntax
0x0000_0000 | Hexadecimal number syntax
bit         | Single binary digit (0 or 1)
BYTE        | 8-bits wide data unit
DWORD       | 32-bits wide data unit
FPGA        | Field Programmable Gate Array
GCD         | Goldschmidt Convergence Division
LSB         | Least Significant bit
MSB         | Most Significant bit
WB          | Wishbone Interface


## 2 Design

The Goldschmidt division is an special application of the Newton-Raphson method. This iterative divider computes:

![\[d(i) = d[i-1].(2-d[i-1])\]](https://latex.codecogs.com/gif.latex?\inline&space;\bg_white&space;\large&space;d(i)&space;=&space;d[i-1].(2-d[i-1]))

![\D(i) = D[i-1].(2-d[i-1])](https://latex.codecogs.com/gif.latex?\inline&space;\bg_white&space;\large&space;D(i)&space;=&space;D[i-1].(2-d[i-1]))

were '_d_' is the divisor; '_D_' is the dividend; '_i_' is the step. _D_ converges toward the quotient and d converges toward 1 at a quadratic rate. For the divisor to converge to 1 it must obviously be less than 2 therefore integers greater than 2 must be multiplied by 10 to the negative powers to shift the decimal point. Consider the following example:

Step  | D                | d                 | 2-d
----: | :--------------- | :---------------- | :---------------
.	    | 16	             | 4                 | 1.6
0	    | 1.6	             | 0.4               | 1.36
1	    | 2.56             | 0.64              | 1.1296
2	    | 3.4816           | 0.8704            | 1.01679616
3	    | 3.93281536       | 0.98320384        | 1.00028211099075
4	    | 3.99887155603702 | 0.999717889009254 | 1.00000007958661
5	    | 3.99999968165356 | 0.999999920413389 | 1.00000000000001
5	    | 3.99999968165356 | 0.999999920413389 | 1.00000000000001
6     | 3.99999999999997 | 0.999999999999994 | 1
7     | 4                | 1                 | 1

The code implementation compares the size of the divisor against 2*10^_n_ were _n_ is a natural number. The result of the comparison indicates against which 10^_m_, were _m_ is a negative integer, to multiply the divisor. Then the Goldschmidt division is performed until the divisor converges to degree indicated by `P_GCD_ACCURACY`. The quotient returned is the rounded up value to which the dividend converged to. Each Goldschmidt step is performed in to two half steps in order use only one multiplier and save resources.

The remainder calculation requires an extra which is why the address tag is used to make the decision on whether to do the calculation or skip it. The calculation simply take the value after the decimal point of the quotient a multiplies it by the divisor.


## 3 Clocks and Resets

Signals        | Initial State | Direction | Definition
:------------- | :-----------: | :-------: | :--------------------------------------------------------------------
`i_clk`        |      N/A      |    In     | Input clock. Streaming interface fall within the domain of this clock
`i_reset_sync` |      N/A      |    In     | Synchronous reset. Used to reset this unit.

## 4 Interfaces

The ORC_R32I employs independent interfaces for reading the memory containing the instructions to be decoded and reading and writing to other devices such as memories and I/O devices.

The divider and divisor are received through `i_master_div0_read_data` and `i_master_div1_read_data` and qualified by the `i_slave_stb`. The `i_slave_stb` signal could be managed in different ways. It can be a pulse with the width of a singe clock to operate as a pipelined Wishbone interface and the `o_master_div_write_stb` can be considered as a Wishbone o_ACK. I can also be operated as a Wishbone standard using those same signals.

When the division concludes  the `o_master_div_write_stb` is asserted and writes the result to the address received through `i_slave_addr`.

### 4.1 WB Write Slave

Signals        | Initial State | Dimension | Direction | Definition
:------------- | :-----------: | :-------: | :-------: | :-----------------------
`i_slave_stb`  |      0b0      |   1-bit   |    In     | Start indicator.
`i_slave_addr` |      N/A      | `[P_GID_ADDR_MSB:0]` |    In     | Result destination address.
`i_slave_tga`  |      N/A      | `[1:0]`  |    In     | Indicates the calculation to perform. bit[1] 0=quotient, 1=remainder; bit[0] 0=signed, 1=unsigned

### 4.2 Data WB Read Master

Signals                   | Initial State | Dimension               | Direction | Definition
:------------------------ | :-----------: | :---------------------: | :-------: | :---------
`i_master_div0_read_data` |      N/A      | `[P_GID_FACTORS_MSB:0]` |    In     | Dividend.
`i_master_div0_read_data` |      N/A      | `[P_GID_FACTORS_MSB:0]` |    In     | Divisor.

### 4.3 Data WB Write Master

Signals                   | Initial State | Dimension | Direction | Definition
:------------------------ | :-----------: | :-------: | :-------: | :------------------------
`o_master_div_write_stb`  |      0b0      |   1-bit   |    Out    | Write request signal.
`o_master_div_write_addr` |  0x0000_0000  | `[P_GID_ADDR_MSB:0]`  |    Out    | Write Address signal.
`o_master_div_write_data` |      0x0      | `[P_GID_FACTORS_MSB:0]` |    Out    | Write data

## 5 Configurable Parameters

Parameters           |   Default  | Description
:------------------- | :--------: | :---------------------------------------------------
`P_GID_FACTORS_MSB`  |      31    | Dividend, divisor and results most significant bit
`P_GID_ADDR_MSB`     |      4     | Most significant bit of the result's destination address. For the ORC_R32IM Log2(Number_Of_Total_Register)-1
`P_GID_ACCURACY_LVL` |     12     | Divisor Convergence Threshold. How close to one does it get to accept the result. These are the 32bits after the decimal point, 0.XXXXXXXX expressed as an integer. The default value represent the 999 part of a 64bit binary fractional number equal to 0.999.
`P_GID_ROUND_UP_LVL` |      2     | Number of bits to look at after the decimal point to round up.
`P_IS_ANLOGIC`       |      0     | When '1' it generates ANLOGIC Eagle FPGA DSPs.

## 6 Memory Map

N/A

## 7 Test Bench and Simulation

### 7.1 Test Bench

The test bench is written in uvm-python (UVM), it requires cocotb. A Wishbone Slave verification agent stimulates the DUT by sending factors for the DUT to provide the division result. A Wishbone Master verification agent is used as a monitor to capture the result. A predictor sees the Wishbone Slave transactions and consequently generates Wishbone Master transactions to compare against the response generated by the DUT.

### 7.2 Simulation

#### 7.3 Prerequisites

 - Verilator
 - cocotb
 - cocotb-coverage (optional)
 - uvm-python
 - gtkwave(optional)

To install a simulator follow the instructions in in the verilator website.
For setting cocotb and uvm-python:

    sudo apt install python3-pip
    pip install cocotb
    pip install cocotb-coverage
    git clone https://github.com/tpoikela/uvm-python.git
    cd uvm-python
    python -m pip install --user .


#### 7.4 Execution

From the /Goldschmidt_Integer_Divider/sim/ directory run the command

    make

To view the wave form open the file `wave.gtkw` with gtkwave.
