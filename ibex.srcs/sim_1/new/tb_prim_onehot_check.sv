`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for prim_onehot_check
// Tests: Onehot checking with enable and address validation
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_prim_onehot_check();

  // Test parameters - test multiple configurations
  localparam int AddrWidth = 5;
  localparam int OneHotWidth = 32;

  // Testbench signals
  logic                      clk_i;
  logic                      rst_ni;
  logic [OneHotWidth-1:0]    oh_i;
  logic [AddrWidth-1:0]      addr_i;
  logic                      en_i;
  logic                      err_o;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Clock generation (10ns period = 100MHz)
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // DUT instantiations for different configurations
  
  // Configuration 1: Full checks (AddrCheck=1, EnableCheck=1, StrictCheck=1)
  logic err_full;
  prim_onehot_check #(
    .AddrWidth(AddrWidth),
    .OneHotWidth(OneHotWidth),
    .AddrCheck(1),
    .EnableCheck(1),
    .StrictCheck(1),
    .EnableAlertTriggerSVA(0)
  ) dut_full (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .oh_i(oh_i),
    .addr_i(addr_i),
    .en_i(en_i),
    .err_o(err_full)
  );

  // Configuration 2: No address check (AddrCheck=0, EnableCheck=1, StrictCheck=1)
  logic err_no_addr;
  prim_onehot_check #(
    .AddrWidth(AddrWidth),
    .OneHotWidth(OneHotWidth),
    .AddrCheck(0),
    .EnableCheck(1),
    .StrictCheck(1),
    .EnableAlertTriggerSVA(0)
  ) dut_no_addr (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .oh_i(oh_i),
    .addr_i(addr_i),
    .en_i(en_i),
    .err_o(err_no_addr)
  );

  // Configuration 3: No enable check (AddrCheck=0, EnableCheck=0, StrictCheck=0)
  logic err_no_enable;
  prim_onehot_check #(
    .AddrWidth(AddrWidth),
    .OneHotWidth(OneHotWidth),
    .AddrCheck(0),
    .EnableCheck(0),
    .StrictCheck(0),
    .EnableAlertTriggerSVA(0)
  ) dut_no_enable (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .oh_i(oh_i),
    .addr_i(addr_i),
    .en_i(en_i),
    .err_o(err_no_enable)
  );

  // Configuration 4: Not strict (AddrCheck=1, EnableCheck=1, StrictCheck=0)
  logic err_not_strict;
  prim_onehot_check #(
    .AddrWidth(AddrWidth),
    .OneHotWidth(OneHotWidth),
    .AddrCheck(1),
    .EnableCheck(1),
    .StrictCheck(0),
    .EnableAlertTriggerSVA(0)
  ) dut_not_strict (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .oh_i(oh_i),
    .addr_i(addr_i),
    .en_i(en_i),
    .err_o(err_not_strict)
  );

  // Initialize signals
  task automatic init_signals();
    rst_ni = 0;
    oh_i = '0;
    addr_i = '0;
    en_i = 0;
  endtask

  // Reset DUT
  task automatic reset_dut();
    rst_ni = 0;
    repeat(3) @(posedge clk_i);
    rst_ni = 1;
    repeat(2) @(posedge clk_i);
  endtask

  // Task to test full configuration
  task automatic test_full_config(
    input logic [OneHotWidth-1:0] oh_val,
    input logic [AddrWidth-1:0] addr_val,
    input logic en_val,
    input logic expected_err,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    oh_i = oh_val;
    addr_i = addr_val;
    en_i = en_val;
    
    #1; // Wait for combinational logic
    
    if (err_full === expected_err) begin
      $display("[PASS] Test %0d: Full - %s - oh=0x%h, addr=%0d, en=%b, err=%b", 
               test_num, desc, oh_val, addr_val, en_val, err_full);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Full - %s - oh=0x%h, addr=%0d, en=%b, expected_err=%b, got=%b", 
               test_num, desc, oh_val, addr_val, en_val, expected_err, err_full);
      fail_count++;
    end
  endtask

  // Task to test no address check configuration
  task automatic test_no_addr_config(
    input logic [OneHotWidth-1:0] oh_val,
    input logic en_val,
    input logic expected_err,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    oh_i = oh_val;
    en_i = en_val;
    addr_i = '0; // Don't care
    
    #1; // Wait for combinational logic
    
    if (err_no_addr === expected_err) begin
      $display("[PASS] Test %0d: NoAddr - %s - oh=0x%h, en=%b, err=%b", 
               test_num, desc, oh_val, en_val, err_no_addr);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: NoAddr - %s - oh=0x%h, en=%b, expected_err=%b, got=%b", 
               test_num, desc, oh_val, en_val, expected_err, err_no_addr);
      fail_count++;
    end
  endtask

  // Task to test not strict configuration
  task automatic test_not_strict_config(
    input logic [OneHotWidth-1:0] oh_val,
    input logic [AddrWidth-1:0] addr_val,
    input logic en_val,
    input logic expected_err,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    oh_i = oh_val;
    addr_i = addr_val;
    en_i = en_val;
    
    #1; // Wait for combinational logic
    
    if (err_not_strict === expected_err) begin
      $display("[PASS] Test %0d: NotStrict - %s - oh=0x%h, addr=%0d, en=%b, err=%b", 
               test_num, desc, oh_val, addr_val, en_val, err_not_strict);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: NotStrict - %s - oh=0x%h, addr=%0d, en=%b, expected_err=%b, got=%b", 
               test_num, desc, oh_val, addr_val, en_val, expected_err, err_not_strict);
      fail_count++;
    end
  endtask

  // Helper function to create one-hot value
  function logic [OneHotWidth-1:0] make_onehot(input int pos);
    return (pos < OneHotWidth) ? (1 << pos) : '0;
  endfunction

  // Main test sequence
  initial begin
    $display("========================================");
    $display("prim_onehot_check Self-Testing Testbench");
    $display("========================================");
    $display("AddrWidth=%0d, OneHotWidth=%0d", AddrWidth, OneHotWidth);
    
    init_signals();
    reset_dut();
    repeat(5) @(posedge clk_i);
    
    $display("\n--- Testing Full Configuration (Addr+Enable+Strict) ---");
    
    // Valid onehot cases with matching address and enable
    test_full_config(32'h00000001, 5'd0, 1'b1, 1'b0, "valid bit 0");
    test_full_config(32'h00000002, 5'd1, 1'b1, 1'b0, "valid bit 1");
    test_full_config(32'h00000004, 5'd2, 1'b1, 1'b0, "valid bit 2");
    test_full_config(32'h00000008, 5'd3, 1'b1, 1'b0, "valid bit 3");
    test_full_config(32'h00000010, 5'd4, 1'b1, 1'b0, "valid bit 4");
    test_full_config(32'h00000020, 5'd5, 1'b1, 1'b0, "valid bit 5");
    test_full_config(32'h00000100, 5'd8, 1'b1, 1'b0, "valid bit 8");
    test_full_config(32'h00010000, 5'd16, 1'b1, 1'b0, "valid bit 16");
    test_full_config(32'h80000000, 5'd31, 1'b1, 1'b0, "valid bit 31");
    
    // Valid onehot0 (all zeros) with enable=0
    test_full_config(32'h00000000, 5'd0, 1'b0, 1'b0, "valid onehot0");
    
    // Error: Multiple bits set (violates onehot0)
    test_full_config(32'h00000003, 5'd0, 1'b1, 1'b1, "error: 2 bits set");
    test_full_config(32'h00000005, 5'd2, 1'b1, 1'b1, "error: bits 0,2 set");
    test_full_config(32'h00000011, 5'd4, 1'b1, 1'b1, "error: bits 0,4 set");
    test_full_config(32'hFFFFFFFF, 5'd0, 1'b1, 1'b1, "error: all bits set");
    
    // Error: Address mismatch
    test_full_config(32'h00000001, 5'd1, 1'b1, 1'b1, "error: addr mismatch bit0");
    test_full_config(32'h00000002, 5'd0, 1'b1, 1'b1, "error: addr mismatch bit1");
    test_full_config(32'h00000100, 5'd7, 1'b1, 1'b1, "error: addr mismatch bit8");
    
    // Error: Enable mismatch (strict mode)
    test_full_config(32'h00000001, 5'd0, 1'b0, 1'b1, "error: en=0 but oh set");
    test_full_config(32'h00000000, 5'd0, 1'b1, 1'b1, "error: en=1 but oh=0");
    
    $display("\n--- Testing No Address Check Configuration ---");
    
    // Valid onehot with enable (address ignored)
    test_no_addr_config(32'h00000001, 1'b1, 1'b0, "valid bit 0");
    test_no_addr_config(32'h00000080, 1'b1, 1'b0, "valid bit 7");
    test_no_addr_config(32'h00000000, 1'b0, 1'b0, "valid onehot0");
    
    // Error: Multiple bits
    test_no_addr_config(32'h00000003, 1'b1, 1'b1, "error: 2 bits");
    
    // Error: Enable mismatch
    test_no_addr_config(32'h00000001, 1'b0, 1'b1, "error: en mismatch");
    test_no_addr_config(32'h00000000, 1'b1, 1'b1, "error: en=1 oh=0");
    
    $display("\n--- Testing Not Strict Configuration ---");
    
    // Valid cases
    test_not_strict_config(32'h00000001, 5'd0, 1'b1, 1'b0, "valid bit 0");
    test_not_strict_config(32'h00000000, 5'd0, 1'b0, 1'b0, "valid oh=0 en=0");
    
    // Not strict: allows oh=0 when en=1
    test_not_strict_config(32'h00000000, 5'd0, 1'b1, 1'b0, "ok: oh=0 en=1 not strict");
    
    // Error: oh=1 but en=0 is still error
    test_not_strict_config(32'h00000001, 5'd0, 1'b0, 1'b1, "error: oh=1 en=0");
    
    // Error: Multiple bits
    test_not_strict_config(32'h00000003, 5'd0, 1'b1, 1'b1, "error: 2 bits");
    
    // Error: Address mismatch
    test_not_strict_config(32'h00000001, 5'd1, 1'b1, 1'b1, "error: addr mismatch");
    
    $display("\n--- Testing Edge Cases ---");
    
    // Test all valid one-hot positions
    for (int i = 0; i < OneHotWidth; i++) begin
      test_full_config(make_onehot(i), i[AddrWidth-1:0], 1'b1, 1'b0, 
                      $sformatf("scan all bits %0d", i));
    end
    
    // Test adjacent bit errors
    for (int i = 0; i < OneHotWidth-1; i++) begin
      test_full_config(make_onehot(i) | make_onehot(i+1), i[AddrWidth-1:0], 1'b1, 1'b1,
                      $sformatf("adjacent bits %0d,%0d", i, i+1));
    end
    
    $display("\n--- Testing Special Patterns ---");
    
    // Alternating patterns
    test_full_config(32'hAAAAAAAA, 5'd1, 1'b1, 1'b1, "alternating pattern");
    test_full_config(32'h55555555, 5'd0, 1'b1, 1'b1, "alternating pattern");
    
    // Single bit at boundaries
    test_full_config(32'h00000001, 5'd0, 1'b1, 1'b0, "LSB");
    test_full_config(32'h80000000, 5'd31, 1'b1, 1'b0, "MSB");
    
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
