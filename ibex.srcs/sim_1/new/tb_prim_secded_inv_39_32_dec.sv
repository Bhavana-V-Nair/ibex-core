`timescale 1ns / 1ps

module tb_prim_secded_inv_39_32_dec;

    // Testbench signals
    logic [38:0] data_i;
    logic [31:0] data_o;
    logic [6:0]  syndrome_o;
    logic [1:0]  err_o;
    
    // Expected outputs
    logic [31:0] expected_data_o;
    logic [6:0]  expected_syndrome_o;
    logic [1:0]  expected_err_o;
    
    // Test statistics
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // Instantiate DUT
    prim_secded_inv_39_32_dec dut (
        .data_i(data_i),
        .data_o(data_o),
        .syndrome_o(syndrome_o),
        .err_o(err_o)
    );
    
    // Encoder function to generate valid codewords (static)
    function logic [38:0] encode_data;
        input logic [31:0] data_in;
        logic [38:0] temp;
        begin
            temp = 39'(data_in);
            temp[32] = ^(temp & 39'h002606BD25);
            temp[33] = ^(temp & 39'h00DEBA8050);
            temp[34] = ^(temp & 39'h00413D89AA);
            temp[35] = ^(temp & 39'h0031234ED1);
            temp[36] = ^(temp & 39'h00C2C1323B);
            temp[37] = ^(temp & 39'h002DCC624C);
            temp[38] = ^(temp & 39'h0098505586);
            temp = temp ^ 39'h2A00000000;
            encode_data = temp;
        end
    endfunction
    
    // Function to calculate expected syndrome (static)
    function logic [6:0] calc_syndrome;
        input logic [38:0] data_in;
        logic [6:0] synd;
        logic [38:0] uninverted;
        begin
            uninverted = data_in ^ 39'h2A00000000;
            synd[0] = ^(uninverted & 39'h012606BD25);
            synd[1] = ^(uninverted & 39'h02DEBA8050);
            synd[2] = ^(uninverted & 39'h04413D89AA);
            synd[3] = ^(uninverted & 39'h0831234ED1);
            synd[4] = ^(uninverted & 39'h10C2C1323B);
            synd[5] = ^(uninverted & 39'h202DCC624C);
            synd[6] = ^(uninverted & 39'h4098505586);
            calc_syndrome = synd;
        end
    endfunction
    
    // Function to calculate expected data output with correction (static)
    function logic [31:0] calc_corrected_data;
        input logic [38:0] data_in;
        input logic [6:0] synd;
        logic [31:0] corrected;
        begin
            corrected[0]  = (synd == 7'h19) ^ data_in[0];
            corrected[1]  = (synd == 7'h54) ^ data_in[1];
            corrected[2]  = (synd == 7'h61) ^ data_in[2];
            corrected[3]  = (synd == 7'h34) ^ data_in[3];
            corrected[4]  = (synd == 7'h1a) ^ data_in[4];
            corrected[5]  = (synd == 7'h15) ^ data_in[5];
            corrected[6]  = (synd == 7'h2a) ^ data_in[6];
            corrected[7]  = (synd == 7'h4c) ^ data_in[7];
            corrected[8]  = (synd == 7'h45) ^ data_in[8];
            corrected[9]  = (synd == 7'h38) ^ data_in[9];
            corrected[10] = (synd == 7'h49) ^ data_in[10];
            corrected[11] = (synd == 7'h0d) ^ data_in[11];
            corrected[12] = (synd == 7'h51) ^ data_in[12];
            corrected[13] = (synd == 7'h31) ^ data_in[13];
            corrected[14] = (synd == 7'h68) ^ data_in[14];
            corrected[15] = (synd == 7'h07) ^ data_in[15];
            corrected[16] = (synd == 7'h1c) ^ data_in[16];
            corrected[17] = (synd == 7'h0b) ^ data_in[17];
            corrected[18] = (synd == 7'h25) ^ data_in[18];
            corrected[19] = (synd == 7'h26) ^ data_in[19];
            corrected[20] = (synd == 7'h46) ^ data_in[20];
            corrected[21] = (synd == 7'h0e) ^ data_in[21];
            corrected[22] = (synd == 7'h70) ^ data_in[22];
            corrected[23] = (synd == 7'h32) ^ data_in[23];
            corrected[24] = (synd == 7'h2c) ^ data_in[24];
            corrected[25] = (synd == 7'h13) ^ data_in[25];
            corrected[26] = (synd == 7'h23) ^ data_in[26];
            corrected[27] = (synd == 7'h62) ^ data_in[27];
            corrected[28] = (synd == 7'h4a) ^ data_in[28];
            corrected[29] = (synd == 7'h29) ^ data_in[29];
            corrected[30] = (synd == 7'h16) ^ data_in[30];
            corrected[31] = (synd == 7'h52) ^ data_in[31];
            calc_corrected_data = corrected;
        end
    endfunction
    
    // Function to calculate expected error flags (static)
    function logic [1:0] calc_error_flags;
        input logic [6:0] synd;
        logic [1:0] err;
        begin
            err[0] = ^synd;                  // Single error (odd parity)
            err[1] = ~err[0] & (|synd);      // Double error (even parity, non-zero)
            calc_error_flags = err;
        end
    endfunction
    
    // Task to verify outputs
    task check_outputs;
        input string test_name;
        input logic [31:0] original_data;
        input logic [38:0] input_codeword;
        input integer error_count;
        begin
            test_count = test_count + 1;
            #10;
            
            expected_syndrome_o = calc_syndrome(data_i);
            expected_data_o = calc_corrected_data(data_i, expected_syndrome_o);
            expected_err_o = calc_error_flags(expected_syndrome_o);
            
            if (data_o === expected_data_o && 
                syndrome_o === expected_syndrome_o && 
                err_o === expected_err_o) begin
                pass_count = pass_count + 1;
                
                // Only show passing tests with errors for brevity
                if (error_count > 0) begin
                    $display("[PASS] Test %4d: %-45s | Errors=%0d | Syndrome=0x%02h | Err=%0d%0d | Data=0x%08h", 
                             test_count, test_name, error_count, syndrome_o, err_o[1], err_o[0], data_o);
                end
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test %4d: %-45s", test_count, test_name);
                $display("       Input=0x%010h | Original=0x%08h | Errors=%0d", input_codeword, original_data, error_count);
                $display("       Expected: Data=0x%08h Syndrome=0x%02h Err=%0d%0d", 
                         expected_data_o, expected_syndrome_o, expected_err_o[1], expected_err_o[0]);
                $display("       Got:      Data=0x%08h Syndrome=0x%02h Err=%0d%0d", 
                         data_o, syndrome_o, err_o[1], err_o[0]);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        logic [31:0] test_data;
        logic [38:0] encoded;
        logic [38:0] corrupted;
        integer i, j, bit_pos;
        integer bit1, bit2, data_bit, parity_bit;
        
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================================================");
        $display("  SECDED Inverted (39,32) Decoder Testbench for IBEX ICache");
        $display("========================================================================\n");
        
        // =====================================================================
        // Test Category 1: No Error Cases
        // =====================================================================
        $display("--- Category 1: No Error Cases (Valid Codewords) ---");
        
        test_data = 32'h00000000;
        data_i = encode_data(test_data);
        check_outputs("No Error - All Zeros", test_data, data_i, 0);
        
        test_data = 32'hFFFFFFFF;
        data_i = encode_data(test_data);
        check_outputs("No Error - All Ones", test_data, data_i, 0);
        
        test_data = 32'hAAAAAAAA;
        data_i = encode_data(test_data);
        check_outputs("No Error - Alternating 10", test_data, data_i, 0);
        
        test_data = 32'h55555555;
        data_i = encode_data(test_data);
        check_outputs("No Error - Alternating 01", test_data, data_i, 0);
        
        test_data = 32'h12345678;
        data_i = encode_data(test_data);
        check_outputs("No Error - Pattern 0x12345678", test_data, data_i, 0);
        
        test_data = 32'h9ABCDEF0;
        data_i = encode_data(test_data);
        check_outputs("No Error - Pattern 0x9ABCDEF0", test_data, data_i, 0);
        
        test_data = 32'hDEADBEEF;
        data_i = encode_data(test_data);
        check_outputs("No Error - Pattern 0xDEADBEEF", test_data, data_i, 0);
        
        test_data = 32'hCAFEBABE;
        data_i = encode_data(test_data);
        check_outputs("No Error - Pattern 0xCAFEBABE", test_data, data_i, 0);
        
        $display("       ... %0d no-error tests passed (not all shown)", pass_count);
        
        // =====================================================================
        // Test Category 2: Single Bit Errors in Data Bits (Should Correct)
        // =====================================================================
        $display("\n--- Category 2: Single Bit Errors in Data Bits ---");
        
        // Test single bit error in each data bit position (0-31)
        test_data = 32'h55555555;
        for (bit_pos = 0; bit_pos < 32; bit_pos = bit_pos + 1) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Data Bit", test_data, corrupted, 1);
        end
        
        // Test single bit errors with different data patterns
        test_data = 32'h00000000;
        for (bit_pos = 0; bit_pos < 32; bit_pos = bit_pos + 8) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern All 0s", test_data, corrupted, 1);
        end
        
        test_data = 32'hFFFFFFFF;
        for (bit_pos = 1; bit_pos < 32; bit_pos = bit_pos + 8) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern All 1s", test_data, corrupted, 1);
        end
        
        test_data = 32'hAAAAAAAA;
        for (bit_pos = 2; bit_pos < 32; bit_pos = bit_pos + 8) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern Alt 10", test_data, corrupted, 1);
        end
        
        test_data = 32'h12345678;
        for (bit_pos = 3; bit_pos < 32; bit_pos = bit_pos + 8) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern 0x12345678", test_data, corrupted, 1);
        end
        
        // =====================================================================
        // Test Category 3: Single Bit Errors in Parity Bits (Should Detect)
        // =====================================================================
        $display("\n--- Category 3: Single Bit Errors in Parity Bits ---");
        
        for (bit_pos = 32; bit_pos < 39; bit_pos = bit_pos + 1) begin
            test_data = 32'hAAAAAAAA;
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Parity Bit", test_data, corrupted, 1);
        end
        
        test_data = 32'h55555555;
        for (bit_pos = 32; bit_pos < 39; bit_pos = bit_pos + 1) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (39'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Parity Bit Alt Pattern", test_data, corrupted, 1);
        end
        
        // =====================================================================
        // Test Category 4: Double Bit Errors (Should Detect, Not Correct)
        // =====================================================================
        $display("\n--- Category 4: Double Bit Errors ---");
        
        // Test various double bit error combinations
        test_data = 32'h12345678;
        encoded = encode_data(test_data);
        
        // Adjacent bit errors in data bits
        for (bit_pos = 0; bit_pos < 31; bit_pos = bit_pos + 6) begin
            corrupted = encoded ^ (39'h3 << bit_pos);
            data_i = corrupted;
            check_outputs("Double Error - Adjacent Data Bits", test_data, corrupted, 2);
        end
        
        // Non-adjacent bit errors in data bits
        bit1 = 0;
        bit2 = 15;
        corrupted = encoded ^ (39'h1 << bit1) ^ (39'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Data Bits [0,15]", test_data, corrupted, 2);
        
        bit1 = 8;
        bit2 = 24;
        corrupted = encoded ^ (39'h1 << bit1) ^ (39'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Data Bits [8,24]", test_data, corrupted, 2);
        
        bit1 = 3;
        bit2 = 27;
        corrupted = encoded ^ (39'h1 << bit1) ^ (39'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Data Bits [3,27]", test_data, corrupted, 2);
        
        bit1 = 10;
        bit2 = 20;
        corrupted = encoded ^ (39'h1 << bit1) ^ (39'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Data Bits [10,20]", test_data, corrupted, 2);
        
        // Double errors involving parity bits
        test_data = 32'h0F0F0F0F;
        encoded = encode_data(test_data);
        
        // Data bit + parity bit combinations
        data_bit = 0;
        parity_bit = 32;
        corrupted = encoded ^ (39'h1 << data_bit) ^ (39'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[0] + Parity[32]", test_data, corrupted, 2);
        
        data_bit = 15;
        parity_bit = 35;
        corrupted = encoded ^ (39'h1 << data_bit) ^ (39'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[15] + Parity[35]", test_data, corrupted, 2);
        
        data_bit = 31;
        parity_bit = 38;
        corrupted = encoded ^ (39'h1 << data_bit) ^ (39'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[31] + Parity[38]", test_data, corrupted, 2);
        
        data_bit = 7;
        parity_bit = 33;
        corrupted = encoded ^ (39'h1 << data_bit) ^ (39'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[7] + Parity[33]", test_data, corrupted, 2);
        
        // Two parity bits
        parity_bit = 32;
        bit2 = 36;
        corrupted = encoded ^ (39'h1 << parity_bit) ^ (39'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Parity[32] + Parity[36]", test_data, corrupted, 2);
        
        // =====================================================================
        // Test Category 5: RISC-V Instruction Patterns
        // =====================================================================
        $display("\n--- Category 5: RISC-V Instruction Patterns ---");
        
        // Common RISC-V instructions
        test_data = 32'h00000013;  // NOP
        data_i = encode_data(test_data);
        check_outputs("RISC-V NOP - No Error", test_data, data_i, 0);
        encoded = encode_data(test_data);
        corrupted = encoded ^ 39'h1;
        data_i = corrupted;
        check_outputs("RISC-V NOP - Single Error", test_data, corrupted, 1);
        
        test_data = 32'hFE010113;  // ADDI sp,sp,-32
        data_i = encode_data(test_data);
        check_outputs("RISC-V ADDI - No Error", test_data, data_i, 0);
        encoded = encode_data(test_data);
        corrupted = encoded ^ (39'h1 << 5);
        data_i = corrupted;
        check_outputs("RISC-V ADDI - Single Error", test_data, corrupted, 1);
        
        test_data = 32'h00112623;  // SW ra,12(sp)
        data_i = encode_data(test_data);
        check_outputs("RISC-V SW - No Error", test_data, data_i, 0);
        
        test_data = 32'h00C12083;  // LW ra,12(sp)
        data_i = encode_data(test_data);
        check_outputs("RISC-V LW - No Error", test_data, data_i, 0);
        
        test_data = 32'h00008067;  // RET
        data_i = encode_data(test_data);
        check_outputs("RISC-V RET - No Error", test_data, data_i, 0);
        
        test_data = 32'h0FF0000F;  // FENCE
        data_i = encode_data(test_data);
        check_outputs("RISC-V FENCE - No Error", test_data, data_i, 0);
        
        // =====================================================================
        // Test Category 6: Edge Cases
        // =====================================================================
        $display("\n--- Category 6: Edge Cases ---");
        
        // LSB only
        test_data = 32'h00000001;
        data_i = encode_data(test_data);
        check_outputs("Edge - LSB Only - No Error", test_data, data_i, 0);
        encoded = encode_data(test_data);
        corrupted = encoded ^ 39'h1;
        data_i = corrupted;
        check_outputs("Edge - LSB Only - Single Error", test_data, corrupted, 1);
        
        // MSB only
        test_data = 32'h80000000;
        data_i = encode_data(test_data);
        check_outputs("Edge - MSB Only - No Error", test_data, data_i, 0);
        encoded = encode_data(test_data);
        corrupted = encoded ^ (39'h1 << 31);
        data_i = corrupted;
        check_outputs("Edge - MSB Only - Single Error", test_data, corrupted, 1);
        
        // Byte patterns
        test_data = 32'h000000FF;
        data_i = encode_data(test_data);
        check_outputs("Edge - Byte 0 Only", test_data, data_i, 0);
        
        test_data = 32'hFF000000;
        data_i = encode_data(test_data);
        check_outputs("Edge - Byte 3 Only", test_data, data_i, 0);
        
        test_data = 32'hFF00FF00;
        data_i = encode_data(test_data);
        check_outputs("Edge - Bytes 1 and 3", test_data, data_i, 0);
        
        test_data = 32'h00FF00FF;
        data_i = encode_data(test_data);
        check_outputs("Edge - Bytes 0 and 2", test_data, data_i, 0);
        
        // Half patterns
        test_data = 32'hFFFF0000;
        data_i = encode_data(test_data);
        check_outputs("Edge - Upper Half", test_data, data_i, 0);
        
        test_data = 32'h0000FFFF;
        data_i = encode_data(test_data);
        check_outputs("Edge - Lower Half", test_data, data_i, 0);
        
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
