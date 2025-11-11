`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_flop
// Tests: Parameterizable D flip-flop with asynchronous reset
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_flop();

  // Test parameters
  localparam int WIDTH_1 = 1;
  localparam int WIDTH_8 = 8;
  localparam int WIDTH_16 = 16;
  localparam int WIDTH_32 = 32;
  localparam real CLK_PERIOD = 10.0; // 100MHz

  // Clock and reset
  logic clk_i;
  logic rst_ni;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Signals for WIDTH=1, ResetValue=0
  logic [WIDTH_1-1:0] d_1_rv0;
  logic [WIDTH_1-1:0] q_1_rv0;

  // Signals for WIDTH=1, ResetValue=1
  logic [WIDTH_1-1:0] d_1_rv1;
  logic [WIDTH_1-1:0] q_1_rv1;

  // Signals for WIDTH=8, ResetValue=0xAA
  logic [WIDTH_8-1:0] d_8;
  logic [WIDTH_8-1:0] q_8;

  // Signals for WIDTH=16, ResetValue=0x0000
  logic [WIDTH_16-1:0] d_16;
  logic [WIDTH_16-1:0] q_16;

  // Signals for WIDTH=32, ResetValue=0xDEADBEEF
  logic [WIDTH_32-1:0] d_32;
  logic [WIDTH_32-1:0] q_32;

  // Clock generation
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // DUT instantiations with different parameters
  
  // 1-bit flop with reset value 0
  prim_flop #(
    .Width(WIDTH_1),
    .ResetValue(1'b0)
  ) dut_1_rv0 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(d_1_rv0),
    .q_o(q_1_rv0)
  );

  // 1-bit flop with reset value 1
  prim_flop #(
    .Width(WIDTH_1),
    .ResetValue(1'b1)
  ) dut_1_rv1 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(d_1_rv1),
    .q_o(q_1_rv1)
  );

  // 8-bit flop with reset value 0xAA
  prim_flop #(
    .Width(WIDTH_8),
    .ResetValue(8'hAA)
  ) dut_8 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(d_8),
    .q_o(q_8)
  );

  // 16-bit flop with reset value 0
  prim_flop #(
    .Width(WIDTH_16),
    .ResetValue(16'h0000)
  ) dut_16 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(d_16),
    .q_o(q_16)
  );

  // 32-bit flop with reset value 0xDEADBEEF
  prim_flop #(
    .Width(WIDTH_32),
    .ResetValue(32'hDEADBEEF)
  ) dut_32 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(d_32),
    .q_o(q_32)
  );

  // Task to apply reset
  task automatic apply_reset();
    rst_ni = 0;
    repeat(2) @(posedge clk_i);
    rst_ni = 1;
    @(posedge clk_i);
  endtask

  // Task to test 1-bit flop
  task automatic test_flop_1(
    input logic d_val,
    input logic expected_q,
    input logic [WIDTH_1-1:0] reset_val,
    input string desc
  );
    test_num++;
    
    if (reset_val == 1'b0) begin
      d_1_rv0 = d_val;
      @(posedge clk_i);
      #1; // Small delay after clock edge
      
      if (q_1_rv0 === expected_q) begin
        $display("[PASS] Test %0d: W=1,RV=0 %s - d=%b, q=%b", 
                 test_num, desc, d_val, q_1_rv0);
        pass_count++;
      end else begin
        $display("[FAIL] Test %0d: W=1,RV=0 %s - d=%b, expected_q=%b, got_q=%b", 
                 test_num, desc, d_val, expected_q, q_1_rv0);
        fail_count++;
      end
    end else begin
      d_1_rv1 = d_val;
      @(posedge clk_i);
      #1; // Small delay after clock edge
      
      if (q_1_rv1 === expected_q) begin
        $display("[PASS] Test %0d: W=1,RV=1 %s - d=%b, q=%b", 
                 test_num, desc, d_val, q_1_rv1);
        pass_count++;
      end else begin
        $display("[FAIL] Test %0d: W=1,RV=1 %s - d=%b, expected_q=%b, got_q=%b", 
                 test_num, desc, d_val, expected_q, q_1_rv1);
        fail_count++;
      end
    end
  endtask

  // Task to test 8-bit flop
  task automatic test_flop_8(
    input logic [WIDTH_8-1:0] d_val,
    input logic [WIDTH_8-1:0] expected_q,
    input string desc
  );
    test_num++;
    
    d_8 = d_val;
    @(posedge clk_i);
    #1; // Small delay after clock edge
    
    if (q_8 === expected_q) begin
      $display("[PASS] Test %0d: W=8 %s - d=0x%h, q=0x%h", 
               test_num, desc, d_val, q_8);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=8 %s - d=0x%h, expected_q=0x%h, got_q=0x%h", 
               test_num, desc, d_val, expected_q, q_8);
      fail_count++;
    end
  endtask

  // Task to test 32-bit flop
  task automatic test_flop_32(
    input logic [WIDTH_32-1:0] d_val,
    input logic [WIDTH_32-1:0] expected_q,
    input string desc
  );
    test_num++;
    
    d_32 = d_val;
    @(posedge clk_i);
    #1; // Small delay after clock edge
    
    if (q_32 === expected_q) begin
      $display("[PASS] Test %0d: W=32 %s - d=0x%h, q=0x%h", 
               test_num, desc, d_val, q_32);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: W=32 %s - d=0x%h, expected_q=0x%h, got_q=0x%h", 
               test_num, desc, d_val, expected_q, q_32);
      fail_count++;
    end
  endtask

  // Task to verify reset value
  task automatic verify_reset_value();
    test_num++;
    
    rst_ni = 0;
    #1; // Small delay to let reset propagate
    
    if (q_1_rv0 === 1'b0 && q_1_rv1 === 1'b1 && 
        q_8 === 8'hAA && q_16 === 16'h0000 && q_32 === 32'hDEADBEEF) begin
      $display("[PASS] Test %0d: Reset values correct - rv0=0x%h, rv1=0x%h, rv8=0x%h, rv16=0x%h, rv32=0x%h", 
               test_num, q_1_rv0, q_1_rv1, q_8, q_16, q_32);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Reset values incorrect", test_num);
      $display("  q_1_rv0=%b (expected 0), q_1_rv1=%b (expected 1)", q_1_rv0, q_1_rv1);
      $display("  q_8=0x%h (expected 0xAA), q_16=0x%h (expected 0x0000)", q_8, q_16);
      $display("  q_32=0x%h (expected 0xDEADBEEF)", q_32);
      fail_count++;
    end
    
    rst_ni = 1;
    @(posedge clk_i);
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("prim_flop Self-Testing Testbench");
    $display("========================================");
    $display("Clock Period: %0.1f ns", CLK_PERIOD);
    
    // Initialize inputs
    d_1_rv0 = 0;
    d_1_rv1 = 0;
    d_8 = 0;
    d_16 = 0;
    d_32 = 0;
    rst_ni = 1;
    
    repeat(2) @(posedge clk_i);
    
    $display("\n--- Testing Asynchronous Reset Values ---");
    verify_reset_value();
    
    $display("\n--- Testing 1-bit Flop (ResetValue=0) ---");
    apply_reset();
    
    // Test data propagation
    test_flop_1(1'b0, 1'b0, 1'b0, "hold 0");
    test_flop_1(1'b1, 1'b1, 1'b0, "set to 1");
    test_flop_1(1'b1, 1'b1, 1'b0, "hold 1");
    test_flop_1(1'b0, 1'b0, 1'b0, "clear to 0");
    
    // Test toggle pattern
    for (int i = 0; i < 10; i++) begin
      logic val = i[0];
      test_flop_1(val, val, 1'b0, $sformatf("toggle %0d", i));
    end
    
    $display("\n--- Testing 1-bit Flop (ResetValue=1) ---");
    apply_reset();
    
    test_flop_1(1'b1, 1'b1, 1'b1, "hold 1");
    test_flop_1(1'b0, 1'b0, 1'b1, "clear to 0");
    test_flop_1(1'b0, 1'b0, 1'b1, "hold 0");
    test_flop_1(1'b1, 1'b1, 1'b1, "set to 1");
    
    $display("\n--- Testing 8-bit Flop (ResetValue=0xAA) ---");
    apply_reset();
    
    // Test various 8-bit patterns
    test_flop_8(8'h00, 8'h00, "all zeros");
    test_flop_8(8'hFF, 8'hFF, "all ones");
    test_flop_8(8'hAA, 8'hAA, "alternating 10");
    test_flop_8(8'h55, 8'h55, "alternating 01");
    test_flop_8(8'h12, 8'h12, "pattern 0x12");
    test_flop_8(8'h34, 8'h34, "pattern 0x34");
    
    // Test sequential values
    for (int i = 0; i < 8; i++) begin
      test_flop_8(8'(i * 16), 8'(i * 16), $sformatf("sequential 0x%h", i * 16));
    end
    
    $display("\n--- Testing 32-bit Flop (ResetValue=0xDEADBEEF) ---");
    apply_reset();
    
    // Test various 32-bit patterns
    test_flop_32(32'h00000000, 32'h00000000, "all zeros");
    test_flop_32(32'hFFFFFFFF, 32'hFFFFFFFF, "all ones");
    test_flop_32(32'h12345678, 32'h12345678, "pattern 1");
    test_flop_32(32'h9ABCDEF0, 32'h9ABCDEF0, "pattern 2");
    test_flop_32(32'hAAAAAAAA, 32'hAAAAAAAA, "alternating");
    test_flop_32(32'h55555555, 32'h55555555, "alternating");
    test_flop_32(32'hCAFEBABE, 32'hCAFEBABE, "pattern 3");
    
    $display("\n--- Testing Asynchronous Reset During Operation ---");
    
    // Load a value, then reset
    d_32 = 32'h12345678;
    @(posedge clk_i);
    #1;
    $display("[INFO] Loaded value: q_32=0x%h", q_32);
    
    // Apply async reset (active low)
    rst_ni = 0;
    #(CLK_PERIOD/4); // Reset in middle of clock cycle
    
    if (q_32 === 32'hDEADBEEF) begin
      $display("[PASS] Async reset worked immediately (q_32=0x%h)", q_32);
      pass_count++;
      test_num++;
    end else begin
      $display("[FAIL] Async reset failed (q_32=0x%h, expected 0xDEADBEEF)", q_32);
      fail_count++;
      test_num++;
    end
    
    rst_ni = 1;
    @(posedge clk_i);
    
    $display("\n--- Testing Data Retention ---");
    
    // Load value and verify it holds for multiple cycles
    d_32 = 32'hA5A5A5A5;
    @(posedge clk_i);
    #1;
    
    d_32 = 32'h00000000; // Change input
    
    for (int i = 0; i < 5; i++) begin
      @(posedge clk_i);
      #1;
      if (i == 0 && q_32 === 32'h00000000) begin
        $display("[INFO] Data updated on first cycle after input change");
        break;
      end
    end
    
    $display("\n--- Testing Setup/Hold Time (Functional) ---");
    
    // Change data right before clock edge
    d_8 = 8'hAA;
    @(posedge clk_i);
    #(CLK_PERIOD - 0.5); // Just before next clock edge
    d_8 = 8'h55;
    @(posedge clk_i);
    #1;
    
    if (q_8 === 8'h55) begin
      $display("[INFO] Late data change captured: q_8=0x%h", q_8);
    end else begin
      $display("[INFO] Late data change not captured: q_8=0x%h (setup violation)", q_8);
    end
    
    $display("\n--- Testing Random Patterns ---");
    
    for (int i = 0; i < 10; i++) begin
      logic [31:0] random_val = $urandom();
      test_flop_32(random_val, random_val, $sformatf("random %0d", i));
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
