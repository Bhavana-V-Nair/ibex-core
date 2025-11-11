`timescale 1ns / 1ps

module tb_prim_secded_inv_28_22_enc;

    // Testbench signals
    logic [21:0] data_i;
    logic [27:0] data_o;
    
    // Expected output for verification
    logic [27:0] expected_data_o;
    
    // Test statistics
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Instantiate DUT
    prim_secded_inv_28_22_enc dut (
        .data_i(data_i),
        .data_o(data_o)
    );
    
    // Function to calculate expected output
    function logic [27:0] calc_expected_output(input logic [21:0] data_in);
        logic [27:0] temp;
        temp = 28'(data_in);
        
        // Calculate parity bits
        temp[22] = ^(temp & 28'h03003FF);
        temp[23] = ^(temp & 28'h010FC0F);
        temp[24] = ^(temp & 28'h0271C71);
        temp[25] = ^(temp & 28'h03B6592);
        temp[26] = ^(temp & 28'h03DAAA4);
        temp[27] = ^(temp & 28'h03ED348);
        
        // Apply inversion
        temp = temp ^ 28'hA800000;
        
        return temp;
    endfunction
    
    // Task to run a single test
    task run_test(input logic [21:0] test_data, input string test_name);
        test_count++;
        data_i = test_data;
        #10; // Wait for combinational logic
        
        expected_data_o = calc_expected_output(test_data);
        
        if (data_o === expected_data_o) begin
            pass_count++;
            $display("[PASS] Test %0d: %s | Input=0x%0h | Output=0x%0h", 
                     test_count, test_name, data_i, data_o);
        end else begin
            fail_count++;
            $display("[FAIL] Test %0d: %s | Input=0x%0h | Expected=0x%0h | Got=0x%0h", 
                     test_count, test_name, data_i, expected_data_o, data_o);
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("========================================");
        $display("SECDED Inverted (28,22) Encoder Testbench");
        $display("========================================\n");
        
        // Test 1: All zeros
        run_test(22'h000000, "All Zeros");
        
        // Test 2: All ones
        run_test(22'h3FFFFF, "All Ones");
        
        // Test 3: Alternating pattern 1
        run_test(22'h2AAAAA, "Alternating 10");
        
        // Test 4: Alternating pattern 2
        run_test(22'h155555, "Alternating 01");
        
        // Test 5: Single bit set tests
        for (int i = 0; i < 22; i++) begin
            run_test(22'(1 << i), $sformatf("Single Bit [%0d]", i));
        end
        
        // Test 6: Walking ones
        run_test(22'h000001, "Walking Ones - Bit 0");
        run_test(22'h000003, "Walking Ones - Bits 0-1");
        run_test(22'h000007, "Walking Ones - Bits 0-2");
        run_test(22'h00000F, "Walking Ones - Bits 0-3");
        
        // Test 7: Walking zeros
        run_test(22'h3FFFFE, "Walking Zeros - Bit 0");
        run_test(22'h3FFFFC, "Walking Zeros - Bits 0-1");
        run_test(22'h3FFFF8, "Walking Zeros - Bits 0-2");
        run_test(22'h3FFFF0, "Walking Zeros - Bits 0-3");
        
        // Test 8: Random patterns
        run_test(22'h123456, "Random Pattern 1");
        run_test(22'h3EDCBA, "Random Pattern 2");
        run_test(22'h0F0F0F, "Random Pattern 3");
        run_test(22'h30C30C, "Random Pattern 4");
        run_test(22'h1A2B3C, "Random Pattern 5");
        
        // Test 9: Boundary values
        run_test(22'h200000, "MSB Only");
        run_test(22'h1FFFFF, "All Bits Except MSB");
        run_test(22'h000001, "LSB Only");
        run_test(22'h3FFFFE, "All Bits Except LSB");
        
        // Test 10: Sequential patterns
        for (int i = 0; i < 10; i++) begin
            run_test(22'(i), $sformatf("Sequential %0d", i));
        end
        
        // Test 11: Parity-specific patterns
        run_test(22'h003FF, "Parity Region 0");
        run_test(22'h0FC0F, "Parity Region 1");
        run_test(22'h71C71, "Parity Region 2");
        run_test(22'hB6592, "Parity Region 3");
        run_test(22'hDAAA4, "Parity Region 4");
        run_test(22'hED348, "Parity Region 5");
        
        // Test 12: Comprehensive random tests
        repeat(100) begin
            automatic logic [21:0] random_data = $random;
            run_test(random_data, "Random Comprehensive");
        end
        
        // Display final results
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("Pass Rate:   %.2f%%", (pass_count * 100.0) / test_count);
        $display("========================================\n");
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TEST(S) FAILED ***", fail_count);
        end
        
        $finish;
    end

endmodule
