/////////////////////////////////////////////////////////////////////////////////
// BSD 3-Clause License
// 
// Copyright (c) 2020, Jose R. Garcia
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
// File name     : GID_TOP.v
// Author        : Jose R Garcia
// Created       : 2020/11/04 23:20:43
// Last modified : 2021/02/18 19:29:28
// Project Name  : IIR Filter
// Module Name   : GID_TOP
// Description   : The GID_TOP is a wrapper to include the missing signals
//                 required by the verification agents.
//
// Additional Comments:
//   
/////////////////////////////////////////////////////////////////////////////////
module GID_TOP #(
  // Compile time configurable generic parameters
  parameter integer P_GID_FACTORS_MSB  = 31,
  parameter integer P_GID_ADDR_MSB     = 1,
  parameter integer P_GID_ACCURACY_LVL = 12,
  parameter integer P_GID_ROUND_UP_LVL = 2,
  parameter integer P_GID_ANLOGIC_MUL  = 0
)(
  // Component's clocks and resets
  input i_clk,        // Main Clock
  input i_reset_sync, // Synchronous Reset
  // Sample In Wishbone(Standard) Master Read Interface
  input                    i_slave_stb,  // WB read enable
  input [P_GID_ADDR_MSB:0] i_slave_addr, // WB acknowledge 
  input [1:0]              i_slave_tga,  // WB data
  // WB(pipeline) Master Read Interface
  input [((P_GID_FACTORS_MSB+1)*2)-1:0] i_slave_div_read_data, // WB data, dividend
  // WB(pipeline) Master Write Interface
  output                       o_master_div_write_stb,  // WB stb, result
  output [P_GID_ADDR_MSB:0]    o_master_div_write_addr, // WB data, result
  output [P_GID_FACTORS_MSB:0] o_master_div_write_data, // WB data, result
  // Stubs
  output [P_GID_ADDR_MSB:0]    adr_o,   // Added to stub connections
  output [P_GID_FACTORS_MSB:0] dat_o,   // Added to stub connections
  output [P_GID_FACTORS_MSB:0] dat_i,   // Added to stub connections
  output                       we_o,    // Added to stub connections
  output                       ack_i,   // Added to stub connections
  output                       sel_o,   // Added to stub connections
  output                       cyc_o,   // Added to stub connections
  input                        stall_i, // Added to stub connections
  output                       tga_o,   // Added to stub connections
  input                        tgd_i,   // Added to stub connections
  output                       tgd_o,   // Added to stub connections
  output                       tgc_o    // Added to stub connections
);
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : div
  // Description : Instance of a Goldschmidt Division implementation.
  ///////////////////////////////////////////////////////////////////////////////
  Goldschmidt_Integer_Divider_2CPS #(
    P_GID_FACTORS_MSB,
    P_GID_ADDR_MSB,
    P_GID_ACCURACY_LVL,
    P_GID_ROUND_UP_LVL,
    P_GID_ANLOGIC_MUL
  ) div (
    // Clock and Reset
    .i_clk(i_clk),
    .i_reset_sync(i_reset_sync),
    // WB Interface
    .i_slave_stb(i_slave_stb),   // start
    .i_slave_addr(i_slave_addr), // result destination
    .i_slave_tga(i_slave_tga),   // quotient=0, remainder=1
    // mem0 WB(pipeline) master Read Interface
    .i_master_div0_read_data(i_slave_div_read_data[((P_GID_FACTORS_MSB+1)*2)-1:P_GID_FACTORS_MSB+1]), // WB data
    // mem1 WB(pipeline) master Read Interface
    .i_master_div1_read_data(i_slave_div_read_data[P_GID_FACTORS_MSB:0]), // WB data
    // mem WB(pipeline) master Write Interface
    .o_master_div_write_stb(o_master_div_write_stb),   // WB strobe
    .o_master_div_write_addr(o_master_div_write_addr), // WB address
    .o_master_div_write_data(o_master_div_write_data)  // WB data
  );

assign ack_i = 1;
assign adr_o = 0;
assign we_o  = 0;
assign sel_o = 0;
assign cyc_o = 0;
assign tga_o = 0;
assign tgd_o = 0;
assign tgc_o = 0;   

endmodule
