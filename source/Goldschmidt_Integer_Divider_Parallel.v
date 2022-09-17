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
// File name     : Goldschmidt_Integer_Divider_Parallel.v
// Author        : Jose R Garcia
// Created       : 31-05-2021 18:07
// Last modified : 2021/09/25 21:23:18
// Project Name  : Goldschmidt Integer Divider Parallel
// Module Name   : Goldschmidt_Integer_Divider_Parallel
// Description   : The Goldschmidt divider is an iterative method
//                 to approximate the division result. This implementation
//                 targets integer numbers.
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
module Goldschmidt_Integer_Divider_Parallel #(
  parameter integer P_GDIV_FACTORS_MSB = 31, // Integer vector MSB 
  parameter integer P_GDIV_FRAC_LENGTH = 16, // Integer vector MSB 
  parameter integer P_GDIV_CONV_BITS   = 8,  // Bits that must = 0 to determine convergence
  parameter integer P_GDIV_ROUND_LVL   = 3   //
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
  output [P_GDIV_FACTORS_MSB:0]       o_wb4s_data   // WB data, result
);

  ///////////////////////////////////////////////////////////////////////////////
  // Functions Declaration
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : Array Length
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function integer F_ARRAY_HIGH (
    input integer one_tength
  );
    // This function's variables
    integer jj;

    begin
      F_ARRAY_HIGH = 0;
      // Count how many values the LookUp Table has.
      for (jj = one_tength; jj > 10; jj = jj/10) begin
        F_ARRAY_HIGH = F_ARRAY_HIGH+1;
      end
    end
  endfunction // F_ARRAY_HIGH

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : EE Look Up Table
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function [P_GDIV_FACTORS_MSB:0] F_EE_LUT (
    input integer one_tength,
    input integer nth_iteration
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
  function [P_GDIV_FACTORS_MSB:0] F_TWO_EE (
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
  localparam integer L_MUL_FACTORS_MSB  = (P_GDIV_FACTORS_MSB+1)+(P_GDIV_FRAC_LENGTH)-1;
  localparam integer L_FACTOR1_LSB      = P_GDIV_FACTORS_MSB+1;
  localparam integer L_FACTOR1_MSB      = (P_GDIV_FACTORS_MSB*2)+1;
  localparam integer L_RESULT_MSB       = ((P_GDIV_FACTORS_MSB+1)*3)-1;
  localparam integer L_RESULT_LSB       = (P_GDIV_FACTORS_MSB+1)*2;
  localparam integer L_PRODUCT_MSB      = (P_GDIV_FACTORS_MSB+1)+((P_GDIV_FRAC_LENGTH)*2)-1;
  localparam integer L_STEP_PRODUCT_LSB = P_GDIV_FRAC_LENGTH;
  // Round up bit limits
  localparam integer L_ROUND_LSB = P_GDIV_FACTORS_MSB-P_GDIV_ROUND_LVL;
  //
  localparam integer L_NINE_NIBLES = ((P_GDIV_FACTORS_MSB+1)/4)-1;
  localparam integer L_ONE_TENGTH  = {4'h1, {L_NINE_NIBLES{4'h9}}};
  localparam integer L_ARRAY_HIGH  = F_ARRAY_HIGH(L_ONE_TENGTH);
  // Program Counter FSM States
  localparam [0:0] S_INITIATE = 1'b1; // Waits for valid factors.
  localparam [0:0] S_ITERATE  = 1'b0; // D[i] * (2-d[i]); d[i] * (2-d[i]); were i is the iteration step. D dividend & d divisor.
  // Misc.
  localparam integer               L_ZERO_FILLER        = L_FACTOR1_LSB;
  localparam integer               L_TWOS_LEADING_ZEROS = P_GDIV_FACTORS_MSB-1;
  localparam [L_MUL_FACTORS_MSB:0] L_NUMBER_TWO_EXT     = {{L_TWOS_LEADING_ZEROS{1'b0}}, 2'b10, {P_GDIV_FRAC_LENGTH{1'b0}}};

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Misc.
  integer iter;
  // Divider Accumulator signals
  reg                        r_div_acc_state;
  reg                        r_calc_remainder;
  reg                        r_neg_result;
  reg [P_GDIV_FACTORS_MSB:0] r_divisor;
  reg [L_MUL_FACTORS_MSB:0]  r_dividend_acc;
  // Turn negative to positive is signed division
  wire [P_GDIV_FACTORS_MSB:0] w_dividend = (i_wb4s_tgc[0]==1'b0 && i_wb4s_data[P_GDIV_FACTORS_MSB]==1'b1) ?
                                            -(i_wb4s_data[P_GDIV_FACTORS_MSB:0]) :
                                            i_wb4s_data[P_GDIV_FACTORS_MSB:0];
  wire [P_GDIV_FACTORS_MSB:0] w_divisor  = (i_wb4s_tgc[0]==1'b0 && i_wb4s_data[L_FACTOR1_MSB]==1'b1) ?
                                            -(i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB]) :
                                            i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB];
  // Corner Cases
  wire w_less_than          = (w_dividend > w_divisor) ? 1'b0 : 1'b1;
  wire w_divisor_zero       = i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB]==0 ? 1'b1 : 1'b0;
  wire w_divisor_is_one     = w_divisor == 1 ? 1'b1 : 1'b0;
  wire w_divisor_is_neg_one = w_divisor == -1 ? 1'b1 : 1'b0;
  wire w_equal_factors      = i_wb4s_data[P_GDIV_FACTORS_MSB:0] == i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB] ? 1'b1 : 1'b0;
  //
  reg [L_PRODUCT_MSB:0] r_product0;
  reg [L_PRODUCT_MSB:0] r_product1;
  // Iterative operation signals
  wire [L_MUL_FACTORS_MSB:0] w_divisor_acc = (r_div_acc_state==1'b1 && i_wb4s_stb==1'b1) ?
                                               {w_divisor, {P_GDIV_FRAC_LENGTH{1'b0}}} :
                                               r_product1[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB];

  wire [L_MUL_FACTORS_MSB:0] w_two_minus_divisor = (L_NUMBER_TWO_EXT + ~r_product1[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB]); // 2-divisor
  wire                       w_converged         = ~(|w_two_minus_divisor[P_GDIV_FRAC_LENGTH-1 -: P_GDIV_CONV_BITS]); // is it .00xxx...?
  reg                        r_converged;

  wire [L_MUL_FACTORS_MSB:0] w_dividend_acc = 
    (r_div_acc_state==1'b1) ? {w_dividend, {P_GDIV_FRAC_LENGTH{1'b0}}} :
    (r_div_acc_state==1'b0 && w_converged==1'b1 && r_calc_remainder==1'b1) ?
      {{(P_GDIV_FACTORS_MSB+1){1'b0}}, r_product0[L_STEP_PRODUCT_LSB-1 -: P_GDIV_FRAC_LENGTH]} :
      r_product0[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB];
  // 
  reg  [31:0]                r_lut_value; // The calculation is done in integers
  wire [L_MUL_FACTORS_MSB:0] w_lut_value = {{(P_GDIV_FACTORS_MSB+1){1'b0}}, r_lut_value[31 -: P_GDIV_FRAC_LENGTH]}; // Fixed point adjust
  //
  wire [L_MUL_FACTORS_MSB:0] w_multiplier = 
    (r_div_acc_state==1'b1) ? w_lut_value :
    (r_div_acc_state==1'b0 && w_converged==1'b1 && r_calc_remainder==1'b1 ) ?
      {r_divisor, {P_GDIV_FRAC_LENGTH{1'b0}}} : w_two_minus_divisor;
  // Round Up?
  wire w_ceil = &r_product0[P_GDIV_FACTORS_MSB:L_ROUND_LSB];
  // Result Registers Write Signals
  wire [P_GDIV_FACTORS_MSB:0] w_result_mag = 
    (w_ceil==1'b1) ? (r_product0[L_PRODUCT_MSB -: (P_GDIV_FACTORS_MSB+1)]+1) : r_product0[L_PRODUCT_MSB -: (P_GDIV_FACTORS_MSB+1)];

  wire [P_GDIV_FACTORS_MSB:0] w_result     = 
    (r_div_acc_state==1'b1) ? r_dividend_acc[L_MUL_FACTORS_MSB -: (P_GDIV_FACTORS_MSB+1)] :
    (r_neg_result==1'b1) ? -w_result_mag : w_result_mag;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  // WB4 Slave Interface ouput wires
  assign o_wb4s_stall = ~r_div_acc_state;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Divider Accumulator
  // Description : FSM that controls the pipelined division step. Performs the
  //               step iterations until divisor converges to a value close to
  //               "1".
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (i_rst == 1'b1 || i_wb4s_cyc == 1'b0) begin
      r_div_acc_state  <= S_INITIATE;
      r_divisor        <= 0;
      r_dividend_acc   <= 0;
      r_calc_remainder <= 1'b0;
      r_converged      <= 1'b0;
      r_neg_result     <= 1'b0;
    end
    else if (i_wb4s_cyc == 1'b1)begin
      casez (1'b1)
        r_div_acc_state : begin
          if (i_wb4s_stb == 1'b1) begin
            // Start division. Look for any special case that can be done
            // without the iterative process, else perform Goldschmidt division.
            casez(1'b1)
              w_divisor_zero : begin
                // If either is zero return zero
                r_converged     <= 1'b1;
                r_dividend_acc  <= -1;
                r_div_acc_state <= S_INITIATE;
              end
              w_less_than : begin
                // If either is zero return zero
                r_converged     <= 1'b1;
                r_dividend_acc  <= 0;
                r_div_acc_state <= S_INITIATE;
              end
              w_divisor_is_one : begin
                // if divisor is 1 return numerator
                r_converged     <= 1'b1;
                r_dividend_acc  <= {i_wb4s_data[P_GDIV_FACTORS_MSB:0], {P_GDIV_FRAC_LENGTH{1'b0}}};
                r_div_acc_state <= S_INITIATE;
              end
              w_divisor_is_neg_one : begin
                // if divisor is -1 return -1*numerator
                r_converged     <= 1'b1;
                r_dividend_acc  <= {-($signed(i_wb4s_data[P_GDIV_FACTORS_MSB:0])), {P_GDIV_FRAC_LENGTH{1'b0}}};
                r_div_acc_state <= S_INITIATE;
              end
              w_equal_factors : begin
                // if equal return 1 for quotient and zero for remainder
                r_converged     <= 1'b1;
                r_dividend_acc  <= {{(P_GDIV_FACTORS_MSB){1'b0}}, 1'b1, {P_GDIV_FRAC_LENGTH{1'b0}}};
                r_div_acc_state <= S_INITIATE;
              end
              default : begin
                // Shift the decimal point in the divisor.
                if (i_wb4s_tgc[0] == 1'b0 && (
                  i_wb4s_data[P_GDIV_FACTORS_MSB]==1'b1 ^ i_wb4s_data[L_FACTOR1_MSB]==1'b1)) begin
                  // If performing signed division and the result should be negative.
                  r_neg_result <= 1'b1;
                end
                else begin
                  //
                  r_neg_result <= 1'b0;
                end
                //
                r_converged     <= 1'b0;
                r_dividend_acc  <= {w_dividend, {P_GDIV_FRAC_LENGTH{1'b0}}};
                r_div_acc_state <= S_ITERATE;
              end
            endcase
            r_calc_remainder <= i_wb4s_tgc[1];
          end
          else begin
            //
            r_div_acc_state  <= S_INITIATE;
            r_dividend_acc   <= 0;
            r_calc_remainder <= 1'b0;
            r_neg_result     <= 1'b0;
          end
          r_divisor <= w_divisor;
        end
        !r_div_acc_state : begin
          //
          if (r_converged == 1'b1) begin
            // Remainder
            r_converged     <= 1'b0;
            r_div_acc_state <= S_INITIATE;
          end
          else if (w_converged == 1'b1 && r_calc_remainder == 1'b1) begin
            // Convert the remainder from decimal fraction to a natural number
            if (w_ceil == 1'b1) begin
	            //
              r_dividend_acc <= 0;
            end
            else begin
	            //
              r_dividend_acc <= r_product0[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB];
            end
            r_converged     <= 1'b1;
            r_div_acc_state <= S_ITERATE;
          end
          else if (w_converged == 1'b1) begin
            r_converged     <= 1'b0;
            r_div_acc_state <= S_INITIATE;
          end
          else begin
            // Second half of the division step
            r_dividend_acc  <= r_product0[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB];
            r_converged     <= 1'b0;
            r_div_acc_state <= S_ITERATE;
          end
        end
        default : begin
          r_div_acc_state  <= S_INITIATE;
          r_divisor        <= w_divisor;
          r_dividend_acc   <= 0;
          r_calc_remainder <= 1'b0;
          r_converged      <= 1'b0;
          r_neg_result     <= 1'b0;
        end
      endcase
    end
  end

  // WB4 Master Write Interface wires
  assign o_wb4s_ack  = (r_calc_remainder==1'b0 && r_div_acc_state==1'b0) ? w_converged : r_converged;
  assign o_wb4s_data = w_result;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : EE_LUT_Entry_Select
  // Description : Creates and selects the correct entry in the LUT.
  ///////////////////////////////////////////////////////////////////////////////
  always @(*) begin : EE_LUT_Entry_Select
    // Creates a check of the input against the 2EEx to select the LUT entry
    // that creates the proper decimal point shift.
    if (i_rst == 1'b1 || i_wb4s_cyc == 1'b0) begin
      r_lut_value = F_EE_LUT(L_ONE_TENGTH, 1);
    end
    else begin
      r_lut_value = F_EE_LUT(L_ONE_TENGTH, 1);
      for (iter = L_ARRAY_HIGH; iter > 0; iter = iter-1) begin
        if (w_divisor < F_TWO_EE(iter)) begin
           r_lut_value = F_EE_LUT(L_ONE_TENGTH, iter);
        end
      end
    end
  end // EE_LUT_Entry_Select

  /////////////////////////////////////////////////////////////////////////////
  // Process     : Dividen Multiplication Process
  // Description : This is a generic code, generally inferred as a DSPs block
  //               by modern synthesis tools.
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Dividen_Multiplication_Process
    if (i_rst == 1'b0 && i_wb4s_cyc == 1'b1) begin
      // Multiply during active cycle
      r_product0 <= w_dividend_acc * w_multiplier;
    end
  end // Dividen_Multiplication_Process

  /////////////////////////////////////////////////////////////////////////////
  // Process     : Divisor Multiplication Process
  // Description : This is a generic code, generally inferred as a DSPs block
  //               by modern synthesis tools.
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Divisor_Multiplication_Process
    if (i_rst == 1'b0 && i_wb4s_cyc == 1'b1) begin
      // Multiply during active cycle
      r_product1 <= w_divisor_acc * w_multiplier;
    end
  end // Divisor_Multiplication_Process

endmodule // Goldschmidt_Integer_Divider
