`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-Testing Testbench for ibex_counter
// Tests: 64-bit performance counter with configurable width
// Compatible with Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

module tb_ibex_counter();

  // Test parameters
  localparam real CLK_PERIOD = 10.0; // 100MHz

  // Clock and reset
  logic clk_i;
  logic rst_ni;

  // Test tracking
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  // Signals for 32-bit counter with value update
  logic        counter_inc_32;
  logic        counterh_we_32;
  logic        counter_we_32;
  logic [31:0] counter_val_i_32;
  logic [63:0] counter_val_o_32;
  logic [63:0] counter_val_upd_o_32;

  // Signals for 64-bit counter without value update
  logic        counter_inc_64;
  logic        counterh_we_64;
  logic        counter_we_64;
  logic [31:0] counter_val_i_64;
  logic [63:0] counter_val_o_64;
  logic [63:0] counter_val_upd_o_64;

  // Signals for 48-bit counter (DSP width)
  logic        counter_inc_48;
  logic        counterh_we_48;
  logic        counter_we_48;
  logic [31:0] counter_val_i_48;
  logic [63:0] counter_val_o_48;
  logic [63:0] counter_val_upd_o_48;

  // Clock generation
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // DUT instantiations

  // Configuration 1: 32-bit counter with value update
  ibex_counter #(
    .CounterWidth(32),
    .ProvideValUpd(1)
  ) dut_32 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .counter_inc_i(counter_inc_32),
    .counterh_we_i(counterh_we_32),
    .counter_we_i(counter_we_32),
    .counter_val_i(counter_val_i_32),
    .counter_val_o(counter_val_o_32),
    .counter_val_upd_o(counter_val_upd_o_32)
  );

  // Configuration 2: 64-bit counter without value update
  ibex_counter #(
    .CounterWidth(64),
    .ProvideValUpd(0)
  ) dut_64 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .counter_inc_i(counter_inc_64),
    .counterh_we_i(counterh_we_64),
    .counter_we_i(counter_we_64),
    .counter_val_i(counter_val_i_64),
    .counter_val_o(counter_val_o_64),
    .counter_val_upd_o(counter_val_upd_o_64)
  );

  // Configuration 3: 48-bit counter (DSP-optimized width)
  ibex_counter #(
    .CounterWidth(48),
    .ProvideValUpd(0)
  ) dut_48 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .counter_inc_i(counter_inc_48),
    .counterh_we_i(counterh_we_48),
    .counter_we_i(counter_we_48),
    .counter_val_i(counter_val_i_48),
    .counter_val_o(counter_val_o_48),
    .counter_val_upd_o(counter_val_upd_o_48)
  );

  // Task to initialize signals
  task automatic init_signals();
    counter_inc_32 = 0;
    counterh_we_32 = 0;
    counter_we_32 = 0;
    counter_val_i_32 = 0;
    
    counter_inc_64 = 0;
    counterh_we_64 = 0;
    counter_we_64 = 0;
    counter_val_i_64 = 0;
    
    counter_inc_48 = 0;
    counterh_we_48 = 0;
    counter_we_48 = 0;
    counter_val_i_48 = 0;
  endtask

  // Task to apply reset
  task automatic apply_reset();
    rst_ni = 0;
    repeat(2) @(posedge clk_i);
    rst_ni = 1;
    @(posedge clk_i);
  endtask

  // Task to write lower 32 bits of counter
  task automatic write_counter_low(
    input logic [31:0] value,
    input string desc
  );
    test_num++;
    
    @(posedge clk_i);
    counter_we_32 = 1;
    counter_val_i_32 = value;
    
    @(posedge clk_i);
    counter_we_32 = 0;
    #1;
    
    if (counter_val_o_32[31:0] === value) begin
      $display("[PASS] Test %0d: Write Low %s - value=0x%h", test_num, desc, value);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Write Low %s - value=0x%h, got=0x%h", 
               test_num, desc, value, counter_val_o_32[31:0]);
      fail_count++;
    end
  endtask

  // Task to increment counter and verify (32-bit)
  task automatic test_increment_32(
    input int num_increments,
    input logic [31:0] start_value,
    input string desc
  );
    logic [31:0] expected_value;
    test_num++;
    
    // Set starting value
    @(posedge clk_i);
    counter_we_32 = 1;
    counter_val_i_32 = start_value;
    @(posedge clk_i);
    counter_we_32 = 0;
    
    // Increment
    counter_inc_32 = 1;
    repeat(num_increments) @(posedge clk_i);
    counter_inc_32 = 0;
    @(posedge clk_i);
    #1;
    
    expected_value = start_value + num_increments;
    
    if (counter_val_o_32[31:0] === expected_value) begin
      $display("[PASS] Test %0d: Increment %s - start=0x%h, increments=%0d, result=0x%h", 
               test_num, desc, start_value, num_increments, counter_val_o_32[31:0]);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Increment %s - start=0x%h, increments=%0d, expected=0x%h, got=0x%h", 
               test_num, desc, start_value, num_increments, expected_value, counter_val_o_32[31:0]);
      fail_count++;
    end
  endtask

  // Task to increment counter and verify (64-bit)
  task automatic test_increment_64(
    input int num_increments,
    input logic [63:0] start_value,
    input string desc
  );
    logic [63:0] expected_value;
    test_num++;
    
    // Set starting value
    @(posedge clk_i);
    counter_we_64 = 1;
    counter_val_i_64 = start_value[31:0];
    @(posedge clk_i);
    counter_we_64 = 0;
    counterh_we_64 = 1;
    counter_val_i_64 = start_value[63:32];
    @(posedge clk_i);
    counterh_we_64 = 0;
    
    // Increment
    counter_inc_64 = 1;
    repeat(num_increments) @(posedge clk_i);
    counter_inc_64 = 0;
    @(posedge clk_i);
    #1;
    
    expected_value = start_value + num_increments;
    
    if (counter_val_o_64 === expected_value) begin
      $display("[PASS] Test %0d: Increment %s - start=0x%h, increments=%0d, result=0x%h", 
               test_num, desc, start_value, num_increments, counter_val_o_64);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Increment %s - start=0x%h, increments=%0d, expected=0x%h, got=0x%h", 
               test_num, desc, start_value, num_increments, expected_value, counter_val_o_64);
      fail_count++;
    end
  endtask

  // Task to verify counter update output
  task automatic verify_counter_upd_output();
    test_num++;
    
    // Set counter value
    @(posedge clk_i);
    counter_we_32 = 1;
    counter_val_i_32 = 32'h12345678;
    @(posedge clk_i);
    counter_we_32 = 0;
    #1;
    
    // Check that counter_val_upd_o shows incremented value
    if (counter_val_upd_o_32[31:0] === 32'h12345679) begin
      $display("[PASS] Test %0d: Counter update output shows incremented value", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Counter update output incorrect: 0x%h (expected 0x12345679)", 
               test_num, counter_val_upd_o_32[31:0]);
      fail_count++;
    end
  endtask

  // Main test sequence
  initial begin
    $display("========================================");
    $display("ibex_counter Self-Testing Testbench");
    $display("========================================");
    $display("Clock Period: %0.1f ns", CLK_PERIOD);
    
    init_signals();
    rst_ni = 1;
    repeat(2) @(posedge clk_i);
    
    $display("\n--- Testing Reset ---");
    
    apply_reset();
    test_num++;
    #1;
    if (counter_val_o_32 === 64'h0 && counter_val_o_64 === 64'h0 && counter_val_o_48 === 64'h0) begin
      $display("[PASS] Test %0d: Reset values all zero", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Reset values incorrect", test_num);
      fail_count++;
    end
    
    $display("\n--- Testing Write Operations (32-bit Counter) ---");
    
    write_counter_low(32'h12345678, "pattern 1");
    write_counter_low(32'hDEADBEEF, "pattern 2");
    write_counter_low(32'hCAFEBABE, "pattern 3");
    write_counter_low(32'h00000000, "zeros");
    write_counter_low(32'hFFFFFFFF, "all ones");
    
    // Note: For 32-bit counter, upper 32 bits are always zero
    test_num++;
    if (counter_val_o_32[63:32] === 32'h00000000) begin
      $display("[PASS] Test %0d: 32-bit counter upper bits are zero", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 32-bit counter upper bits should be zero, got 0x%h", 
               test_num, counter_val_o_32[63:32]);
      fail_count++;
    end
    
    $display("\n--- Testing Counter Increment (32-bit) ---");
    
    test_increment_32(1, 32'h00000000, "increment from 0");
    test_increment_32(10, 32'h00000000, "increment 10 times");
    test_increment_32(100, 32'h00000100, "increment 100 times");
    test_increment_32(1, 32'hFFFFFFFE, "near 32-bit max");
    test_increment_32(2, 32'hFFFFFFFE, "32-bit overflow wraps to 0");
    
    $display("\n--- Testing Counter Update Output ---");
    
    verify_counter_upd_output();
    
    $display("\n--- Testing 64-bit Counter ---");
    
    // Write 64-bit counter
    test_num++;
    @(posedge clk_i);
    counter_we_64 = 1;
    counter_val_i_64 = 32'h11111111;
    @(posedge clk_i);
    counter_we_64 = 0;
    counterh_we_64 = 1;
    counter_val_i_64 = 32'h22222222;
    @(posedge clk_i);
    counterh_we_64 = 0;
    #1;
    
    if (counter_val_o_64 === 64'h2222222211111111) begin
      $display("[PASS] Test %0d: 64-bit counter write", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 64-bit counter write - got 0x%h", test_num, counter_val_o_64);
      fail_count++;
    end
    
    // Increment 64-bit counter
    test_num++;
    counter_inc_64 = 1;
    repeat(10) @(posedge clk_i);
    counter_inc_64 = 0;
    @(posedge clk_i);
    #1;
    
    if (counter_val_o_64 === 64'h222222221111111B) begin
      $display("[PASS] Test %0d: 64-bit counter increment", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 64-bit counter increment - got 0x%h", test_num, counter_val_o_64);
      fail_count++;
    end
    
    // Test 64-bit overflow at 32-bit boundary
    test_increment_64(1, 64'h00000000FFFFFFFF, "64-bit overflow 32-bit boundary");
    
    // Test near 64-bit max
    test_increment_64(5, 64'hFFFFFFFFFFFFFFFA, "64-bit near max");
    
    // Verify counter_val_upd_o is zero (ProvideValUpd=0)
    test_num++;
    if (counter_val_upd_o_64 === 64'h0) begin
      $display("[PASS] Test %0d: 64-bit counter update output disabled", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 64-bit counter update output should be 0, got 0x%h", 
               test_num, counter_val_upd_o_64);
      fail_count++;
    end
    
    $display("\n--- Testing 48-bit Counter (DSP Width) ---");
    
    test_num++;
    @(posedge clk_i);
    counter_we_48 = 1;
    counter_val_i_48 = 32'hFFFFFFFF;
    @(posedge clk_i);
    counter_we_48 = 0;
    counterh_we_48 = 1;
    counter_val_i_48 = 32'hFFFF;
    @(posedge clk_i);
    counterh_we_48 = 0;
    #1;
    
    // Check that only lower 48 bits are used
    if (counter_val_o_48[47:0] === 48'hFFFFFFFFFFFF && counter_val_o_48[63:48] === 16'h0) begin
      $display("[PASS] Test %0d: 48-bit counter write (upper bits zero)", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: 48-bit counter write - got 0x%h", test_num, counter_val_o_48);
      fail_count++;
    end
    
    $display("\n--- Testing Continuous Counting ---");
    
    // Long continuous count
    apply_reset();
    counter_inc_32 = 1;
    repeat(1000) @(posedge clk_i);
    counter_inc_32 = 0;
    @(posedge clk_i);
    #1;
    
    test_num++;
    if (counter_val_o_32[31:0] === 32'h000003E8) begin // 1000 in hex
      $display("[PASS] Test %0d: Continuous counting 1000 cycles", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Continuous counting - expected 0x3E8, got 0x%h", 
               test_num, counter_val_o_32[31:0]);
      fail_count++;
    end
    
    $display("\n--- Testing Write During Increment ---");
    
    // Start incrementing
    counter_inc_32 = 1;
    repeat(5) @(posedge clk_i);
    
    // Write should override increment
    counter_we_32 = 1;
    counter_val_i_32 = 32'hABCDABCD;
    @(posedge clk_i);
    counter_we_32 = 0;
    counter_inc_32 = 0;
    @(posedge clk_i);
    #1;
    
    test_num++;
    if (counter_val_o_32[31:0] === 32'hABCDABCD) begin
      $display("[PASS] Test %0d: Write overrides increment", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Write override failed - got 0x%h", 
               test_num, counter_val_o_32[31:0]);
      fail_count++;
    end
    
    $display("\n--- Testing Hold Value (No Increment) ---");
    
    @(posedge clk_i);
    counter_we_32 = 1;
    counter_val_i_32 = 32'h5A5A5A5A;
    @(posedge clk_i);
    counter_we_32 = 0;
    
    // Wait without incrementing
    repeat(10) @(posedge clk_i);
    #1;
    
    test_num++;
    if (counter_val_o_32[31:0] === 32'h5A5A5A5A) begin
      $display("[PASS] Test %0d: Counter holds value without increment", test_num);
      pass_count++;
    end else begin
      $display("[FAIL] Test %0d: Counter changed without increment - got 0x%h", 
               test_num, counter_val_o_32[31:0]);
      fail_count++;
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
    #200000;
    $display("\n[ERROR] Simulation timeout!");
    $finish;
  end

endmodule
