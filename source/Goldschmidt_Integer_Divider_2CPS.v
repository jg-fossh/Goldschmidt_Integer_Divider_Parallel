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
// File name     : Goldschmidt_Integer_Divider.v
// Author        : Jose R Garcia
// Created       : 2021/01/23 11:23:01
// Last modified : 2021/08/07 17:07:59
// Project Name  : ORCs
// Module Name   : Goldschmidt_Integer_Divider
// Description   : The Goldschmidt divider is an iterative method
//                 to approximate the division result. This implementation
//                 targets integer numbers. The division step is pipeline and
//                 separated in two half steps in order to use a single
//                 multiplier.
//
// Additional Comments:
//   This code implementation is based on the description of the Goldschmidt
//   Dividers found on a publication of 2006; Synthesis of Arithmetic
//   Circuits, FPGA, ASIC and Embedded Systems by Jean-Pierre Deschamp,
//   Gery Jean Antoine Bioul and Gustavo D. Sutter. This divider computes:
//                 d(i) = d[i-1].(2-d[i-1])
//                          and
//                 D(i) = D[i-1].(2-d[i-1])
//   were 'd' is the divisor; 'D' is the dividend; 'i' is the step.
//
//  The remainder calculation requires an extra which is why the address tag is
//  used to make the decision on whether to do the calculation or skip it.
/////////////////////////////////////////////////////////////////////////////////
module Goldschmidt_Integer_Divider #(
  parameter integer P_GID_FACTORS_MSB  = 31, //
  parameter integer P_GID_ACCURACY_LVL = 24, //
  parameter integer P_GID_ROUND_UP_LVL = 3   //
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Wishbone Pipeline Slave Interface
  input                              i_wb4_slave_stb,   // WB stb, valid strobe
  input  [(P_GID_FACTORS_MSB*2)+1:0] i_wb4_slave_data,  // WB data, {divisor, dividend}
  input  [1:0]                       i_wb4_slave_tgd,   // [1] 0=quotient, 1=rem; [0] 0=signed, 1=unsigned
  output                             o_wb4_slave_stall, // WB stall, not ready
  // Wishbone Pipeline Master Interface
  output                       o_wb4_master_stb,  // WB write enable
  output [P_GID_FACTORS_MSB:0] o_wb4_master_data, // WB data, result
  input                        i_wb4_master_stall // WB stall, not ready
);

  ///////////////////////////////////////////////////////////////////////////////
  // Functions Declaration
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : Array Length
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function integer F_ARRAY_HIGH (
    input [P_GID_FACTORS_MSB:0] one_tength
  );
    // This function's variables
    integer jj;

    begin
      // Count how many values the LUT has.
      for (jj = one_tength; jj > 10; jj = jj/10) begin
        F_ARRAY_HIGH = jj;
      end
    end
  endfunction // F_ARRAY_HIGH

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : EE Look Up Table
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function [P_GID_FACTORS_MSB:0] F_EE_LUT (
    input [P_GID_FACTORS_MSB:0] one_tength,
    input integer               nth_iteration
  );
    // This function's variables
    integer hh;

    begin
      // Fill the LUT wih starting at 0.1 to 10^(-nth_iteration)
      F_EE_LUT = one_tength;
      if (nth_iteration > 0) begin
        for (hh = 1; hh < nth_iteration; hh = hh+1) begin
          // Each entry is ten times smaller than the previous.
          F_EE_LUT = F_EE_LUT / 10;
        end
      end
    end
  endfunction // F_EE_LUT

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : Two * Entered Exponent
  // Description : Calculates 2EE(input)
  ///////////////////////////////////////////////////////////////////////////////
  function [P_GID_FACTORS_MSB:0] F_TWO_EE (
    input integer ee
  );
    // This function's variables
    integer kk;

    begin
      // Fill the LUT wih starting at 0.1 to 10^(-nth_iteration)
      F_TWO_EE = 2;
      for (kk = 1; kk <= ee; kk = kk+1) begin
        // Each entry is ten times smaller than the previous.
        F_TWO_EE = F_TWO_EE * 10;
      end
    end
  endfunction // F_TWO_EE

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameters Declaration
  ///////////////////////////////////////////////////////////////////////////////
  //
  localparam integer L_MUL_FACTORS_MSB  = (P_GID_FACTORS_MSB*2)+1;
  localparam integer L_FACTOR1_LSB      = P_GID_FACTORS_MSB+1;
  localparam integer L_FACTOR1_MSB      = L_MUL_FACTORS_MSB;
  localparam integer L_STEP_PRODUCT_MSB = (L_MUL_FACTORS_MSB+1)+P_GID_FACTORS_MSB;
  localparam integer L_RESULT_MSB       = ((P_GID_FACTORS_MSB+1)*3)-1;
  localparam integer L_RESULT_LSB       = (P_GID_FACTORS_MSB+1)*2;
  // Round up bit limits
  //localparam integer L_ROUND_LSB = L_RESULT_LSB-1-P_GID_ROUND_UP_LVL;
  localparam integer L_ROUND_LSB = P_GID_FACTORS_MSB-P_GID_ROUND_UP_LVL;
  //
  localparam integer               L_NINE_BYTES   = ((P_GID_FACTORS_MSB+1)/4)-1;
  localparam [P_GID_FACTORS_MSB:0] L_ONE_TENGTH   = {4'h1, {L_NINE_BYTES{4'h9}}};
  localparam integer               L_ARRAY_HIGH   = F_ARRAY_HIGH(L_ONE_TENGTH);
  localparam integer               L_ARRAY_LENGTH = L_ARRAY_HIGH+1;
  // Program Counter FSM States
  localparam [5:0] S_IDLE                 = 6'b000001; // Waits for valid factors.
  localparam [5:0] S_SHIFT_DIVIDEND_POINT = 6'b000010; // multiply the dividend by minus powers of ten to shift the decimal point.
  localparam [5:0] S_HALF_STEP_ONE        = 6'b000100; // D[i] * (2-d[i]); were i is the iteration.
  localparam [5:0] S_HALF_STEP_TWO        = 6'b001000; // d[i] * (2-d[i]); were i is the iteration.
  localparam [5:0] S_REMAINDER_TO_NATURAL = 6'b010000; // Convert remainder from decimal fraction to a natural number.
  localparam [5:0] S_OFFLOAD_RESULT       = 6'b100000; //
  // Misc.
  localparam integer               L_TWOS_LEADING_ZEROS = P_GID_FACTORS_MSB-1;
  localparam [L_MUL_FACTORS_MSB:0] L_NUMBER_TWO_EXT     = {{L_TWOS_LEADING_ZEROS{1'b0}}, 2'b10, {L_FACTOR1_LSB{1'b0}}};

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Misc.
  integer iter;
  // Divider Accumulator signals
  reg  [P_GID_FACTORS_MSB:0] w_lut_value;
  reg  [5:0]                 r_div_acc_state;
  wire                       w_dividend_not_zero = i_wb4_slave_data[P_GID_FACTORS_MSB:0]==0 ? 1'b0 : 1'b1;
  wire                       w_divisor_not_zero  = i_wb4_slave_data[L_FACTOR1_MSB:L_FACTOR1_LSB]==0 ? 1'b0 : 1'b1;
  reg  [P_GID_FACTORS_MSB:0] r_dividend;
  reg  [L_MUL_FACTORS_MSB:0] r_multiplicand;
  reg  [L_MUL_FACTORS_MSB:0] r_multiplier;
  reg  [P_GID_FACTORS_MSB:0] r_divisor;
  reg                        r_calc_remainder;
  reg                        r_signed_extend;
  // Turn negative to positive is signed division
  wire [P_GID_FACTORS_MSB:0] w_dividend = (i_wb4_slave_tgd[0]==1'b0 && i_wb4_slave_data[P_GID_FACTORS_MSB]==1'b1) ?
                                            ~i_wb4_slave_data[P_GID_FACTORS_MSB:0] :
                                            i_wb4_slave_data[P_GID_FACTORS_MSB:0];
  wire [P_GID_FACTORS_MSB:0] w_divisor  = (i_wb4_slave_tgd[0]==1'b0 && i_wb4_slave_data[L_FACTOR1_MSB]==1'b1) ?
                                            ~i_wb4_slave_data[L_FACTOR1_MSB:L_FACTOR1_LSB] :
                                            i_wb4_slave_data[L_FACTOR1_MSB:L_FACTOR1_LSB];
  //
  reg  [((P_GID_FACTORS_MSB+1)*4)-1:0] r_product;
  // Iterative operation signals
  wire [L_MUL_FACTORS_MSB:0] w_current_divisor   = r_div_acc_state==S_HALF_STEP_TWO ? r_multiplicand : r_product[L_STEP_PRODUCT_MSB:P_GID_FACTORS_MSB+1];
  wire [L_MUL_FACTORS_MSB:0] w_two_minus_divisor = (L_NUMBER_TWO_EXT + ~w_current_divisor); // 2-divisor
  wire                       w_converged         = &r_multiplicand[P_GID_FACTORS_MSB:P_GID_FACTORS_MSB-P_GID_ACCURACY_LVL]; // is it 0.9xxx...?
  reg                        r_converged;
  // Result Registers Write Signals
  // wire                       w_rounder   = &r_product[(L_RESULT_LSB-1):L_ROUND_LSB];
  wire                       w_rounder   = &r_product[P_GID_FACTORS_MSB:L_ROUND_LSB];
  wire [P_GID_FACTORS_MSB:0] w_quotient  = r_converged==1'b0 ? r_dividend :
                                             w_rounder==1'b1 ? (r_product[L_RESULT_MSB:L_RESULT_LSB]+1) :
                                             r_product[L_RESULT_MSB:L_RESULT_LSB];

  wire [P_GID_FACTORS_MSB:0] w_remainder = r_converged==1'b0 ? r_divisor :
                                             w_rounder==1'b1 ? (r_product[L_RESULT_MSB:L_RESULT_LSB]+1) :
                                             r_product[L_RESULT_MSB:L_RESULT_LSB];
  wire [P_GID_FACTORS_MSB:0] w_result    = r_calc_remainder==1'b1 ? ((r_converged==1'b1 && r_signed_extend==1'b1) ? ~w_remainder : w_remainder) :
                                                                    ((r_converged==1'b1 && r_signed_extend==1'b1) ? ~w_quotient  : w_quotient);
  // Initial Cases
  wire w_denominator_is_one     = $signed(i_wb4_slave_data[L_FACTOR1_MSB:L_FACTOR1_LSB]) == 1 ? 1'b1 : 1'b0;
  wire w_denominator_is_neg_one = ($signed(i_wb4_slave_data[L_FACTOR1_MSB:L_FACTOR1_LSB]) == -1 && i_wb4_slave_tgd[0] == 1'b0) ? 1'b1 : 1'b0;
  wire w_equal_factors          = i_wb4_slave_data[P_GID_FACTORS_MSB:0] == i_wb4_slave_data[L_FACTOR1_MSB:L_FACTOR1_LSB] ? 1'b1 : 1'b0;
  //
  reg r_div_acc_stb;
  reg r_div_acc_stall;
  reg r_div_acc_ack;
  // Adder Controller Process signals
  reg                       r_div_wb4_stb;
  reg [P_GID_FACTORS_MSB:0] r_div_wb4_result;
  reg                       r_div_wb4_stall;
  // Control wires (indicate when this module is available)
  wire w_div_wb4_stall = r_div_wb4_stall & i_wb4_master_stall;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  // WB4 Slave Interface ouput wires
  assign o_wb4_slave_stall = r_div_acc_stall;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Divider Accumulator
  // Description : FSM that controls the pipelined division step. Performs the
  //               step iterations until divisor converges to a value close to
  //               "1".
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_reset_sync == 1'b1) begin
      r_div_acc_state  <= S_IDLE;
      r_div_acc_stb    <= 1'b0;
      r_div_acc_ack    <= 1'b0;
      r_divisor        <= 0;
      r_dividend       <= 0;
      r_multiplicand   <= 0;
      r_multiplier     <= 0;
      r_calc_remainder <= 1'b0;
      r_converged      <= 1'b0;
      r_signed_extend  <= 1'b0;
    end
    else begin
      casez (1'b1)
        r_div_acc_state[0] : begin
          if (i_wb4_slave_stb == 1'b1) begin
            // Start division. Look for any special case that can be done
            // without the iterative process, else perform Goldschmidt division.
            casez(1'b1)
              !w_divisor_not_zero : begin
                // If either is zero return zero
                r_div_acc_stb <= 1'b1;
                r_divisor       <= i_wb4_slave_data[P_GID_FACTORS_MSB:0];
                r_dividend      <= -1;
                if (w_div_wb4_stall == 1'b1) begin
                  //
                  r_div_acc_stall <= 1'b1;
                  r_div_acc_state <= S_OFFLOAD_RESULT;
                end
                else begin
                  //
                  r_div_acc_state <= S_IDLE;
                end
              end
              !w_dividend_not_zero : begin
                // If either is zero return zero
                r_div_acc_stb <= 1'b1;
                r_divisor       <= 0;
                r_dividend      <= 0;
                if (w_div_wb4_stall == 1'b1) begin
                  //
                  r_div_acc_stall <= 1'b1;
                  r_div_acc_state <= S_OFFLOAD_RESULT;
                end
                else begin
                  //
                  r_div_acc_state <= S_IDLE;
                end
               end
               w_denominator_is_one : begin
                // if denominator is 1 return numerator
                r_div_acc_stb <= 1'b1;
                r_divisor       <= 0;
                r_dividend      <=  i_wb4_slave_data[P_GID_FACTORS_MSB:0];
                if (w_div_wb4_stall == 1'b1) begin
                  //
                  r_div_acc_stall <= 1'b1;
                  r_div_acc_state <= S_OFFLOAD_RESULT;
                end
                else begin
                  //
                  r_div_acc_state <= S_IDLE;
                end
              end
              w_denominator_is_neg_one : begin
                // if denominator is -1 return -1*numerator
                r_div_acc_stb <= 1'b1;
                r_divisor       <= 0;
                r_dividend      <= ~i_wb4_slave_data[P_GID_FACTORS_MSB:0];
                if (w_div_wb4_stall == 1'b1) begin
                  //
                  r_div_acc_stall <= 1'b1;
                  r_div_acc_state <= S_OFFLOAD_RESULT;
                end
                else begin
                  //
                  r_div_acc_state <= S_IDLE;
                end
              end
              w_equal_factors : begin
                // if equal return 1 for quotient and zero for remainder
                r_div_acc_stb <= 1'b1;
                r_divisor       <= 0;
                r_dividend      <= {{(L_FACTOR1_LSB-1){1'b0}}, 1'b1};
                if (w_div_wb4_stall == 1'b1) begin
                  //
                  r_div_acc_stall <= 1'b1;
                  r_div_acc_state <= S_OFFLOAD_RESULT;
                end
                else begin
                  //
                  r_div_acc_state <= S_IDLE;
                end
              end
              default : begin
                // Shift the decimal point in the divisor.
                if (i_wb4_slave_tgd[0] == 1'b0 && (
                  i_wb4_slave_data[P_GID_FACTORS_MSB]==1'b1 ^ i_wb4_slave_data[L_FACTOR1_MSB]==1'b1)) begin
                  // If performing signed division and the result should be negative.
                  r_signed_extend <= 1'b1;
                end
                else begin
                  //
                  r_signed_extend <= 1'b0;
                end
                //
                r_multiplicand <= {w_divisor, {L_FACTOR1_LSB{1'b0}}};
                r_multiplier   <= {{L_FACTOR1_LSB{1'b0}}, w_lut_value};
                r_dividend     <= w_dividend;
                r_divisor      <= w_divisor;
                //
                r_div_acc_stb   <= 1'b0;
                r_div_acc_stall <= 1'b1;
                r_div_acc_state <= S_SHIFT_DIVIDEND_POINT;
              end
            endcase
            r_div_acc_ack    <= 1'b1;
            r_calc_remainder <= i_wb4_slave_tgd[1];
          end
          else begin
            //
            r_div_acc_stb   <= 1'b0;
            r_div_acc_ack   <= 1'b0;
            r_div_acc_stall <= 1'b0;
            r_div_acc_state <= S_IDLE;
          end
          r_converged <= 1'b0;
        end
        r_div_acc_state[1] : begin
          // S_SHIFT_DIVIDEND_POINT
          r_multiplicand  <= {r_dividend, {L_FACTOR1_LSB{1'b0}}};
          r_multiplier    <= r_multiplier;
          r_div_acc_state <= S_HALF_STEP_ONE;
        end
        r_div_acc_state[2] : begin
          // S_HALF_STEP_ONE
          if (r_converged == 1'b1) begin
            // When the divisor converges to 1.0 (actually 0.99...).
            // Return the quotient
            r_div_acc_stb <= 1'b1;
            r_div_acc_state <= S_OFFLOAD_RESULT;
          end
          else begin
            // Increase count and start another division whole step.
            r_multiplicand  <= r_product[L_STEP_PRODUCT_MSB:P_GID_FACTORS_MSB+1];
            r_multiplier    <= w_two_minus_divisor;
            r_div_acc_state <= S_HALF_STEP_TWO;
          end
        end
        r_div_acc_state[3] : begin
          if (w_converged == 1'b1 && r_calc_remainder == 1'b1) begin
            // Convert the remainder from decimal fraction to a natural number
            if (w_rounder == 1'b1) begin
              //
              r_multiplicand  <= 0;
            end
            else begin
              //
              r_multiplicand <= {{L_FACTOR1_LSB{1'b0}}, r_product[L_RESULT_LSB-1:P_GID_FACTORS_MSB+1]};
            end
            r_multiplier    <= {r_divisor, {L_FACTOR1_LSB{1'b0}}};
            r_converged     <= 1'b1;
            r_div_acc_state <= S_REMAINDER_TO_NATURAL;
          end
          else begin
            // Second half of the division step
            r_multiplicand  <= r_product[L_STEP_PRODUCT_MSB:P_GID_FACTORS_MSB+1];
            r_multiplier    <= w_two_minus_divisor;
            r_converged     <= w_converged;
            r_div_acc_state <= S_HALF_STEP_ONE;
          end
        end
        r_div_acc_state[4] : begin
          // Return the remainder
          r_div_acc_stb   <= 1'b1;
          r_div_acc_state <= S_OFFLOAD_RESULT;
        end
        r_div_acc_state[5] : begin
          // S_OFFLOAD_RESULT
          r_div_acc_ack <= 1'b0;
          if (w_div_wb4_stall == 1'b1) begin
            //
            r_div_acc_stb   <= 1'b1;
            r_div_acc_state <= S_OFFLOAD_RESULT;
          end
          else begin
            //
            r_div_acc_stb   <= 1'b0;
            r_div_acc_stall <= 1'b0;
            r_div_acc_state <= S_IDLE;
          end
        end
        default : begin
          r_div_acc_stb   <= 1'b0;
          r_div_acc_stall <= 1'b0;
          r_div_acc_ack   <= 1'b0;
          r_converged     <= 1'b0;
          r_div_acc_state <= S_IDLE;
        end
      endcase
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : WB4 Master Process
  // Description : Generates the result of the addition or substraction based on
  //               the input data and data tag.
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : WB4_Master_Process
    if (i_reset_sync == 1'b1) begin
      r_div_wb4_stb    <= 1'b0;
      r_div_wb4_stall  <= 1'b1;
      r_div_wb4_result <= 0;
    end
    else begin
      //
      r_div_wb4_stall <= i_wb4_master_stall;

      if (r_div_acc_stb == 1'b1 && w_div_wb4_stall == 1'b0) begin
        // When ready and new data comes in.
        r_div_wb4_stb    <= 1'b1;
        r_div_wb4_result <= w_result;
      end
      else if (r_div_acc_stb == 1'b0) begin
        //
        r_div_wb4_stb <= 1'b0;
      end
      else begin
        // When w_div_wb4_stall == 1
        r_div_wb4_stb <= r_div_wb4_stb;
      end
    end
  end // WB4_Master_Process

  // WB4 Master Write Interface wires
  assign o_wb4_master_stb  = r_div_wb4_stb;
  assign o_wb4_master_data = r_div_wb4_result;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : EE_LUT_Entry_Select
  // Description : Creates and selects the correct entry in the LUT.
  ///////////////////////////////////////////////////////////////////////////////
  always @(*) begin : EE_LUT_Entry_Select
    if (i_wb4_slave_stb == 1'b1) begin
      // Creates a check of the input against the 2EEx to select the LUT entry
      // that creates the proper decimal point shift.
      for (iter = L_ARRAY_HIGH; iter >= 0; iter = iter-1) begin
        if (w_divisor < F_TWO_EE(iter)) begin
           w_lut_value = F_EE_LUT(L_ONE_TENGTH, iter);
        end
      end
    end
    else begin
      w_lut_value = 0;
    end
  end // EE_LUT_Entry_Select

  /////////////////////////////////////////////////////////////////////////////
  // Process     : Multiplication Process
  // Description : This is a generic code, generally inferred as a DSPs block
  //               by modern synthesis tools.
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Multiplication_Process
    if ((r_div_acc_state[0] == 1'b1 &&  i_wb4_slave_stb == 1'b1) ||
      |r_div_acc_state[4:1] == 1'b1) begin
      //	Multiply any time the inputs changes.
      r_product <= $signed(r_multiplicand) * $signed(r_multiplier);
    end
  end // Multiplication_Process

endmodule // Goldschmidt_Integer_Divider
