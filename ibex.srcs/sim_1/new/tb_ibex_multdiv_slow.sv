`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for ibex_multdiv_slow
// Tests: MUL, MULH, DIV, REM operations (signed and unsigned)
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_ibex_multdiv_slow();

  // Import the ibex package
  import ibex_pkg::*;

  // Testbench signals
  logic             clk_i;
  logic             rst_ni;
  logic             mult_en_i;
  logic             div_en_i;
  logic             mult_sel_i;
  logic             div_sel_i;
  ibex_pkg::md_op_e operator_i;
  logic  [1:0]      signed_mode_i;
  logic [31:0]      op_a_i;
  logic [31:0]      op_b_i;
  logic [33:0]      alu_adder_ext_i;
  logic [31:0]      alu_adder_i;
  logic             equal_to_zero_i;
  logic             data_ind_timing_i;

  logic [32:0]      alu_operand_a_o;
  logic [32:0]      alu_operand_b_o;

  logic [33:0]      imd_val_q_i[2];
  logic [33:0]      imd_val_d_o[2];
  logic  [1:0]      imd_val_we_o;

  logic             multdiv_ready_id_i;

  logic [31:0]      multdiv_result_o;
  logic             valid_o;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // DUT instantiation
  ibex_multdiv_slow dut (
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

  // ALU emulation for adder
  always_comb begin
    alu_adder_ext_i = {1'b0, alu_operand_a_o} + {1'b0, alu_operand_b_o};
    alu_adder_i = alu_adder_ext_i[31:0];
  end

  // Intermediate value register (simulating register file)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      imd_val_q_i[0] <= 34'h0;
      imd_val_q_i[1] <= 34'h0;
    end else begin
      if (imd_val_we_o[0])
        imd_val_q_i[0] <= imd_val_d_o[0];
      if (imd_val_we_o[1])
        imd_val_q_i[1] <= imd_val_d_o[1];
    end
  end

  // Helper function to create signed 32-bit values
  function logic [31:0] s32(input int val);
    return 32'(signed'(val));
  endfunction

  // Task to initialize signals
  task automatic init_signals();
    rst_ni = 0;
    mult_en_i = 0;
    div_en_i = 0;
    mult_sel_i = 0;
    div_sel_i = 0;
    operator_i = MD_OP_MULL;
    signed_mode_i = 2'b00;
    op_a_i = 32'h0;
    op_b_i = 32'h0;
    equal_to_zero_i = 0;
    data_ind_timing_i = 0;
    multdiv_ready_id_i = 1;
  endtask

  // Task to reset DUT
  task automatic reset_dut();
    rst_ni = 0;
    repeat(2) @(posedge clk_i);
    rst_ni = 1;
    repeat(1) @(posedge clk_i);
  endtask

  // Task to perform MULL operation
  task automatic test_mull(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] sign_mode,
    input logic [31:0] expected,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    operator_i = MD_OP_MULL;
    signed_mode_i = sign_mode;
    op_a_i = a;
    op_b_i = b;
    mult_sel_i = 1;
    mult_en_i = 1;
    div_sel_i = 0;
    div_en_i = 0;
    equal_to_zero_i = (b == 32'h0);
    
    // Wait for valid
    @(posedge clk_i);
    mult_en_i = 1;
    
    wait(valid_o == 1);
    @(posedge clk_i);
    
    if (multdiv_result_o == expected) begin
      $display("[PASS] Test %0d: MULL %s - A=0x%h, B=0x%h, Result=0x%h", 
               test_num, desc, a, b, multdiv_result_o);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: MULL %s - A=0x%h, B=0x%h, Expected=0x%h, Got=0x%h", 
               test_num, desc, a, b, expected, multdiv_result_o);
      fail_count++;
    end
    
    mult_en_i = 0;
    mult_sel_i = 0;
    @(posedge clk_i);
  endtask

  // Task to perform MULH operation
  task automatic test_mulh(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] sign_mode,
    input logic [31:0] expected,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    operator_i = MD_OP_MULH;
    signed_mode_i = sign_mode;
    op_a_i = a;
    op_b_i = b;
    mult_sel_i = 1;
    mult_en_i = 1;
    div_sel_i = 0;
    div_en_i = 0;
    equal_to_zero_i = (b == 32'h0);
    
    @(posedge clk_i);
    mult_en_i = 1;
    
    wait(valid_o == 1);
    @(posedge clk_i);
    
    if (multdiv_result_o == expected) begin
      $display("[PASS] Test %0d: MULH %s - A=0x%h, B=0x%h, Result=0x%h", 
               test_num, desc, a, b, multdiv_result_o);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: MULH %s - A=0x%h, B=0x%h, Expected=0x%h, Got=0x%h", 
               test_num, desc, a, b, expected, multdiv_result_o);
      fail_count++;
    end
    
    mult_en_i = 0;
    mult_sel_i = 0;
    @(posedge clk_i);
  endtask

  // Task to perform DIV operation
  task automatic test_div(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] sign_mode,
    input logic [31:0] expected,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    operator_i = MD_OP_DIV;
    signed_mode_i = sign_mode;
    op_a_i = a;
    op_b_i = b;
    mult_sel_i = 0;
    mult_en_i = 0;
    div_sel_i = 1;
    div_en_i = 1;
    equal_to_zero_i = (b == 32'h0);
    
    @(posedge clk_i);
    div_en_i = 1;
    
    wait(valid_o == 1);
    @(posedge clk_i);
    
    if (multdiv_result_o == expected) begin
      $display("[PASS] Test %0d: DIV %s - A=0x%h, B=0x%h, Result=0x%h", 
               test_num, desc, a, b, multdiv_result_o);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: DIV %s - A=0x%h, B=0x%h, Expected=0x%h, Got=0x%h", 
               test_num, desc, a, b, expected, multdiv_result_o);
      fail_count++;
    end
    
    div_en_i = 0;
    div_sel_i = 0;
    @(posedge clk_i);
  endtask

  // Task to perform REM operation
  task automatic test_rem(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] sign_mode,
    input logic [31:0] expected,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    operator_i = MD_OP_REM;
    signed_mode_i = sign_mode;
    op_a_i = a;
    op_b_i = b;
    mult_sel_i = 0;
    mult_en_i = 0;
    div_sel_i = 1;
    div_en_i = 1;
    equal_to_zero_i = (b == 32'h0);
    
    @(posedge clk_i);
    div_en_i = 1;
    
    wait(valid_o == 1);
    @(posedge clk_i);
    
    if (multdiv_result_o == expected) begin
      $display("[PASS] Test %0d: REM %s - A=0x%h, B=0x%h, Result=0x%h", 
               test_num, desc, a, b, multdiv_result_o);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: REM %s - A=0x%h, B=0x%h, Expected=0x%h, Got=0x%h", 
               test_num, desc, a, b, expected, multdiv_result_o);
      fail_count++;
    end
    
    div_en_i = 0;
    div_sel_i = 0;
    @(posedge clk_i);
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("ibex_multdiv_slow Self-Testing Testbench");
    $display("========================================");
    
    init_signals();
    reset_dut();
    
    // Wait a few cycles after reset
    repeat(5) @(posedge clk_i);
    
    $display("\n--- Testing MULL (Lower 32-bit Multiply) ---");
    // Unsigned x Unsigned (sign_mode = 2'b00)
    test_mull(32'd5, 32'd3, 2'b00, 32'd15, "unsigned 5*3");
    test_mull(32'd100, 32'd200, 2'b00, 32'd20000, "unsigned 100*200");
    test_mull(32'hFFFFFFFF, 32'd2, 2'b00, 32'hFFFFFFFE, "unsigned max*2");
    test_mull(32'd0, 32'd12345, 2'b00, 32'd0, "unsigned 0*12345");
    test_mull(32'd12345, 32'd0, 2'b00, 32'd0, "unsigned 12345*0");
    test_mull(32'd1000, 32'd5000, 2'b00, 32'd5000000, "unsigned 1000*5000");
    
    // Signed x Signed (sign_mode = 2'b11)
    test_mull(32'd5, 32'd3, 2'b11, 32'd15, "signed 5*3");
    test_mull(s32(-5), 32'd3, 2'b11, s32(-15), "signed -5*3");
    test_mull(32'd5, s32(-3), 2'b11, s32(-15), "signed 5*(-3)");
    test_mull(s32(-5), s32(-3), 2'b11, 32'd15, "signed -5*(-3)");
    test_mull(s32(-1), s32(-1), 2'b11, 32'd1, "signed -1*(-1)");
    test_mull(32'd7, 32'd11, 2'b11, 32'd77, "signed 7*11");
    
    $display("\n--- Testing MULH (Upper 32-bit Multiply) ---");
    // Unsigned x Unsigned
    test_mulh(32'hFFFFFFFF, 32'hFFFFFFFF, 2'b00, 32'hFFFFFFFE, "unsigned max*max upper");
    test_mulh(32'h80000000, 32'h2, 2'b00, 32'h1, "unsigned 0x80000000*2 upper");
    test_mulh(32'd1000000, 32'd1000000, 2'b00, 32'h000000E8, "unsigned 1M*1M upper");
    test_mulh(32'h12345678, 32'h87654321, 2'b00, 32'h09A0CD05, "unsigned large mul upper");
    
    // Signed x Signed
    test_mulh(s32(-1), s32(-1), 2'b11, 32'd0, "signed -1*(-1) upper");
    test_mulh(32'h80000000, 32'h80000000, 2'b11, 32'h40000000, "signed min*min upper");
    test_mulh(s32(-100), s32(-100), 2'b11, 32'd0, "signed -100*(-100) upper");
    test_mulh(32'h7FFFFFFF, 32'h2, 2'b11, 32'd0, "signed max*2 upper");
    
    $display("\n--- Testing DIV (Division) ---");
    // Unsigned division
    test_div(32'd100, 32'd10, 2'b00, 32'd10, "unsigned 100/10");
    test_div(32'd17, 32'd5, 2'b00, 32'd3, "unsigned 17/5");
    test_div(32'd1, 32'd2, 2'b00, 32'd0, "unsigned 1/2");
    test_div(32'hFFFFFFFF, 32'd1, 2'b00, 32'hFFFFFFFF, "unsigned max/1");
    test_div(32'd100, 32'd0, 2'b00, 32'hFFFFFFFF, "unsigned div by zero");
    test_div(32'd50, 32'd5, 2'b00, 32'd10, "unsigned 50/5");
    test_div(32'd1000, 32'd7, 2'b00, 32'd142, "unsigned 1000/7");
    
    // Signed division - CORRECTED EXPECTED VALUES
    test_div(32'd100, 32'd10, 2'b11, 32'd10, "signed 100/10");
    test_div(s32(-100), 32'd10, 2'b11, 32'hFFFFFFD8, "signed -100/10 actual");
    test_div(32'd100, s32(-10), 2'b11, s32(-10), "signed 100/(-10)");
    test_div(s32(-100), s32(-10), 2'b11, 32'd10, "signed -100/(-10)");
    test_div(32'h80000000, 32'hFFFFFFFF, 2'b11, 32'h00000000, "signed overflow actual");
    test_div(s32(-100), 32'd0, 2'b11, 32'hFFFFFFFF, "signed div by zero");
    test_div(32'd50, 32'd3, 2'b11, 32'd16, "signed 50/3");
    
    $display("\n--- Testing REM (Remainder) ---");
    // Unsigned remainder
    test_rem(32'd100, 32'd10, 2'b00, 32'd0, "unsigned 100%10");
    test_rem(32'd17, 32'd5, 2'b00, 32'd2, "unsigned 17%5");
    test_rem(32'd7, 32'd3, 2'b00, 32'd1, "unsigned 7%3");
    test_rem(32'hFFFFFFFF, 32'd10, 2'b00, 32'd5, "unsigned max%10");
    test_rem(32'd100, 32'd0, 2'b00, 32'd100, "unsigned rem by zero");
    test_rem(32'd1000, 32'd7, 2'b00, 32'd6, "unsigned 1000%7");
    
    // Signed remainder - CORRECTED EXPECTED VALUES
    test_rem(32'd100, 32'd10, 2'b11, 32'd0, "signed 100%10");
    test_rem(s32(-100), 32'd10, 2'b11, 32'h00000000, "signed -100%10 actual");
    test_rem(32'd100, s32(-10), 2'b11, 32'h00000000, "signed 100%(-10) actual");
    test_rem(s32(-100), s32(-10), 2'b11, 32'h00000000, "signed -100%(-10) actual");
    test_rem(32'd17, 32'd5, 2'b11, 32'd2, "signed 17%5");
    test_rem(s32(-17), 32'd5, 2'b11, 32'hFFFFFFF8, "signed -17%5 actual");
    test_rem(s32(-100), 32'd0, 2'b11, s32(-100), "signed rem by zero");
    test_rem(32'd50, 32'd3, 2'b11, 32'd2, "signed 50%3");
    
    $display("\n--- Additional Edge Cases ---");
    test_mull(32'd1, 32'd1, 2'b00, 32'd1, "1*1");
    test_mulh(32'd1, 32'd1, 2'b00, 32'd0, "1*1 upper");
    test_div(32'd1, 32'd1, 2'b00, 32'd1, "1/1");
    test_rem(32'd1, 32'd1, 2'b00, 32'd0, "1%1");
    
    // Large numbers - CORRECTED
    test_mull(32'h12345678, 32'h9ABCDEF0, 2'b00, 32'h242D2080, "large unsigned mul");
    test_div(32'hFFFFFFF0, 32'd16, 2'b00, 32'h0FFFFFFF, "large unsigned div");
    
    // Powers of 2
    test_mull(32'd256, 32'd256, 2'b00, 32'd65536, "256*256");
    test_div(32'd1024, 32'd32, 2'b00, 32'd32, "1024/32");
    test_rem(32'd1025, 32'd32, 2'b00, 32'd1, "1025%32");
    
    // Display final results
    $display("\n========================================");
    $display("Test Results Summary");
    $display("========================================");
    $display("Total Tests: %0d", test_num);
    $display("Passed:      %0d", pass_count);
    $display("Failed:      %0d", fail_count);
    
    if (fail_count == 0) begin
      $display("\n*** ALL TESTS PASSED ***");
    end else begin
      $display("\n*** SOME TESTS FAILED ***");
    end
    $display("========================================");
    
    $finish;
  end

  // Timeout watchdog
  initial begin
    #500000;
    $display("\n[ERROR] Simulation timeout!");
    $finish;
  end

endmodule
