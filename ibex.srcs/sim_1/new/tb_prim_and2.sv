`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_and2
// Tests: 2-input bitwise AND gate with parameterizable width
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_and2();

  // Test parameters - test multiple widths
  localparam int WIDTH_1 = 1;
  localparam int WIDTH_8 = 8;
  localparam int WIDTH_16 = 16;
  localparam int WIDTH_32 = 32;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Signals for WIDTH=1
  logic [WIDTH_1-1:0] in0_1;
  logic [WIDTH_1-1:0] in1_1;
  logic [WIDTH_1-1:0] out_1;

  // Signals for WIDTH=8
  logic [WIDTH_8-1:0] in0_8;
  logic [WIDTH_8-1:0] in1_8;
  logic [WIDTH_8-1:0] out_8;

  // Signals for WIDTH=16
  logic [WIDTH_16-1:0] in0_16;
  logic [WIDTH_16-1:0] in1_16;
  logic [WIDTH_16-1:0] out_16;

  // Signals for WIDTH=32
  logic [WIDTH_32-1:0] in0_32;
  logic [WIDTH_32-1:0] in1_32;
  logic [WIDTH_32-1:0] out_32;

  // DUT instantiations
  prim_and2 #(.Width(WIDTH_1)) dut_1 (
    .in0_i(in0_1),
    .in1_i(in1_1),
    .out_o(out_1)
  );

  prim_and2 #(.Width(WIDTH_8)) dut_8 (
    .in0_i(in0_8),
    .in1_i(in1_8),
    .out_o(out_8)
  );

  prim_and2 #(.Width(WIDTH_16)) dut_16 (
    .in0_i(in0_16),
    .in1_i(in1_16),
    .out_o(out_16)
  );

  prim_and2 #(.Width(WIDTH_32)) dut_32 (
    .in0_i(in0_32),
    .in1_i(in1_32),
    .out_o(out_32)
  );

  // Task to test WIDTH=1 AND gate
  task automatic test_and_1(
    input logic in0,
    input logic in1,
    input logic expected,
    input string desc
  );
    test_num++;
    
    in0_1 = in0;
    in1_1 = in1;
    #1; // Wait for combinational logic
    
    if (out_1 === expected) begin
      $display("[PASS] Test %0d: W=1 %s - %b AND %b = %b", 
               test_num, desc, in0, in1, out_1);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=1 %s - %b AND %b, expected=%b, got=%b", 
               test_num, desc, in0, in1, expected, out_1);
      fail_count++;
    end
  endtask

  // Task to test WIDTH=8 AND gate
  task automatic test_and_8(
    input logic [7:0] in0,
    input logic [7:0] in1,
    input logic [7:0] expected,
    input string desc
  );
    test_num++;
    
    in0_8 = in0;
    in1_8 = in1;
    #1; // Wait for combinational logic
    
    if (out_8 === expected) begin
      $display("[PASS] Test %0d: W=8 %s - 0x%h AND 0x%h = 0x%h", 
               test_num, desc, in0, in1, out_8);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=8 %s - 0x%h AND 0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, in0, in1, expected, out_8);
      fail_count++;
    end
  endtask

  // Task to test WIDTH=16 AND gate
  task automatic test_and_16(
    input logic [15:0] in0,
    input logic [15:0] in1,
    input logic [15:0] expected,
    input string desc
  );
    test_num++;
    
    in0_16 = in0;
    in1_16 = in1;
    #1; // Wait for combinational logic
    
    if (out_16 === expected) begin
      $display("[PASS] Test %0d: W=16 %s - 0x%h AND 0x%h = 0x%h", 
               test_num, desc, in0, in1, out_16);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=16 %s - 0x%h AND 0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, in0, in1, expected, out_16);
      fail_count++;
    end
  endtask

  // Task to test WIDTH=32 AND gate
  task automatic test_and_32(
    input logic [31:0] in0,
    input logic [31:0] in1,
    input logic [31:0] expected,
    input string desc
  );
    test_num++;
    
    in0_32 = in0;
    in1_32 = in1;
    #1; // Wait for combinational logic
    
    if (out_32 === expected) begin
      $display("[PASS] Test %0d: W=32 %s - 0x%h AND 0x%h = 0x%h", 
               test_num, desc, in0, in1, out_32);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=32 %s - 0x%h AND 0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, in0, in1, expected, out_32);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("prim_and2 Self-Testing Testbench");
    $display("========================================");
    
    // Initialize
    in0_1 = '0;
    in1_1 = '0;
    in0_8 = '0;
    in1_8 = '0;
    in0_16 = '0;
    in1_16 = '0;
    in0_32 = '0;
    in1_32 = '0;
    #10;
    
    $display("\n--- Testing WIDTH=1 (Truth Table) ---");
    // Complete truth table for 1-bit AND
    test_and_1(1'b0, 1'b0, 1'b0, "0 AND 0");
    test_and_1(1'b0, 1'b1, 1'b0, "0 AND 1");
    test_and_1(1'b1, 1'b0, 1'b0, "1 AND 0");
    test_and_1(1'b1, 1'b1, 1'b1, "1 AND 1");
    
    $display("\n--- Testing WIDTH=8 (Bitwise Operations) ---");
    // All zeros
    test_and_8(8'h00, 8'h00, 8'h00, "all zeros");
    
    // All ones
    test_and_8(8'hFF, 8'hFF, 8'hFF, "all ones");
    
    // One operand zero
    test_and_8(8'hFF, 8'h00, 8'h00, "0xFF AND 0x00");
    test_and_8(8'h00, 8'hFF, 8'h00, "0x00 AND 0xFF");
    
    // Alternating patterns
    test_and_8(8'hAA, 8'h55, 8'h00, "0xAA AND 0x55");
    test_and_8(8'hAA, 8'hAA, 8'hAA, "0xAA AND 0xAA");
    test_and_8(8'h55, 8'h55, 8'h55, "0x55 AND 0x55");
    
    // Nibble patterns
    test_and_8(8'hF0, 8'h0F, 8'h00, "0xF0 AND 0x0F");
    test_and_8(8'hF0, 8'hFF, 8'hF0, "0xF0 AND 0xFF");
    test_and_8(8'h0F, 8'hFF, 8'h0F, "0x0F AND 0xFF");
    
    // Bit masking examples
    test_and_8(8'b11010110, 8'b00000001, 8'b00000000, "check LSB (even)");
    test_and_8(8'b11010111, 8'b00000001, 8'b00000001, "check LSB (odd)");
    test_and_8(8'b11010110, 8'b10000000, 8'b10000000, "check MSB set");
    test_and_8(8'b01010110, 8'b10000000, 8'b00000000, "check MSB clear");
    
    $display("\n--- Testing WIDTH=16 ---");
    // Basic patterns
    test_and_16(16'h0000, 16'h0000, 16'h0000, "all zeros");
    test_and_16(16'hFFFF, 16'hFFFF, 16'hFFFF, "all ones");
    test_and_16(16'hFFFF, 16'h0000, 16'h0000, "one zero operand");
    
    // Alternating patterns
    test_and_16(16'hAAAA, 16'h5555, 16'h0000, "alternating patterns");
    test_and_16(16'hAAAA, 16'hAAAA, 16'hAAAA, "same pattern");
    
    // Byte patterns
    test_and_16(16'hFF00, 16'h00FF, 16'h0000, "byte complement");
    test_and_16(16'hFF00, 16'hFFFF, 16'hFF00, "byte mask upper");
    test_and_16(16'h00FF, 16'hFFFF, 16'h00FF, "byte mask lower");
    
    // Random patterns
    test_and_16(16'h1234, 16'h5678, 16'h1230, "pattern 1");
    test_and_16(16'h9ABC, 16'hDEF0, 16'h9AB0, "pattern 2");
    
    $display("\n--- Testing WIDTH=32 ---");
    // Basic patterns
    test_and_32(32'h00000000, 32'h00000000, 32'h00000000, "all zeros");
    test_and_32(32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "all ones");
    test_and_32(32'hFFFFFFFF, 32'h00000000, 32'h00000000, "one zero operand");
    
    // Alternating patterns
    test_and_32(32'hAAAAAAAA, 32'h55555555, 32'h00000000, "alternating");
    test_and_32(32'hAAAAAAAA, 32'hAAAAAAAA, 32'hAAAAAAAA, "same pattern");
    
    // Word patterns
    test_and_32(32'hFFFF0000, 32'h0000FFFF, 32'h00000000, "word complement");
    test_and_32(32'hFFFF0000, 32'hFFFFFFFF, 32'hFFFF0000, "word mask upper");
    test_and_32(32'h0000FFFF, 32'hFFFFFFFF, 32'h0000FFFF, "word mask lower");
    
    // Complex patterns
    test_and_32(32'h12345678, 32'h9ABCDEF0, 32'h12345670, "complex 1");
    test_and_32(32'hDEADBEEF, 32'hCAFEBABE, 32'hCAACBAAE, "complex 2");
    test_and_32(32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, "nibble complement");
    
    // Bit masking examples
    test_and_32(32'hFFFFFFFF, 32'h00000001, 32'h00000001, "mask LSB");
    test_and_32(32'hFFFFFFFF, 32'h80000000, 32'h80000000, "mask MSB");
    test_and_32(32'h12345678, 32'h000000FF, 32'h00000078, "extract byte");
    
    $display("\n--- Testing Identity Properties ---");
    // AND with all ones is identity
    test_and_8(8'h5A, 8'hFF, 8'h5A, "identity: x AND 1...1");
    test_and_16(16'h5A5A, 16'hFFFF, 16'h5A5A, "identity: x AND 1...1");
    test_and_32(32'h5A5A5A5A, 32'hFFFFFFFF, 32'h5A5A5A5A, "identity: x AND 1...1");
    
    // AND with zero is zero
    test_and_8(8'h5A, 8'h00, 8'h00, "zero: x AND 0");
    test_and_16(16'h5A5A, 16'h0000, 16'h0000, "zero: x AND 0");
    test_and_32(32'h5A5A5A5A, 32'h00000000, 32'h00000000, "zero: x AND 0");
    
    // AND with self is identity
    test_and_8(8'h5A, 8'h5A, 8'h5A, "idempotent: x AND x");
    test_and_16(16'h5A5A, 16'h5A5A, 16'h5A5A, "idempotent: x AND x");
    test_and_32(32'h5A5A5A5A, 32'h5A5A5A5A, 32'h5A5A5A5A, "idempotent: x AND x");
    
    $display("\n--- Testing Commutativity (A AND B = B AND A) ---");
    test_and_8(8'h12, 8'h34, 8'h10, "commutative test 1a");
    test_and_8(8'h34, 8'h12, 8'h10, "commutative test 1b");
    test_and_32(32'h12345678, 32'h87654321, 32'h02244220, "commutative test 2a");
    test_and_32(32'h87654321, 32'h12345678, 32'h02244220, "commutative test 2b");
    
    $display("\n--- Testing Special Cases ---");
    // Single bit set
    test_and_32(32'h00000001, 32'h00000001, 32'h00000001, "single LSB");
    test_and_32(32'h80000000, 32'h80000000, 32'h80000000, "single MSB");
    
    // Power of 2 patterns
    test_and_32(32'h00000001, 32'h00000002, 32'h00000000, "powers of 2");
    test_and_32(32'h00000004, 32'h00000008, 32'h00000000, "powers of 2");
    
    // Random comprehensive test
    for (int i = 0; i < 10; i++) begin
      logic [31:0] rand_a, rand_b, expected_result;
      rand_a = $urandom();
      rand_b = $urandom();
      expected_result = rand_a & rand_b;
      test_and_32(rand_a, rand_b, expected_result, $sformatf("random test %0d", i));
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

endmodule
