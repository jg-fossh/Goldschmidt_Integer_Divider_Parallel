/////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (c) 2023, Jose R. Garcia (jg-fossh@protonmail.com)
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
//                targets integer numbers. For this version the approach is to
//                minimal DSPs using only two sets of Multiplier 'banks' and 
//                apply backpreassure to the pipeline while the operations is 
//                performed. It also uses RAM blocks to store the 'normalizing'
//                values.
//
// Additional Comments:
//   Suggested values for 32bit integer division
//     P_GDIV_FACTORS_MSB = 31,                   
//     P_GDIV_FRAC_LENGTH = P_GDIV_FACTORS_MSB+1,           
//     P_GDIV_ROUND_LVL   = 3                   
/////////////////////////////////////////////////////////////////////////////////
module Goldschmidt_Integer_Divider_Parallel #(
  parameter integer P_GDIV_FACTORS_MSB = 24,                   // The MSB of each division factor.
  parameter integer P_GDIV_FRAC_LENGTH = P_GDIV_FACTORS_MSB+1, // he amount of bits after the fixed point.
  parameter integer P_GDIV_ROUND_LVL   = 3,                    // Bits after fixed point that need to be '1' to round up result.
  parameter integer P_GDIV_RDUC_STP_BY = 0                     // Force a reduction in the amount of steps of the division.
)(
  // Component's clocks and resets
  input i_clk, // clock
  input i_rst, // reset
  // WB4S Pipeline Interface
  input                               i_wb4s_cyc,   // WB cyc, active/abort signal
  input                               i_wb4s_stb,   // WB stb, valid strobe
  input  [(P_GDIV_FACTORS_MSB*2)+1:0] i_wb4s_data,  // WB data, {divisor, dividend}
  input  [1:0]                        i_wb4s_tgd,   // [1] 0=quotient, 1=rem; [0] 0=signed, 1=unsigned
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
      
    if (P_GDIV_RDUC_STP_BY < 0 || P_GDIV_RDUC_STP_BY > $rtoi($ceil($sqrt(P_GDIV_FACTORS_MSB+1)))-1)
      $display("\nError-Type : Parameter Out of Range\nError-Msg  : P_GDIV_RDUC_STP_BY is out of range. \n");
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Functions Declaration
  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Function    : Array Length
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function automatic integer F_ARRAY_HIGH (
    input [L_LUT_MSB:0] one_tength
  );
    // This function's variables
    reg [L_LUT_MSB:0] jj;

    begin
      F_ARRAY_HIGH = 0;
      // Count how many values the LookUp Table has.
      for (jj = one_tength; jj > 0; jj = jj/10) begin
        F_ARRAY_HIGH = F_ARRAY_HIGH + 1;
      end
    end
  endfunction // F_ARRAY_HIGH

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : ROM Address MSB
  // Description : .
  ///////////////////////////////////////////////////////////////////////////////
  function automatic integer F_ROM_ADDR_MSB (
    input integer v_array_high
  );
    begin

      F_ROM_ADDR_MSB = $clog2(v_array_high-1);
      if (F_ROM_ADDR_MSB >= 8)
        F_ROM_ADDR_MSB = 15;
      else
        F_ROM_ADDR_MSB = 7;
    end
  endfunction // F_ROM_ADDR_MSB

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
      // create a constant values of 2E(ee) to compare against a detect home
      // much the decimal point must roll over.
      F_TWO_EE = 20;
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
    input integer nth_iteration
  );
    // This function's variables
    integer hh;

    begin
      // Fill the LUT wih starting at 0.1 to 10^(-nth_iteration)
      F_EE_LUT = L_ONE_TENGTH;
      for (hh = 1; hh < nth_iteration; hh = hh+1) begin
        // Each entry is ten times smaller than the previous.
        F_EE_LUT = F_EE_LUT / 10;
      end
    end
  endfunction // F_EE_LUT

  ///////////////////////////////////////////////////////////////////////////////
  // Function    : EE Look Up Table
  // Description : Calculates the length of the Power of 10 Look Up Table.
  ///////////////////////////////////////////////////////////////////////////////
  function automatic [L_BRAM_ADDR_MSB:0] F_LUT_ADDR (
    input [P_GDIV_FACTORS_MSB:0] v_divisor
  );
    // This function's variables
    integer jj;

    begin
      //
      F_LUT_ADDR = 0;
      for (jj = 1; jj <= L_ARRAY_HIGH; jj = jj+1) begin
        if (v_divisor >= F_TWO_EE(jj)) begin
           F_LUT_ADDR = jj[L_BRAM_ADDR_MSB:0];
        end
      end
    end
  endfunction // F_LUT_ADDR
  
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
  localparam integer       L_LUT_MSB       = ((P_GDIV_FACTORS_MSB+1)*2)-P_GDIV_FRAC_LENGTH-1;
  localparam integer       L_NINE_NIBLES   = ((P_GDIV_FACTORS_MSB+1)/4)-1;
  localparam [L_LUT_MSB:0] L_ONE_TENGTH    = {4'h1, {L_NINE_NIBLES{4'h9}}, {(L_LUT_MSB-((L_NINE_NIBLES*4)+4-1)){1'b0}}};
  localparam integer       L_ARRAY_HIGH    = F_ARRAY_HIGH(L_ONE_TENGTH);
  localparam integer       L_BRAM_ADDR_MSB = F_ROM_ADDR_MSB(L_ARRAY_HIGH);
  // Division Process '2' constants
  localparam integer               L_TWOS_LEADING_ZEROS = P_GDIV_FACTORS_MSB-1;
  localparam [L_MUL_FACTORS_MSB:0] L_NUMBER_TWO_EXT     = {{L_TWOS_LEADING_ZEROS{1'b0}}, 2'b10, {P_GDIV_FRAC_LENGTH{1'b0}}};
  // Division Iteration Steps Limits
  localparam integer L_QUO_LIMIT = $rtoi($ceil($sqrt(P_GDIV_FACTORS_MSB+1)))-1-P_GDIV_RDUC_STP_BY;
  localparam integer L_REM_LIMIT = $rtoi($ceil($sqrt((P_GDIV_FACTORS_MSB+1)+(P_GDIV_FRAC_LENGTH))))-1-P_GDIV_RDUC_STP_BY;

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
  reg                         r_gte_twenty;
  wire                        w_converged = 
    r_calc_remainder==1'b1 ? r_div_step[L_REM_LIMIT] : r_div_step[L_QUO_LIMIT];
  // FSM States
  wire s_initiate = i_wb4s_stb & !r_stall;
  wire s_ee_mul   = r_gte_twenty;
  wire s_iterate  = !r_gte_twenty & r_stall;
  // Turn negative to positive is signed division
  wire [P_GDIV_FACTORS_MSB:0] w_dividend = 
    (i_wb4s_tgd[0]==1'b0 && i_wb4s_data[P_GDIV_FACTORS_MSB]==1'b1) ?
      -(i_wb4s_data[P_GDIV_FACTORS_MSB:0]) : i_wb4s_data[P_GDIV_FACTORS_MSB:0];

  wire [P_GDIV_FACTORS_MSB:0] w_divisor  = 
    (i_wb4s_tgd[0]==1'b0 && i_wb4s_data[L_FACTOR1_MSB]==1'b1) ?
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
  integer               iter;
  integer               iter2;
  wire    [L_LUT_MSB:0] w_lut_value; // The calculation is done in integers
  // Multiplier Select
  wire [L_MUL_FACTORS_MSB:0] w_multiplier = 
    (s_initiate==1'b1) ? {{(P_GDIV_FACTORS_MSB+1){1'b0}}, L_ONE_TENGTH} : // Fixed point adjust for 2^P_GDIV_FACTORS_MSB+1
    (s_ee_mul==1'b1)   ? {{(P_GDIV_FACTORS_MSB+1){1'b0}}, w_lut_value} : // Fixed point adjust
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

  wire [L_BRAM_ADDR_MSB:0] w_addr = s_iterate | i_rst ? 0 : F_LUT_ADDR(w_divisor);

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
      r_gte_twenty     <= 1'b0;
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
              if (i_wb4s_tgd[0] == 1'b0 && (
                i_wb4s_data[P_GDIV_FACTORS_MSB]==1'b1 ^ i_wb4s_data[L_FACTOR1_MSB]==1'b1)) begin
                // If performing signed division and the result should be negative.
                r_neg_result <= 1'b1;
              end
              else begin
                //
                r_neg_result <= 1'b0;
              end
              //
              r_gte_twenty   <= (w_divisor >= 20) ? 1'b1 : 1'b0; // if the divisor is greater than or equal 20 then need a second round to adjust.
              r_1step_result <= 0;
              r_stall        <= 1'b1;
              r_ack          <= 1'b0;
            end
          endcase
          r_calc_remainder <= i_wb4s_tgd[1];
          r_divisor        <= w_divisor;
          r_rem_zero       <= 1'b0;
        end
        s_ee_mul : begin
          r_gte_twenty <= 1'b0;
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
          r_gte_twenty     <= 1'b0;
        end
      endcase
    end
  end // Divider_Accumulator_Process

  // WB4 Master Write Interface wires
  assign o_wb4s_ack  = r_ack;
  assign o_wb4s_data = w_result;

  /////////////////////////////////////////////////////////////////////////////
  // Process     : Division Step Process
  // Description : Shifts in a '1' for every step of the division. This is used
  //               to track the convergance for the quotient and remainder.
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Division_Step_Process
    if (r_stall == 1'b1 && s_ee_mul == 1'b0) begin
      // In the itrative steps, push 1s in to detect when the compile time 
      // determined convergence occurs.
      r_div_step <= r_div_step << 1;
    end
    else begin
      // Stall is asserted when the FSM enters the iterative states,
      // Hence when not stalling ready the signal.
      r_div_step <= 1;
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

  ///////////////////////////////////////////////////////////////////////////////
  // Instance    : Bram_Lut
  // Description : 

  ///////////////////////////////////////////////////////////////////////////////
  Generic_Simple_DPRAM #(
    .P_SPRAM_DATA_MSB(L_LUT_MSB),
    .P_SPRAM_ADDR_MSB(L_BRAM_ADDR_MSB),
    //.P_SPRAM_ADDR_MSB(L_BRAM_ADDR_MSB),
    .P_SPRAM_MASK_MSB(0),
    .P_SPRAM_HAS_FILE(1),
    .P_SPRAM_INIT_FILE("lut.memb")
  ) Bram_Lut (
    .i_ce(1),
    .i_wclk(i_clk),
    .i_rclk(i_clk),
    .i_waddr(11),
    .i_raddr(w_addr),
    .i_we(0),
    .i_mask(0), // 0=writes, 1=masks
    .i_wdata(0),
    .o_rdata(w_lut_value)
);


endmodule // Goldschmidt_Integer_Divider_Parallel
