/////////////////////////////////////////////////////////////////////////////////
// BSD 3-Clause License
//
// Copyright (c) 2022, Jose R. Garcia
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
/////////////////////////////////////////////////////////////////////////////////
// File name    : TB_TOP.v
// Author       : Jose R Garcia (jg-fossh@protonmail.com)
// Project Name : Goldschmidt Integer Divider
// Module Name  : TB_TOP
// Description  : The TB_TOP is a wrapper to include the missing signals
//                required by the verification agents(stub agents interface
//                unused signals)
//
// Additional Comments:
//
/////////////////////////////////////////////////////////////////////////////////
module TB_TOP #(
  parameter integer P_GDIV_FACTORS_MSB = 31,                   // The MSB of each division factor.
  parameter integer P_GDIV_FRAC_LENGTH = P_GDIV_FACTORS_MSB+1, // he amount of bits after the fixed point.
  parameter integer P_GDIV_CONV_BITS   = P_GDIV_FRAC_LENGTH,   // Bits that must = 0 to determine convergence
  parameter integer P_GDIV_ROUND_LVL   = 3                     // Bits after fixed point that need to be '1' to round up result.
)(
  // Component's clocks and resets
  input i_clk, // clock
  input i_rst, // reset
  // WB4S Pipeline Interface
  input                               i_wb4s_cyc,   // WB cyc, active/abort signal
  input  [1:0]                        i_wb4s_tgc,   // [1] 0=quotient, 1=rem; [0] 0=signed, 1=unsigned
  input                               i_wb4s_stb,   // WB stb, valid strobe
  input  [(P_GDIV_FACTORS_MSB*2)+1:0] i_wb4s_data,  // WB data, {divisor, dividend}
  output                              o_wb4s_stall, // WB stall, not ready
  output                              o_wb4s_ack,   // WB write enable
  output [P_GDIV_FACTORS_MSB:0]       o_wb4s_data,  // WB data, result
  // Wishbone Pipeline Slave Verification Agent Stubs
  input  adr_i, //
  input  we_i,  //
  input  sel_i, //
  output tga_i, // Added to stub connections
  output tgd_i, // Added to stub connections
  output tgd_o  // Added to stub connections
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  // Slave Stubs
  assign tgd_o = 0;

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : dut
  // Description : Instance of the CLU implementation.
  ///////////////////////////////////////////////////////////////////////////////
  Goldschmidt_Integer_Divider_Parallel #(
    .P_GDIV_FACTORS_MSB(P_GDIV_FACTORS_MSB), 
    .P_GDIV_FRAC_LENGTH(P_GDIV_FRAC_LENGTH),
    .P_GDIV_ROUND_LVL(P_GDIV_ROUND_LVL)
  ) dut (
    // Component's clocks and resets
    .i_clk(i_clk), // clock
    .i_rst(i_rst), // reset
    // Wishbone(Pipeline) Slave Interface
    .i_wb4s_cyc(i_wb4s_cyc),     // WB stb, valid strobe
    .i_wb4s_stb(i_wb4s_stb),     // WB stb, valid strobe
    .i_wb4s_data(i_wb4s_data),   // WB data 0
    .i_wb4s_tgc(i_wb4s_tgc),     // WB data tag, 0=add 1=substract
    .o_wb4s_stall(o_wb4s_stall), // WB stall, not ready
    .o_wb4s_ack(o_wb4s_ack),     // WB write enable
    .o_wb4s_data(o_wb4s_data)    // WB data, result
  );

endmodule
