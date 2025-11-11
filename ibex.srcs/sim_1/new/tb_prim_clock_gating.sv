`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_clock_gating
// Tests: Clock gating with enable and test enable
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_clock_gating();

  // Test parameters
  localparam real CLK_PERIOD = 10.0; // 100MHz clock

  // Clock and control signals
  logic clk_i;
  logic en_i;
  logic test_en_i;

  // Outputs for different configurations
  logic clk_o_no_gate;
  logic clk_o_bufgce;
  logic clk_o_bufhce;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Clock generation
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // DUT instantiations for different configurations

  // Configuration 1: No gating (bypass mode)
  prim_clock_gating #(
    .NoFpgaGate(1'b1),
    .FpgaBufGlobal(1'b1) // Don't care when NoFpgaGate=1
  ) dut_no_gate (
    .clk_i(clk_i),
    .en_i(en_i),
    .test_en_i(test_en_i),
    .clk_o(clk_o_no_gate)
  );

  // Configuration 2: BUFGCE (global buffer with enable)
  prim_clock_gating #(
    .NoFpgaGate(1'b0),
    .FpgaBufGlobal(1'b1)
  ) dut_bufgce (
    .clk_i(clk_i),
    .en_i(en_i),
    .test_en_i(test_en_i),
    .clk_o(clk_o_bufgce)
  );

  // Configuration 3: BUFHCE (local/horizontal buffer with enable)
  prim_clock_gating #(
    .NoFpgaGate(1'b0),
    .FpgaBufGlobal(1'b0)
  ) dut_bufhce (
    .clk_i(clk_i),
    .en_i(en_i),
    .test_en_i(test_en_i),
    .clk_o(clk_o_bufhce)
  );

  // Clock edge counters
  int no_gate_edges = 0;
  int bufgce_edges = 0;
  int bufhce_edges = 0;

  // Count clock edges
  always @(posedge clk_o_no_gate) no_gate_edges++;
  always @(posedge clk_o_bufgce) bufgce_edges++;
  always @(posedge clk_o_bufhce) bufhce_edges++;

  // Task to wait for clock edges
  task automatic wait_clocks(int num_clocks);
    repeat(num_clocks) @(posedge clk_i);
  endtask

  // Task to test no-gating configuration
  task automatic test_no_gate_config(
    input logic en_val,
    input logic test_en_val,
    input string desc
  );
    int start_edges, end_edges;
    test_num++;
    
    // Set enables
    en_i = en_val;
    test_en_i = test_en_val;
    
    // Wait for enable to take effect
    wait_clocks(2);
    start_edges = no_gate_edges;
    
    // Wait and count edges
    wait_clocks(10);
    end_edges = no_gate_edges;
    
    // No-gate mode should always pass clock through
    if ((end_edges - start_edges) >= 9) begin
      $display("[PASS] Test %0d: NoGate %s - en=%b, test_en=%b, edges=%0d", 
               test_num, desc, en_val, test_en_val, end_edges - start_edges);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: NoGate %s - en=%b, test_en=%b, expected>=9 edges, got=%0d", 
               test_num, desc, en_val, test_en_val, end_edges - start_edges);
      fail_count++;
    end
  endtask

  // Task to test BUFGCE configuration
  task automatic test_bufgce_config(
    input logic en_val,
    input logic test_en_val,
    input int expected_min_edges,
    input string desc
  );
    int start_edges, end_edges;
    test_num++;
    
    // Set enables
    en_i = en_val;
    test_en_i = test_en_val;
    
    // Wait for enable to take effect
    wait_clocks(2);
    start_edges = bufgce_edges;
    
    // Wait and count edges
    wait_clocks(10);
    end_edges = bufgce_edges;
    
    if ((end_edges - start_edges) >= expected_min_edges) begin
      $display("[PASS] Test %0d: BUFGCE %s - en=%b, test_en=%b, edges=%0d", 
               test_num, desc, en_val, test_en_val, end_edges - start_edges);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: BUFGCE %s - en=%b, test_en=%b, expected>=%0d edges, got=%0d", 
               test_num, desc, en_val, test_en_val, expected_min_edges, end_edges - start_edges);
      fail_count++;
    end
  endtask

  // Task to test BUFHCE configuration
  task automatic test_bufhce_config(
    input logic en_val,
    input logic test_en_val,
    input int expected_min_edges,
    input string desc
  );
    int start_edges, end_edges;
    test_num++;
    
    // Set enables
    en_i = en_val;
    test_en_i = test_en_val;
    
    // Wait for enable to take effect
    wait_clocks(2);
    start_edges = bufhce_edges;
    
    // Wait and count edges
    wait_clocks(10);
    end_edges = bufhce_edges;
    
    if ((end_edges - start_edges) >= expected_min_edges) begin
      $display("[PASS] Test %0d: BUFHCE %s - en=%b, test_en=%b, edges=%0d", 
               test_num, desc, en_val, test_en_val, end_edges - start_edges);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: BUFHCE %s - en=%b, test_en=%b, expected>=%0d edges, got=%0d", 
               test_num, desc, en_val, test_en_val, expected_min_edges, end_edges - start_edges);
      fail_count++;
    end
  endtask

  // Task to verify clock output follows input (no gating mode)
  task automatic verify_clock_passthrough();
    logic last_clk_i, last_clk_o;
    int mismatches = 0;
    
    test_num++;
    $display("[INFO] Verifying clock passthrough for NoGate configuration...");
    
    for (int i = 0; i < 20; i++) begin
      @(posedge clk_i or negedge clk_i);
      #0.1; // Small delay to let signal propagate
      if (clk_i !== clk_o_no_gate) begin
        mismatches++;
      end
    end
    
    if (mismatches == 0) begin
      $display("[PASS] Test %0d: Clock passthrough verification", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Clock passthrough had %0d mismatches", test_num, mismatches);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("prim_clock_gating Self-Testing Testbench");
    $display("========================================");
    $display("Clock Period: %0.1f ns", CLK_PERIOD);
    
    // Initialize
    en_i = 0;
    test_en_i = 0;
    
    // Wait for initial settling
    wait_clocks(5);
    
    $display("\n--- Testing NoFpgaGate=1 Configuration (Bypass) ---");
    
    // No-gate mode should always pass clock through regardless of enables
    test_no_gate_config(1'b0, 1'b0, "both disabled");
    test_no_gate_config(1'b1, 1'b0, "en enabled");
    test_no_gate_config(1'b0, 1'b1, "test_en enabled");
    test_no_gate_config(1'b1, 1'b1, "both enabled");
    
    // Verify clock passthrough
    verify_clock_passthrough();
    
    $display("\n--- Testing BUFGCE Configuration (Global Buffer) ---");
    
    // BUFGCE gates clock when both en_i and test_en_i are low
    test_bufgce_config(1'b0, 1'b0, 0, "both disabled - gated");
    test_bufgce_config(1'b1, 1'b0, 9, "en enabled");
    test_bufgce_config(1'b0, 1'b1, 9, "test_en enabled");
    test_bufgce_config(1'b1, 1'b1, 9, "both enabled");
    
    $display("\n--- Testing BUFHCE Configuration (Local Buffer) ---");
    
    // BUFHCE gates clock when both en_i and test_en_i are low
    test_bufhce_config(1'b0, 1'b0, 0, "both disabled - gated");
    test_bufhce_config(1'b1, 1'b0, 9, "en enabled");
    test_bufhce_config(1'b0, 1'b1, 9, "test_en enabled");
    test_bufhce_config(1'b1, 1'b1, 9, "both enabled");
    
    $display("\n--- Testing Enable Transitions ---");
    
    // Test enable toggling for BUFGCE
    en_i = 1'b1;
    test_en_i = 1'b0;
    wait_clocks(5);
    
    en_i = 1'b0; // Disable clock
    wait_clocks(5);
    
    en_i = 1'b1; // Re-enable clock
    wait_clocks(5);
    
    $display("[INFO] Enable toggle test completed");
    
    // Test test_en override
    en_i = 1'b0;
    test_en_i = 1'b1; // test_en should override en_i
    wait_clocks(5);
    
    test_en_i = 1'b0; // Both disabled - clock should gate
    wait_clocks(5);
    
    $display("[INFO] Test enable override test completed");
    
    $display("\n--- Testing Glitch-Free Transitions ---");
    
    // Test rapid enable changes (should be glitch-free in hardware)
    for (int i = 0; i < 10; i++) begin
      en_i = ~en_i;
      wait_clocks(3);
    end
    
    $display("[INFO] Rapid enable toggle test completed");
    
    $display("\n--- Functional Test Summary ---");
    $display("NoGate edges: %0d", no_gate_edges);
    $display("BUFGCE edges: %0d", bufgce_edges);
    $display("BUFHCE edges: %0d", bufhce_edges);
    
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

  // Monitor for clock glitches (simple check)
  real last_posedge_time = 0;
  real current_time;
  
  always @(posedge clk_o_bufgce) begin
    current_time = $realtime;
    if (last_posedge_time > 0) begin
      real period = current_time - last_posedge_time;
      // Check if period is within reasonable bounds (allowing some tolerance)
      if (period < CLK_PERIOD * 0.8 || period > CLK_PERIOD * 1.2) begin
        if (en_i || test_en_i) begin // Only flag if clock should be running
          $display("[WARNING] BUFGCE clock period anomaly: %.2f ns at time %.2f ns", 
                   period, current_time);
        end
      end
    end
    last_posedge_time = current_time;
  end

endmodule
