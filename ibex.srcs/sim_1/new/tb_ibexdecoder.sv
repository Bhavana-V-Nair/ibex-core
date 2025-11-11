`timescale 1ns/1ps

module tb_ibex_decoder;

  // Parameters
  parameter bit RV32E = 0;
  parameter     RV32M = "Fast"; 
  parameter     RV32B = "None"; 
  parameter bit BranchTargetALU = 0;

  // Inputs - corrected signal names
  reg         clk_i, rst_ni;
  reg  [31:0] instr_rdata_i;
  reg  [31:0] instr_rdata_alu_i;
  reg         instr_first_cycle_i;
  reg         branch_taken_i;
  reg         illegal_c_insn_i;

  // Key outputs to check
  wire        illegal_insn_o;
  wire        jump_in_dec_o, branch_in_dec_o;
  wire        rf_we_o, rf_ren_a_o, rf_ren_b_o;
  wire        data_req_o, data_we_o;
  wire        ebrk_insn_o, mret_insn_o, dret_insn_o, ecall_insn_o, wfi_insn_o;
  wire        jump_set_o, icache_inval_o;
  wire [4:0]  rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o;
  wire [1:0]  data_type_o;
  wire        data_sign_extension_o;
  wire        mult_en_o, div_en_o, mult_sel_o, div_sel_o;
  wire        csr_access_o, alu_multicycle_o;
  wire [31:0] imm_i_type_o, imm_s_type_o, imm_b_type_o, imm_u_type_o, imm_j_type_o, zimm_rs1_type_o;
  wire [5:0]  alu_operator_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o;

  // Instantiate decoder with ALL required ports
  ibex_decoder #(
    .RV32E(RV32E), 
    .RV32M(RV32M), 
    .RV32B(RV32B), 
    .BranchTargetALU(BranchTargetALU)
  ) dut (
    .clk_i(clk_i), 
    .rst_ni(rst_ni), 
    .instr_rdata_i(instr_rdata_i), 
    .instr_rdata_alu_i(instr_rdata_alu_i),
    .instr_first_cycle_i(instr_first_cycle_i),
    .branch_taken_i(branch_taken_i), 
    .illegal_c_insn_i(illegal_c_insn_i),
    
    // All outputs connected
    .illegal_insn_o(illegal_insn_o),
    .ebrk_insn_o(ebrk_insn_o),
    .mret_insn_o(mret_insn_o),
    .dret_insn_o(dret_insn_o),
    .ecall_insn_o(ecall_insn_o),
    .wfi_insn_o(wfi_insn_o),
    .jump_set_o(jump_set_o),
    .icache_inval_o(icache_inval_o),
    .jump_in_dec_o(jump_in_dec_o),
    .branch_in_dec_o(branch_in_dec_o),
    .rf_we_o(rf_we_o),
    .rf_ren_a_o(rf_ren_a_o),
    .rf_ren_b_o(rf_ren_b_o),
    .rf_raddr_a_o(rf_raddr_a_o),
    .rf_raddr_b_o(rf_raddr_b_o),
    .rf_waddr_o(rf_waddr_o),
    .data_req_o(data_req_o),
    .data_we_o(data_we_o),
    .data_type_o(data_type_o),
    .data_sign_extension_o(data_sign_extension_o),
    .mult_en_o(mult_en_o),
    .div_en_o(div_en_o),
    .mult_sel_o(mult_sel_o),
    .div_sel_o(div_sel_o),
    .csr_access_o(csr_access_o),
    .alu_multicycle_o(alu_multicycle_o),
    .imm_i_type_o(imm_i_type_o),
    .imm_s_type_o(imm_s_type_o),
    .imm_b_type_o(imm_b_type_o),
    .imm_u_type_o(imm_u_type_o),
    .imm_j_type_o(imm_j_type_o),
    .zimm_rs1_type_o(zimm_rs1_type_o),
    .alu_operator_o(alu_operator_o),
    .alu_op_a_mux_sel_o(alu_op_a_mux_sel_o),
    .alu_op_b_mux_sel_o(alu_op_b_mux_sel_o)
  );

  // Test sequence - main operations only
  initial begin
    // Initialize all signals properly
    clk_i = 0; 
    rst_ni = 0; 
    instr_first_cycle_i = 1; 
    branch_taken_i = 0; 
    illegal_c_insn_i = 0;
    instr_rdata_i = 32'h00000000;  // Initialize to avoid X states
    instr_rdata_alu_i = 32'h00000000;
    
    #10 rst_ni = 1;  // Hold reset longer
    #10;

    // Test LUI - Load Upper Immediate (0x000010b7 = LUI x1, 1)
    $display("Testing LUI at time %t", $time);
    instr_rdata_i = 32'h000010b7; 
    instr_rdata_alu_i = 32'h000010b7;
    #10;
    if (!(rf_we_o && !illegal_insn_o && rf_waddr_o == 5'd1)) begin
      $error("LUI failed: rf_we_o=%b, illegal_insn_o=%b, rf_waddr_o=%d", rf_we_o, illegal_insn_o, rf_waddr_o);
    end else begin
      $display("LUI PASSED");
    end

    // Test ADDI - Add Immediate (0x00210113 = ADDI x2, x2, 2)
    $display("Testing ADDI at time %t", $time);
    instr_rdata_i = 32'h00210113;
    instr_rdata_alu_i = 32'h00210113;
    #10;
    if (!(rf_we_o && rf_ren_a_o && !illegal_insn_o && rf_waddr_o == 5'd2)) begin
      $error("ADDI failed: rf_we_o=%b, rf_ren_a_o=%b, illegal_insn_o=%b", rf_we_o, rf_ren_a_o, illegal_insn_o);
    end else begin
      $display("ADDI PASSED");
    end

    // Test ADD - Register Add (0x002081b3 = ADD x3, x1, x2)
    $display("Testing ADD at time %t", $time);
    instr_rdata_i = 32'h002081b3;
    instr_rdata_alu_i = 32'h002081b3;
    #10;
    if (!(rf_we_o && rf_ren_a_o && rf_ren_b_o && !illegal_insn_o)) begin
      $error("ADD failed: rf_we_o=%b, rf_ren_a_o=%b, rf_ren_b_o=%b, illegal_insn_o=%b", rf_we_o, rf_ren_a_o, rf_ren_b_o, illegal_insn_o);
    end else begin
      $display("ADD PASSED"); 
    end

    // Test LW - Load Word (0x00012083 = LW x1, 0(x2))
    $display("Testing LW at time %t", $time);
    instr_rdata_i = 32'h00012083;
    instr_rdata_alu_i = 32'h00012083;
    #10;
    if (!(data_req_o && !data_we_o && rf_we_o && !illegal_insn_o)) begin
      $error("LW failed: data_req_o=%b, data_we_o=%b, rf_we_o=%b, illegal_insn_o=%b", data_req_o, data_we_o, rf_we_o, illegal_insn_o);
    end else begin
      $display("LW PASSED");
    end

    // Test SW - Store Word (0x00112023 = SW x1, 0(x2))
    $display("Testing SW at time %t", $time);
    instr_rdata_i = 32'h00112023;
    instr_rdata_alu_i = 32'h00112023;
    #10;
    if (!(data_req_o && data_we_o && !rf_we_o && !illegal_insn_o)) begin
      $error("SW failed: data_req_o=%b, data_we_o=%b, rf_we_o=%b, illegal_insn_o=%b", data_req_o, data_we_o, rf_we_o, illegal_insn_o);
    end else begin
      $display("SW PASSED");
    end

    // Test BEQ - Branch Equal (0x00208463 = BEQ x1, x2, 8) 
    $display("Testing BEQ at time %t", $time);
    instr_rdata_i = 32'h00208463;
    instr_rdata_alu_i = 32'h00208463;
    #10;
    if (!(branch_in_dec_o && rf_ren_a_o && rf_ren_b_o && !illegal_insn_o)) begin
      $error("BEQ failed: branch_in_dec_o=%b, rf_ren_a_o=%b, rf_ren_b_o=%b, illegal_insn_o=%b", branch_in_dec_o, rf_ren_a_o, rf_ren_b_o, illegal_insn_o);
    end else begin
      $display("BEQ PASSED");
    end

    // Test JAL - Jump and Link (0x004000ef = JAL x1, 4)
    $display("Testing JAL at time %t", $time);
    instr_rdata_i = 32'h004000ef;
    instr_rdata_alu_i = 32'h004000ef;
    #10;
    if (!(jump_in_dec_o && rf_we_o && !illegal_insn_o)) begin
      $error("JAL failed: jump_in_dec_o=%b, rf_we_o=%b, illegal_insn_o=%b", jump_in_dec_o, rf_we_o, illegal_insn_o);
    end else begin
      $display("JAL PASSED");
    end

    $display("All main operation tests completed at time %t", $time);
    #20;
    $finish;
  end

  // Clock generation
  always #5 clk_i = ~clk_i;  // 10ns period clock

endmodule
