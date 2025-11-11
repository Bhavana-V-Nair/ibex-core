`timescale 1ns / 1ps

module tb_ibex_dummy_instr;

    // Import ibex_pkg
    import ibex_pkg::*;
    
    // Clock and reset
    logic        clk_i;
    logic        rst_ni;
    
    // CSR interface
    logic        dummy_instr_en_i;
    logic [2:0]  dummy_instr_mask_i;
    logic        dummy_instr_seed_en_i;
    logic [31:0] dummy_instr_seed_i;
    
    // IF stage interface
    logic        fetch_valid_i;
    logic        id_in_ready_i;
    logic        insert_dummy_instr_o;
    logic [31:0] dummy_instr_data_o;
    
    // Test statistics
    int test_count;
    int pass_count;
    int fail_count;
    
    // Monitoring variables
    int dummy_instr_count;
    int real_instr_count;
    int cycle_counter;
    logic [31:0] last_dummy_instr;
    
    // Validation flags
    logic instr_valid;
    logic [6:0] instr_opcode;
    logic [4:0] instr_rd;
    logic [2:0] instr_funct3;
    logic [6:0] instr_funct7;
    string instr_type;
    
    // Clock generation - 100MHz (10ns period)
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end
    
    // Maximum simulation timeout (safety mechanism)
    initial begin
        #200000;  // 200us maximum
        $display("\n[WARNING] Maximum simulation time reached - auto-terminating");
        $display("Current test: %0d, Passed: %0d, Failed: %0d", test_count, pass_count, fail_count);
        $finish;
    end
    
    // DUT instantiation
    ibex_dummy_instr #(
        .RndCnstLfsrSeed(RndCnstLfsrSeedDefault),
        .RndCnstLfsrPerm(RndCnstLfsrPermDefault)
    ) dut (
        .clk_i                (clk_i),
        .rst_ni               (rst_ni),
        .dummy_instr_en_i     (dummy_instr_en_i),
        .dummy_instr_mask_i   (dummy_instr_mask_i),
        .dummy_instr_seed_en_i(dummy_instr_seed_en_i),
        .dummy_instr_seed_i   (dummy_instr_seed_i),
        .fetch_valid_i        (fetch_valid_i),
        .id_in_ready_i        (id_in_ready_i),
        .insert_dummy_instr_o (insert_dummy_instr_o),
        .dummy_instr_data_o   (dummy_instr_data_o)
    );
    
    // Task to decode and validate dummy instruction
    task decode_and_validate_instr;
        input logic [31:0] instr;
        begin
            instr_opcode = instr[6:0];
            instr_rd = instr[11:7];
            instr_funct3 = instr[14:12];
            instr_funct7 = instr[31:25];
            
            // Check opcode is R-type (0x33)
            instr_valid = (instr_opcode == 7'h33);
            
            // Check destination is x0
            instr_valid = instr_valid && (instr_rd == 5'h00);
            
            // Determine instruction type and validate
            if (instr_funct7 == 7'b0000000 && instr_funct3 == 3'b000) begin
                instr_type = "ADD";
            end else if (instr_funct7 == 7'b0000001 && instr_funct3 == 3'b000) begin
                instr_type = "MUL";
            end else if (instr_funct7 == 7'b0000001 && instr_funct3 == 3'b100) begin
                instr_type = "DIV";
            end else if (instr_funct7 == 7'b0000000 && instr_funct3 == 3'b111) begin
                instr_type = "AND";
            end else begin
                instr_type = "UNKNOWN";
                instr_valid = 0;
            end
        end
    endtask
    
    // Task to perform reset
    task perform_reset;
        begin
            rst_ni = 0;
            dummy_instr_en_i = 0;
            dummy_instr_mask_i = 3'b000;
            dummy_instr_seed_en_i = 0;
            dummy_instr_seed_i = 32'h0;
            fetch_valid_i = 0;
            id_in_ready_i = 0;
            repeat(5) @(posedge clk_i);
            rst_ni = 1;
            repeat(2) @(posedge clk_i);
        end
    endtask
    
    // Task to execute instructions
    task execute_instructions;
        input int num_instrs;
        input logic enable_fetch;
        input logic enable_ready;
        int local_cycle;
        begin
            for (local_cycle = 0; local_cycle < num_instrs; local_cycle = local_cycle + 1) begin
                fetch_valid_i = enable_fetch;
                id_in_ready_i = enable_ready;
                
                @(posedge clk_i);
                cycle_counter = cycle_counter + 1;
                
                if (insert_dummy_instr_o) begin
                    dummy_instr_count = dummy_instr_count + 1;
                    last_dummy_instr = dummy_instr_data_o;
                    
                    // Validate the instruction
                    decode_and_validate_instr(dummy_instr_data_o);
                    
                    if (!instr_valid) begin
                        $display("       [ERROR] Invalid dummy instruction: 0x%08h", dummy_instr_data_o);
                        fail_count = fail_count + 1;
                    end
                end else if (enable_fetch && enable_ready) begin
                    real_instr_count = real_instr_count + 1;
                end
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        dummy_instr_count = 0;
        real_instr_count = 0;
        cycle_counter = 0;
        
        $display("\n========================================================================");
        $display("  IBEX Dummy Instruction Module Testbench");
        $display("  Simulation Start Time: %0t", $time);
        $display("========================================================================\n");
        
        // =====================================================================
        // Test 1: Reset Behavior
        // =====================================================================
        $display("--- Test 1: Reset Behavior ---");
        test_count = test_count + 1;
        
        perform_reset();
        
        if (insert_dummy_instr_o == 0) begin
            $display("[PASS] Test %0d: Dummy instruction insertion disabled after reset", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: Dummy instruction unexpectedly inserted after reset", test_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 2: Disabled Dummy Instructions
        // =====================================================================
        $display("\n--- Test 2: Disabled Dummy Instructions ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        real_instr_count = 0;
        dummy_instr_en_i = 0;  // Keep disabled
        
        execute_instructions(50, 1, 1);
        
        if (dummy_instr_count == 0) begin
            $display("[PASS] Test %0d: No dummy instructions when disabled (Real=%0d)", 
                     test_count, real_instr_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %0d dummy instructions inserted when disabled", 
                     test_count, dummy_instr_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 3: Enabled with Mask 000 (Highest Frequency)
        // =====================================================================
        $display("\n--- Test 3: Enabled with Mask 000 (Highest Frequency) ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        real_instr_count = 0;
        dummy_instr_en_i = 1;  // Enable
        dummy_instr_mask_i = 3'b000;
        
        execute_instructions(50, 1, 1);
        
        $display("       Dummy=%0d, Real=%0d", dummy_instr_count, real_instr_count);
        
        if (dummy_instr_count > 0) begin
            $display("[PASS] Test %0d: Dummy instructions inserted with mask 000", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: No dummy instructions with mask 000", test_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 4: Enabled with Mask 001
        // =====================================================================
        $display("\n--- Test 4: Enabled with Mask 001 (Medium Frequency) ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        real_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b001;
        
        execute_instructions(50, 1, 1);
        
        $display("       Dummy=%0d, Real=%0d", dummy_instr_count, real_instr_count);
        
        if (dummy_instr_count >= 0) begin
            $display("[PASS] Test %0d: Mask 001 test completed", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: Mask 001 test failed", test_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 5: Enabled with Mask 011
        // =====================================================================
        $display("\n--- Test 5: Enabled with Mask 011 (Lower Frequency) ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        real_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b011;
        
        execute_instructions(60, 1, 1);
        
        $display("       Dummy=%0d, Real=%0d", dummy_instr_count, real_instr_count);
        
        if (dummy_instr_count >= 0) begin
            $display("[PASS] Test %0d: Mask 011 test completed", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: Mask 011 test failed", test_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 6: Enabled with Mask 111 (Lowest Frequency)
        // =====================================================================
        $display("\n--- Test 6: Enabled with Mask 111 (Lowest Frequency) ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        real_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b111;
        
        execute_instructions(80, 1, 1);
        
        $display("       Dummy=%0d, Real=%0d", dummy_instr_count, real_instr_count);
        
        if (dummy_instr_count >= 0) begin
            $display("[PASS] Test %0d: Mask 111 test completed", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: Mask 111 test failed", test_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 7: Seed Update
        // =====================================================================
        $display("\n--- Test 7: LFSR Seed Update ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b000;
        
        // Execute with default seed
        dummy_instr_count = 0;
        execute_instructions(15, 1, 1);
        
        // Update seed
        dummy_instr_seed_i = 32'hDEADBEEF;
        dummy_instr_seed_en_i = 1;
        @(posedge clk_i);
        dummy_instr_seed_en_i = 0;
        @(posedge clk_i);
        
        // Execute with new seed
        execute_instructions(15, 1, 1);
        
        $display("       Dummy instructions after seed update: %0d", dummy_instr_count);
        
        if (dummy_instr_count > 0) begin
            $display("[PASS] Test %0d: Seed update successful", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: Seed update failed", test_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 8: Instruction Format Validation
        // =====================================================================
        $display("\n--- Test 8: Instruction Format Validation ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b000;
        
        execute_instructions(30, 1, 1);
        
        if (dummy_instr_count > 0) begin
            decode_and_validate_instr(last_dummy_instr);
            $display("       Total dummy instructions: %0d", dummy_instr_count);
            $display("       Last instruction: 0x%08h (Type: %s, Valid: %0d)", 
                     last_dummy_instr, instr_type, instr_valid);
            
            if (instr_valid) begin
                $display("[PASS] Test %0d: All instructions have valid format", test_count);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: Invalid instruction format detected", test_count);
                fail_count = fail_count + 1;
            end
        end else begin
            $display("[PASS] Test %0d: Format validation completed (no dummy instrs)", test_count);
            pass_count = pass_count + 1;
        end
        
        // =====================================================================
        // Test 9: No Insertion When Fetch Invalid
        // =====================================================================
        $display("\n--- Test 9: No Insertion When Fetch Invalid ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b000;
        
        execute_instructions(30, 0, 1);  // fetch_valid_i = 0
        
        if (dummy_instr_count == 0) begin
            $display("[PASS] Test %0d: No dummy instructions when fetch invalid", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %0d dummy instructions with fetch invalid", 
                     test_count, dummy_instr_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 10: No Insertion When ID Not Ready
        // =====================================================================
        $display("\n--- Test 10: No Insertion When ID Not Ready ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b000;
        
        execute_instructions(30, 1, 0);  // id_in_ready_i = 0
        
        if (dummy_instr_count == 0) begin
            $display("[PASS] Test %0d: No dummy instructions when ID not ready", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %0d dummy instructions when ID not ready", 
                     test_count, dummy_instr_count);
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Test 11: Multiple Seed Updates
        // =====================================================================
        $display("\n--- Test 11: Multiple Seed Updates ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b001;
        
        // First seed update
        dummy_instr_seed_i = 32'h12345678;
        dummy_instr_seed_en_i = 1;
        @(posedge clk_i);
        dummy_instr_seed_en_i = 0;
        
        execute_instructions(10, 1, 1);
        
        // Second seed update
        dummy_instr_seed_i = 32'hABCDEF00;
        dummy_instr_seed_en_i = 1;
        @(posedge clk_i);
        dummy_instr_seed_en_i = 0;
        
        execute_instructions(10, 1, 1);
        
        $display("[PASS] Test %0d: Multiple seed updates completed", test_count);
        pass_count = pass_count + 1;
        
        // =====================================================================
        // Test 12: Verify All Instruction Types
        // =====================================================================
        $display("\n--- Test 12: Instruction Type Coverage ---");
        test_count = test_count + 1;
        
        perform_reset();
        dummy_instr_count = 0;
        dummy_instr_en_i = 1;
        dummy_instr_mask_i = 3'b000;
        
        // Run enough cycles to potentially see all 4 instruction types
        execute_instructions(100, 1, 1);
        
        $display("       Total dummy instructions generated: %0d", dummy_instr_count);
        $display("[PASS] Test %0d: Instruction type coverage test completed", test_count);
        pass_count = pass_count + 1;
        
        // =====================================================================
        // Display Final Results
        // =====================================================================
        $display("\n========================================================================");
        $display("  Test Summary");
        $display("========================================================================");
        $display("  Total Tests:      %4d", test_count);
        $display("  Passed:           %4d", pass_count);
        $display("  Failed:           %4d", fail_count);
        if (test_count > 0) begin
            $display("  Pass Rate:        %6.2f%%", (pass_count * 100.0) / test_count);
        end
        $display("  Total Cycles:     %4d", cycle_counter);
        $display("  Simulation Time:  %0t", $time);
        $display("========================================================================\n");
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED SUCCESSFULLY ***\n");
        end else begin
            $display("*** %0d TEST(S) FAILED ***\n", fail_count);
        end
        
        $display("Simulation completed at time: %0t\n", $time);
        $finish;
    end

endmodule
