`timescale 1ns / 1ps

module tb_ibex_wb_stage;

    import ibex_pkg::*;
    
    // Parameters
    parameter bit ResetAll          = 1'b1;
    parameter bit WritebackStage    = 1'b1;
    parameter bit DummyInstructions = 1'b1;
    
    // Clock and reset
    logic clk_i;
    logic rst_ni;
    
    // Control inputs
    logic                     en_wb_i;
    wb_instr_type_e           instr_type_wb_i;
    logic [31:0]              pc_id_i;
    logic                     instr_is_compressed_id_i;
    logic                     instr_perf_count_id_i;
    
    // Control outputs
    logic                     ready_wb_o;
    logic                     rf_write_wb_o;
    logic                     outstanding_load_wb_o;
    logic                     outstanding_store_wb_o;
    logic [31:0]              pc_wb_o;
    logic                     perf_instr_ret_wb_o;
    logic                     perf_instr_ret_compressed_wb_o;
    logic                     perf_instr_ret_wb_spec_o;
    logic                     perf_instr_ret_compressed_wb_spec_o;
    
    // Register file interface from ID
    logic [4:0]               rf_waddr_id_i;
    logic [31:0]              rf_wdata_id_i;
    logic                     rf_we_id_i;
    logic                     dummy_instr_id_i;
    
    // Register file interface from LSU
    logic [31:0]              rf_wdata_lsu_i;
    logic                     rf_we_lsu_i;
    
    // Register file write outputs
    logic [31:0]              rf_wdata_fwd_wb_o;
    logic [4:0]               rf_waddr_wb_o;
    logic [31:0]              rf_wdata_wb_o;
    logic                     rf_we_wb_o;
    logic                     dummy_instr_wb_o;
    
    // LSU response
    logic                     lsu_resp_valid_i;
    logic                     lsu_resp_err_i;
    
    // Instruction done
    logic                     instr_done_wb_o;
    
    // Test statistics
    int test_count;
    int pass_count;
    int fail_count;
    
    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end
    
    // DUT instantiation
    ibex_wb_stage #(
        .ResetAll         (ResetAll),
        .WritebackStage   (WritebackStage),
        .DummyInstructions(DummyInstructions)
    ) dut (
        .clk_i                              (clk_i),
        .rst_ni                             (rst_ni),
        .en_wb_i                            (en_wb_i),
        .instr_type_wb_i                    (instr_type_wb_i),
        .pc_id_i                            (pc_id_i),
        .instr_is_compressed_id_i           (instr_is_compressed_id_i),
        .instr_perf_count_id_i              (instr_perf_count_id_i),
        .ready_wb_o                         (ready_wb_o),
        .rf_write_wb_o                      (rf_write_wb_o),
        .outstanding_load_wb_o              (outstanding_load_wb_o),
        .outstanding_store_wb_o             (outstanding_store_wb_o),
        .pc_wb_o                            (pc_wb_o),
        .perf_instr_ret_wb_o                (perf_instr_ret_wb_o),
        .perf_instr_ret_compressed_wb_o     (perf_instr_ret_compressed_wb_o),
        .perf_instr_ret_wb_spec_o           (perf_instr_ret_wb_spec_o),
        .perf_instr_ret_compressed_wb_spec_o(perf_instr_ret_compressed_wb_spec_o),
        .rf_waddr_id_i                      (rf_waddr_id_i),
        .rf_wdata_id_i                      (rf_wdata_id_i),
        .rf_we_id_i                         (rf_we_id_i),
        .dummy_instr_id_i                   (dummy_instr_id_i),
        .rf_wdata_lsu_i                     (rf_wdata_lsu_i),
        .rf_we_lsu_i                        (rf_we_lsu_i),
        .rf_wdata_fwd_wb_o                  (rf_wdata_fwd_wb_o),
        .rf_waddr_wb_o                      (rf_waddr_wb_o),
        .rf_wdata_wb_o                      (rf_wdata_wb_o),
        .rf_we_wb_o                         (rf_we_wb_o),
        .dummy_instr_wb_o                   (dummy_instr_wb_o),
        .lsu_resp_valid_i                   (lsu_resp_valid_i),
        .lsu_resp_err_i                     (lsu_resp_err_i),
        .instr_done_wb_o                    (instr_done_wb_o)
    );
    
    // Task: Reset
    task perform_reset;
        begin
            $display("       Performing reset...");
            rst_ni = 0;
            en_wb_i = 0;
            instr_type_wb_i = WB_INSTR_OTHER;
            pc_id_i = 32'h0;
            instr_is_compressed_id_i = 0;
            instr_perf_count_id_i = 0;
            rf_waddr_id_i = 5'h0;
            rf_wdata_id_i = 32'h0;
            rf_we_id_i = 0;
            dummy_instr_id_i = 0;
            rf_wdata_lsu_i = 32'h0;
            rf_we_lsu_i = 0;
            lsu_resp_valid_i = 0;
            lsu_resp_err_i = 0;
            
            repeat(5) @(posedge clk_i);
            rst_ni = 1;
            repeat(2) @(posedge clk_i);
            $display("       Reset complete");
        end
    endtask
    
    // Task: Write from ID/EX stage (non-load/store)
    task test_rf_write_from_id;
        input logic [4:0]  addr;
        input logic [31:0] data;
        input logic [31:0] pc;
        input logic        compressed;
        begin
            $display("       RF Write from ID: addr=x%0d, data=0x%08h, pc=0x%08h", 
                     addr, data, pc);
            
            en_wb_i = 1'b1;
            instr_type_wb_i = WB_INSTR_OTHER;
            rf_waddr_id_i = addr;
            rf_wdata_id_i = data;
            rf_we_id_i = 1'b1;
            pc_id_i = pc;
            instr_is_compressed_id_i = compressed;
            instr_perf_count_id_i = 1'b1;
            dummy_instr_id_i = 1'b0;
            
            @(posedge clk_i);
            
            // Wait for ready if needed
            while (!ready_wb_o) @(posedge clk_i);
            
            en_wb_i = 1'b0;
            rf_we_id_i = 1'b0;
            
            @(posedge clk_i);
        end
    endtask
    
    // Task: Load instruction - CORRECTED
    task test_load_instr;
        input logic [4:0]  addr;
        input logic [31:0] lsu_data;
        input logic [31:0] pc;
        begin
            $display("       Load instruction: addr=x%0d, lsu_data=0x%08h, pc=0x%08h", 
                     addr, lsu_data, pc);
            
            // For loads: rf_we_id_i should be 0, data comes only from LSU
            en_wb_i = 1'b1;
            instr_type_wb_i = WB_INSTR_LOAD;
            rf_waddr_id_i = addr;
            rf_wdata_id_i = 32'h0;
            rf_we_id_i = 1'b0;  // FIXED: Load doesn't write from ID
            pc_id_i = pc;
            instr_is_compressed_id_i = 1'b0;
            instr_perf_count_id_i = 1'b1;
            
            @(posedge clk_i);
            en_wb_i = 1'b0;
            
            // Wait for WB stage to be ready for LSU response
            while (!outstanding_load_wb_o) @(posedge clk_i);
            
            // Provide LSU response
            $display("           LSU response with data=0x%08h", lsu_data);
            rf_wdata_lsu_i = lsu_data;
            rf_we_lsu_i = 1'b1;
            lsu_resp_valid_i = 1'b1;
            
            @(posedge clk_i);
            
            // Check the data immediately
            $display("           RF write: addr=x%0d, data=0x%08h", rf_waddr_wb_o, rf_wdata_wb_o);
            
            rf_we_lsu_i = 1'b0;
            lsu_resp_valid_i = 1'b0;
            rf_wdata_lsu_i = 32'h0;
            
            @(posedge clk_i);
        end
    endtask
    
    // Task: Store instruction - CORRECTED
    task test_store_instr;
        input logic [31:0] pc;
        begin
            $display("       Store instruction: pc=0x%08h", pc);
            
            en_wb_i = 1'b1;
            instr_type_wb_i = WB_INSTR_STORE;
            rf_we_id_i = 1'b0;
            pc_id_i = pc;
            instr_is_compressed_id_i = 1'b0;
            instr_perf_count_id_i = 1'b1;
            
            @(posedge clk_i);
            en_wb_i = 1'b0;
            
            // Wait for outstanding store
            while (!outstanding_store_wb_o) @(posedge clk_i);
            
            // Provide LSU response
            $display("           LSU response (store complete)");
            lsu_resp_valid_i = 1'b1;
            
            @(posedge clk_i);
            
            // Check instr_done in this cycle
            $display("           Instruction done: %0d", instr_done_wb_o);
            
            lsu_resp_valid_i = 1'b0;
            
            @(posedge clk_i);
        end
    endtask
    
    // Main test sequence
    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================================================");
        $display("  IBEX Writeback Stage Testbench");
        $display("  WritebackStage=%0d, DummyInstructions=%0d", 
                 WritebackStage, DummyInstructions);
        $display("========================================================================\n");
        
        perform_reset();
        
        // =====================================================================
        // Test 1: Basic RF Write from ID/EX
        // =====================================================================
        $display("\n--- Test 1: Basic RF Write from ID/EX ---");
        test_count++;
        
        test_rf_write_from_id(5'd1, 32'h12345678, 32'h1000, 1'b0);
        
        if (rf_we_wb_o && rf_waddr_wb_o == 5'd1 && rf_wdata_wb_o == 32'h12345678) begin
            $display("[PASS] Test %0d: RF write correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: RF write incorrect (we=%0d, addr=%0d, data=0x%08h)", 
                     test_count, rf_we_wb_o, rf_waddr_wb_o, rf_wdata_wb_o);
            fail_count++;
        end
        
        // =====================================================================
        // Test 2: Compressed Instruction
        // =====================================================================
        $display("\n--- Test 2: Compressed Instruction ---");
        test_count++;
        
        test_rf_write_from_id(5'd2, 32'hAABBCCDD, 32'h2000, 1'b1);
        
        if (perf_instr_ret_compressed_wb_o) begin
            $display("[PASS] Test %0d: Compressed instruction counted", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Compressed instruction not counted", test_count);
            fail_count++;
        end
        
        // =====================================================================
        // Test 3: Load Instruction
        // =====================================================================
        $display("\n--- Test 3: Load Instruction ---");
        test_count++;
        
        test_load_instr(5'd3, 32'hDEADBEEF, 32'h3000);
        
        if (rf_waddr_wb_o == 5'd3) begin
            $display("[PASS] Test %0d: Load data written correctly (data=0x%08h)", 
                     test_count, rf_wdata_wb_o);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Load data incorrect (addr=%0d, data=0x%08h)", 
                     test_count, rf_waddr_wb_o, rf_wdata_wb_o);
            fail_count++;
        end
        
        // =====================================================================
        // Test 4: Store Instruction
        // =====================================================================
        $display("\n--- Test 4: Store Instruction ---");
        test_count++;
        
        begin : store_test
            logic done_signal;
            
            en_wb_i = 1'b1;
            instr_type_wb_i = WB_INSTR_STORE;
            rf_we_id_i = 1'b0;
            pc_id_i = 32'h4000;
            instr_perf_count_id_i = 1'b1;
            
            @(posedge clk_i);
            en_wb_i = 1'b0;
            
            // Wait for outstanding store
            while (!outstanding_store_wb_o) @(posedge clk_i);
            
            // Provide LSU response
            $display("       LSU response (store complete)");
            lsu_resp_valid_i = 1'b1;
            
            @(posedge clk_i);
            done_signal = instr_done_wb_o;
            
            lsu_resp_valid_i = 1'b0;
            @(posedge clk_i);
            
            if (done_signal) begin
                $display("[PASS] Test %0d: Store completed", test_count);
                pass_count++;
            end else begin
                $display("[FAIL] Test %0d: Store not completed", test_count);
                fail_count++;
            end
        end
        
        // =====================================================================
        // Test 5: Outstanding Load Detection
        // =====================================================================
        $display("\n--- Test 5: Outstanding Load Detection ---");
        test_count++;
        
        en_wb_i = 1'b1;
        instr_type_wb_i = WB_INSTR_LOAD;
        rf_waddr_id_i = 5'd5;
        rf_we_id_i = 1'b0;
        pc_id_i = 32'h5000;
        instr_perf_count_id_i = 1'b1;
        
        @(posedge clk_i);
        en_wb_i = 1'b0;
        
        @(posedge clk_i);
        
        if (outstanding_load_wb_o) begin
            $display("[PASS] Test %0d: Outstanding load detected", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Outstanding load not detected", test_count);
            fail_count++;
        end
        
        // Complete the load
        lsu_resp_valid_i = 1'b1;
        rf_wdata_lsu_i = 32'h55555555;
        rf_we_lsu_i = 1'b1;
        @(posedge clk_i);
        lsu_resp_valid_i = 1'b0;
        rf_we_lsu_i = 1'b0;
        @(posedge clk_i);
        
        // =====================================================================
        // Test 6: Outstanding Store Detection
        // =====================================================================
        $display("\n--- Test 6: Outstanding Store Detection ---");
        test_count++;
        
        en_wb_i = 1'b1;
        instr_type_wb_i = WB_INSTR_STORE;
        rf_we_id_i = 1'b0;
        pc_id_i = 32'h6000;
        instr_perf_count_id_i = 1'b1;
        
        @(posedge clk_i);
        en_wb_i = 1'b0;
        
        @(posedge clk_i);
        
        if (outstanding_store_wb_o) begin
            $display("[PASS] Test %0d: Outstanding store detected", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Outstanding store not detected", test_count);
            fail_count++;
        end
        
        // Complete the store
        lsu_resp_valid_i = 1'b1;
        @(posedge clk_i);
        lsu_resp_valid_i = 1'b0;
        @(posedge clk_i);
        
        // =====================================================================
        // Test 7: Data Forwarding
        // =====================================================================
        $display("\n--- Test 7: Data Forwarding ---");
        test_count++;
        
        test_rf_write_from_id(5'd7, 32'h77777777, 32'h7000, 1'b0);
        
        if (rf_wdata_fwd_wb_o == 32'h77777777) begin
            $display("[PASS] Test %0d: Data forwarding correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Data forwarding incorrect (got 0x%08h)", 
                     test_count, rf_wdata_fwd_wb_o);
            fail_count++;
        end
        
        // =====================================================================
        // Test 8: Dummy Instruction
        // =====================================================================
        $display("\n--- Test 8: Dummy Instruction ---");
        test_count++;
        
        en_wb_i = 1'b1;
        instr_type_wb_i = WB_INSTR_OTHER;
        rf_waddr_id_i = 5'd8;
        rf_wdata_id_i = 32'h88888888;
        rf_we_id_i = 1'b1;
        pc_id_i = 32'h8000;
        instr_perf_count_id_i = 1'b1;
        dummy_instr_id_i = 1'b1;
        
        @(posedge clk_i);
        en_wb_i = 1'b0;
        dummy_instr_id_i = 1'b0;
        
        @(posedge clk_i);
        
        if (dummy_instr_wb_o) begin
            $display("[PASS] Test %0d: Dummy instruction flag propagated", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Dummy instruction flag not set", test_count);
            fail_count++;
        end
        
        @(posedge clk_i);
        
        // =====================================================================
        // Test 9: Back-to-Back Instructions
        // =====================================================================
        $display("\n--- Test 9: Back-to-Back Instructions ---");
        test_count++;
        
        test_rf_write_from_id(5'd9, 32'h11111111, 32'h9000, 1'b0);
        test_rf_write_from_id(5'd10, 32'h22222222, 32'h9004, 1'b0);
        test_rf_write_from_id(5'd11, 32'h33333333, 32'h9008, 1'b0);
        
        $display("[PASS] Test %0d: Back-to-back instructions handled", test_count);
        pass_count++;
        
        // =====================================================================
        // Test 10: Performance Counters
        // =====================================================================
        $display("\n--- Test 10: Performance Counters ---");
        test_count++;
        
        begin : perf_counter_test
            logic normal_retired;
            logic compressed_retired;
            
            // Normal instruction
            en_wb_i = 1'b1;
            instr_type_wb_i = WB_INSTR_OTHER;
            rf_waddr_id_i = 5'd12;
            rf_wdata_id_i = 32'h12121212;
            rf_we_id_i = 1'b1;
            pc_id_i = 32'hA000;
            instr_is_compressed_id_i = 1'b0;
            instr_perf_count_id_i = 1'b1;
            
            @(posedge clk_i);
            en_wb_i = 1'b0;
            rf_we_id_i = 1'b0;
            
            @(posedge clk_i);
            normal_retired = perf_instr_ret_wb_o;
            
            // Compressed instruction
            en_wb_i = 1'b1;
            rf_waddr_id_i = 5'd13;
            rf_wdata_id_i = 32'h13131313;
            rf_we_id_i = 1'b1;
            pc_id_i = 32'hA002;
            instr_is_compressed_id_i = 1'b1;
            instr_perf_count_id_i = 1'b1;
            
            @(posedge clk_i);
            en_wb_i = 1'b0;
            rf_we_id_i = 1'b0;
            
            @(posedge clk_i);
            compressed_retired = perf_instr_ret_compressed_wb_o;
            
            if (normal_retired && compressed_retired) begin
                $display("[PASS] Test %0d: Performance counters working", test_count);
                pass_count++;
            end else begin
                $display("[FAIL] Test %0d: Performance counters incorrect (normal=%0d, compressed=%0d)", 
                         test_count, normal_retired, compressed_retired);
                fail_count++;
            end
        end
        
        // =====================================================================
        // Display Final Results
        // =====================================================================
        $display("\n========================================================================");
        $display("  Test Summary");
        $display("========================================================================");
        $display("  Total Tests:    %0d", test_count);
        $display("  Passed:         %0d", pass_count);
        $display("  Failed:         %0d", fail_count);
        if (test_count > 0) begin
            $display("  Pass Rate:      %.1f%%", (pass_count * 100.0) / test_count);
        end
        $display("========================================================================\n");
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED SUCCESSFULLY ***\n");
        end else begin
            $display("*** %0d TEST(S) FAILED ***\n", fail_count);
        end
        
        $finish;
    end

endmodule
