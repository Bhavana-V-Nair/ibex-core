`timescale 1ns / 1ps

module tb_prim_secded_inv_39_32_enc;

    // Testbench signals
    logic [31:0] data_i;
    logic [38:0] data_o;
    
    // Expected output for verification
    logic [38:0] expected_data_o;
    
    // Test statistics
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Instantiate DUT (Device Under Test)
    prim_secded_inv_39_32_enc dut (
        .data_i(data_i),
        .data_o(data_o)
    );
    
    // Function to calculate expected output (golden reference model)
    function automatic logic [38:0] calc_expected_output(input logic [31:0] data_in);
        logic [38:0] temp;
        
        // Step 1: Assign input data to lower 32 bits
        temp = 39'(data_in);
        
        // Step 2: Calculate parity bits using XOR reduction
        temp[32] = ^(temp & 39'h002606BD25);
        temp[33] = ^(temp & 39'h00DEBA8050);
        temp[34] = ^(temp & 39'h00413D89AA);
        temp[35] = ^(temp & 39'h0031234ED1);
        temp[36] = ^(temp & 39'h00C2C1323B);
        temp[37] = ^(temp & 39'h002DCC624C);
        temp[38] = ^(temp & 39'h0098505586);
        
        // Step 3: Apply inversion mask
        temp = temp ^ 39'h2A00000000;
        
        return temp;
    endfunction
    
    // Task to run a single test case
    task automatic run_test(input logic [31:0] test_data, input string test_name);
        test_count++;
        data_i = test_data;
        #10; // Wait for combinational logic to settle
        
        expected_data_o = calc_expected_output(test_data);
        
        if (data_o === expected_data_o) begin
            pass_count++;
            $display("[PASS] Test %4d: %-35s | Input=0x%08h | Output=0x%010h", 
                     test_count, test_name, data_i, data_o);
        end else begin
            fail_count++;
            $display("[FAIL] Test %4d: %-35s | Input=0x%08h | Expected=0x%010h | Got=0x%010h", 
                     test_count, test_name, data_i, expected_data_o, data_o);
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n========================================================================");
        $display("  SECDED Inverted (39,32) Encoder Testbench for IBEX ICache");
        $display("========================================================================\n");
        
        // =====================================================================
        // Test Category 1: Corner Cases
        // =====================================================================
        $display("--- Category 1: Corner Cases ---");
        run_test(32'h00000000, "All Zeros");
        run_test(32'hFFFFFFFF, "All Ones");
        run_test(32'h80000000, "MSB Only");
        run_test(32'h00000001, "LSB Only");
        run_test(32'h7FFFFFFF, "All Bits Except MSB");
        run_test(32'hFFFFFFFE, "All Bits Except LSB");
        
        // =====================================================================
        // Test Category 2: Alternating Patterns
        // =====================================================================
        $display("\n--- Category 2: Alternating Patterns ---");
        run_test(32'hAAAAAAAA, "Alternating 10101010");
        run_test(32'h55555555, "Alternating 01010101");
        run_test(32'hCCCCCCCC, "Alternating 11001100");
        run_test(32'h33333333, "Alternating 00110011");
        run_test(32'hF0F0F0F0, "Alternating 11110000");
        run_test(32'h0F0F0F0F, "Alternating 00001111");
        
        // =====================================================================
        // Test Category 3: Single Bit Tests (Walking Ones)
        // =====================================================================
        $display("\n--- Category 3: Single Bit Tests ---");
        for (int i = 0; i < 32; i++) begin
            run_test(32'(1 << i), $sformatf("Single Bit [%2d]", i));
        end
        
        // =====================================================================
        // Test Category 4: Walking Ones Patterns
        // =====================================================================
        $display("\n--- Category 4: Walking Ones Patterns ---");
        run_test(32'h00000001, "Walking Ones - 1 bit");
        run_test(32'h00000003, "Walking Ones - 2 bits");
        run_test(32'h00000007, "Walking Ones - 3 bits");
        run_test(32'h0000000F, "Walking Ones - 4 bits");
        run_test(32'h0000001F, "Walking Ones - 5 bits");
        run_test(32'h0000003F, "Walking Ones - 6 bits");
        run_test(32'h0000007F, "Walking Ones - 7 bits");
        run_test(32'h000000FF, "Walking Ones - 8 bits");
        
        // =====================================================================
        // Test Category 5: Walking Zeros Patterns
        // =====================================================================
        $display("\n--- Category 5: Walking Zeros Patterns ---");
        run_test(32'hFFFFFFFE, "Walking Zeros - 1 bit");
        run_test(32'hFFFFFFFC, "Walking Zeros - 2 bits");
        run_test(32'hFFFFFFF8, "Walking Zeros - 3 bits");
        run_test(32'hFFFFFFF0, "Walking Zeros - 4 bits");
        run_test(32'hFFFFFFE0, "Walking Zeros - 5 bits");
        run_test(32'hFFFFFFC0, "Walking Zeros - 6 bits");
        run_test(32'hFFFFFF80, "Walking Zeros - 7 bits");
        run_test(32'hFFFFFF00, "Walking Zeros - 8 bits");
        
        // =====================================================================
        // Test Category 6: Byte-aligned Patterns
        // =====================================================================
        $display("\n--- Category 6: Byte-Aligned Patterns ---");
        run_test(32'h000000FF, "Byte 0 Only");
        run_test(32'h0000FF00, "Byte 1 Only");
        run_test(32'h00FF0000, "Byte 2 Only");
        run_test(32'hFF000000, "Byte 3 Only");
        run_test(32'h00FF00FF, "Bytes 0 and 2");
        run_test(32'hFF00FF00, "Bytes 1 and 3");
        
        // =====================================================================
        // Test Category 7: Nibble Patterns
        // =====================================================================
        $display("\n--- Category 7: Nibble Patterns ---");
        run_test(32'h0000000F, "Nibble 0");
        run_test(32'h000000F0, "Nibble 1");
        run_test(32'h00000F00, "Nibble 2");
        run_test(32'h0000F000, "Nibble 3");
        run_test(32'h000F0000, "Nibble 4");
        run_test(32'h00F00000, "Nibble 5");
        run_test(32'h0F000000, "Nibble 6");
        run_test(32'hF0000000, "Nibble 7");
        
        // =====================================================================
        // Test Category 8: Parity-Specific Patterns
        // =====================================================================
        $display("\n--- Category 8: Parity-Specific Patterns ---");
        run_test(32'h2606BD25, "Parity Mask 0 (bits 32)");
        run_test(32'hDEBA8050, "Parity Mask 1 (bits 33)");
        run_test(32'h413D89AA, "Parity Mask 2 (bits 34)");
        run_test(32'h31234ED1, "Parity Mask 3 (bits 35)");
        run_test(32'hC2C1323B, "Parity Mask 4 (bits 36)");
        run_test(32'h2DCC624C, "Parity Mask 5 (bits 37)");
        run_test(32'h98505586, "Parity Mask 6 (bits 38)");
        
        // =====================================================================
        // Test Category 9: Sequential Values
        // =====================================================================
        $display("\n--- Category 9: Sequential Values ---");
        for (int i = 0; i < 16; i++) begin
            run_test(32'(i), $sformatf("Sequential Value %0d", i));
        end
        
        // =====================================================================
        // Test Category 10: Common Instruction Patterns (RISC-V)
        // =====================================================================
        $display("\n--- Category 10: Common Instruction Patterns ---");
        run_test(32'h00000013, "NOP Instruction (ADDI x0,x0,0)");
        run_test(32'h00000093, "LI x1, 0");
        run_test(32'hFE010113, "ADDI sp,sp,-32");
        run_test(32'h00112623, "SW ra,12(sp)");
        run_test(32'h00C12083, "LW ra,12(sp)");
        run_test(32'h02010113, "ADDI sp,sp,32");
        run_test(32'h00008067, "RET (JALR x0,0(x1))");
        run_test(32'h0FF0000F, "FENCE");
        
        // =====================================================================
        // Test Category 11: Powers of Two
        // =====================================================================
        $display("\n--- Category 11: Powers of Two ---");
        run_test(32'h00000001, "2^0");
        run_test(32'h00000002, "2^1");
        run_test(32'h00000004, "2^2");
        run_test(32'h00000008, "2^3");
        run_test(32'h00000010, "2^4");
        run_test(32'h00000100, "2^8");
        run_test(32'h00001000, "2^12");
        run_test(32'h00010000, "2^16");
        run_test(32'h01000000, "2^24");
        
        // =====================================================================
        // Test Category 12: Random Patterns
        // =====================================================================
        $display("\n--- Category 12: Random Patterns ---");
        run_test(32'h12345678, "Random Pattern 1");
        run_test(32'h9ABCDEF0, "Random Pattern 2");
        run_test(32'hDEADBEEF, "Random Pattern 3");
        run_test(32'hCAFEBABE, "Random Pattern 4");
        run_test(32'hFEEDFACE, "Random Pattern 5");
        run_test(32'h0BADC0DE, "Random Pattern 6");
        run_test(32'hC0FFEE00, "Random Pattern 7");
        run_test(32'hBAAAAAAD, "Random Pattern 8");
        
        // =====================================================================
        // Test Category 13: Comprehensive Random Tests
        // =====================================================================
        $display("\n--- Category 13: Comprehensive Random Tests ---");
        repeat(50) begin
            automatic logic [31:0] random_data = $random;
            run_test(random_data, $sformatf("Random 0x%08h", random_data));
        end
        
        // =====================================================================
        // Test Category 14: Edge Cases with Specific Bit Patterns
        // =====================================================================
        $display("\n--- Category 14: Edge Cases ---");
        run_test(32'hFFFF0000, "Upper Half Ones");
        run_test(32'h0000FFFF, "Lower Half Ones");
        run_test(32'hFF00FF00, "Even Bytes");
        run_test(32'h00FF00FF, "Odd Bytes");
        run_test(32'h80008000, "Upper Bits of Each Half");
        run_test(32'h00010001, "Lower Bits of Each Half");
        
        // =====================================================================
        // Display Final Results
        // =====================================================================
        $display("\n========================================================================");
        $display("  Test Summary");
        $display("========================================================================");
        $display("  Total Tests:    %4d", test_count);
        $display("  Passed:         %4d", pass_count);
        $display("  Failed:         %4d", fail_count);
        $display("  Pass Rate:      %6.2f%%", (pass_count * 100.0) / test_count);
        $display("========================================================================\n");
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED SUCCESSFULLY ***\n");
        end else begin
            $display("*** %0d TEST(S) FAILED ***\n", fail_count);
        end
        
        $finish;
    end

endmodule
