`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_onehot_enc
// Tests: Binary to One-Hot Encoder with enable
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_onehot_enc();

  // Test parameters - test multiple widths
  localparam int WIDTH_4 = 4;
  localparam int WIDTH_8 = 8;
  localparam int WIDTH_16 = 16;
  localparam int WIDTH_32 = 32;

  // Compute input widths
  localparam int IN_WIDTH_4 = $clog2(WIDTH_4);
  localparam int IN_WIDTH_8 = $clog2(WIDTH_8);
  localparam int IN_WIDTH_16 = $clog2(WIDTH_16);
  localparam int IN_WIDTH_32 = $clog2(WIDTH_32);

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Signals for WIDTH=4
  logic [IN_WIDTH_4-1:0] in_4;
  logic                  en_4;
  logic [WIDTH_4-1:0]    out_4;

  // Signals for WIDTH=8
  logic [IN_WIDTH_8-1:0] in_8;
  logic                  en_8;
  logic [WIDTH_8-1:0]    out_8;

  // Signals for WIDTH=16
  logic [IN_WIDTH_16-1:0] in_16;
  logic                   en_16;
  logic [WIDTH_16-1:0]    out_16;

  // Signals for WIDTH=32
  logic [IN_WIDTH_32-1:0] in_32;
  logic                   en_32;
  logic [WIDTH_32-1:0]    out_32;

  // DUT instantiations
  prim_onehot_enc #(.OneHotWidth(WIDTH_4)) dut_4 (
    .in_i(in_4),
    .en_i(en_4),
    .out_o(out_4)
  );

  prim_onehot_enc #(.OneHotWidth(WIDTH_8)) dut_8 (
    .in_i(in_8),
    .en_i(en_8),
    .out_o(out_8)
  );

  prim_onehot_enc #(.OneHotWidth(WIDTH_16)) dut_16 (
    .in_i(in_16),
    .en_i(en_16),
    .out_o(out_16)
  );

  prim_onehot_enc #(.OneHotWidth(WIDTH_32)) dut_32 (
    .in_i(in_32),
    .en_i(en_32),
    .out_o(out_32)
  );

  // Helper function to create expected one-hot output
  function automatic logic [31:0] make_onehot(input int pos, input int width, input logic enable);
    logic [31:0] result;
    result = '0;
    if (enable && (pos < width)) begin
      result = (1 << pos);
    end
    return result;
  endfunction

  // Helper function to check if output is one-hot
  function automatic logic is_onehot(input logic [31:0] value);
    return $onehot(value) || (value == '0);
  endfunction

  // Helper function to count set bits
  function automatic int count_ones(input logic [31:0] value);
    int count = 0;
    for (int i = 0; i < 32; i++) begin
      if (value[i]) count++;
    end
    return count;
  endfunction

  // Task to test WIDTH=4 encoder
  task automatic test_enc_4(
    input logic [IN_WIDTH_4-1:0] in_val,
    input logic en_val,
    input string desc
  );
    logic [WIDTH_4-1:0] expected;
    test_num++;
    
    in_4 = in_val;
    en_4 = en_val;
    #1; // Wait for combinational logic
    
    expected = make_onehot(in_val, WIDTH_4, en_val);
    
    if (out_4 === expected[WIDTH_4-1:0]) begin
      $display("[PASS] Test %0d: W=4 %s - in=%0d, en=%b, out=0b%b", 
               test_num, desc, in_val, en_val, out_4);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=4 %s - in=%0d, en=%b, expected=0b%b, got=0b%b", 
               test_num, desc, in_val, en_val, expected[WIDTH_4-1:0], out_4);
      fail_count++;
    end
  endtask

  // Task to test WIDTH=8 encoder
  task automatic test_enc_8(
    input logic [IN_WIDTH_8-1:0] in_val,
    input logic en_val,
    input string desc
  );
    logic [WIDTH_8-1:0] expected;
    test_num++;
    
    in_8 = in_val;
    en_8 = en_val;
    #1; // Wait for combinational logic
    
    expected = make_onehot(in_val, WIDTH_8, en_val);
    
    if (out_8 === expected[WIDTH_8-1:0]) begin
      $display("[PASS] Test %0d: W=8 %s - in=%0d, en=%b, out=0x%h", 
               test_num, desc, in_val, en_val, out_8);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=8 %s - in=%0d, en=%b, expected=0x%h, got=0x%h", 
               test_num, desc, in_val, en_val, expected[WIDTH_8-1:0], out_8);
      fail_count++;
    end
  endtask

  // Task to test WIDTH=16 encoder
  task automatic test_enc_16(
    input logic [IN_WIDTH_16-1:0] in_val,
    input logic en_val,
    input string desc
  );
    logic [WIDTH_16-1:0] expected;
    test_num++;
    
    in_16 = in_val;
    en_16 = en_val;
    #1; // Wait for combinational logic
    
    expected = make_onehot(in_val, WIDTH_16, en_val);
    
    if (out_16 === expected[WIDTH_16-1:0]) begin
      $display("[PASS] Test %0d: W=16 %s - in=%0d, en=%b, out=0x%h", 
               test_num, desc, in_val, en_val, out_16);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=16 %s - in=%0d, en=%b, expected=0x%h, got=0x%h", 
               test_num, desc, in_val, en_val, expected[WIDTH_16-1:0], out_16);
      fail_count++;
    end
  endtask

  // Task to test WIDTH=32 encoder
  task automatic test_enc_32(
    input logic [IN_WIDTH_32-1:0] in_val,
    input logic en_val,
    input string desc
  );
    logic [WIDTH_32-1:0] expected;
    test_num++;
    
    in_32 = in_val;
    en_32 = en_val;
    #1; // Wait for combinational logic
    
    expected = make_onehot(in_val, WIDTH_32, en_val);
    
    if (out_32 === expected[WIDTH_32-1:0]) begin
      $display("[PASS] Test %0d: W=32 %s - in=%0d, en=%b, out=0x%h", 
               test_num, desc, in_val, en_val, out_32);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=32 %s - in=%0d, en=%b, expected=0x%h, got=0x%h", 
               test_num, desc, in_val, en_val, expected[WIDTH_32-1:0], out_32);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("prim_onehot_enc Self-Testing Testbench");
    $display("========================================");
    
    // Initialize
    in_4 = '0;
    en_4 = '0;
    in_8 = '0;
    en_8 = '0;
    in_16 = '0;
    en_16 = '0;
    in_32 = '0;
    en_32 = '0;
    #10;
    
    $display("\n--- Testing WIDTH=4 (2-bit input) ---");
    // Test all inputs with enable=1
    test_enc_4(2'd0, 1'b1, "encode 0");
    test_enc_4(2'd1, 1'b1, "encode 1");
    test_enc_4(2'd2, 1'b1, "encode 2");
    test_enc_4(2'd3, 1'b1, "encode 3");
    
    // Test with enable=0 (should output all zeros)
    test_enc_4(2'd0, 1'b0, "en=0 in=0");
    test_enc_4(2'd1, 1'b0, "en=0 in=1");
    test_enc_4(2'd2, 1'b0, "en=0 in=2");
    test_enc_4(2'd3, 1'b0, "en=0 in=3");
    
    $display("\n--- Testing WIDTH=8 (3-bit input) ---");
    // Test all inputs with enable=1
    for (int i = 0; i < 8; i++) begin
      test_enc_8(i[IN_WIDTH_8-1:0], 1'b1, $sformatf("encode %0d", i));
    end
    
    // Test boundary cases with enable=0
    test_enc_8(3'd0, 1'b0, "en=0 in=0");
    test_enc_8(3'd7, 1'b0, "en=0 in=7");
    
    $display("\n--- Testing WIDTH=16 (4-bit input) ---");
    // Test boundary and selected values
    test_enc_16(4'd0, 1'b1, "encode 0");
    test_enc_16(4'd1, 1'b1, "encode 1");
    test_enc_16(4'd7, 1'b1, "encode 7");
    test_enc_16(4'd8, 1'b1, "encode 8");
    test_enc_16(4'd15, 1'b1, "encode 15");
    
    // Test with enable=0
    test_enc_16(4'd0, 1'b0, "en=0 in=0");
    test_enc_16(4'd8, 1'b0, "en=0 in=8");
    test_enc_16(4'd15, 1'b0, "en=0 in=15");
    
    $display("\n--- Testing WIDTH=32 (5-bit input) ---");
    // Test boundary cases
    test_enc_32(5'd0, 1'b1, "encode 0 (LSB)");
    test_enc_32(5'd1, 1'b1, "encode 1");
    test_enc_32(5'd15, 1'b1, "encode 15");
    test_enc_32(5'd16, 1'b1, "encode 16");
    test_enc_32(5'd31, 1'b1, "encode 31 (MSB)");
    
    // Test powers of 2
    test_enc_32(5'd2, 1'b1, "encode 2");
    test_enc_32(5'd4, 1'b1, "encode 4");
    test_enc_32(5'd8, 1'b1, "encode 8");
    
    // Test with enable=0
    test_enc_32(5'd0, 1'b0, "en=0 in=0");
    test_enc_32(5'd16, 1'b0, "en=0 in=16");
    test_enc_32(5'd31, 1'b0, "en=0 in=31");
    
    $display("\n--- Testing All Positions for WIDTH=32 ---");
    // Comprehensive scan of all positions
    for (int i = 0; i < 32; i++) begin
      test_enc_32(i[IN_WIDTH_32-1:0], 1'b1, $sformatf("scan pos %0d", i));
    end
    
    $display("\n--- Testing Enable Toggle ---");
    // Rapid enable toggling
    for (int i = 0; i < 8; i++) begin
      test_enc_8(3'd5, 1'b1, "toggle en=1");
      test_enc_8(3'd5, 1'b0, "toggle en=0");
    end
    
    $display("\n--- Verifying One-Hot Property ---");
    // Verify all outputs are truly one-hot (exactly 1 bit set when enabled)
    begin
      int verification_pass;
      int bits_set;
      logic test_passed;
      
      verification_pass = 1;
      
      for (int i = 0; i < 32; i++) begin
        in_32 = i[IN_WIDTH_32-1:0];
        en_32 = 1'b1;
        #1;
        
        // Count set bits
        bits_set = count_ones(out_32);
        
        // Check that exactly one bit is set
        test_passed = 1'b1;
        if (bits_set != 1) begin
          $display("[ERROR] Not one-hot: in=%0d, out=0x%h has %0d bits set", 
                   i, out_32, bits_set);
          verification_pass = 0;
          test_passed = 1'b0;
        end
        
        // Check that the correct bit is set
        if (test_passed && (out_32[i] != 1'b1)) begin
          $display("[ERROR] Wrong bit: in=%0d, expected bit %0d set, got 0x%h", 
                   i, i, out_32);
          verification_pass = 0;
        end
      end
      
      if (verification_pass) begin
        $display("[INFO] All outputs verified as proper one-hot encoding");
      end else begin
        $display("[ERROR] One-hot property violations detected");
        fail_count = fail_count + 1;
      end
    end
    
    $display("\n--- Testing Sequential Pattern ---");
    // Test sequential encoding
    for (int i = 0; i < 16; i++) begin
      test_enc_16(i[IN_WIDTH_16-1:0], 1'b1, $sformatf("sequential %0d", i));
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
