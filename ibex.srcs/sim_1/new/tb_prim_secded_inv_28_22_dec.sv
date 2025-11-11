`timescale 1ns / 1ps

module tb_prim_secded_inv_28_22_dec;

    // Testbench signals
    logic [27:0] data_i;
    logic [21:0] data_o;
    logic [5:0]  syndrome_o;
    logic [1:0]  err_o;
    
    // Expected outputs
    logic [21:0] expected_data_o;
    logic [5:0]  expected_syndrome_o;
    logic [1:0]  expected_err_o;
    
    // Test statistics
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // Instantiate DUT
    prim_secded_inv_28_22_dec dut (
        .data_i(data_i),
        .data_o(data_o),
        .syndrome_o(syndrome_o),
        .err_o(err_o)
    );
    
    // Encoder function to generate valid codewords (static)
    function logic [27:0] encode_data;
        input logic [21:0] data_in;
        logic [27:0] temp;
        begin
            temp = 28'(data_in);
            temp[22] = ^(temp & 28'h03003FF);
            temp[23] = ^(temp & 28'h010FC0F);
            temp[24] = ^(temp & 28'h0271C71);
            temp[25] = ^(temp & 28'h03B6592);
            temp[26] = ^(temp & 28'h03DAAA4);
            temp[27] = ^(temp & 28'h03ED348);
            temp = temp ^ 28'hA800000;
            encode_data = temp;
        end
    endfunction
    
    // Function to calculate expected syndrome (static)
    function logic [5:0] calc_syndrome;
        input logic [27:0] data_in;
        logic [5:0] synd;
        logic [27:0] uninverted;
        begin
            uninverted = data_in ^ 28'hA800000;
            synd[0] = ^(uninverted & 28'h07003FF);
            synd[1] = ^(uninverted & 28'h090FC0F);
            synd[2] = ^(uninverted & 28'h1271C71);
            synd[3] = ^(uninverted & 28'h23B6592);
            synd[4] = ^(uninverted & 28'h43DAAA4);
            synd[5] = ^(uninverted & 28'h83ED348);
            calc_syndrome = synd;
        end
    endfunction
    
    // Function to calculate expected data output with correction (static)
    function logic [21:0] calc_corrected_data;
        input logic [27:0] data_in;
        input logic [5:0] synd;
        logic [21:0] corrected;
        begin
            corrected[0]  = (synd == 6'h07) ^ data_in[0];
            corrected[1]  = (synd == 6'h0b) ^ data_in[1];
            corrected[2]  = (synd == 6'h13) ^ data_in[2];
            corrected[3]  = (synd == 6'h23) ^ data_in[3];
            corrected[4]  = (synd == 6'h0d) ^ data_in[4];
            corrected[5]  = (synd == 6'h15) ^ data_in[5];
            corrected[6]  = (synd == 6'h25) ^ data_in[6];
            corrected[7]  = (synd == 6'h19) ^ data_in[7];
            corrected[8]  = (synd == 6'h29) ^ data_in[8];
            corrected[9]  = (synd == 6'h31) ^ data_in[9];
            corrected[10] = (synd == 6'h0e) ^ data_in[10];
            corrected[11] = (synd == 6'h16) ^ data_in[11];
            corrected[12] = (synd == 6'h26) ^ data_in[12];
            corrected[13] = (synd == 6'h1a) ^ data_in[13];
            corrected[14] = (synd == 6'h2a) ^ data_in[14];
            corrected[15] = (synd == 6'h32) ^ data_in[15];
            corrected[16] = (synd == 6'h1c) ^ data_in[16];
            corrected[17] = (synd == 6'h2c) ^ data_in[17];
            corrected[18] = (synd == 6'h34) ^ data_in[18];
            corrected[19] = (synd == 6'h38) ^ data_in[19];
            corrected[20] = (synd == 6'h3b) ^ data_in[20];
            corrected[21] = (synd == 6'h3d) ^ data_in[21];
            calc_corrected_data = corrected;
        end
    endfunction
    
    // Function to calculate expected error flags (static)
    function logic [1:0] calc_error_flags;
        input logic [5:0] synd;
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
        input logic [21:0] original_data;
        input logic [27:0] input_codeword;
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
                    $display("[PASS] Test %4d: %-45s | Errors=%0d | Syndrome=0x%02h | Err=%0d%0d | Data=0x%06h", 
                             test_count, test_name, error_count, syndrome_o, err_o[1], err_o[0], data_o);
                end
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test %4d: %-45s", test_count, test_name);
                $display("       Input=0x%07h | Original=0x%06h | Errors=%0d", input_codeword, original_data, error_count);
                $display("       Expected: Data=0x%06h Syndrome=0x%02h Err=%0d%0d", 
                         expected_data_o, expected_syndrome_o, expected_err_o[1], expected_err_o[0]);
                $display("       Got:      Data=0x%06h Syndrome=0x%02h Err=%0d%0d", 
                         data_o, syndrome_o, err_o[1], err_o[0]);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        logic [21:0] test_data;
        logic [27:0] encoded;
        logic [27:0] corrupted;
        integer i, j, bit_pos, error_bit1, error_bit2;
        integer p, bit1, bit2, data_bit, parity_bit;
        
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================================================");
        $display("  SECDED Inverted (28,22) Decoder Testbench for IBEX ICache");
        $display("========================================================================\n");
        
        // =====================================================================
        // Test Category 1: No Error Cases
        // =====================================================================
        $display("--- Category 1: No Error Cases (Valid Codewords) ---");
        
        test_data = 22'h000000;
        data_i = encode_data(test_data);
        check_outputs("No Error - All Zeros", test_data, data_i, 0);
        
        test_data = 22'h3FFFFF;
        data_i = encode_data(test_data);
        check_outputs("No Error - All Ones", test_data, data_i, 0);
        
        test_data = 22'h2AAAAA;
        data_i = encode_data(test_data);
        check_outputs("No Error - Alternating 10", test_data, data_i, 0);
        
        test_data = 22'h155555;
        data_i = encode_data(test_data);
        check_outputs("No Error - Alternating 01", test_data, data_i, 0);
        
        // Test several random valid codewords
        test_data = 22'h123456;
        data_i = encode_data(test_data);
        check_outputs("No Error - Random 0x123456", test_data, data_i, 0);
        
        test_data = 22'h0F0F0F;
        data_i = encode_data(test_data);
        check_outputs("No Error - Random 0x0F0F0F", test_data, data_i, 0);
        
        test_data = 22'h30C30C;
        data_i = encode_data(test_data);
        check_outputs("No Error - Random 0x30C30C", test_data, data_i, 0);
        
        test_data = 22'h1A2B3C;
        data_i = encode_data(test_data);
        check_outputs("No Error - Random 0x1A2B3C", test_data, data_i, 0);
        
        $display("       ... %0d no-error tests passed (not all shown)", pass_count);
        
        // =====================================================================
        // Test Category 2: Single Bit Errors in Data Bits (Should Correct)
        // =====================================================================
        $display("\n--- Category 2: Single Bit Errors in Data Bits ---");
        
        // Test single bit error in each data bit position
        for (bit_pos = 0; bit_pos < 22; bit_pos = bit_pos + 1) begin
            test_data = 22'h155555;
            encoded = encode_data(test_data);
            corrupted = encoded ^ (28'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Data Bit", test_data, corrupted, 1);
        end
        
        // Test single bit errors with different data patterns
        test_data = 22'h000000;
        for (bit_pos = 0; bit_pos < 22; bit_pos = bit_pos + 5) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (28'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern All 0s", test_data, corrupted, 1);
        end
        
        test_data = 22'h3FFFFF;
        for (bit_pos = 1; bit_pos < 22; bit_pos = bit_pos + 5) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (28'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern All 1s", test_data, corrupted, 1);
        end
        
        test_data = 22'h2AAAAA;
        for (bit_pos = 2; bit_pos < 22; bit_pos = bit_pos + 5) begin
            encoded = encode_data(test_data);
            corrupted = encoded ^ (28'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Pattern Alt 10", test_data, corrupted, 1);
        end
        
        // =====================================================================
        // Test Category 3: Single Bit Errors in Parity Bits (Should Detect)
        // =====================================================================
        $display("\n--- Category 3: Single Bit Errors in Parity Bits ---");
        
        for (bit_pos = 22; bit_pos < 28; bit_pos = bit_pos + 1) begin
            test_data = 22'h2AAAAA;
            encoded = encode_data(test_data);
            corrupted = encoded ^ (28'h1 << bit_pos);
            data_i = corrupted;
            check_outputs("Single Error - Parity Bit", test_data, corrupted, 1);
        end
        
        // =====================================================================
        // Test Category 4: Double Bit Errors (Should Detect, Not Correct)
        // =====================================================================
        $display("\n--- Category 4: Double Bit Errors ---");
        
        // Test various double bit error combinations
        test_data = 22'h123456;
        encoded = encode_data(test_data);
        
        // Adjacent bit errors
        for (bit_pos = 0; bit_pos < 21; bit_pos = bit_pos + 4) begin
            corrupted = encoded ^ (28'h3 << bit_pos);
            data_i = corrupted;
            check_outputs("Double Error - Adjacent Bits", test_data, corrupted, 2);
        end
        
        // Non-adjacent bit errors
        bit1 = 0;
        bit2 = 10;
        corrupted = encoded ^ (28'h1 << bit1) ^ (28'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Bits [0,10]", test_data, corrupted, 2);
        
        bit1 = 5;
        bit2 = 15;
        corrupted = encoded ^ (28'h1 << bit1) ^ (28'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Bits [5,15]", test_data, corrupted, 2);
        
        bit1 = 10;
        bit2 = 20;
        corrupted = encoded ^ (28'h1 << bit1) ^ (28'h1 << bit2);
        data_i = corrupted;
        check_outputs("Double Error - Bits [10,20]", test_data, corrupted, 2);
        
        // Double errors involving parity bits
        test_data = 22'h0F0F0F;
        encoded = encode_data(test_data);
        
        // Data bit + parity bit combinations
        data_bit = 0;
        parity_bit = 22;
        corrupted = encoded ^ (28'h1 << data_bit) ^ (28'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[0] + Parity[22]", test_data, corrupted, 2);
        
        data_bit = 10;
        parity_bit = 25;
        corrupted = encoded ^ (28'h1 << data_bit) ^ (28'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[10] + Parity[25]", test_data, corrupted, 2);
        
        data_bit = 20;
        parity_bit = 27;
        corrupted = encoded ^ (28'h1 << data_bit) ^ (28'h1 << parity_bit);
        data_i = corrupted;
        check_outputs("Double Error - Data[20] + Parity[27]", test_data, corrupted, 2);
        
        // =====================================================================
        // Test Category 5: Edge Cases with Specific Data Patterns
        // =====================================================================
        $display("\n--- Category 5: Edge Cases ---");
        
        // Pattern 1: LSB only
        test_data = 22'h000001;
        data_i = encode_data(test_data);
        check_outputs("Edge - LSB Only - No Error", test_data, data_i, 0);
        encoded = encode_data(test_data);
        corrupted = encoded ^ 28'h1;
        data_i = corrupted;
        check_outputs("Edge - LSB Only - Single Error", test_data, corrupted, 1);
        
        // Pattern 2: MSB only
        test_data = 22'h200000;
        data_i = encode_data(test_data);
        check_outputs("Edge - MSB Only - No Error", test_data, data_i, 0);
        encoded = encode_data(test_data);
        corrupted = encoded ^ (28'h1 << 21);
        data_i = corrupted;
        check_outputs("Edge - MSB Only - Single Error", test_data, corrupted, 1);
        
        // Pattern 3: All except LSB
        test_data = 22'h3FFFFE;
        data_i = encode_data(test_data);
        check_outputs("Edge - All Except LSB - No Error", test_data, data_i, 0);
        
        // Pattern 4: All except MSB
        test_data = 22'h1FFFFF;
        data_i = encode_data(test_data);
        check_outputs("Edge - All Except MSB - No Error", test_data, data_i, 0);
        
        // Pattern 5: Nibble patterns
        test_data = 22'h0F0F0F;
        data_i = encode_data(test_data);
        check_outputs("Edge - Nibble 0F Pattern - No Error", test_data, data_i, 0);
        
        test_data = 22'h30C30C;
        data_i = encode_data(test_data);
        check_outputs("Edge - Nibble 30C Pattern - No Error", test_data, data_i, 0);
        
        // Pattern 6: Common data values
        test_data = 22'h123ABC;
        data_i = encode_data(test_data);
        check_outputs("Edge - Common Value 0x123ABC", test_data, data_i, 0);
        
        test_data = 22'h3EDCBA;
        data_i = encode_data(test_data);
        check_outputs("Edge - Common Value 0x3EDCBA", test_data, data_i, 0);
        
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
