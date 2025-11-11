`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_buf
// Tests: Buffer passthrough for various widths and values
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_buf();

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Test parameters
  localparam int WIDTH_1  = 1;
  localparam int WIDTH_8  = 8;
  localparam int WIDTH_16 = 16;
  localparam int WIDTH_32 = 32;
  localparam int WIDTH_64 = 64;

  // Signals for WIDTH=1
  logic [WIDTH_1-1:0]  in_1;
  logic [WIDTH_1-1:0]  out_1;

  // Signals for WIDTH=8
  logic [WIDTH_8-1:0]  in_8;
  logic [WIDTH_8-1:0]  out_8;

  // Signals for WIDTH=16
  logic [WIDTH_16-1:0] in_16;
  logic [WIDTH_16-1:0] out_16;

  // Signals for WIDTH=32
  logic [WIDTH_32-1:0] in_32;
  logic [WIDTH_32-1:0] out_32;

  // Signals for WIDTH=64
  logic [WIDTH_64-1:0] in_64;
  logic [WIDTH_64-1:0] out_64;

  // DUT instantiation for different widths
  prim_buf #(.Width(WIDTH_1)) dut_1 (
    .in_i(in_1),
    .out_o(out_1)
  );

  prim_buf #(.Width(WIDTH_8)) dut_8 (
    .in_i(in_8),
    .out_o(out_8)
  );

  prim_buf #(.Width(WIDTH_16)) dut_16 (
    .in_i(in_16),
    .out_o(out_16)
  );

  prim_buf #(.Width(WIDTH_32)) dut_32 (
    .in_i(in_32),
    .out_o(out_32)
  );

  prim_buf #(.Width(WIDTH_64)) dut_64 (
    .in_i(in_64),
    .out_o(out_64)
  );

  // Task to test 1-bit buffer
  task automatic test_buf_1(
    input logic value,
    input logic expected,
    input string desc
  );
    test_num++;
    in_1 = value;
    #1; // Wait for combinational propagation
    
    if (out_1 === expected) begin
      $display("[PASS] Test %0d: WIDTH=1 %s - in=0x%h, out=0x%h", 
               test_num, desc, value, out_1);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: WIDTH=1 %s - in=0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, value, expected, out_1);
      fail_count++;
    end
  endtask

  // Task to test 8-bit buffer
  task automatic test_buf_8(
    input logic [7:0] value,
    input string desc
  );
    test_num++;
    in_8 = value;
    #1; // Wait for combinational propagation
    
    if (out_8 === value) begin
      $display("[PASS] Test %0d: WIDTH=8 %s - in=0x%h, out=0x%h", 
               test_num, desc, value, out_8);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: WIDTH=8 %s - in=0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, value, value, out_8);
      fail_count++;
    end
  endtask

  // Task to test 16-bit buffer
  task automatic test_buf_16(
    input logic [15:0] value,
    input string desc
  );
    test_num++;
    in_16 = value;
    #1; // Wait for combinational propagation
    
    if (out_16 === value) begin
      $display("[PASS] Test %0d: WIDTH=16 %s - in=0x%h, out=0x%h", 
               test_num, desc, value, out_16);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: WIDTH=16 %s - in=0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, value, value, out_16);
      fail_count++;
    end
  endtask

  // Task to test 32-bit buffer
  task automatic test_buf_32(
    input logic [31:0] value,
    input string desc
  );
    test_num++;
    in_32 = value;
    #1; // Wait for combinational propagation
    
    if (out_32 === value) begin
      $display("[PASS] Test %0d: WIDTH=32 %s - in=0x%h, out=0x%h", 
               test_num, desc, value, out_32);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: WIDTH=32 %s - in=0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, value, value, out_32);
      fail_count++;
    end
  endtask

  // Task to test 64-bit buffer
  task automatic test_buf_64(
    input logic [63:0] value,
    input string desc
  );
    test_num++;
    in_64 = value;
    #1; // Wait for combinational propagation
    
    if (out_64 === value) begin
      $display("[PASS] Test %0d: WIDTH=64 %s - in=0x%h, out=0x%h", 
               test_num, desc, value, out_64);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: WIDTH=64 %s - in=0x%h, expected=0x%h, got=0x%h", 
               test_num, desc, value, value, out_64);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("prim_buf Self-Testing Testbench");
    $display("========================================");
    
    // Initialize all inputs
    in_1  = 1'b0;
    in_8  = 8'h0;
    in_16 = 16'h0;
    in_32 = 32'h0;
    in_64 = 64'h0;
    #10;
    
    $display("\n--- Testing WIDTH=1 Buffer ---");
    test_buf_1(1'b0, 1'b0, "logic 0");
    test_buf_1(1'b1, 1'b1, "logic 1");
    test_buf_1(1'bx, 1'bx, "unknown X");
    // Z converts to X in standard buffer (not tri-state)
    test_buf_1(1'bz, 1'bx, "high impedance Z->X");
    
    $display("\n--- Testing WIDTH=8 Buffer ---");
    test_buf_8(8'h00, "all zeros");
    test_buf_8(8'hFF, "all ones");
    test_buf_8(8'hAA, "alternating 10101010");
    test_buf_8(8'h55, "alternating 01010101");
    test_buf_8(8'h0F, "half 0s half 1s");
    test_buf_8(8'hF0, "half 1s half 0s");
    test_buf_8(8'h12, "random value 0x12");
    test_buf_8(8'h34, "random value 0x34");
    test_buf_8(8'h56, "random value 0x56");
    test_buf_8(8'h78, "random value 0x78");
    test_buf_8(8'h9A, "random value 0x9A");
    test_buf_8(8'hBC, "random value 0xBC");
    test_buf_8(8'hDE, "random value 0xDE");
    test_buf_8(8'h01, "LSB set");
    test_buf_8(8'h80, "MSB set");
    
    $display("\n--- Testing WIDTH=16 Buffer ---");
    test_buf_16(16'h0000, "all zeros");
    test_buf_16(16'hFFFF, "all ones");
    test_buf_16(16'hAAAA, "alternating pattern");
    test_buf_16(16'h5555, "alternating pattern");
    test_buf_16(16'h00FF, "byte patterns");
    test_buf_16(16'hFF00, "byte patterns");
    test_buf_16(16'h1234, "random value 0x1234");
    test_buf_16(16'h5678, "random value 0x5678");
    test_buf_16(16'h9ABC, "random value 0x9ABC");
    test_buf_16(16'hDEF0, "random value 0xDEF0");
    test_buf_16(16'h0001, "LSB set");
    test_buf_16(16'h8000, "MSB set");
    
    $display("\n--- Testing WIDTH=32 Buffer ---");
    test_buf_32(32'h00000000, "all zeros");
    test_buf_32(32'hFFFFFFFF, "all ones");
    test_buf_32(32'hAAAAAAAA, "alternating pattern");
    test_buf_32(32'h55555555, "alternating pattern");
    test_buf_32(32'h0000FFFF, "word patterns");
    test_buf_32(32'hFFFF0000, "word patterns");
    test_buf_32(32'h12345678, "random value");
    test_buf_32(32'h9ABCDEF0, "random value");
    test_buf_32(32'hDEADBEEF, "pattern 0xDEADBEEF");
    test_buf_32(32'hCAFEBABE, "pattern 0xCAFEBABE");
    test_buf_32(32'h80000000, "MSB set");
    test_buf_32(32'h00000001, "LSB set");
    test_buf_32(32'h7FFFFFFF, "max positive");
    test_buf_32(32'hF0F0F0F0, "nibble pattern");
    test_buf_32(32'h0F0F0F0F, "nibble pattern");
    
    $display("\n--- Testing WIDTH=64 Buffer ---");
    test_buf_64(64'h0000000000000000, "all zeros");
    test_buf_64(64'hFFFFFFFFFFFFFFFF, "all ones");
    test_buf_64(64'hAAAAAAAAAAAAAAAA, "alternating pattern");
    test_buf_64(64'h5555555555555555, "alternating pattern");
    test_buf_64(64'h00000000FFFFFFFF, "dword patterns");
    test_buf_64(64'hFFFFFFFF00000000, "dword patterns");
    test_buf_64(64'h123456789ABCDEF0, "random value");
    test_buf_64(64'hFEDCBA9876543210, "random value");
    test_buf_64(64'hDEADBEEFCAFEBABE, "pattern");
    test_buf_64(64'h0F0F0F0F0F0F0F0F, "nibble pattern");
    test_buf_64(64'hF0F0F0F0F0F0F0F0, "nibble pattern");
    test_buf_64(64'h8000000000000000, "MSB set");
    test_buf_64(64'h0000000000000001, "LSB set");
    test_buf_64(64'h0123456789ABCDEF, "sequential pattern");
    test_buf_64(64'hFEDCBA9876543210, "reverse pattern");
    
    $display("\n--- Testing Edge Cases ---");
    // Test rapid transitions for WIDTH=8
    for (int i = 0; i < 10; i++) begin
      test_buf_8($urandom_range(0, 255), $sformatf("random test %0d", i));
    end
    
    // Test rapid transitions for WIDTH=32
    for (int i = 0; i < 10; i++) begin
      test_buf_32($urandom(), $sformatf("random test %0d", i));
    end
    
    // Test boundary transitions
    $display("\n--- Testing Transitions ---");
    test_buf_32(32'h00000000, "zero");
    test_buf_32(32'hFFFFFFFF, "to all ones");
    test_buf_32(32'h00000000, "back to zero");
    test_buf_32(32'hA5A5A5A5, "pattern A5");
    test_buf_32(32'h5A5A5A5A, "pattern 5A");
    
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
