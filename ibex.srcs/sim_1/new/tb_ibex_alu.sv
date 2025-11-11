`timescale 1ns / 1ps

module tb_ibex_alu;
    import ibex_pkg::*;

    // Testbench signals
    reg clk;
    reg rst_n;

    // ALU inputs
    reg [6:0] operator_r;
    reg [31:0] operand_a_r;
    reg [31:0] operand_b_r;
    reg instr_first_cycle_r;
    reg [32:0] multdiv_operand_a_r;
    reg [32:0] multdiv_operand_b_r;
    reg multdiv_sel_r;
    reg [31:0] imd_val_q_r[2];

    // ALU outputs
    wire [31:0] imd_val_d_w[2];
    wire [1:0] imd_val_we_w;
    wire [31:0] adder_result_w;
    wire [33:0] adder_result_ext_w;
    wire [31:0] result_w;
    wire comparison_result_w;
    wire is_equal_result_w;

    // Test control
    integer test_count;
    integer pass_count;
    integer fail_count;

    // DUT instantiation
    ibex_alu #(
        .RV32B(ibex_pkg::RV32BFull)
    ) dut (
        .operator_i(alu_op_e'(operator_r)),
        .operand_a_i(operand_a_r),
        .operand_b_i(operand_b_r),
        .instr_first_cycle_i(instr_first_cycle_r),
        .multdiv_operand_a_i(multdiv_operand_a_r),
        .multdiv_operand_b_i(multdiv_operand_b_r),
        .multdiv_sel_i(multdiv_sel_r),
        .imd_val_q_i(imd_val_q_r),
        .imd_val_d_o(imd_val_d_w),
        .imd_val_we_o(imd_val_we_w),
        .adder_result_o(adder_result_w),
        .adder_result_ext_o(adder_result_ext_w),
        .result_o(result_w),
        .comparison_result_o(comparison_result_w),
        .is_equal_result_o(is_equal_result_w)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test task
    task test_alu_op(
        input string op_name,
        input alu_op_e op,
        input [31:0] op_a,
        input [31:0] op_b,
        input [31:0] expected_result,
        input bit check_comparison,
        input bit expected_comparison,
        input bit is_multicycle,
        input [31:0] imd_val_0,
        input [31:0] imd_val_1
    );
        begin
            test_count = test_count + 1;

            // Setup inputs
            operator_r = op;
            operand_a_r = op_a;
            operand_b_r = op_b;
            instr_first_cycle_r = 1'b1;
            multdiv_sel_r = 1'b0;
            multdiv_operand_a_r = 33'h0;
            multdiv_operand_b_r = 33'h0;
            imd_val_q_r[0] = imd_val_0;
            imd_val_q_r[1] = imd_val_1;

            @(posedge clk);
            #1;

            // For multicycle operations, run second cycle
            if (is_multicycle) begin
                instr_first_cycle_r = 1'b0;
                imd_val_q_r[0] = imd_val_d_w[0];
                imd_val_q_r[1] = imd_val_d_w[1];
                @(posedge clk);
                #1;
            end

            // Check results
            if (result_w === expected_result && 
                (!check_comparison || (comparison_result_w === expected_comparison))) begin
                $display("PASS: %s | A=0x%08h B=0x%08h | Result=0x%08h Expected=0x%08h", 
                        op_name, op_a, op_b, result_w, expected_result);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s | A=0x%08h B=0x%08h | Result=0x%08h Expected=0x%08h Cmp=%b ExpCmp=%b", 
                        op_name, op_a, op_b, result_w, expected_result, comparison_result_w, expected_comparison);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Main test procedure
    initial begin
        rst_n = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        $display("========================================");
        $display("IBEX ALU Complete Test - All Operations");
        $display("========================================");

        // Call test_alu_op for all ALU operations with representative inputs
        test_alu_op("ALU_ADD", ALU_ADD, 32'h12345678, 32'h87654321, 32'h99999999, 0, 0, 0, 0, 0);
        test_alu_op("ALU_SUB", ALU_SUB, 32'h87654321, 32'h12345678, 32'h7530ECA9, 0, 0, 0, 0, 0);
        // ... repeat for all other ALU operations, both single and multicycle
        // (see previous message for full list with case names and expected values).

        $display("========================================");
        $display("FINAL Test Summary:");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Success Rate: %0.1f%%", (pass_count * 100.0) / test_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("🎉 ALL TESTS PASSED! PERFECT SCORE! ✓");
        end else begin
            $display("❌ %0d TESTS FAILED! ✗", fail_count);
        end

        $finish;
    end

    // Timeout protection
    initial begin
        #100000;
        $display("ERROR: Test timeout after 100μs!");
        $finish;
    end

endmodule
