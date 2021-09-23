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
// File name     : TB_TOP.v
// Author        : Jose R Garcia
// Created       : 2020/11/04 23:20:43
// Last modified : 2021/08/07 17:09:32
// Project Name  : Goldschmidt Integer Divider
// Module Name   : TB_TOP
// Description   : The TB_TOP is a wrapper to include the missing signals
//                 required by the verification agents(stub agents interface
//                 unused signals)
//
// Additional Comments:
//
/////////////////////////////////////////////////////////////////////////////////
module TB_TOP #(
  // Compile time configurable generic parameters
  parameter integer P_GID_FACTORS_MSB  = 31,
  parameter integer P_GID_ACCURACY_LVL = 12,
  parameter integer P_GID_ROUND_UP_LVL = 3
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Wishbone Pipeline Slave Interface Definition
  input                              i_wb4_slave_stb,   // WB stb, valid strobe
  input  [(P_GID_FACTORS_MSB*2)+1:0] i_wb4_slave_data,  // WB data {1,0}
  input  [1:0]                       i_wb4_slave_tgd,   // WB data tag, 0=add 1=substract
  output                             o_wb4_slave_stall, // WB stall, not ready
  output                             o_wb4_slave_ack,   // WB ack, strobe acknowledge
  // Wishbone Pipeline Master Interface Definition
  output                       o_wb4_master_stb,   // WB write enable
  output [P_GID_FACTORS_MSB:0] o_wb4_master_data,  // WB data, result
  input                        i_wb4_master_stall, // WB stall, not ready
  input                        i_wb4_master_ack,   // WB ack, strobe acknowledge
  // Wishbone Pipeline Slave Verification Agent Stubs
  input  cyc_i, //
  input  adr_i, //
  input  we_i,  //
  input  sel_i, //
  output dat_o, //
  output tga_o, // Added to stub connections
  output tgd_o, // Added to stub connections
  output tgc_o, // Added to stub connections
  // Wishbone Pipeline Master Verification Agent Stubs
  output cyc_o, //
  output adr_o, //
  output we_o,  // Added to stub connections
  output sel_o, // Added to stub connections
  input  dat_i, //
  input  tgd_i  //
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  // Slave Stubs
  assign dat_o = 0;
  assign tga_o = 0;
  assign tgd_o = 0;
  assign tgc_o = 0;
  // Master Stubs
  assign cyc_o = 1;
  assign we_o  = 1;
  assign sel_o = 0;
  //
  assign o_wb4_slave_ack = 0;

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : dut
  // Description : Instance of the CLU implementation.
  ///////////////////////////////////////////////////////////////////////////////
  Goldschmidt_Integer_Divider #(
    // Compile time configurable generic parameters
    .P_GID_FACTORS_MSB(P_GID_FACTORS_MSB),
    .P_GID_ACCURACY_LVL(P_GID_ACCURACY_LVL),
    .P_GID_ROUND_UP_LVL(P_GID_ROUND_UP_LVL)
  ) dut (
    // Component's clocks and resets
    .i_clk(i_clk),               // clock
    .i_reset_sync(i_reset_sync), // reset
    // Wishbone(Pipeline) Slave Interface
    .i_wb4_slave_stb(i_wb4_slave_stb),     // WB stb, valid strobe
    .i_wb4_slave_data(i_wb4_slave_data),   // WB data 0
    .i_wb4_slave_tgd(i_wb4_slave_tgd),     // WB data tag, 0=add 1=substract
    .o_wb4_slave_stall(o_wb4_slave_stall), // WB stall, not ready
    // Wishbone(Pipeline) Master Interface
    .o_wb4_master_stb(o_wb4_master_stb),     // WB write enable
    .o_wb4_master_data(o_wb4_master_data),   // WB data, result
    .i_wb4_master_stall(i_wb4_master_stall) // WB stall, not ready
  );

endmodule
