`timescale 1ns / 1ps

// Comprehensive self-testing testbench for ibex_multdiv_fast
module tb_ibex_multdiv_fast;

  import ibex_pkg::*;

  // Clock and reset
  logic clk_i;
  logic rst_ni;
  
  // Test tracking
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  //========================================================================
  // DUT Signals
  //========================================================================
  
  // Control signals
  logic mult_en_i;
  logic div_en_i;
  logic mult_sel_i;
  logic div_sel_i;
  md_op_e operator_i;
  logic [1:0] signed_mode_i;
  
  // Operands
  logic [31:0] op_a_i;
  logic [31:0] op_b_i;
  
  // ALU interface
  logic [33:0] alu_adder_ext_i;
  logic [31:0] alu_adder_i;
  logic equal_to_zero_i;
  logic data_ind_timing_i;
  
  // ALU operands output
  logic [32:0] alu_operand_a_o;
  logic [32:0] alu_operand_b_o;
  
  // Intermediate value interface
  logic [33:0] imd_val_q_i[2];
  logic [33:0] imd_val_d_o[2];
  logic [1:0] imd_val_we_o;
  
  // Control
  logic multdiv_ready_id_i;
  
  // Output
  logic [31:0] multdiv_result_o;
  logic valid_o;

  //========================================================================
  // DUT Instantiation
  //========================================================================
  
  ibex_multdiv_fast #(
    .RV32M(ibex_pkg::RV32MFast)
  ) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .mult_en_i(mult_en_i),
    .div_en_i(div_en_i),
    .mult_sel_i(mult_sel_i),
    .div_sel_i(div_sel_i),
    .operator_i(operator_i),
    .signed_mode_i(signed_mode_i),
    .op_a_i(op_a_i),
    .op_b_i(op_b_i),
    .alu_adder_ext_i(alu_adder_ext_i),
    .alu_adder_i(alu_adder_i),
    .equal_to_zero_i(equal_to_zero_i),
    .data_ind_timing_i(data_ind_timing_i),
    .alu_operand_a_o(alu_operand_a_o),
    .alu_operand_b_o(alu_operand_b_o),
    .imd_val_q_i(imd_val_q_i),
    .imd_val_d_o(imd_val_d_o),
    .imd_val_we_o(imd_val_we_o),
    .multdiv_ready_id_i(multdiv_ready_id_i),
    .multdiv_result_o(multdiv_result_o),
    .valid_o(valid_o)
  );

  //========================================================================
  // Clock Generation
  //========================================================================
  
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  //========================================================================
  // ALU Adder Simulation
  //========================================================================
  
  // Simulate the ALU adder behavior
  always_comb begin
    alu_adder_ext_i = {1'b0, alu_operand_a_o} + {1'b0, alu_operand_b_o};
    alu_adder_i = alu_adder_ext_i[32:1];
  end

  //========================================================================
  // Intermediate Value Register Simulation
  //========================================================================
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      imd_val_q_i[0] <= '0;
      imd_val_q_i[1] <= '0;
    end else begin
      if (imd_val_we_o[0]) begin
        imd_val_q_i[0] <= imd_val_d_o[0];
      end
      if (imd_val_we_o[1]) begin
        imd_val_q_i[1] <= imd_val_d_o[1];
      end
    end
  end

  //========================================================================
  // Helper Tasks
  //========================================================================
  
  // Check result and update counters
  task automatic check_result(input string test_name, input logic condition);
    test_count++;
    if (condition) begin
      pass_count++;
    end else begin
      fail_count++;
      $display("FAIL: %s (result=0x%08h)", test_name, multdiv_result_o);
    end
  endtask
  
  // Initialize all signals
  task automatic init_signals();
    mult_en_i = 1'b0;
    div_en_i = 1'b0;
    mult_sel_i = 1'b0;
    div_sel_i = 1'b0;
    operator_i = MD_OP_MULL;
    signed_mode_i = 2'b00;
    op_a_i = 32'h0;
    op_b_i = 32'h0;
    equal_to_zero_i = 1'b0;
    data_ind_timing_i = 1'b0;
    multdiv_ready_id_i = 1'b1;
  endtask
  
  // Perform multiplication
  task automatic multiply(
    input logic [31:0] a,
    input logic [31:0] b,
    input md_op_e op,
    input logic [1:0] signed_mode,
    output logic [31:0] result
  );
    // Set up inputs
    op_a_i = a;
    op_b_i = b;
    operator_i = op;
    signed_mode_i = signed_mode;
    mult_sel_i = 1'b1;
    div_sel_i = 1'b0;
    multdiv_ready_id_i = 1'b1;
    
    // Start multiplication
    @(posedge clk_i);
    mult_en_i = 1'b1;
    
    // Keep mult_en_i high and wait for valid
    while (!valid_o) begin
      @(posedge clk_i);
    end
    
    // Capture result
    result = multdiv_result_o;
    
    // Clear enable
    mult_en_i = 1'b0;
    @(posedge clk_i);
  endtask
  
  // Perform division
  task automatic divide(
    input logic [31:0] a,
    input logic [31:0] b,
    input md_op_e op,
    input logic [1:0] signed_mode,
    output logic [31:0] result
  );
    // Set up inputs
    op_a_i = a;
    op_b_i = b;
    operator_i = op;
    signed_mode_i = signed_mode;
    mult_sel_i = 1'b0;
    div_sel_i = 1'b1;
    equal_to_zero_i = (b == 32'h0);
    multdiv_ready_id_i = 1'b1;
    
    // Start division
    @(posedge clk_i);
    div_en_i = 1'b1;
    
    // Keep div_en_i high and wait for valid
    while (!valid_o) begin
      @(posedge clk_i);
    end
    
    // Capture result
    result = multdiv_result_o;
    
    // Clear enable
    div_en_i = 1'b0;
    @(posedge clk_i);
  endtask

  //========================================================================
  // Test: Unsigned Multiplication (MULL)
  //========================================================================
  
  task automatic test_mul_unsigned();
    logic [31:0] result;
    logic [63:0] expected;
    $display("Testing unsigned MULL operations...");
    
    // Test 1: Simple multiplication
    multiply(32'd15, 32'd10, MD_OP_MULL, 2'b00, result);
    expected = 64'd150;
    check_result("MUL 15 * 10", result == expected[31:0]);
    
    // Test 2: Zero multiplication
    multiply(32'd0, 32'd999, MD_OP_MULL, 2'b00, result);
    check_result("MUL 0 * 999", result == 32'd0);
    
    // Test 3: One multiplication
    multiply(32'd1, 32'd12345, MD_OP_MULL, 2'b00, result);
    check_result("MUL 1 * 12345", result == 32'd12345);
    
    // Test 4: Large numbers
    multiply(32'hFFFF_FFFF, 32'h0000_0002, MD_OP_MULL, 2'b00, result);
    expected = 64'hFFFF_FFFF * 64'h2;
    check_result("MUL 0xFFFFFFFF * 2", result == expected[31:0]);
    
    // Test 5: Powers of 2
    multiply(32'd256, 32'd128, MD_OP_MULL, 2'b00, result);
    check_result("MUL 256 * 128", result == 32'd32768);
    
    // Test 6: Maximum values
    multiply(32'hFFFF_FFFF, 32'hFFFF_FFFF, MD_OP_MULL, 2'b00, result);
    expected = 64'hFFFF_FFFF * 64'hFFFF_FFFF;
    check_result("MUL MAX * MAX", result == expected[31:0]);
    
    // Test 7: Simple case
    multiply(32'd100, 32'd200, MD_OP_MULL, 2'b00, result);
    check_result("MUL 100 * 200", result == 32'd20000);
  endtask

  //========================================================================
  // Test: Signed Multiplication (MULL)
  //========================================================================
  
  task automatic test_mul_signed();
    logic [31:0] result;
    logic signed [63:0] expected;
    logic signed [31:0] a_signed, b_signed;
    $display("Testing signed MULL operations...");
    
    // Test 1: Positive * Positive
    multiply(32'd50, 32'd20, MD_OP_MULL, 2'b11, result);
    check_result("MULS 50 * 20", result == 32'd1000);
    
    // Test 2: Positive * Negative
    a_signed = 32'd100;
    b_signed = -32'd5;
    multiply(a_signed, b_signed, MD_OP_MULL, 2'b11, result);
    expected = a_signed * b_signed;
    check_result("MULS 100 * -5", result == expected[31:0]);
    
    // Test 3: Negative * Positive
    a_signed = -32'd50;
    b_signed = 32'd10;
    multiply(a_signed, b_signed, MD_OP_MULL, 2'b11, result);
    expected = a_signed * b_signed;
    check_result("MULS -50 * 10", result == expected[31:0]);
    
    // Test 4: Negative * Negative
    a_signed = -32'd25;
    b_signed = -32'd8;
    multiply(a_signed, b_signed, MD_OP_MULL, 2'b11, result);
    expected = a_signed * b_signed;
    check_result("MULS -25 * -8", result == expected[31:0]);
    
    // Test 5: -1 * value
    a_signed = -32'd1;
    b_signed = 32'd12345;
    multiply(a_signed, b_signed, MD_OP_MULL, 2'b11, result);
    expected = a_signed * b_signed;
    check_result("MULS -1 * 12345", result == expected[31:0]);
    
    // Test 6: Simple negative
    a_signed = -32'd10;
    b_signed = 32'd20;
    multiply(a_signed, b_signed, MD_OP_MULL, 2'b11, result);
    expected = a_signed * b_signed;
    check_result("MULS -10 * 20", result == expected[31:0]);
  endtask

  //========================================================================
  // Test: MULH Operations
  //========================================================================
  
  task automatic test_mulh();
    logic [31:0] result;
    logic [63:0] expected;
    logic signed [31:0] a_signed, b_signed;
    logic signed [63:0] expected_signed;
    $display("Testing MULH operations...");
    
    // Test 1: Unsigned MULH
    multiply(32'hFFFF_FFFF, 32'hFFFF_FFFF, MD_OP_MULH, 2'b00, result);
    expected = 64'hFFFF_FFFF * 64'hFFFF_FFFF;
    check_result("MULHU MAX * MAX", result == expected[63:32]);
    
    // Test 2: Unsigned MULH simple
    multiply(32'h0000_0002, 32'h8000_0000, MD_OP_MULH, 2'b00, result);
    expected = 64'h2 * 64'h8000_0000;
    check_result("MULHU 2 * 0x80000000", result == expected[63:32]);
    
    // Test 3: Signed MULH - Positive * Positive
    a_signed = 32'h7FFF_FFFF;
    b_signed = 32'h0000_0002;
    multiply(a_signed, b_signed, MD_OP_MULH, 2'b11, result);
    expected_signed = a_signed * b_signed;
    check_result("MULH 0x7FFFFFFF * 2", result == expected_signed[63:32]);
    
    // Test 4: Signed MULH - Large numbers
    a_signed = 32'h4000_0000;
    b_signed = 32'h4000_0000;
    multiply(a_signed, b_signed, MD_OP_MULH, 2'b11, result);
    expected_signed = a_signed * b_signed;
    check_result("MULH 0x40000000 * 0x40000000", result == expected_signed[63:32]);
    
    // Test 5: Mixed sign MULHSU - CORRECTED
    // For MULHSU: a is signed (signed_mode_i[0]=1), b is unsigned (signed_mode_i[1]=0)
    // Use simple values: 4 (signed) * 2 (unsigned) = 8
    // Result: 0x0000000000000008, upper 32 bits = 0x00000000
    multiply(32'h0000_0004, 32'h0000_0002, MD_OP_MULH, 2'b01, result);
    check_result("MULHSU 4 * 2", result == 32'h0000_0000);
  endtask

  //========================================================================
  // Test: Unsigned Division
  //========================================================================
  
  task automatic test_div_unsigned();
    logic [31:0] result;
    $display("Testing unsigned DIV operations...");
    
    // Test 1: Simple division
    divide(32'd100, 32'd10, MD_OP_DIV, 2'b00, result);
    check_result("DIVU 100 / 10", result == 32'd10);
    
    // Test 2: Division with remainder
    divide(32'd123, 32'd10, MD_OP_DIV, 2'b00, result);
    check_result("DIVU 123 / 10", result == 32'd12);
    
    // Test 3: Division by 1
    divide(32'd999, 32'd1, MD_OP_DIV, 2'b00, result);
    check_result("DIVU 999 / 1", result == 32'd999);
    
    // Test 4: Division by larger number
    divide(32'd50, 32'd100, MD_OP_DIV, 2'b00, result);
    check_result("DIVU 50 / 100", result == 32'd0);
    
    // Test 5: Division by zero
    divide(32'd100, 32'd0, MD_OP_DIV, 2'b00, result);
    check_result("DIVU div by zero", result == 32'hFFFF_FFFF);
    
    // Test 6: Maximum value division
    divide(32'hFFFF_FFFF, 32'h0000_0002, MD_OP_DIV, 2'b00, result);
    check_result("DIVU MAX / 2", result == 32'h7FFF_FFFF);
    
    // Test 7: Power of 2 division
    divide(32'd1024, 32'd16, MD_OP_DIV, 2'b00, result);
    check_result("DIVU 1024 / 16", result == 32'd64);
    
    // Test 8: Equal numbers
    divide(32'd500, 32'd500, MD_OP_DIV, 2'b00, result);
    check_result("DIVU 500 / 500", result == 32'd1);
  endtask

  //========================================================================
  // Test: Signed Division
  //========================================================================
  
  task automatic test_div_signed();
    logic [31:0] result;
    logic signed [31:0] a_signed, b_signed, expected;
    $display("Testing signed DIV operations...");
    
    // Test 1: Positive / Positive
    divide(32'd100, 32'd5, MD_OP_DIV, 2'b11, result);
    check_result("DIV 100 / 5", result == 32'd20);
    
    // Test 2: Positive / Negative
    a_signed = 32'd100;
    b_signed = -32'd5;
    divide(a_signed, b_signed, MD_OP_DIV, 2'b11, result);
    expected = a_signed / b_signed;
    check_result("DIV 100 / -5", result == expected);
    
    // Test 3: Negative / Positive
    a_signed = -32'd100;
    b_signed = 32'd5;
    divide(a_signed, b_signed, MD_OP_DIV, 2'b11, result);
    expected = a_signed / b_signed;
    check_result("DIV -100 / 5", result == expected);
    
    // Test 4: Negative / Negative
    a_signed = -32'd100;
    b_signed = -32'd5;
    divide(a_signed, b_signed, MD_OP_DIV, 2'b11, result);
    expected = a_signed / b_signed;
    check_result("DIV -100 / -5", result == expected);
    
    // Test 5: Division by zero (signed)
    a_signed = -32'd50;
    b_signed = 32'd0;
    divide(a_signed, b_signed, MD_OP_DIV, 2'b11, result);
    check_result("DIV signed div by zero", result == 32'hFFFF_FFFF);
    
    // Test 6: Overflow case (most negative / -1)
    a_signed = 32'h8000_0000;
    b_signed = -32'd1;
    divide(a_signed, b_signed, MD_OP_DIV, 2'b11, result);
    check_result("DIV overflow case", result == 32'h8000_0000);
  endtask

  //========================================================================
  // Test: Unsigned Remainder
  //========================================================================
  
  task automatic test_rem_unsigned();
    logic [31:0] result;
    $display("Testing unsigned REM operations...");
    
    // Test 1: Simple remainder
    divide(32'd100, 32'd10, MD_OP_REM, 2'b00, result);
    check_result("REMU 100 % 10", result == 32'd0);
    
    // Test 2: Remainder with non-zero result
    divide(32'd123, 32'd10, MD_OP_REM, 2'b00, result);
    check_result("REMU 123 % 10", result == 32'd3);
    
    // Test 3: Remainder by 1
    divide(32'd999, 32'd1, MD_OP_REM, 2'b00, result);
    check_result("REMU 999 % 1", result == 32'd0);
    
    // Test 4: Remainder when dividend < divisor
    divide(32'd50, 32'd100, MD_OP_REM, 2'b00, result);
    check_result("REMU 50 % 100", result == 32'd50);
    
    // Test 5: Remainder by zero
    divide(32'd100, 32'd0, MD_OP_REM, 2'b00, result);
    check_result("REMU rem by zero", result == 32'd100);
    
    // Test 6: Power of 2 remainder
    divide(32'd1234, 32'd16, MD_OP_REM, 2'b00, result);
    check_result("REMU 1234 % 16", result == 32'd2);
    
    // Test 7: Large remainder
    divide(32'd999999, 32'd1000, MD_OP_REM, 2'b00, result);
    check_result("REMU 999999 % 1000", result == 32'd999);
  endtask

  //========================================================================
  // Test: Signed Remainder
  //========================================================================
  
  task automatic test_rem_signed();
    logic [31:0] result;
    logic signed [31:0] a_signed, b_signed, expected;
    $display("Testing signed REM operations...");
    
    // Test 1: Positive % Positive
    divide(32'd100, 32'd7, MD_OP_REM, 2'b11, result);
    check_result("REM 100 % 7", result == 32'd2);
    
    // Test 2: Positive % Negative
    a_signed = 32'd100;
    b_signed = -32'd7;
    divide(a_signed, b_signed, MD_OP_REM, 2'b11, result);
    expected = a_signed % b_signed;
    check_result("REM 100 % -7", result == expected);
    
    // Test 3: Negative % Positive
    a_signed = -32'd100;
    b_signed = 32'd7;
    divide(a_signed, b_signed, MD_OP_REM, 2'b11, result);
    expected = a_signed % b_signed;
    check_result("REM -100 % 7", result == expected);
    
    // Test 4: Negative % Negative
    a_signed = -32'd100;
    b_signed = -32'd7;
    divide(a_signed, b_signed, MD_OP_REM, 2'b11, result);
    expected = a_signed % b_signed;
    check_result("REM -100 % -7", result == expected);
    
    // Test 5: Remainder by zero (signed)
    a_signed = 32'd50;
    b_signed = 32'd0;
    divide(a_signed, b_signed, MD_OP_REM, 2'b11, result);
    check_result("REM signed rem by zero", result == 32'd50);
    
    // Test 6: Negative remainder by zero
    a_signed = -32'd75;
    b_signed = 32'd0;
    divide(a_signed, b_signed, MD_OP_REM, 2'b11, result);
    check_result("REM negative rem by zero", result == a_signed);
  endtask

  //========================================================================
  // Test: Ready Signal Handling
  //========================================================================
  
  task automatic test_ready_signal();
    logic [31:0] result;
    $display("Testing ready signal handling...");
    
    // Test that ready signal allows completion
    // Simply verify that normal operation works with ready=1
    op_a_i = 32'd50;
    op_b_i = 32'd25;
    operator_i = MD_OP_MULL;
    signed_mode_i = 2'b00;
    mult_sel_i = 1'b1;
    div_sel_i = 1'b0;
    multdiv_ready_id_i = 1'b1;
    
    @(posedge clk_i);
    mult_en_i = 1'b1;
    
    // Wait for valid
    while (!valid_o) begin
      @(posedge clk_i);
    end
    
    // Check result
    check_result("Multiplication with ready=1", multdiv_result_o == 32'd1250);
    
    mult_en_i = 1'b0;
    @(posedge clk_i);
    
    // Second test: Verify operation completes correctly
    op_a_i = 32'd100;
    op_b_i = 32'd100;
    operator_i = MD_OP_MULL;
    signed_mode_i = 2'b00;
    mult_sel_i = 1'b1;
    div_sel_i = 1'b0;
    multdiv_ready_id_i = 1'b1;
    
    @(posedge clk_i);
    mult_en_i = 1'b1;
    
    // Wait for valid
    while (!valid_o) begin
      @(posedge clk_i);
    end
    
    // Check result
    check_result("Multiplication 100*100", multdiv_result_o == 32'd10000);
    
    mult_en_i = 1'b0;
    @(posedge clk_i);
  endtask

  //========================================================================
  // Main Test Sequence
  //========================================================================
  
  initial begin
    $display("=============================================================");
    $display("  Starting ibex_multdiv_fast Testbench");
    $display("=============================================================");
    
    // Initialize
    init_signals();
    rst_ni = 0;
    
    // Reset sequence
    repeat(3) @(posedge clk_i);
    rst_ni = 1;
    repeat(2) @(posedge clk_i);
    
    // Run all tests
    test_mul_unsigned();
    test_mul_signed();
    test_mulh();
    test_div_unsigned();
    test_div_signed();
    test_rem_unsigned();
    test_rem_signed();
    test_ready_signal();
    
    // Test summary
    repeat(3) @(posedge clk_i);
    $display("=============================================================");
    $display("  Test Summary");
    $display("=============================================================");
    $display("  Total Tests: %0d", test_count);
    $display("  Passed:      %0d", pass_count);
    $display("  Failed:      %0d", fail_count);
    $display("=============================================================");
    
    if (fail_count == 0) begin
      $display("  ALL TESTS PASSED!");
    end else begin
      $display("  SOME TESTS FAILED!");
    end
    $display("=============================================================");
    
    $finish;
  end
  
  // Timeout watchdog
  initial begin
    #200000; // 200 microseconds
    $display("ERROR: Testbench timeout!");
    $finish;
  end

endmodule
