`timescale 1ns / 1ps

module tb_ibex_branch_predict;

    import ibex_pkg::*;
    
    // Clock and reset
    logic        clk_i;
    logic        rst_ni;
    
    // Inputs
    logic [31:0] fetch_rdata_i;
    logic [31:0] fetch_pc_i;
    logic        fetch_valid_i;
    
    // Outputs
    logic        predict_branch_taken_o;
    logic [31:0] predict_branch_pc_o;
    
    // Test statistics
    int test_count;
    int pass_count;
    int fail_count;
    
    // Expected values
    logic        expected_taken;
    logic [31:0] expected_pc;
    
    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end
    
    // DUT instantiation
    ibex_branch_predict dut (
        .clk_i                (clk_i),
        .rst_ni               (rst_ni),
        .fetch_rdata_i        (fetch_rdata_i),
        .fetch_pc_i           (fetch_pc_i),
        .fetch_valid_i        (fetch_valid_i),
        .predict_branch_taken_o(predict_branch_taken_o),
        .predict_branch_pc_o  (predict_branch_pc_o)
    );
    
    // Function to extract B-type immediate (as RTL does for default case)
    function logic [31:0] extract_b_imm;
        input logic [31:0] instr;
        logic [31:0] imm;
        begin
            imm = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
            extract_b_imm = imm;
        end
    endfunction
    
    // Task to perform reset
    task perform_reset;
        begin
            rst_ni = 0;
            fetch_rdata_i = 32'h0;
            fetch_pc_i = 32'h0;
            fetch_valid_i = 0;
            repeat(3) @(posedge clk_i);
            rst_ni = 1;
            @(posedge clk_i);
        end
    endtask
    
    // Task to check prediction
    task check_prediction;
        input string test_name;
        input logic [31:0] instruction;
        input logic [31:0] pc;
        input logic valid;
        input logic exp_taken;
        input logic [31:0] exp_target;
        begin
            test_count = test_count + 1;
            
            fetch_rdata_i = instruction;
            fetch_pc_i = pc;
            fetch_valid_i = valid;
            expected_taken = exp_taken;
            expected_pc = exp_target;
            
            @(posedge clk_i);
            #1; // Small delay for combinational logic
            
            if (predict_branch_taken_o === expected_taken && 
                predict_branch_pc_o === expected_pc) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       Instruction=0x%08h, PC=0x%08h", instruction, pc);
                $display("       Expected: taken=%0d, target=0x%08h", expected_taken, expected_pc);
                $display("       Got:      taken=%0d, target=0x%08h", 
                         predict_branch_taken_o, predict_branch_pc_o);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Corrected function to create JAL instruction
    function logic [31:0] create_jal;
        input logic [4:0] rd;
        input logic signed [20:0] imm;
        logic [31:0] instr;
        logic [20:0] imm_unsigned;
        begin
            imm_unsigned = imm[20:0];
            instr[31] = imm_unsigned[20];
            instr[30:21] = imm_unsigned[10:1];
            instr[20] = imm_unsigned[11];
            instr[19:12] = imm_unsigned[19:12];
            instr[11:7] = rd;
            instr[6:0] = 7'h6F;
            create_jal = instr;
        end
    endfunction
    
    // Corrected function to create branch instruction
    function logic [31:0] create_branch;
        input logic [2:0] funct3;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic signed [12:0] imm;
        logic [31:0] instr;
        logic [12:0] imm_unsigned;
        begin
            imm_unsigned = imm[12:0];
            instr[31] = imm_unsigned[12];
            instr[30:25] = imm_unsigned[10:5];
            instr[24:20] = rs2;
            instr[19:15] = rs1;
            instr[14:12] = funct3;
            instr[11:8] = imm_unsigned[4:1];
            instr[7] = imm_unsigned[11];
            instr[6:0] = 7'h63;
            create_branch = instr;
        end
    endfunction
    
    // Corrected function to create compressed jump
    function logic [31:0] create_c_j;
        input logic signed [11:0] imm;
        input logic is_cjal;
        logic [15:0] instr;
        logic [11:0] imm_unsigned;
        begin
            imm_unsigned = imm[11:0];
            instr[15:13] = is_cjal ? 3'b001 : 3'b101;
            instr[12] = imm_unsigned[11];
            instr[11] = imm_unsigned[4];
            instr[10:9] = imm_unsigned[9:8];
            instr[8] = imm_unsigned[10];
            instr[7] = imm_unsigned[6];
            instr[6] = imm_unsigned[7];
            instr[5:3] = imm_unsigned[3:1];
            instr[2] = imm_unsigned[5];
            instr[1:0] = 2'b01;
            create_c_j = {16'h0, instr};
        end
    endfunction
    
    // Corrected function to create compressed branch
    function logic [31:0] create_c_branch;
        input logic is_bnez;
        input logic [2:0] rs1_prime;
        input logic signed [8:0] imm;
        logic [15:0] instr;
        logic [8:0] imm_unsigned;
        begin
            imm_unsigned = imm[8:0];
            instr[15:13] = is_bnez ? 3'b111 : 3'b110;
            instr[12] = imm_unsigned[8];
            instr[11:10] = imm_unsigned[4:3];
            instr[9:7] = rs1_prime;
            instr[6:5] = imm_unsigned[7:6];
            instr[4:3] = imm_unsigned[2:1];
            instr[2] = imm_unsigned[5];
            instr[1:0] = 2'b01;
            create_c_branch = {16'h0, instr};
        end
    endfunction
    
    // Main test sequence
    initial begin
        logic [31:0] add_instr, lw_instr, b_imm;
        
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n========================================================================");
        $display("  IBEX Branch Predictor Testbench");
        $display("========================================================================\n");
        
        perform_reset();
        
        // =====================================================================
        // Test 1: Fetch Invalid
        // =====================================================================
        $display("--- Test Category 1: Invalid Fetch ---");
        
        check_prediction("Invalid fetch - JAL ignored",
                        create_jal(5'd1, 21'sd256),
                        32'h1000,
                        1'b0,
                        1'b0,
                        32'h1100);
        
        // =====================================================================
        // Test 2: JAL Instructions
        // =====================================================================
        $display("\n--- Test Category 2: JAL Instructions (Always Taken) ---");
        
        check_prediction("JAL forward jump +256",
                        create_jal(5'd1, 21'sd256),
                        32'h1000,
                        1'b1,
                        1'b1,
                        32'h1100);
        
        check_prediction("JAL backward jump -256",
                        create_jal(5'd1, -21'sd256),
                        32'h1000,
                        1'b1,
                        1'b1,
                        32'h0F00);
        
        check_prediction("JAL small forward +8",
                        create_jal(5'd1, 21'sd8),
                        32'h2000,
                        1'b1,
                        1'b1,
                        32'h2008);
        
        check_prediction("JAL zero offset (infinite loop)",
                        create_jal(5'd1, 21'sd0),
                        32'h3000,
                        1'b1,
                        1'b1,
                        32'h3000);
        
        // =====================================================================
        // Test 3: Forward Branches
        // =====================================================================
        $display("\n--- Test Category 3: Forward Branches (Not Taken) ---");
        
        check_prediction("BEQ forward +128 (not taken)",
                        create_branch(3'b000, 5'd2, 5'd3, 13'sd128),
                        32'h4000,
                        1'b1,
                        1'b0,
                        32'h4080);
        
        check_prediction("BNE forward +64 (not taken)",
                        create_branch(3'b001, 5'd4, 5'd5, 13'sd64),
                        32'h5000,
                        1'b1,
                        1'b0,
                        32'h5040);
        
        check_prediction("BLT forward +32 (not taken)",
                        create_branch(3'b100, 5'd6, 5'd7, 13'sd32),
                        32'h6000,
                        1'b1,
                        1'b0,
                        32'h6020);
        
        // =====================================================================
        // Test 4: Backward Branches
        // =====================================================================
        $display("\n--- Test Category 4: Backward Branches (Taken) ---");
        
        check_prediction("BEQ backward -128 (taken)",
                        create_branch(3'b000, 5'd2, 5'd3, -13'sd128),
                        32'h5000,
                        1'b1,
                        1'b1,
                        32'h4F80);
        
        check_prediction("BNE backward -64 (taken)",
                        create_branch(3'b001, 5'd4, 5'd5, -13'sd64),
                        32'h6000,
                        1'b1,
                        1'b1,
                        32'h5FC0);
        
        check_prediction("BGE backward -32 (taken)",
                        create_branch(3'b101, 5'd8, 5'd9, -13'sd32),
                        32'h7000,
                        1'b1,
                        1'b1,
                        32'h6FE0);
        
        check_prediction("BLTU backward -16 (taken)",
                        create_branch(3'b110, 5'd10, 5'd11, -13'sd16),
                        32'h8000,
                        1'b1,
                        1'b1,
                        32'h7FF0);
        
        // =====================================================================
        // Test 5: Compressed Jumps
        // =====================================================================
        $display("\n--- Test Category 5: Compressed Jump C.J (Always Taken) ---");
        
        check_prediction("C.J forward +128",
                        create_c_j(12'sd128, 1'b0),
                        32'h9000,
                        1'b1,
                        1'b1,
                        32'h9080);
        
        check_prediction("C.J backward -128",
                        create_c_j(-12'sd128, 1'b0),
                        32'hA000,
                        1'b1,
                        1'b1,
                        32'h9F80);
        
        check_prediction("C.JAL forward +64",
                        create_c_j(12'sd64, 1'b1),
                        32'hB000,
                        1'b1,
                        1'b1,
                        32'hB040);
        
        // =====================================================================
        // Test 6: Compressed Forward Branches
        // =====================================================================
        $display("\n--- Test Category 6: Compressed Forward Branches (Not Taken) ---");
        
        check_prediction("C.BEQZ forward +32 (not taken)",
                        create_c_branch(1'b0, 3'd2, 9'sd32),
                        32'hC000,
                        1'b1,
                        1'b0,
                        32'hC020);
        
        check_prediction("C.BNEZ forward +64 (not taken)",
                        create_c_branch(1'b1, 3'd3, 9'sd64),
                        32'hD000,
                        1'b1,
                        1'b0,
                        32'hD040);
        
        // =====================================================================
        // Test 7: Compressed Backward Branches
        // =====================================================================
        $display("\n--- Test Category 7: Compressed Backward Branches (Taken) ---");
        
        check_prediction("C.BEQZ backward -32 (taken)",
                        create_c_branch(1'b0, 3'd4, -9'sd32),
                        32'hE000,
                        1'b1,
                        1'b1,
                        32'hDFE0);
        
        check_prediction("C.BNEZ backward -64 (taken)",
                        create_c_branch(1'b1, 3'd5, -9'sd64),
                        32'hF000,
                        1'b1,
                        1'b1,
                        32'hEFC0);
        
        // =====================================================================
        // Test 8: Non-Branch Instructions (Account for B-type extraction)
        // =====================================================================
        $display("\n--- Test Category 8: Non-Branch Instructions (Not Taken) ---");
        
        // ADD instruction - RTL extracts B-type imm by default
        add_instr = 32'h003100B3; // add x1, x2, x3
        b_imm = extract_b_imm(add_instr);
        check_prediction("ADD (not a branch)",
                        add_instr,
                        32'h10000,
                        1'b1,
                        1'b0,
                        32'h10000 + b_imm); // PC + extracted B-imm
        
        // LW instruction - RTL extracts B-type imm by default
        lw_instr = 32'h00012083; // lw x1, 0(x2)
        b_imm = extract_b_imm(lw_instr);
        check_prediction("LW (not a branch)",
                        lw_instr,
                        32'h11000,
                        1'b1,
                        1'b0,
                        32'h11000 + b_imm); // PC + extracted B-imm
        
        // NOP
        check_prediction("NOP (not a branch)",
                        32'h00000013,
                        32'h12000,
                        1'b1,
                        1'b0,
                        32'h12000);
        
        // =====================================================================
        // Test 9: Edge Cases
        // =====================================================================
        $display("\n--- Test Category 9: Edge Cases ---");
        
        check_prediction("Branch max forward offset",
                        create_branch(3'b000, 5'd1, 5'd2, 13'sd4094),
                        32'h20000,
                        1'b1,
                        1'b0,
                        32'h20FFE);
        
        check_prediction("Branch max backward offset",
                        create_branch(3'b000, 5'd1, 5'd2, -13'sd4096),
                        32'h30000,
                        1'b1,
                        1'b1,
                        32'h2F000);
        
        check_prediction("Branch smallest forward +2",
                        create_branch(3'b000, 5'd1, 5'd2, 13'sd2),
                        32'h40000,
                        1'b1,
                        1'b0,
                        32'h40002);
        
        check_prediction("JAL to self (tight loop)",
                        create_jal(5'd0, 21'sd0),
                        32'h50000,
                        1'b1,
                        1'b1,
                        32'h50000);
        
        // =====================================================================
        // Test 10: Various PC Values
        // =====================================================================
        $display("\n--- Test Category 10: Various PC Values ---");
        
        check_prediction("JAL from PC=0",
                        create_jal(5'd1, 21'sd256),
                        32'h0,
                        1'b1,
                        1'b1,
                        32'h100);
        
        // Branch from high PC - corrected to -257 for proper alignment
        check_prediction("Branch from high PC",
                        create_branch(3'b000, 5'd1, 5'd2, -13'sd256),
                        32'hFFFFF000,
                        1'b1,
                        1'b1,
                        32'hFFFFF000 - 32'd256); // Explicit 32-bit arithmetic
        
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
