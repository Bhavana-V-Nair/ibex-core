`timescale 1ns / 1ps

module tb_ibex_pmp;

    import ibex_pkg::*;
    
    // Parameters
    parameter int unsigned DmBaseAddr     = 32'h1A110000;
    parameter int unsigned DmAddrMask     = 32'h00000FFF;
    parameter int unsigned PMPGranularity = 0;
    parameter int unsigned PMPNumChan     = 2;
    parameter int unsigned PMPNumRegions  = 4;
    
    // CSR inputs
    pmp_cfg_t      csr_pmp_cfg_i     [PMPNumRegions];
    logic [33:0]   csr_pmp_addr_i    [PMPNumRegions];
    pmp_mseccfg_t  csr_pmp_mseccfg_i;
    
    // Control inputs
    logic          debug_mode_i;
    priv_lvl_e     priv_mode_i    [PMPNumChan];
    
    // Access request inputs
    logic [33:0]   pmp_req_addr_i [PMPNumChan];
    pmp_req_e      pmp_req_type_i [PMPNumChan];
    
    // Outputs
    logic          pmp_req_err_o  [PMPNumChan];
    
    // Test statistics
    int test_count;
    int pass_count;
    int fail_count;
    
    // DUT instantiation
    ibex_pmp #(
        .DmBaseAddr    (DmBaseAddr),
        .DmAddrMask    (DmAddrMask),
        .PMPGranularity(PMPGranularity),
        .PMPNumChan    (PMPNumChan),
        .PMPNumRegions (PMPNumRegions)
    ) dut (
        .csr_pmp_cfg_i     (csr_pmp_cfg_i),
        .csr_pmp_addr_i    (csr_pmp_addr_i),
        .csr_pmp_mseccfg_i (csr_pmp_mseccfg_i),
        .debug_mode_i      (debug_mode_i),
        .priv_mode_i       (priv_mode_i),
        .pmp_req_addr_i    (pmp_req_addr_i),
        .pmp_req_type_i    (pmp_req_type_i),
        .pmp_req_err_o     (pmp_req_err_o)
    );
    
    // Main test sequence
    initial begin
        int i;
        
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================================================");
        $display("  IBEX PMP Testbench");
        $display("  PMPNumRegions=%0d, PMPNumChan=%0d, PMPGranularity=%0d",
                 PMPNumRegions, PMPNumChan, PMPGranularity);
        $display("========================================================================\n");
        
        // Initial reset
        $display("       Resetting PMP configuration...");
        for (i = 0; i < PMPNumRegions; i++) begin
            csr_pmp_cfg_i[i].lock  = 1'b0;
            csr_pmp_cfg_i[i].mode  = PMP_MODE_OFF;
            csr_pmp_cfg_i[i].exec  = 1'b0;
            csr_pmp_cfg_i[i].write = 1'b0;
            csr_pmp_cfg_i[i].read  = 1'b0;
            csr_pmp_addr_i[i] = 34'h0;
        end
        csr_pmp_mseccfg_i.mml  = 1'b0;
        csr_pmp_mseccfg_i.mmwp = 1'b0;
        csr_pmp_mseccfg_i.rlb  = 1'b0;
        debug_mode_i = 1'b0;
        for (i = 0; i < PMPNumChan; i++) begin
            priv_mode_i[i] = PRIV_LVL_M;
            pmp_req_addr_i[i] = 34'h0;
            pmp_req_type_i[i] = PMP_ACC_READ;
        end
        #1;
        
        // =====================================================================
        // Test 1: All Regions OFF - M-mode access allowed
        // =====================================================================
        $display("\n--- Test 1: PMP OFF Mode - M-mode Full Access ---");
        
        test_count++; pmp_req_addr_i[0] = 34'h100000; pmp_req_type_i[0] = PMP_ACC_READ; 
        priv_mode_i[0] = PRIV_LVL_M; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: M-mode read allowed when PMP off", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: M-mode read should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_type_i[0] = PMP_ACC_WRITE; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: M-mode write allowed when PMP off", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: M-mode write should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_type_i[0] = PMP_ACC_EXEC; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: M-mode exec allowed when PMP off", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: M-mode exec should be allowed", test_count); fail_count++;
        end
        
        // =====================================================================
        // Test 2: All Regions OFF - U-mode access denied
        // =====================================================================
        $display("\n--- Test 2: PMP OFF Mode - U-mode Access Denied ---");
        
        test_count++; priv_mode_i[0] = PRIV_LVL_U; pmp_req_type_i[0] = PMP_ACC_READ; #1;
        if (pmp_req_err_o[0] == 1'b1) begin
            $display("[PASS] Test %0d: U-mode read denied when PMP off", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: U-mode read should be denied", test_count); fail_count++;
        end
        
        test_count++; pmp_req_type_i[0] = PMP_ACC_WRITE; #1;
        if (pmp_req_err_o[0] == 1'b1) begin
            $display("[PASS] Test %0d: U-mode write denied when PMP off", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: U-mode write should be denied", test_count); fail_count++;
        end
        
        // =====================================================================
        // Test 3: TOR Mode - Basic Access Control
        // =====================================================================
        $display("\n--- Test 3: TOR Mode Access Control ---");
        
        // Configure TOR region 0->1
        $display("       Configuring TOR region 0->1: 0x080000-0x0C0000, RWX");
        csr_pmp_cfg_i[0].mode = PMP_MODE_TOR; csr_pmp_cfg_i[0].read = 1'b1;
        csr_pmp_cfg_i[0].write = 1'b1; csr_pmp_cfg_i[0].exec = 1'b1; csr_pmp_cfg_i[0].lock = 1'b0;
        csr_pmp_addr_i[0] = 34'h080000;
        csr_pmp_cfg_i[1].mode = PMP_MODE_TOR; csr_pmp_cfg_i[1].read = 1'b1;
        csr_pmp_cfg_i[1].write = 1'b1; csr_pmp_cfg_i[1].exec = 1'b1; csr_pmp_cfg_i[1].lock = 1'b0;
        csr_pmp_addr_i[1] = 34'h0C0000;
        #1;
        
        test_count++; pmp_req_addr_i[0] = 34'h090000; pmp_req_type_i[0] = PMP_ACC_READ;
        priv_mode_i[0] = PRIV_LVL_U; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: TOR U-mode read in allowed region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: TOR U-mode read should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_type_i[0] = PMP_ACC_WRITE; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: TOR U-mode write in allowed region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: TOR U-mode write should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_addr_i[0] = 34'h200000; pmp_req_type_i[0] = PMP_ACC_READ; #1;
        if (pmp_req_err_o[0] == 1'b1) begin
            $display("[PASS] Test %0d: TOR U-mode read outside region denied", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: TOR U-mode read should be denied", test_count); fail_count++;
        end
        
        // =====================================================================
        // Test 4: NA4 Mode
        // =====================================================================
        $display("\n--- Test 4: NA4 Mode Access Control ---");
        
        // Reset and configure NA4
        for (i = 0; i < PMPNumRegions; i++) begin
            csr_pmp_cfg_i[i].mode = PMP_MODE_OFF; csr_pmp_cfg_i[i].lock = 1'b0;
            csr_pmp_cfg_i[i].read = 1'b0; csr_pmp_cfg_i[i].write = 1'b0; csr_pmp_cfg_i[i].exec = 1'b0;
        end
        $display("       Configuring NA4 region at 0x040000, RX only");
        csr_pmp_cfg_i[0].mode = PMP_MODE_NA4; csr_pmp_cfg_i[0].read = 1'b1;
        csr_pmp_cfg_i[0].write = 1'b0; csr_pmp_cfg_i[0].exec = 1'b1;
        csr_pmp_addr_i[0] = 34'h040000;
        #1;
        
        test_count++; pmp_req_addr_i[0] = 34'h040000; pmp_req_type_i[0] = PMP_ACC_READ;
        priv_mode_i[0] = PRIV_LVL_U; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: NA4 read allowed at exact address", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: NA4 read should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_type_i[0] = PMP_ACC_WRITE; #1;
        if (pmp_req_err_o[0] == 1'b1) begin
            $display("[PASS] Test %0d: NA4 write denied (no write perm)", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: NA4 write should be denied", test_count); fail_count++;
        end
        
        test_count++; pmp_req_addr_i[0] = 34'h040004; pmp_req_type_i[0] = PMP_ACC_READ; #1;
        if (pmp_req_err_o[0] == 1'b1) begin
            $display("[PASS] Test %0d: NA4 read denied at next address", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: NA4 read should be denied", test_count); fail_count++;
        end
        
        // =====================================================================
        // Test 5: NAPOT Mode
        // =====================================================================
        $display("\n--- Test 5: NAPOT Mode Access Control ---");
        
        for (i = 0; i < PMPNumRegions; i++) begin
            csr_pmp_cfg_i[i].mode = PMP_MODE_OFF;
        end
        $display("       Configuring NAPOT 256-byte region at 0x040000, RW");
        csr_pmp_cfg_i[0].mode = PMP_MODE_NAPOT; csr_pmp_cfg_i[0].read = 1'b1;
        csr_pmp_cfg_i[0].write = 1'b1; csr_pmp_cfg_i[0].exec = 1'b0;
        csr_pmp_addr_i[0] = 34'h04007F;
        #1;
        
        test_count++; pmp_req_addr_i[0] = 34'h040000; pmp_req_type_i[0] = PMP_ACC_READ; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: NAPOT read at start of region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: NAPOT read should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_addr_i[0] = 34'h0400FF; pmp_req_type_i[0] = PMP_ACC_WRITE; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: NAPOT write at end of region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: NAPOT write should be allowed", test_count); fail_count++;
        end
        
        test_count++; pmp_req_addr_i[0] = 34'h040100; pmp_req_type_i[0] = PMP_ACC_READ; #1;
        if (pmp_req_err_o[0] == 1'b1) begin
            $display("[PASS] Test %0d: NAPOT access denied outside region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: NAPOT access should be denied", test_count); fail_count++;
        end
        
        // =====================================================================
        // Test 6: Lock Bit
        // =====================================================================
        $display("\n--- Test 6: Lock Bit Functionality ---");
        
        for (i = 0; i < PMPNumRegions; i++) begin
            csr_pmp_cfg_i[i].mode = PMP_MODE_OFF;
        end
        $display("       Configuring locked TOR region, RWX");
        csr_pmp_cfg_i[0].mode = PMP_MODE_TOR; csr_pmp_cfg_i[0].read = 1'b1;
        csr_pmp_cfg_i[0].write = 1'b1; csr_pmp_cfg_i[0].exec = 1'b1; csr_pmp_cfg_i[0].lock = 1'b1;
        csr_pmp_addr_i[0] = 34'h080000;
        csr_pmp_cfg_i[1].mode = PMP_MODE_TOR; csr_pmp_cfg_i[1].read = 1'b1;
        csr_pmp_cfg_i[1].write = 1'b1; csr_pmp_cfg_i[1].exec = 1'b1; csr_pmp_cfg_i[1].lock = 1'b1;
        csr_pmp_addr_i[1] = 34'h0C0000;
        #1;
        
        test_count++; pmp_req_addr_i[0] = 34'h090000; pmp_req_type_i[0] = PMP_ACC_READ;
        priv_mode_i[0] = PRIV_LVL_U; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: Lock U-mode access allowed in locked region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Lock U-mode should be allowed", test_count); fail_count++;
        end
        
        test_count++; priv_mode_i[0] = PRIV_LVL_M; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: Lock M-mode access allowed in locked region", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Lock M-mode should be allowed", test_count); fail_count++;
        end
        
        // =====================================================================
        // Test 7: Debug Mode
        // =====================================================================
        $display("\n--- Test 7: Debug Mode Bypass ---");
        
        for (i = 0; i < PMPNumRegions; i++) begin
            csr_pmp_cfg_i[i].mode = PMP_MODE_OFF;
        end
        debug_mode_i = 1'b1;
        
        test_count++; pmp_req_addr_i[0] = {2'b0, DmBaseAddr}; pmp_req_type_i[0] = PMP_ACC_READ;
        priv_mode_i[0] = PRIV_LVL_M; #1;
        if (pmp_req_err_o[0] == 1'b0) begin
            $display("[PASS] Test %0d: Debug mode access to DM allowed", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Debug mode should allow DM access", test_count); fail_count++;
        end
        
        debug_mode_i = 1'b0;
        
        // =====================================================================
        // Test 8: Multi-Channel
        // =====================================================================
        $display("\n--- Test 8: Multi-Channel Simultaneous Access ---");
        
        csr_pmp_cfg_i[0].mode = PMP_MODE_TOR; csr_pmp_cfg_i[0].read = 1'b1;
        csr_pmp_cfg_i[0].write = 1'b0; csr_pmp_cfg_i[0].exec = 1'b1;
        csr_pmp_addr_i[0] = 34'h040000;
        csr_pmp_cfg_i[1].mode = PMP_MODE_TOR; csr_pmp_cfg_i[1].read = 1'b1;
        csr_pmp_cfg_i[1].write = 1'b0; csr_pmp_cfg_i[1].exec = 1'b1;
        csr_pmp_addr_i[1] = 34'h080000;
        
        test_count++; pmp_req_addr_i[0] = 34'h050000; pmp_req_type_i[0] = PMP_ACC_READ;
        pmp_req_addr_i[1] = 34'h050000; pmp_req_type_i[1] = PMP_ACC_WRITE;
        priv_mode_i[0] = PRIV_LVL_U; priv_mode_i[1] = PRIV_LVL_U; #1;
        if (pmp_req_err_o[0] == 1'b0 && pmp_req_err_o[1] == 1'b1) begin
            $display("[PASS] Test %0d: Multi-channel access correct", test_count); pass_count++;
        end else begin
            $display("[FAIL] Test %0d: Multi-channel wrong (ch0=%0b, ch1=%0b)", 
                     test_count, pmp_req_err_o[0], pmp_req_err_o[1]); fail_count++;
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
