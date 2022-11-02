/////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (c) 2022, Jose R. Garcia (jg-fossh@protonmail.com)
// All rights reserved.
//
// The following hardware description source code is subject to the terms of the
//                  Open Hardware Description License, v. 1.0
// If a copy of the afromentioned license was not distributed with this file you
// can obtain one at http://juliusbaxter.net/ohdl/ohdl.txt
//
/////////////////////////////////////////////////////////////////////////////////
// File name    : Goldschmidt_Integer_Divider_Parallel.v
// Author       : Jose R Garcia (jg-fossh@protonmail.com)
// Project Name : Goldschmidt Integer Divider Parallel
// Module Name  : Goldschmidt_Integer_Divider_Parallel
// Description  : The Goldschmidt divider is an iterative method
//                to approximate the division result. This implementation
//                targets integer numbers.
//
// Additional Comments:
//   Suggested values for 32bit integer division
//     P_GDIV_FACTORS_MSB = 31,                   
//     P_GDIV_FRAC_LENGTH = P_GDIV_FACTORS_MSB+1,           
//     P_GDIV_ROUND_LVL   = 3                   
/////////////////////////////////////////////////////////////////////////////////
module Goldschmidt_Integer_Divider_Parallel #(
  parameter integer P_GDIV_FACTORS_MSB = 7,                    // The MSB of each division factor.
  parameter integer P_GDIV_FRAC_LENGTH = P_GDIV_FACTORS_MSB+1, // he amount of bits after the fixed point.
  parameter integer P_GDIV_ROUND_LVL   = 2                     // Bits after fixed point that need to be '1' to round up result.
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
  // Assertions Declaration
  //     This is Verilog code and assertions were introduced in SystemVerilog,
  //     therefore we are using an initial statement to catch mis-configurations.
  //     Also Yosys and Verilator can't handle $error() nor $fatal() hence 
  //     defaulted to $display() to provide feedback to the integrator.
  ///////////////////////////////////////////////////////////////////////////////
  initial begin
    if (P_GDIV_FACTORS_MSB < 7)
      $display("\nError-Type : Parameter Out of Range\nError-Msg  : P_GDIV_FACTORS_MSB should be equal or greater than 7. \n");

    if (P_GDIV_FRAC_LENGTH == 0)
      $display("\nError-Type : Parameter Out of Range\nError-Msg  : P_GDIV_FRAC_LENGTH must be greater than 0. \n");

    if (P_GDIV_ROUND_LVL < 1)
      $display("\nError-Type : Parameter Out of Range\nError-Msg  : P_GDIV_ROUND_LVL must be greater than 0. \n");
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Functions Declaration
  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Function    : Array Length
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function automatic integer F_ARRAY_HIGH (
    input integer one_tength
  );
    // This function's variables
    integer jj;

    begin
      F_ARRAY_HIGH = 0;
      // Count how many values the LookUp Table has.
      for (jj = one_tength; jj > 0; jj = jj/10) begin
        F_ARRAY_HIGH = F_ARRAY_HIGH + 1;
      end
    end
  endfunction // F_ARRAY_HIGH

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : Two * Entered Exponent
  // Description : Calculates 2EE(input)
  ///////////////////////////////////////////////////////////////////////////////
  function automatic [P_GDIV_FACTORS_MSB:0] F_TWO_EE (
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
  // Function    : EE Look Up Table
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function automatic [((P_GDIV_FACTORS_MSB+1)*2)-P_GDIV_FRAC_LENGTH-1:0] F_EE_LUT (
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
  // Internal Parameters Declaration
  ///////////////////////////////////////////////////////////////////////////////
  // Division Process signals indexing constants
  localparam integer L_MUL_FACTORS_MSB  = (P_GDIV_FACTORS_MSB+1)+P_GDIV_FRAC_LENGTH-1;
  localparam integer L_FACTOR1_LSB      = P_GDIV_FACTORS_MSB+1;
  localparam integer L_FACTOR1_MSB      = (P_GDIV_FACTORS_MSB*2)+1;
  localparam integer L_PRODUCT_MSB      = (P_GDIV_FACTORS_MSB+1)+((P_GDIV_FRAC_LENGTH)*2)-1;
  localparam integer L_STEP_PRODUCT_LSB = P_GDIV_FRAC_LENGTH;
  // LookUp Table Constants
  localparam integer L_NINE_NIBLES = ((P_GDIV_FACTORS_MSB+1)/4)-1;
  localparam integer L_ONE_TENGTH  = {4'h1, {L_NINE_NIBLES{4'h9}}};
  localparam integer L_ARRAY_HIGH  = F_ARRAY_HIGH(L_ONE_TENGTH);
  localparam integer L_LUT_MSB     = ((P_GDIV_FACTORS_MSB+1)*2)-P_GDIV_FRAC_LENGTH-1;
  // Division Process '2' constants
  localparam integer               L_TWOS_LEADING_ZEROS = P_GDIV_FACTORS_MSB-1;
  localparam [L_MUL_FACTORS_MSB:0] L_NUMBER_TWO_EXT     = {{L_TWOS_LEADING_ZEROS{1'b0}}, 2'b10, {P_GDIV_FRAC_LENGTH{1'b0}}};
  // Division Iteration Steps Limits
  localparam integer L_QUO_LIMIT   = $rtoi($ceil($sqrt(P_GDIV_FACTORS_MSB+1)))-1;
  localparam integer L_REM_LIMIT   = $rtoi($ceil($sqrt((P_GDIV_FACTORS_MSB+1)+(P_GDIV_FRAC_LENGTH))))-1;

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Division Step Process
  reg [L_REM_LIMIT:0] r_div_step;
  // Divider Accumulator signals
  reg                         r_stall;
  reg                         r_ack;
  reg                         r_calc_remainder;
  reg                         r_neg_result;
  reg  [P_GDIV_FACTORS_MSB:0] r_divisor;
  reg  [P_GDIV_FACTORS_MSB:0] r_1step_result;
  wire                        w_converged = 
    r_calc_remainder==1'b1 ? r_div_step[L_REM_LIMIT] : r_div_step[L_QUO_LIMIT];
  // FSM States
  wire s_initiate = i_wb4s_stb & !r_stall;
  wire s_iterate  = r_stall;
  // Turn negative to positive is signed division
  wire [P_GDIV_FACTORS_MSB:0] w_dividend = 
    (i_wb4s_tgc[0]==1'b0 && i_wb4s_data[P_GDIV_FACTORS_MSB]==1'b1) ?
      -(i_wb4s_data[P_GDIV_FACTORS_MSB:0]) : i_wb4s_data[P_GDIV_FACTORS_MSB:0];

  wire [P_GDIV_FACTORS_MSB:0] w_divisor  = 
    (i_wb4s_tgc[0]==1'b0 && i_wb4s_data[L_FACTOR1_MSB]==1'b1) ?
      -(i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB]) : i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB];

  // Corner Cases
  wire w_less_than          = (w_dividend < w_divisor) ? 1'b1 : 1'b0;
  wire w_divisor_zero       = i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB]==0 ? 1'b1 : 1'b0;
  wire w_divisor_is_one     = w_divisor ==  1 ? 1'b1 : 1'b0;
  wire w_divisor_is_neg_one = w_divisor == -1 ? 1'b1 : 1'b0;
  wire w_equal_factors      = 
    i_wb4s_data[P_GDIV_FACTORS_MSB:0] == i_wb4s_data[L_FACTOR1_MSB:L_FACTOR1_LSB] ? 1'b1 : 1'b0;
  // Multiplication Process
  reg [L_PRODUCT_MSB:0] r_product0;
  reg [L_PRODUCT_MSB:0] r_product1;
  // Iterative operation signals
  wire [L_MUL_FACTORS_MSB:0] w_divisor_acc = s_initiate==1'b1 ?
      {w_divisor, {P_GDIV_FRAC_LENGTH{1'b0}}} : r_product1[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB];

  wire [L_MUL_FACTORS_MSB:0] w_two_minus_divisor =
    (L_NUMBER_TWO_EXT + ~r_product1[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB]); // 2-divisor

  wire [L_MUL_FACTORS_MSB:0] w_dividend_acc = 
    (s_initiate==1'b1) ? {w_dividend, {P_GDIV_FRAC_LENGTH{1'b0}}} :
    (r_div_step[L_REM_LIMIT]==1'b1 && r_calc_remainder==1'b1) ?
      {{(P_GDIV_FACTORS_MSB+1){1'b0}}, r_product0[L_STEP_PRODUCT_LSB-1 -: P_GDIV_FRAC_LENGTH]} :
      r_product0[L_PRODUCT_MSB:L_STEP_PRODUCT_LSB];
  // LookUp Table signals
  integer                       iter;
  reg     [L_LUT_MSB:0]         r_lut_value; // The calculation is done in integers
  wire    [L_MUL_FACTORS_MSB:0] w_lut_value = {{(P_GDIV_FACTORS_MSB+1){1'b0}}, r_lut_value}; // Fixed point adjust
  // Multiplier Select
  wire [L_MUL_FACTORS_MSB:0] w_multiplier = 
    (s_initiate==1'b1) ? w_lut_value :
    (r_div_step[L_REM_LIMIT]==1'b1 && r_calc_remainder==1'b1) ?
      {r_divisor, {P_GDIV_FRAC_LENGTH{1'b0}}} : w_two_minus_divisor;
  // Round Up?
  wire w_ceil = &r_product0[(P_GDIV_FRAC_LENGTH*2)-1 -: P_GDIV_ROUND_LVL];
  // Result Select Signals
  reg                         r_rem_zero;
  wire [P_GDIV_FACTORS_MSB:0] w_result_mag = 
    (w_ceil==1'b1) ? (r_product0[L_PRODUCT_MSB -: (P_GDIV_FACTORS_MSB+1)]+1) : 
                      r_product0[L_PRODUCT_MSB -: (P_GDIV_FACTORS_MSB+1)];
  wire [P_GDIV_FACTORS_MSB:0] w_result = 
    (r_rem_zero==1'b1)   ?              0 :
    (s_initiate==1'b1 && r_calc_remainder==1'b1) ? 
      ((r_neg_result==1'b1) ? -w_result_mag : w_result_mag) :
    (s_initiate==1'b1 && r_div_step[L_QUO_LIMIT+1]==1'b0) ? r_1step_result :
    (r_neg_result==1'b1) ?  -w_result_mag : w_result_mag;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  // WB4 Slave Interface ouput wires
  assign o_wb4s_stall = r_stall;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Divider Accumulator
  // Description : FSM that controls the pipelined division step. Performs the
  //               step iterations until divisor converges to a value close to
  //               "1".
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Divider_Accumulator_Process
    if (i_rst == 1'b1 || i_wb4s_cyc == 1'b0) begin
      r_stall          <= 1'b0;
      r_ack            <= 1'b0;
      r_divisor        <= 0;
      r_1step_result   <= 0;
      r_calc_remainder <= 1'b0;
      r_neg_result     <= 1'b0;
      r_rem_zero       <= 1'b0;
    end
    else if (i_wb4s_cyc == 1'b1) begin
      casez (1'b1)
        s_initiate : begin
          // Start division. Look for any special case that can be done
          // without the iterative process, else perform Goldschmidt division.
          casez(1'b1)
            w_divisor_zero : begin
              // If either is zero return zero
              r_1step_result <= -1;
              r_stall        <= 1'b0;
              r_ack          <= 1'b1;
            end
            w_less_than : begin
              // If either is zero return zero
              r_1step_result <= 0;
              r_stall        <= 1'b0;
              r_ack          <= 1'b1;
            end
            w_divisor_is_one : begin
              // if divisor is 1 return numerator
              r_1step_result <= i_wb4s_data[P_GDIV_FACTORS_MSB:0];
              r_stall        <= 1'b0;
              r_ack          <= 1'b1;
            end
            w_divisor_is_neg_one : begin
              // if divisor is -1 return -1*numerator
              r_1step_result <= -($signed(i_wb4s_data[P_GDIV_FACTORS_MSB:0]));
              r_stall        <= 1'b0;
              r_ack          <= 1'b1;
            end
            w_equal_factors : begin
              // if equal return 1 for quotient and zero for remainder
              r_1step_result <= 1;
              r_stall        <= 1'b0;
              r_ack          <= 1'b1;
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
              r_1step_result <= 0;
              r_stall        <= 1'b1;
              r_ack          <= 1'b0;
            end
          endcase
          r_calc_remainder <= i_wb4s_tgc[1];
          r_divisor        <= w_divisor;
          r_rem_zero       <= 1'b0;
        end
        s_iterate : begin
          // Iterate until the divisor converges towards 1
          if (w_ceil == 1'b1 && r_calc_remainder == 1'b1 && r_div_step[L_QUO_LIMIT] == 1'b1) begin     
            r_rem_zero <= 1'b1;
            r_stall    <= 1'b0;
            r_ack      <= 1'b1;
          end
          else if (w_converged == 1'b1) begin     
            r_rem_zero <= 1'b0;
            r_stall    <= 1'b0;
            r_ack      <= 1'b1;
          end
          else begin
	          //
            r_rem_zero <= 1'b0;
            r_stall    <= 1'b1;
            r_ack      <= 1'b0;
          end
        end
        default : begin
          r_divisor        <= 0;
          r_1step_result   <= 0;
          r_calc_remainder <= 1'b0;
          r_neg_result     <= 1'b0;
          r_stall          <= 1'b0;
          r_ack            <= 1'b0;
          r_rem_zero       <= 1'b0;
        end
      endcase
    end
  end // Divider_Accumulator_Process

  // WB4 Master Write Interface wires
  assign o_wb4s_ack  = r_ack;
  assign o_wb4s_data = w_result;

  ///////////////////////////////////////////////////////////////////////////////
  // Process     : EE_LUT_Entry_Select
  // Description : Creates a mux with the possiible 10^-n values given the size 
  //               of the input vectors and selects the correct that will 'shift'
  //               the inputs decimal point so that it is less the 2.0
  ///////////////////////////////////////////////////////////////////////////////
  always @(*) begin : EE_LUT_Entry_Select
    // Creates a check of the input against the 2EEx to select the LUT entry
    // that creates the proper decimal point shift.
    if (i_rst == 1'b1) begin
      r_lut_value = F_EE_LUT(L_ONE_TENGTH, 1);
    end
    else begin
      r_lut_value = F_EE_LUT(L_ONE_TENGTH, 1);
      for (iter = 2; iter <= L_ARRAY_HIGH; iter = iter+1) begin
        if (w_divisor >= F_TWO_EE(iter-1)) begin
           r_lut_value = F_EE_LUT(L_ONE_TENGTH, iter);
        end
      end
    end
  end // EE_LUT_Entry_Select

  /////////////////////////////////////////////////////////////////////////////
  // Process     : Division Step Process
  // Description : Shifts in a '1' for every step of the division. This is used
  //               to track the convergance for the quotient and remainder.
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Division_Step_Process
    if (r_stall == 1'b0) begin
      // Stall is asserted when the FSM enters the iterative states,
      // Hence when not stalling ready the signal.
      r_div_step <= 1;
    end
    else begin
      // In the itrative steps, push 1s in to detect when the compile time 
      // determined convergence occurs.
      r_div_step <= r_div_step << 1;
    end
  end // Division_Step_Process

  /////////////////////////////////////////////////////////////////////////////
  // Process     : Dividen Multiplication Process
  // Description : This is a generic code, generally inferred as a DSPs block
  //               by modern synthesis tools.
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Dividen_Multiplication_Process
    if (i_wb4s_cyc == 1'b1) begin
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
    if (i_wb4s_cyc == 1'b1) begin
      // Multiply during active cycle
      r_product1 <= w_divisor_acc * w_multiplier;
    end
  end // Divisor_Multiplication_Process
endmodule // Goldschmidt_Integer_Divider_Parallel
