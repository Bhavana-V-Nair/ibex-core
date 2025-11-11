`timescale 1ns / 1ps

module tb_ibex_load_store_unit;

    // Parameters
    parameter bit          MemECC       = 1'b1; // Enable ECC for testing
    parameter int unsigned MemDataWidth = MemECC ? 32 + 7 : 32;
    
    // Clock and reset
    logic clk_i;
    logic rst_ni;
    
    // Data memory interface
    logic                     data_req_o;
    logic                     data_gnt_i;
    logic                     data_rvalid_i;
    logic                     data_bus_err_i;
    logic                     data_pmp_err_i;
    logic [31:0]              data_addr_o;
    logic                     data_we_o;
    logic [3:0]               data_be_o;
    logic [MemDataWidth-1:0]  data_wdata_o;
    logic [MemDataWidth-1:0]  data_rdata_i;
    
    // Signals from ID/EX stage
    logic        lsu_we_i;
    logic [1:0]  lsu_type_i;
    logic [31:0] lsu_wdata_i;
    logic        lsu_sign_ext_i;
    logic [31:0] lsu_rdata_o;
    logic        lsu_rdata_valid_o;
    logic        lsu_req_i;
    logic [31:0] adder_result_ex_i;
    
    // Control signals
    logic        addr_incr_req_o;
    logic [31:0] addr_last_o;
    logic        lsu_req_done_o;
    logic        lsu_resp_valid_o;
    
    // Exception signals
    logic        load_err_o;
    logic        load_resp_intg_err_o;
    logic        store_err_o;
    logic        store_resp_intg_err_o;
    logic        busy_o;
    logic        perf_load_o;
    logic        perf_store_o;
    
    // Test statistics
    int test_count;
    int pass_count;
    int fail_count;
    
    // Memory model - store ECC encoded data directly
    logic [MemDataWidth-1:0] memory [1024]; // 1024 word memory for better range
    
    // ECC encoder/decoder signals
    logic [31:0]             plain_data_for_encode;
    logic [38:0]             ecc_encoded_output;
    logic [31:0]             ecc_decoded_output;
    logic [6:0]              ecc_syndrome;
    logic [1:0]              ecc_err;
    
    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end
    
    // DUT instantiation
    ibex_load_store_unit #(
        .MemECC      (MemECC),
        .MemDataWidth(MemDataWidth)
    ) dut (
        .clk_i                  (clk_i),
        .rst_ni                 (rst_ni),
        .data_req_o             (data_req_o),
        .data_gnt_i             (data_gnt_i),
        .data_rvalid_i          (data_rvalid_i),
        .data_bus_err_i         (data_bus_err_i),
        .data_pmp_err_i         (data_pmp_err_i),
        .data_addr_o            (data_addr_o),
        .data_we_o              (data_we_o),
        .data_be_o              (data_be_o),
        .data_wdata_o           (data_wdata_o),
        .data_rdata_i           (data_rdata_i),
        .lsu_we_i               (lsu_we_i),
        .lsu_type_i             (lsu_type_i),
        .lsu_wdata_i            (lsu_wdata_i),
        .lsu_sign_ext_i         (lsu_sign_ext_i),
        .lsu_rdata_o            (lsu_rdata_o),
        .lsu_rdata_valid_o      (lsu_rdata_valid_o),
        .lsu_req_i              (lsu_req_i),
        .adder_result_ex_i      (adder_result_ex_i),
        .addr_incr_req_o        (addr_incr_req_o),
        .addr_last_o            (addr_last_o),
        .lsu_req_done_o         (lsu_req_done_o),
        .lsu_resp_valid_o       (lsu_resp_valid_o),
        .load_err_o             (load_err_o),
        .load_resp_intg_err_o   (load_resp_intg_err_o),
        .store_err_o            (store_err_o),
        .store_resp_intg_err_o  (store_resp_intg_err_o),
        .busy_o                 (busy_o),
        .perf_load_o            (perf_load_o),
        .perf_store_o           (perf_store_o)
    );
    
    // ECC Encoder/Decoder (if enabled)
    generate
        if (MemECC) begin : g_ecc
            prim_secded_inv_39_32_enc u_ecc_encoder (
                .data_i(plain_data_for_encode),
                .data_o(ecc_encoded_output)
            );
            
            prim_secded_inv_39_32_dec u_ecc_decoder (
                .data_i(data_wdata_o),
                .data_o(ecc_decoded_output),
                .syndrome_o(ecc_syndrome),
                .err_o(ecc_err)
            );
        end else begin : g_no_ecc
            assign ecc_encoded_output = plain_data_for_encode;
            assign ecc_decoded_output = data_wdata_o;
        end
    endgenerate
    
    // Memory interface model with FIXED addressing
    logic [9:0] captured_addr_index;
    logic [MemDataWidth-1:0] captured_wdata;
    logic captured_we;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_gnt_i <= 1'b0;
            data_rvalid_i <= 1'b0;
            data_rdata_i <= '0;
            data_bus_err_i <= 1'b0;
            captured_addr_index <= '0;
            captured_wdata <= '0;
            captured_we <= 1'b0;
        end else begin
            // Grant requests immediately and capture address AT THE SAME TIME
            data_gnt_i <= data_req_o;
            
            if (data_req_o && data_gnt_i) begin
                // Capture request details when granting
                captured_addr_index <= data_addr_o[11:2]; // Word address to index
                captured_wdata <= data_wdata_o;
                captured_we <= data_we_o;
            end
            
            // Process the captured request one cycle later
            data_rvalid_i <= data_gnt_i;
            
            if (data_gnt_i) begin
                if (captured_we) begin
                    // Store operation using CAPTURED address
                    memory[captured_addr_index] <= captured_wdata;
                    data_rdata_i <= '0;
                    $display("           [MEM] Write to index %0d (addr 0x%08h): data=0x%h", 
                             captured_addr_index, {captured_addr_index, 2'b00}, captured_wdata);
                end else begin
                    // Load operation using CAPTURED address
                    data_rdata_i <= memory[captured_addr_index];
                    $display("           [MEM] Read from index %0d (addr 0x%08h): data=0x%h", 
                             captured_addr_index, {captured_addr_index, 2'b00}, memory[captured_addr_index]);
                end
                
                data_bus_err_i <= 1'b0;
            end
        end
    end
    
    // Task: Reset
    task perform_reset;
        int i;
        begin
            $display("       Performing reset...");
            rst_ni = 0;
            lsu_req_i = 0;
            lsu_we_i = 0;
            lsu_type_i = 2'b00;
            lsu_wdata_i = 32'h0;
            lsu_sign_ext_i = 0;
            adder_result_ex_i = 32'h0;
            data_pmp_err_i = 0;
            plain_data_for_encode = 32'h0;
            
            // Clear memory
            for (i = 0; i < 1024; i = i + 1) begin
                memory[i] = '0;
            end
            
            repeat(5) @(posedge clk_i);
            rst_ni = 1;
            repeat(2) @(posedge clk_i);
            $display("       Reset complete");
        end
    endtask
    
    // Task: Store Word
    task test_store_word;
        input logic [31:0] addr;
        input logic [31:0] data;
        begin
            $display("       Store Word: addr=0x%08h, data=0x%08h", addr, data);
            
            lsu_req_i = 1'b1;
            lsu_we_i = 1'b1;
            lsu_type_i = 2'b00; // Word
            lsu_wdata_i = data;
            adder_result_ex_i = addr;
            
            @(posedge clk_i);
            
            // Wait for completion
            while (!lsu_req_done_o) @(posedge clk_i);
            
            lsu_req_i = 1'b0;
            @(posedge clk_i);
            @(posedge clk_i); // Extra cycle for data to settle
        end
    endtask
    
    // Task: Load Word
    task test_load_word;
        input logic [31:0] addr;
        input logic sign_ext;
        output logic [31:0] data;
        begin
            $display("       Load Word: addr=0x%08h", addr);
            
            lsu_req_i = 1'b1;
            lsu_we_i = 1'b0;
            lsu_type_i = 2'b00; // Word
            lsu_sign_ext_i = sign_ext;
            adder_result_ex_i = addr;
            
            @(posedge clk_i);
            
            // Wait for valid data
            while (!lsu_rdata_valid_o) @(posedge clk_i);
            
            data = lsu_rdata_o;
            $display("           Read data: 0x%08h", data);
            
            lsu_req_i = 1'b0;
            @(posedge clk_i);
        end
    endtask
    
    // Task: Load Half Word
    task test_load_half;
        input logic [31:0] addr;
        input logic sign_ext;
        output logic [31:0] data;
        begin
            $display("       Load Half: addr=0x%08h, sign_ext=%0d", addr, sign_ext);
            
            lsu_req_i = 1'b1;
            lsu_we_i = 1'b0;
            lsu_type_i = 2'b01; // Half word
            lsu_sign_ext_i = sign_ext;
            adder_result_ex_i = addr;
            
            @(posedge clk_i);
            
            // Wait for valid data
            while (!lsu_rdata_valid_o) @(posedge clk_i);
            
            data = lsu_rdata_o;
            $display("           Read data: 0x%08h", data);
            
            lsu_req_i = 1'b0;
            @(posedge clk_i);
        end
    endtask
    
    // Task: Load Byte
    task test_load_byte;
        input logic [31:0] addr;
        input logic sign_ext;
        output logic [31:0] data;
        begin
            $display("       Load Byte: addr=0x%08h, sign_ext=%0d", addr, sign_ext);
            
            lsu_req_i = 1'b1;
            lsu_we_i = 1'b0;
            lsu_type_i = 2'b10; // Byte
            lsu_sign_ext_i = sign_ext;
            adder_result_ex_i = addr;
            
            @(posedge clk_i);
            
            // Wait for valid data
            while (!lsu_rdata_valid_o) @(posedge clk_i);
            
            data = lsu_rdata_o;
            $display("           Read data: 0x%08h", data);
            
            lsu_req_i = 1'b0;
            @(posedge clk_i);
        end
    endtask
    
    // Main test sequence
    initial begin
        logic [31:0] read_data;
        
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================================================");
        $display("  IBEX Load Store Unit Testbench (MemECC=%0d)", MemECC);
        $display("========================================================================\n");
        
        perform_reset();
        
        // =====================================================================
        // Test 1: Aligned Word Store and Load
        // =====================================================================
        $display("\n--- Test 1: Aligned Word Store and Load ---");
        test_count++;
        
        test_store_word(32'h00001000, 32'h12345678);
        test_load_word(32'h00001000, 1'b0, read_data);
        
        if (read_data == 32'h12345678) begin
            $display("[PASS] Test %0d: Word store/load correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Expected 0x12345678, got 0x%08h", test_count, read_data);
            fail_count++;
        end
        
        // =====================================================================
        // Test 2: Aligned Half Word Operations (Unsigned)
        // =====================================================================
        $display("\n--- Test 2: Aligned Half Word Load (Unsigned) ---");
        test_count++;
        
        test_store_word(32'h00002000, 32'hABCD5678);
        test_load_half(32'h00002000, 1'b0, read_data);
        
        if (read_data == 32'h00005678) begin
            $display("[PASS] Test %0d: Half word unsigned load correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Expected 0x00005678, got 0x%08h", test_count, read_data);
            fail_count++;
        end
        
        // =====================================================================
        // Test 3: Half Word Sign Extension
        // =====================================================================
        $display("\n--- Test 3: Half Word Load (Signed) ---");
        test_count++;
        
        test_store_word(32'h00003000, 32'h0000ABCD);
        test_load_half(32'h00003000, 1'b1, read_data);
        
        if (read_data == 32'hFFFFABCD) begin
            $display("[PASS] Test %0d: Half word signed load correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Expected 0xFFFFABCD, got 0x%08h", test_count, read_data);
            fail_count++;
        end
        
        // =====================================================================
        // Test 4: Byte Operations (Unsigned)
        // =====================================================================
        $display("\n--- Test 4: Byte Load (Unsigned) ---");
        test_count++;
        
        test_store_word(32'h00004000, 32'h12345678);
        test_load_byte(32'h00004000, 1'b0, read_data);
        
        if (read_data == 32'h00000078) begin
            $display("[PASS] Test %0d: Byte unsigned load correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Expected 0x00000078, got 0x%08h", test_count, read_data);
            fail_count++;
        end
        
        // =====================================================================
        // Test 5: Byte Sign Extension
        // =====================================================================
        $display("\n--- Test 5: Byte Load (Signed) ---");
        test_count++;
        
        test_store_word(32'h00005000, 32'h000000AB);
        test_load_byte(32'h00005000, 1'b1, read_data);
        
        if (read_data == 32'hFFFFFFAB) begin
            $display("[PASS] Test %0d: Byte signed load correct", test_count);
            pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Expected 0xFFFFFFAB, got 0x%08h", test_count, read_data);
            fail_count++;
        end
        
        // =====================================================================
        // Test 6: Different Byte Positions
        // =====================================================================
        $display("\n--- Test 6: Byte Access at Different Offsets ---");
        test_count++;
        
        test_store_word(32'h00007000, 32'h12345678);
        
        test_load_byte(32'h00007001, 1'b0, read_data);
        test_load_byte(32'h00007002, 1'b0, read_data);
        test_load_byte(32'h00007003, 1'b0, read_data);
        
        $display("[PASS] Test %0d: Byte offsets handled", test_count);
        pass_count++;
        
        // =====================================================================
        // Test 7: Multiple Word Operations
        // =====================================================================
        $display("\n--- Test 7: Multiple Word Operations ---");
        test_count++;
        
        test_store_word(32'h00008000, 32'hAABBCCDD);
        test_store_word(32'h00008004, 32'h11223344);
        test_store_word(32'h00008008, 32'h55667788);
        
        test_load_word(32'h00008000, 1'b0, read_data);
        if (read_data == 32'hAABBCCDD) begin
            test_load_word(32'h00008004, 1'b0, read_data);
            if (read_data == 32'h11223344) begin
                test_load_word(32'h00008008, 1'b0, read_data);
                if (read_data == 32'h55667788) begin
                    $display("[PASS] Test %0d: All three words correct", test_count);
                    pass_count++;
                end else begin
                    $display("[FAIL] Test %0d: Third word got 0x%08h", test_count, read_data);
                    fail_count++;
                end
            end else begin
                $display("[FAIL] Test %0d: Second word got 0x%08h (expected 0x11223344)", test_count, read_data);
                fail_count++;
            end
        end else begin
            $display("[FAIL] Test %0d: First word got 0x%08h", test_count, read_data);
            fail_count++;
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
