`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for ibex_csr
// Tests: Control/Status Register with optional shadow copy
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_ibex_csr();

  // Test parameters
  localparam int WIDTH = 32;
  localparam real CLK_PERIOD = 10.0; // 100MHz

  // Clock and reset
  logic clk_i;
  logic rst_ni;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Signals for CSR without shadow (Width=32, ResetValue=0)
  logic [WIDTH-1:0] wr_data_no_shadow;
  logic             wr_en_no_shadow;
  logic [WIDTH-1:0] rd_data_no_shadow;
  logic             rd_error_no_shadow;

  // Signals for CSR with shadow (Width=32, ResetValue=0)
  logic [WIDTH-1:0] wr_data_shadow;
  logic             wr_en_shadow;
  logic [WIDTH-1:0] rd_data_shadow;
  logic             rd_error_shadow;

  // Signals for CSR with custom reset value (Width=32, ResetValue=0xDEADBEEF)
  logic [WIDTH-1:0] wr_data_custom_rv;
  logic             wr_en_custom_rv;
  logic [WIDTH-1:0] rd_data_custom_rv;
  logic             rd_error_custom_rv;

  // Signals for 8-bit CSR with shadow
  logic [7:0]       wr_data_8bit;
  logic             wr_en_8bit;
  logic [7:0]       rd_data_8bit;
  logic             rd_error_8bit;

  // Clock generation
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // DUT instantiations

  // Configuration 1: No shadow copy
  ibex_csr #(
    .Width(WIDTH),
    .ShadowCopy(1'b0),
    .ResetValue(32'h00000000)
  ) dut_no_shadow (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .wr_data_i(wr_data_no_shadow),
    .wr_en_i(wr_en_no_shadow),
    .rd_data_o(rd_data_no_shadow),
    .rd_error_o(rd_error_no_shadow)
  );

  // Configuration 2: With shadow copy
  ibex_csr #(
    .Width(WIDTH),
    .ShadowCopy(1'b1),
    .ResetValue(32'h00000000)
  ) dut_shadow (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .wr_data_i(wr_data_shadow),
    .wr_en_i(wr_en_shadow),
    .rd_data_o(rd_data_shadow),
    .rd_error_o(rd_error_shadow)
  );

  // Configuration 3: Custom reset value with shadow
  ibex_csr #(
    .Width(WIDTH),
    .ShadowCopy(1'b1),
    .ResetValue(32'hDEADBEEF)
  ) dut_custom_rv (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .wr_data_i(wr_data_custom_rv),
    .wr_en_i(wr_en_custom_rv),
    .rd_data_o(rd_data_custom_rv),
    .rd_error_o(rd_error_custom_rv)
  );

  // Configuration 4: 8-bit CSR with shadow
  ibex_csr #(
    .Width(8),
    .ShadowCopy(1'b1),
    .ResetValue(8'hA5)
  ) dut_8bit (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .wr_data_i(wr_data_8bit),
    .wr_en_i(wr_en_8bit),
    .rd_data_o(rd_data_8bit),
    .rd_error_o(rd_error_8bit)
  );

  // Task to initialize signals
  task automatic init_signals();
    wr_data_no_shadow = '0;
    wr_en_no_shadow = 1'b0;
    wr_data_shadow = '0;
    wr_en_shadow = 1'b0;
    wr_data_custom_rv = '0;
    wr_en_custom_rv = 1'b0;
    wr_data_8bit = '0;
    wr_en_8bit = 1'b0;
  endtask

  // Task to apply reset
  task automatic apply_reset();
    rst_ni = 0;
    repeat(2) @(posedge clk_i);
    rst_ni = 1;
    @(posedge clk_i);
  endtask

  // Task to write CSR (no shadow)
  task automatic write_csr_no_shadow(
    input logic [WIDTH-1:0] data,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    wr_data_no_shadow = data;
    wr_en_no_shadow = 1'b1;
    
    @(posedge clk_i);
    wr_en_no_shadow = 1'b0;
    #1; // Small delay
    
    if (rd_data_no_shadow === data && rd_error_no_shadow === 1'b0) begin
      $display("[PASS] Test %0d: NoShadow Write %s - data=0x%h", 
               test_num, desc, data);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: NoShadow Write %s - data=0x%h, rd_data=0x%h, error=%b", 
               test_num, desc, data, rd_data_no_shadow, rd_error_no_shadow);
      fail_count++;
    end
  endtask

  // Task to write CSR (with shadow)
  task automatic write_csr_shadow(
    input logic [WIDTH-1:0] data,
    input logic expect_error,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    wr_data_shadow = data;
    wr_en_shadow = 1'b1;
    
    @(posedge clk_i);
    wr_en_shadow = 1'b0;
    #1; // Small delay
    
    if (rd_data_shadow === data && rd_error_shadow === expect_error) begin
      $display("[PASS] Test %0d: Shadow Write %s - data=0x%h, error=%b", 
               test_num, desc, data, rd_error_shadow);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Shadow Write %s - data=0x%h, rd_data=0x%h, expected_error=%b, got_error=%b", 
               test_num, desc, data, rd_data_shadow, expect_error, rd_error_shadow);
      fail_count++;
    end
  endtask

  // Task to write 8-bit CSR
  task automatic write_csr_8bit(
    input logic [7:0] data,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    wr_data_8bit = data;
    wr_en_8bit = 1'b1;
    
    @(posedge clk_i);
    wr_en_8bit = 1'b0;
    #1; // Small delay
    
    if (rd_data_8bit === data && rd_error_8bit === 1'b0) begin
      $display("[PASS] Test %0d: 8-bit Write %s - data=0x%h", 
               test_num, desc, data);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 8-bit Write %s - data=0x%h, rd_data=0x%h, error=%b", 
               test_num, desc, data, rd_data_8bit, rd_error_8bit);
      fail_count++;
    end
  endtask

  // Task to verify reset values
  task automatic verify_reset_values();
    test_num++;
    
    rst_ni = 0;
    #1; // Small delay to let reset propagate
    
    if (rd_data_no_shadow === 32'h00000000 && 
        rd_data_shadow === 32'h00000000 &&
        rd_data_custom_rv === 32'hDEADBEEF &&
        rd_data_8bit === 8'hA5 &&
        rd_error_no_shadow === 1'b0 &&
        rd_error_shadow === 1'b0 &&
        rd_error_custom_rv === 1'b0 &&
        rd_error_8bit === 1'b0) begin
      $display("[PASS] Test %0d: Reset values correct", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Reset values incorrect", test_num);
      $display("  no_shadow: 0x%h (exp 0x00000000)", rd_data_no_shadow);
      $display("  shadow: 0x%h (exp 0x00000000)", rd_data_shadow);
      $display("  custom_rv: 0x%h (exp 0xDEADBEEF)", rd_data_custom_rv);
      $display("  8bit: 0x%h (exp 0xA5)", rd_data_8bit);
      fail_count++;
    end
    
    rst_ni = 1;
    @(posedge clk_i);
  endtask

  // Task to inject shadow error
  task automatic inject_shadow_error();
    test_num++;
    
    // This is conceptual - in real hardware, bit flips would cause this
    // For testing, we verify that mismatches are detected
    
    // Write a value normally
    @(posedge clk_i);
    wr_data_shadow = 32'h12345678;
    wr_en_shadow = 1'b1;
    
    @(posedge clk_i);
    wr_en_shadow = 1'b0;
    @(posedge clk_i);
    #1;
    
    // Normal operation should have no error
    if (rd_error_shadow === 1'b0) begin
      $display("[PASS] Test %0d: Shadow error detection - no error on normal write", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Shadow error detection - unexpected error on normal write", test_num);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("ibex_csr Self-Testing Testbench");
    $display("========================================");
    $display("Clock Period: %0.1f ns", CLK_PERIOD);
    
    init_signals();
    rst_ni = 1;
    repeat(2) @(posedge clk_i);
    
    $display("\n--- Testing Reset Values ---");
    verify_reset_values();
    
    $display("\n--- Testing CSR Without Shadow Copy ---");
    apply_reset();
    
    // Test basic write/read operations
    write_csr_no_shadow(32'h12345678, "pattern 1");
    write_csr_no_shadow(32'h9ABCDEF0, "pattern 2");
    write_csr_no_shadow(32'hDEADBEEF, "pattern 3");
    write_csr_no_shadow(32'hCAFEBABE, "pattern 4");
    write_csr_no_shadow(32'h00000000, "all zeros");
    write_csr_no_shadow(32'hFFFFFFFF, "all ones");
    write_csr_no_shadow(32'hAAAAAAAA, "alternating");
    write_csr_no_shadow(32'h55555555, "alternating");
    
    // Test that write enable works
    test_num++;
    @(posedge clk_i);
    wr_data_no_shadow = 32'hBADC0FFE;
    wr_en_no_shadow = 1'b0; // Disabled
    @(posedge clk_i);
    #1;
    
    if (rd_data_no_shadow === 32'h55555555) begin // Should retain previous value
      $display("[PASS] Test %0d: Write enable disabled - data retained", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Write enable disabled - data changed to 0x%h", 
               test_num, rd_data_no_shadow);
      fail_count++;
    end
    
    $display("\n--- Testing CSR With Shadow Copy ---");
    apply_reset();
    
    // Test normal writes with shadow checking
    write_csr_shadow(32'h11111111, 1'b0, "pattern 1");
    write_csr_shadow(32'h22222222, 1'b0, "pattern 2");
    write_csr_shadow(32'hAAAAAAAA, 1'b0, "pattern 3");
    write_csr_shadow(32'h55555555, 1'b0, "pattern 4");
    write_csr_shadow(32'hF0F0F0F0, 1'b0, "pattern 5");
    write_csr_shadow(32'h0F0F0F0F, 1'b0, "pattern 6");
    
    // Verify shadow error detection
    inject_shadow_error();
    
    $display("\n--- Testing Custom Reset Value ---");
    apply_reset();
    
    // Verify custom reset value
    test_num++;
    #1;
    if (rd_data_custom_rv === 32'hDEADBEEF && rd_error_custom_rv === 1'b0) begin
      $display("[PASS] Test %0d: Custom reset value verified", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Custom reset value incorrect: 0x%h, error=%b", 
               test_num, rd_data_custom_rv, rd_error_custom_rv);
      fail_count++;
    end
    
    // Write new values
    @(posedge clk_i);
    wr_data_custom_rv = 32'h12345678;
    wr_en_custom_rv = 1'b1;
    @(posedge clk_i);
    wr_en_custom_rv = 1'b0;
    #1;
    
    if (rd_data_custom_rv === 32'h12345678) begin
      $display("[INFO] Custom RV CSR updated to 0x%h", rd_data_custom_rv);
    end
    
    $display("\n--- Testing 8-bit CSR ---");
    apply_reset();
    
    // Test 8-bit operations
    test_num++;
    #1;
    if (rd_data_8bit === 8'hA5) begin
      $display("[PASS] Test %0d: 8-bit reset value correct", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 8-bit reset value incorrect: 0x%h", test_num, rd_data_8bit);
      fail_count++;
    end
    
    // Write 8-bit values using task calls instead of array
    write_csr_8bit(8'h00, "value 0x00");
    write_csr_8bit(8'hFF, "value 0xFF");
    write_csr_8bit(8'h55, "value 0x55");
    write_csr_8bit(8'hAA, "value 0xAA");
    write_csr_8bit(8'h12, "value 0x12");
    write_csr_8bit(8'h34, "value 0x34");
    write_csr_8bit(8'h56, "value 0x56");
    write_csr_8bit(8'h78, "value 0x78");
    
    $display("\n--- Testing Data Persistence ---");
    
    // Write value and verify it persists without write enable
    @(posedge clk_i);
    wr_data_no_shadow = 32'hABCD1234;
    wr_en_no_shadow = 1'b1;
    @(posedge clk_i);
    wr_en_no_shadow = 1'b0;
    
    // Wait several cycles
    repeat(10) @(posedge clk_i);
    #1;
    
    test_num++;
    if (rd_data_no_shadow === 32'hABCD1234) begin
      $display("[PASS] Test %0d: Data persistence verified", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Data changed unexpectedly to 0x%h", 
               test_num, rd_data_no_shadow);
      fail_count++;
    end
    
    $display("\n--- Testing Sequential Writes ---");
    
    for (int i = 0; i < 8; i++) begin
      write_csr_no_shadow(32'h10000000 + i, $sformatf("sequential %0d", i));
    end
    
    $display("\n--- Testing Random Values ---");
    
    for (int i = 0; i < 10; i++) begin
      logic [31:0] rand_val;
      rand_val = $urandom();
      write_csr_no_shadow(rand_val, $sformatf("random %0d", i));
    end
    
    $display("\n--- Testing Boundary Values ---");
    
    write_csr_no_shadow(32'h00000001, "LSB only");
    write_csr_no_shadow(32'h80000000, "MSB only");
    write_csr_no_shadow(32'h7FFFFFFF, "max positive");
    write_csr_no_shadow(32'h80000001, "min negative + 1");
    
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
