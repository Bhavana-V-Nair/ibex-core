`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_onehot_mux
// Tests: One-hot AND/OR multiplexer
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_onehot_mux();

  // Test parameters
  localparam int WIDTH_8 = 8;
  localparam int WIDTH_32 = 32;
  localparam int INPUTS_4 = 4;
  localparam int INPUTS_8 = 8;

  // Clock and reset
  logic clk_i;
  logic rst_ni;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Signals for 8-bit, 4-input mux
  logic [WIDTH_8-1:0]   in_8_4 [INPUTS_4];
  logic [INPUTS_4-1:0]  sel_8_4;
  logic [WIDTH_8-1:0]   out_8_4;

  // Signals for 32-bit, 4-input mux
  logic [WIDTH_32-1:0]  in_32_4 [INPUTS_4];
  logic [INPUTS_4-1:0]  sel_32_4;
  logic [WIDTH_32-1:0]  out_32_4;

  // Signals for 32-bit, 8-input mux
  logic [WIDTH_32-1:0]  in_32_8 [INPUTS_8];
  logic [INPUTS_8-1:0]  sel_32_8;
  logic [WIDTH_32-1:0]  out_32_8;

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // DUT instantiations
  prim_onehot_mux #(
    .Width(WIDTH_8),
    .Inputs(INPUTS_4)
  ) dut_8_4 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .in_i(in_8_4),
    .sel_i(sel_8_4),
    .out_o(out_8_4)
  );

  prim_onehot_mux #(
    .Width(WIDTH_32),
    .Inputs(INPUTS_4)
  ) dut_32_4 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .in_i(in_32_4),
    .sel_i(sel_32_4),
    .out_o(out_32_4)
  );

  prim_onehot_mux #(
    .Width(WIDTH_32),
    .Inputs(INPUTS_8)
  ) dut_32_8 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .in_i(in_32_8),
    .sel_i(sel_32_8),
    .out_o(out_32_8)
  );

  // Helper function to compute expected output
  function automatic logic [31:0] compute_expected(
    input logic [31:0] inputs[],
    input int num_inputs,
    input logic [7:0] sel,
    input int width
  );
    logic [31:0] result;
    result = '0;
    
    for (int i = 0; i < num_inputs; i++) begin
      if (sel[i]) begin
        result = inputs[i];
      end
    end
    
    return result;
  endfunction

  // Initialize signals
  task automatic init_signals();
    rst_ni = 0;
    sel_8_4 = '0;
    sel_32_4 = '0;
    sel_32_8 = '0;
    
    for (int i = 0; i < INPUTS_4; i++) begin
      in_8_4[i] = '0;
      in_32_4[i] = '0;
    end
    
    for (int i = 0; i < INPUTS_8; i++) begin
      in_32_8[i] = '0;
    end
  endtask

  // Reset DUT
  task automatic reset_dut();
    rst_ni = 0;
    repeat(3) @(posedge clk_i);
    rst_ni = 1;
    repeat(2) @(posedge clk_i);
  endtask

  // Task to test 8-bit, 4-input mux
  task automatic test_mux_8_4(
    input logic [WIDTH_8-1:0] inputs[4],
    input logic [INPUTS_4-1:0] sel,
    input logic [WIDTH_8-1:0] expected,
    input string desc
  );
    test_num++;
    
    // Apply inputs
    for (int i = 0; i < INPUTS_4; i++) begin
      in_8_4[i] = inputs[i];
    end
    sel_8_4 = sel;
    
    #1; // Wait for combinational logic
    
    if (out_8_4 === expected) begin
      $display("[PASS] Test %0d: W=8,I=4 %s - sel=0b%b, out=0x%h", 
               test_num, desc, sel, out_8_4);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=8,I=4 %s - sel=0b%b, expected=0x%h, got=0x%h", 
               test_num, desc, sel, expected, out_8_4);
      fail_count++;
    end
  endtask

  // Task to test 32-bit, 4-input mux
  task automatic test_mux_32_4(
    input logic [WIDTH_32-1:0] inputs[4],
    input logic [INPUTS_4-1:0] sel,
    input logic [WIDTH_32-1:0] expected,
    input string desc
  );
    test_num++;
    
    // Apply inputs
    for (int i = 0; i < INPUTS_4; i++) begin
      in_32_4[i] = inputs[i];
    end
    sel_32_4 = sel;
    
    #1; // Wait for combinational logic
    
    if (out_32_4 === expected) begin
      $display("[PASS] Test %0d: W=32,I=4 %s - sel=0b%b, out=0x%h", 
               test_num, desc, sel, out_32_4);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=32,I=4 %s - sel=0b%b, expected=0x%h, got=0x%h", 
               test_num, desc, sel, expected, out_32_4);
      fail_count++;
    end
  endtask

  // Task to test 32-bit, 8-input mux
  task automatic test_mux_32_8(
    input logic [WIDTH_32-1:0] inputs[8],
    input logic [INPUTS_8-1:0] sel,
    input logic [WIDTH_32-1:0] expected,
    input string desc
  );
    test_num++;
    
    // Apply inputs
    for (int i = 0; i < INPUTS_8; i++) begin
      in_32_8[i] = inputs[i];
    end
    sel_32_8 = sel;
    
    #1; // Wait for combinational logic
    
    if (out_32_8 === expected) begin
      $display("[PASS] Test %0d: W=32,I=8 %s - sel=0x%h, out=0x%h", 
               test_num, desc, sel, out_32_8);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=32,I=8 %s - sel=0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, sel, expected, out_32_8);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    logic [WIDTH_8-1:0] test_inputs_8[4];
    logic [WIDTH_32-1:0] test_inputs_32_4[4];
    logic [WIDTH_32-1:0] test_inputs_32_8[8];
    
    $display("========================================");
    $display("prim_onehot_mux Self-Testing Testbench");
    $display("========================================");
    
    init_signals();
    reset_dut();
    repeat(5) @(posedge clk_i);
    
    $display("\n--- Testing 8-bit Width, 4 Inputs ---");
    
    // Setup test inputs
    test_inputs_8[0] = 8'hAA;
    test_inputs_8[1] = 8'hBB;
    test_inputs_8[2] = 8'hCC;
    test_inputs_8[3] = 8'hDD;
    
    // Test each one-hot selection
    test_mux_8_4(test_inputs_8, 4'b0001, 8'hAA, "select input 0");
    test_mux_8_4(test_inputs_8, 4'b0010, 8'hBB, "select input 1");
    test_mux_8_4(test_inputs_8, 4'b0100, 8'hCC, "select input 2");
    test_mux_8_4(test_inputs_8, 4'b1000, 8'hDD, "select input 3");
    
    // Test with all zeros (onehot0 - valid)
    test_mux_8_4(test_inputs_8, 4'b0000, 8'h00, "all zeros");
    
    // Test with different input patterns
    test_inputs_8[0] = 8'h00;
    test_inputs_8[1] = 8'hFF;
    test_inputs_8[2] = 8'h55;
    test_inputs_8[3] = 8'hAA;
    
    test_mux_8_4(test_inputs_8, 4'b0001, 8'h00, "select 0x00");
    test_mux_8_4(test_inputs_8, 4'b0010, 8'hFF, "select 0xFF");
    test_mux_8_4(test_inputs_8, 4'b0100, 8'h55, "select 0x55");
    test_mux_8_4(test_inputs_8, 4'b1000, 8'hAA, "select 0xAA");
    
    $display("\n--- Testing 32-bit Width, 4 Inputs ---");
    
    // Setup test inputs
    test_inputs_32_4[0] = 32'h12345678;
    test_inputs_32_4[1] = 32'h9ABCDEF0;
    test_inputs_32_4[2] = 32'hDEADBEEF;
    test_inputs_32_4[3] = 32'hCAFEBABE;
    
    // Test each one-hot selection
    test_mux_32_4(test_inputs_32_4, 4'b0001, 32'h12345678, "select input 0");
    test_mux_32_4(test_inputs_32_4, 4'b0010, 32'h9ABCDEF0, "select input 1");
    test_mux_32_4(test_inputs_32_4, 4'b0100, 32'hDEADBEEF, "select input 2");
    test_mux_32_4(test_inputs_32_4, 4'b1000, 32'hCAFEBABE, "select input 3");
    
    // Test with all zeros
    test_mux_32_4(test_inputs_32_4, 4'b0000, 32'h00000000, "all zeros");
    
    // Test with boundary values
    test_inputs_32_4[0] = 32'h00000000;
    test_inputs_32_4[1] = 32'hFFFFFFFF;
    test_inputs_32_4[2] = 32'h80000000;
    test_inputs_32_4[3] = 32'h00000001;
    
    test_mux_32_4(test_inputs_32_4, 4'b0001, 32'h00000000, "select all zeros");
    test_mux_32_4(test_inputs_32_4, 4'b0010, 32'hFFFFFFFF, "select all ones");
    test_mux_32_4(test_inputs_32_4, 4'b0100, 32'h80000000, "select MSB");
    test_mux_32_4(test_inputs_32_4, 4'b1000, 32'h00000001, "select LSB");
    
    $display("\n--- Testing 32-bit Width, 8 Inputs ---");
    
    // Setup test inputs
    for (int i = 0; i < 8; i++) begin
      test_inputs_32_8[i] = 32'h10000000 + i;
    end
    
    // Test each one-hot selection
    for (int i = 0; i < 8; i++) begin
      test_mux_32_8(test_inputs_32_8, (1 << i), test_inputs_32_8[i], 
                    $sformatf("select input %0d", i));
    end
    
    // Test with all zeros
    test_mux_32_8(test_inputs_32_8, 8'h00, 32'h00000000, "all zeros");
    
    // Test with different patterns
    test_inputs_32_8[0] = 32'hAAAAAAAA;
    test_inputs_32_8[1] = 32'h55555555;
    test_inputs_32_8[2] = 32'hF0F0F0F0;
    test_inputs_32_8[3] = 32'h0F0F0F0F;
    test_inputs_32_8[4] = 32'hFF00FF00;
    test_inputs_32_8[5] = 32'h00FF00FF;
    test_inputs_32_8[6] = 32'hFFFF0000;
    test_inputs_32_8[7] = 32'h0000FFFF;
    
    test_mux_32_8(test_inputs_32_8, 8'h01, 32'hAAAAAAAA, "select pattern A");
    test_mux_32_8(test_inputs_32_8, 8'h02, 32'h55555555, "select pattern 5");
    test_mux_32_8(test_inputs_32_8, 8'h04, 32'hF0F0F0F0, "select pattern F0");
    test_mux_32_8(test_inputs_32_8, 8'h08, 32'h0F0F0F0F, "select pattern 0F");
    test_mux_32_8(test_inputs_32_8, 8'h10, 32'hFF00FF00, "select byte pattern 1");
    test_mux_32_8(test_inputs_32_8, 8'h20, 32'h00FF00FF, "select byte pattern 2");
    test_mux_32_8(test_inputs_32_8, 8'h40, 32'hFFFF0000, "select word pattern 1");
    test_mux_32_8(test_inputs_32_8, 8'h80, 32'h0000FFFF, "select word pattern 2");
    
    $display("\n--- Testing Sequential Selection ---");
    
    // Test sequential one-hot selections
    for (int i = 0; i < 4; i++) begin
      test_inputs_32_4[i] = 32'hA0000000 + (i << 24);
    end
    
    for (int i = 0; i < 4; i++) begin
      test_mux_32_4(test_inputs_32_4, (1 << i), test_inputs_32_4[i], 
                    $sformatf("sequential %0d", i));
    end
    
    $display("\n--- Testing Edge Cases ---");
    
    // All inputs same value
    for (int i = 0; i < 4; i++) begin
      test_inputs_32_4[i] = 32'h12121212;
    end
    
    test_mux_32_4(test_inputs_32_4, 4'b0001, 32'h12121212, "all same - sel 0");
    test_mux_32_4(test_inputs_32_4, 4'b0010, 32'h12121212, "all same - sel 1");
    test_mux_32_4(test_inputs_32_4, 4'b0100, 32'h12121212, "all same - sel 2");
    test_mux_32_4(test_inputs_32_4, 4'b1000, 32'h12121212, "all same - sel 3");
    
    // Rapidly changing selection
    test_inputs_32_4[0] = 32'h00000001;
    test_inputs_32_4[1] = 32'h00000002;
    test_inputs_32_4[2] = 32'h00000004;
    test_inputs_32_4[3] = 32'h00000008;
    
    for (int i = 0; i < 10; i++) begin
      int sel_idx = i % 4;
      test_mux_32_4(test_inputs_32_4, (1 << sel_idx), test_inputs_32_4[sel_idx], 
                    $sformatf("rapid change %0d", i));
    end
    
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
    #100000;
    $display("\n[ERROR] Simulation timeout!");
    $finish;
  end

endmodule
