`timescale 1ns / 1ps

// Comprehensive self-testing testbench for ibex_cs_registers
module tb_ibex_cs_registers;

  import ibex_pkg::*;

  // Clock and reset
  logic clk_i;
  logic rst_ni;
  
  // Test tracking
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  //========================================================================
  // DUT Signals
  //========================================================================
  
  // Hart ID
  logic [31:0] hart_id_i;
  
  // Privilege mode outputs
  priv_lvl_e priv_mode_id_o;
  priv_lvl_e priv_mode_lsu_o;
  logic csr_mstatus_tw_o;
  
  // mtvec
  logic [31:0] csr_mtvec_o;
  logic csr_mtvec_init_i;
  logic [31:0] boot_addr_i;
  
  // CSR access interface
  logic csr_access_i;
  csr_num_e csr_addr_i;
  logic [31:0] csr_wdata_i;
  csr_op_e csr_op_i;
  logic csr_op_en_i;
  logic [31:0] csr_rdata_o;
  
  // Interrupts
  logic irq_software_i;
  logic irq_timer_i;
  logic irq_external_i;
  logic [14:0] irq_fast_i;
  logic nmi_mode_i;
  logic irq_pending_o;
  irqs_t irqs_o;
  logic csr_mstatus_mie_o;
  logic [31:0] csr_mepc_o;
  logic [31:0] csr_mtval_o;
  
  // PMP outputs
  pmp_cfg_t csr_pmp_cfg_o [4];
  logic [33:0] csr_pmp_addr_o [4];
  pmp_mseccfg_t csr_pmp_mseccfg_o;
  
  // Debug
  logic debug_mode_i;
  logic debug_mode_entering_i;
  dbg_cause_e debug_cause_i;
  logic debug_csr_save_i;
  logic [31:0] csr_depc_o;
  logic debug_single_step_o;
  logic debug_ebreakm_o;
  logic debug_ebreaku_o;
  logic trigger_match_o;
  
  // PC values
  logic [31:0] pc_if_i;
  logic [31:0] pc_id_i;
  logic [31:0] pc_wb_i;
  
  // CPU control bits
  logic data_ind_timing_o;
  logic dummy_instr_en_o;
  logic [2:0] dummy_instr_mask_o;
  logic dummy_instr_seed_en_o;
  logic [31:0] dummy_instr_seed_o;
  logic icache_enable_o;
  logic csr_shadow_err_o;
  logic ic_scr_key_valid_i;
  
  // Exception save/restore
  logic csr_save_if_i;
  logic csr_save_id_i;
  logic csr_save_wb_i;
  logic csr_restore_mret_i;
  logic csr_restore_dret_i;
  logic csr_save_cause_i;
  exc_cause_t csr_mcause_i;
  logic [31:0] csr_mtval_i;
  logic illegal_csr_insn_o;
  logic double_fault_seen_o;
  
  // Performance counters
  logic instr_ret_i;
  logic instr_ret_compressed_i;
  logic instr_ret_spec_i;
  logic instr_ret_compressed_spec_i;
  logic iside_wait_i;
  logic jump_i;
  logic branch_i;
  logic branch_taken_i;
  logic mem_load_i;
  logic mem_store_i;
  logic dside_wait_i;
  logic mul_wait_i;
  logic div_wait_i;

  //========================================================================
  // DUT Instantiation
  //========================================================================
  
  ibex_cs_registers #(
    .DbgTriggerEn(1'b1),
    .DbgHwBreakNum(2),
    .DataIndTiming(1'b1),
    .DummyInstructions(1'b1),
    .ShadowCSR(1'b0),
    .ICache(1'b1),
    .MHPMCounterNum(10),
    .MHPMCounterWidth(40),
    .PMPEnable(1'b1),
    .PMPGranularity(0),
    .PMPNumRegions(4),
    .RV32E(1'b0),
    .RV32M(ibex_pkg::RV32MFast),
    .RV32B(ibex_pkg::RV32BNone),
    .CsrMvendorId(32'h0000_0001),
    .CsrMimpId(32'h0000_0002)
  ) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .hart_id_i(hart_id_i),
    .priv_mode_id_o(priv_mode_id_o),
    .priv_mode_lsu_o(priv_mode_lsu_o),
    .csr_mstatus_tw_o(csr_mstatus_tw_o),
    .csr_mtvec_o(csr_mtvec_o),
    .csr_mtvec_init_i(csr_mtvec_init_i),
    .boot_addr_i(boot_addr_i),
    .csr_access_i(csr_access_i),
    .csr_addr_i(csr_addr_i),
    .csr_wdata_i(csr_wdata_i),
    .csr_op_i(csr_op_i),
    .csr_op_en_i(csr_op_en_i),
    .csr_rdata_o(csr_rdata_o),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
    .irq_fast_i(irq_fast_i),
    .nmi_mode_i(nmi_mode_i),
    .irq_pending_o(irq_pending_o),
    .irqs_o(irqs_o),
    .csr_mstatus_mie_o(csr_mstatus_mie_o),
    .csr_mepc_o(csr_mepc_o),
    .csr_mtval_o(csr_mtval_o),
    .csr_pmp_cfg_o(csr_pmp_cfg_o),
    .csr_pmp_addr_o(csr_pmp_addr_o),
    .csr_pmp_mseccfg_o(csr_pmp_mseccfg_o),
    .debug_mode_i(debug_mode_i),
    .debug_mode_entering_i(debug_mode_entering_i),
    .debug_cause_i(debug_cause_i),
    .debug_csr_save_i(debug_csr_save_i),
    .csr_depc_o(csr_depc_o),
    .debug_single_step_o(debug_single_step_o),
    .debug_ebreakm_o(debug_ebreakm_o),
    .debug_ebreaku_o(debug_ebreaku_o),
    .trigger_match_o(trigger_match_o),
    .pc_if_i(pc_if_i),
    .pc_id_i(pc_id_i),
    .pc_wb_i(pc_wb_i),
    .data_ind_timing_o(data_ind_timing_o),
    .dummy_instr_en_o(dummy_instr_en_o),
    .dummy_instr_mask_o(dummy_instr_mask_o),
    .dummy_instr_seed_en_o(dummy_instr_seed_en_o),
    .dummy_instr_seed_o(dummy_instr_seed_o),
    .icache_enable_o(icache_enable_o),
    .csr_shadow_err_o(csr_shadow_err_o),
    .ic_scr_key_valid_i(ic_scr_key_valid_i),
    .csr_save_if_i(csr_save_if_i),
    .csr_save_id_i(csr_save_id_i),
    .csr_save_wb_i(csr_save_wb_i),
    .csr_restore_mret_i(csr_restore_mret_i),
    .csr_restore_dret_i(csr_restore_dret_i),
    .csr_save_cause_i(csr_save_cause_i),
    .csr_mcause_i(csr_mcause_i),
    .csr_mtval_i(csr_mtval_i),
    .illegal_csr_insn_o(illegal_csr_insn_o),
    .double_fault_seen_o(double_fault_seen_o),
    .instr_ret_i(instr_ret_i),
    .instr_ret_compressed_i(instr_ret_compressed_i),
    .instr_ret_spec_i(instr_ret_spec_i),
    .instr_ret_compressed_spec_i(instr_ret_compressed_spec_i),
    .iside_wait_i(iside_wait_i),
    .jump_i(jump_i),
    .branch_i(branch_i),
    .branch_taken_i(branch_taken_i),
    .mem_load_i(mem_load_i),
    .mem_store_i(mem_store_i),
    .dside_wait_i(dside_wait_i),
    .mul_wait_i(mul_wait_i),
    .div_wait_i(div_wait_i)
  );

  //========================================================================
  // Clock Generation
  //========================================================================
  
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  //========================================================================
  // Helper Tasks
  //========================================================================
  
  // Check result and update counters
  task automatic check_result(input string test_name, input logic condition);
    test_count++;
    if (condition) begin
      pass_count++;
    end else begin
      fail_count++;
      $display("FAIL: %s", test_name);
    end
  endtask
  
  // Initialize all signals
  task automatic init_signals();
    hart_id_i = 32'h0000_0000;
    csr_mtvec_init_i = 1'b0;
    boot_addr_i = 32'h8000_0000;
    csr_access_i = 1'b0;
    csr_addr_i = CSR_MSTATUS;
    csr_wdata_i = 32'h0;
    csr_op_i = CSR_OP_READ;
    csr_op_en_i = 1'b0;
    irq_software_i = 1'b0;
    irq_timer_i = 1'b0;
    irq_external_i = 1'b0;
    irq_fast_i = 15'h0;
    nmi_mode_i = 1'b0;
    debug_mode_i = 1'b0;
    debug_mode_entering_i = 1'b0;
    debug_cause_i = DBG_CAUSE_NONE;
    debug_csr_save_i = 1'b0;
    pc_if_i = 32'h0;
    pc_id_i = 32'h0;
    pc_wb_i = 32'h0;
    ic_scr_key_valid_i = 1'b0;
    csr_save_if_i = 1'b0;
    csr_save_id_i = 1'b0;
    csr_save_wb_i = 1'b0;
    csr_restore_mret_i = 1'b0;
    csr_restore_dret_i = 1'b0;
    csr_save_cause_i = 1'b0;
    csr_mcause_i = '0;
    csr_mtval_i = 32'h0;
    instr_ret_i = 1'b0;
    instr_ret_compressed_i = 1'b0;
    instr_ret_spec_i = 1'b0;
    instr_ret_compressed_spec_i = 1'b0;
    iside_wait_i = 1'b0;
    jump_i = 1'b0;
    branch_i = 1'b0;
    branch_taken_i = 1'b0;
    mem_load_i = 1'b0;
    mem_store_i = 1'b0;
    dside_wait_i = 1'b0;
    mul_wait_i = 1'b0;
    div_wait_i = 1'b0;
  endtask
  
  // CSR write task - REDUCED DELAYS
  task automatic csr_write(input csr_num_e addr, input logic [31:0] data);
    @(posedge clk_i);
    csr_access_i = 1'b1;
    csr_addr_i = addr;
    csr_wdata_i = data;
    csr_op_i = CSR_OP_WRITE;
    csr_op_en_i = 1'b1;
    @(posedge clk_i);
    csr_access_i = 1'b0;
    csr_op_en_i = 1'b0;
  endtask
  
  // CSR read task - REDUCED DELAYS
  task automatic csr_read(input csr_num_e addr, output logic [31:0] data);
    @(posedge clk_i);
    csr_access_i = 1'b1;
    csr_addr_i = addr;
    csr_op_i = CSR_OP_READ;
    csr_op_en_i = 1'b0;
    @(posedge clk_i);
    data = csr_rdata_o;
    csr_access_i = 1'b0;
  endtask
  
  // CSR set bits task - REDUCED DELAYS
  task automatic csr_set(input csr_num_e addr, input logic [31:0] mask);
    @(posedge clk_i);
    csr_access_i = 1'b1;
    csr_addr_i = addr;
    csr_wdata_i = mask;
    csr_op_i = CSR_OP_SET;
    csr_op_en_i = 1'b1;
    @(posedge clk_i);
    csr_access_i = 1'b0;
    csr_op_en_i = 1'b0;
  endtask
  
  // CSR clear bits task - REDUCED DELAYS
  task automatic csr_clear(input csr_num_e addr, input logic [31:0] mask);
    @(posedge clk_i);
    csr_access_i = 1'b1;
    csr_addr_i = addr;
    csr_wdata_i = mask;
    csr_op_i = CSR_OP_CLEAR;
    csr_op_en_i = 1'b1;
    @(posedge clk_i);
    csr_access_i = 1'b0;
    csr_op_en_i = 1'b0;
  endtask

  //========================================================================
  // Test: Read-only CSRs
  //========================================================================
  
  task automatic test_readonly_csrs();
    logic [31:0] rdata;
    $display("Testing read-only CSRs...");
    
    // Test MVENDORID
    csr_read(CSR_MVENDORID, rdata);
    check_result("MVENDORID Read", rdata == 32'h0000_0001);
    
    // Test MARCHID
    csr_read(CSR_MARCHID, rdata);
    check_result("MARCHID Read", rdata == 32'h0000_0016);
    
    // Test MIMPID
    csr_read(CSR_MIMPID, rdata);
    check_result("MIMPID Read", rdata == 32'h0000_0002);
    
    // Test MHARTID
    hart_id_i = 32'h0000_00AB;
    csr_read(CSR_MHARTID, rdata);
    check_result("MHARTID Read", rdata == 32'h0000_00AB);
    
    // Test MISA
    csr_read(CSR_MISA, rdata);
    check_result("MISA Read", rdata[2] == 1'b1);
    check_result("MISA M-mode", rdata[12] == 1'b1);
  endtask

  //========================================================================
  // Test: MSTATUS CSR
  //========================================================================
  
  task automatic test_mstatus();
    logic [31:0] rdata;
    $display("Testing MSTATUS CSR...");
    
    // Test MIE bit (bit 3)
    csr_write(CSR_MSTATUS, 32'h0000_0008);
    csr_read(CSR_MSTATUS, rdata);
    check_result("MSTATUS MIE Set", rdata[3] == 1'b1);
    check_result("MSTATUS MIE Output", csr_mstatus_mie_o == 1'b1);
    
    // Test MPIE bit (bit 7)
    csr_write(CSR_MSTATUS, 32'h0000_0080);
    csr_read(CSR_MSTATUS, rdata);
    check_result("MSTATUS MPIE Set", rdata[7] == 1'b1);
    
    // Test MPP field (bits 12:11)
    csr_write(CSR_MSTATUS, 32'h0000_1800);
    csr_read(CSR_MSTATUS, rdata);
    check_result("MSTATUS MPP M-mode", rdata[12:11] == 2'b11);
    
    // Test MPRV bit (bit 17)
    csr_write(CSR_MSTATUS, 32'h0002_0000);
    csr_read(CSR_MSTATUS, rdata);
    check_result("MSTATUS MPRV Set", rdata[17] == 1'b1);
    
    // Test TW bit (bit 21)
    csr_write(CSR_MSTATUS, 32'h0020_0000);
    csr_read(CSR_MSTATUS, rdata);
    check_result("MSTATUS TW Set", rdata[21] == 1'b1);
    check_result("MSTATUS TW Output", csr_mstatus_tw_o == 1'b1);
  endtask

  //========================================================================
  // Test: Interrupt Enable and Pending
  //========================================================================
  
  task automatic test_interrupts();
    logic [31:0] rdata;
    $display("Testing interrupt CSRs...");
    
    // Enable all interrupts in MIE
    csr_write(CSR_MIE, 32'hFFFF_FFFF);
    csr_read(CSR_MIE, rdata);
    check_result("MIE Software Interrupt", rdata[3] == 1'b1);
    check_result("MIE Timer Interrupt", rdata[7] == 1'b1);
    check_result("MIE External Interrupt", rdata[11] == 1'b1);
    
    // Set interrupt pending signals
    irq_software_i = 1'b1;
    irq_timer_i = 1'b1;
    irq_external_i = 1'b1;
    irq_fast_i = 15'h7FFF;
    @(posedge clk_i);
    
    // Check MIP register
    csr_read(CSR_MIP, rdata);
    check_result("MIP Software Interrupt", rdata[3] == 1'b1);
    check_result("MIP Timer Interrupt", rdata[7] == 1'b1);
    check_result("MIP External Interrupt", rdata[11] == 1'b1);
    
    // Enable MSTATUS.MIE
    csr_write(CSR_MSTATUS, 32'h0000_0008);
    @(posedge clk_i);
    
    // Check interrupt pending output
    check_result("IRQ Pending Output", irq_pending_o == 1'b1);
    
    // Clear interrupt sources
    irq_software_i = 1'b0;
    irq_timer_i = 1'b0;
    irq_external_i = 1'b0;
    irq_fast_i = 15'h0;
    @(posedge clk_i);
    
    check_result("IRQ Cleared", irq_pending_o == 1'b0);
  endtask

  //========================================================================
  // Test: Exception Program Counter (MEPC)
  //========================================================================
  
  task automatic test_mepc();
    logic [31:0] rdata;
    $display("Testing MEPC CSR...");
    
    // Write aligned address
    csr_write(CSR_MEPC, 32'h1000_0004);
    csr_read(CSR_MEPC, rdata);
    check_result("MEPC Aligned Write", rdata == 32'h1000_0004);
    check_result("MEPC Output", csr_mepc_o == 32'h1000_0004);
    
    // Write unaligned address (LSB should be cleared)
    csr_write(CSR_MEPC, 32'h2000_0007);
    csr_read(CSR_MEPC, rdata);
    check_result("MEPC LSB Cleared", rdata[0] == 1'b0);
  endtask

  //========================================================================
  // Test: MCAUSE and MTVAL
  //========================================================================
  
  task automatic test_mcause_mtval();
    logic [31:0] rdata;
    $display("Testing MCAUSE and MTVAL CSRs...");
    
    // Write exception cause (synchronous)
    csr_write(CSR_MCAUSE, 32'h0000_0002);
    csr_read(CSR_MCAUSE, rdata);
    check_result("MCAUSE Exception", rdata[31] == 1'b0);
    check_result("MCAUSE Code", rdata[4:0] == 5'd2);
    
    // Write interrupt cause
    csr_write(CSR_MCAUSE, 32'h8000_0007);
    csr_read(CSR_MCAUSE, rdata);
    check_result("MCAUSE Interrupt", rdata[31] == 1'b1);
    check_result("MCAUSE Int Code", rdata[4:0] == 5'd7);
    
    // Write MTVAL
    csr_write(CSR_MTVAL, 32'hDEAD_BEEF);
    csr_read(CSR_MTVAL, rdata);
    check_result("MTVAL Write", rdata == 32'hDEAD_BEEF);
    check_result("MTVAL Output", csr_mtval_o == 32'hDEAD_BEEF);
  endtask

  //========================================================================
  // Test: MTVEC
  //========================================================================
  
  task automatic test_mtvec();
    logic [31:0] rdata;
    $display("Testing MTVEC CSR...");
    
    // Initialize MTVEC with boot address
    csr_mtvec_init_i = 1'b1;
    boot_addr_i = 32'h8000_0100;
    @(posedge clk_i);
    csr_mtvec_init_i = 1'b0;
    @(posedge clk_i);
    
    csr_read(CSR_MTVEC, rdata);
    check_result("MTVEC Init", rdata[31:8] == boot_addr_i[31:8]);
    check_result("MTVEC Mode Vectored", rdata[1:0] == 2'b01);
    
    // Write new MTVEC value
    csr_write(CSR_MTVEC, 32'h9000_0200);
    csr_read(CSR_MTVEC, rdata);
    check_result("MTVEC Write", rdata[31:8] == 24'h900002);
    check_result("MTVEC Output", csr_mtvec_o[31:8] == 24'h900002);
  endtask

  //========================================================================
  // Test: MSCRATCH
  //========================================================================
  
  task automatic test_mscratch();
    logic [31:0] rdata;
    $display("Testing MSCRATCH CSR...");
    
    // Write and read arbitrary values
    csr_write(CSR_MSCRATCH, 32'h5555_AAAA);
    csr_read(CSR_MSCRATCH, rdata);
    check_result("MSCRATCH Write 1", rdata == 32'h5555_AAAA);
    
    csr_write(CSR_MSCRATCH, 32'hAAAA_5555);
    csr_read(CSR_MSCRATCH, rdata);
    check_result("MSCRATCH Write 2", rdata == 32'hAAAA_5555);
  endtask

  //========================================================================
  // Test: Exception Handling
  //========================================================================
  
  task automatic test_exception_handling();
    logic [31:0] rdata;
    $display("Testing exception handling...");
    
    // Setup: Enable interrupts
    csr_write(CSR_MSTATUS, 32'h0000_0008);
    
    // Trigger exception save
    pc_id_i = 32'h1000_1234;
    csr_mcause_i.irq_int = 1'b0;
    csr_mcause_i.irq_ext = 1'b0;
    csr_mcause_i.lower_cause = 5'd2;
    csr_mtval_i = 32'hBADF_ACED;
    csr_save_cause_i = 1'b1;
    csr_save_id_i = 1'b1;
    @(posedge clk_i);
    csr_save_cause_i = 1'b0;
    csr_save_id_i = 1'b0;
    @(posedge clk_i);
    
    // Check MEPC saved
    check_result("Exception MEPC Saved", csr_mepc_o == 32'h1000_1234);
    
    // Check MCAUSE saved
    csr_read(CSR_MCAUSE, rdata);
    check_result("Exception MCAUSE Saved", rdata[4:0] == 5'd2);
    
    // Check MTVAL saved
    check_result("Exception MTVAL Saved", csr_mtval_o == 32'hBADF_ACED);
    
    // Check MSTATUS updated
    csr_read(CSR_MSTATUS, rdata);
    check_result("Exception MIE Cleared", rdata[3] == 1'b0);
    check_result("Exception MPIE Set", rdata[7] == 1'b1);
    
    // Check privilege mode
    check_result("Exception Priv Mode", priv_mode_id_o == PRIV_LVL_M);
  endtask

  //========================================================================
  // Test: MRET Instruction
  //========================================================================
  
  task automatic test_mret();
    logic [31:0] rdata;
    $display("Testing MRET instruction...");
    
    // Setup: Set MPIE and MPP
    csr_write(CSR_MSTATUS, 32'h0000_1880);
    csr_write(CSR_MEPC, 32'h2000_5678);
    
    // Execute MRET
    csr_restore_mret_i = 1'b1;
    @(posedge clk_i);
    csr_restore_mret_i = 1'b0;
    @(posedge clk_i);
    
    // Check MSTATUS.MIE restored from MPIE
    csr_read(CSR_MSTATUS, rdata);
    check_result("MRET MIE Restored", rdata[3] == 1'b1);
    check_result("MRET MPIE Set", rdata[7] == 1'b1);
    check_result("MRET MPP Updated", rdata[12:11] == 2'b00);
  endtask

  //========================================================================
  // Test: Performance Counters - SIMPLIFIED
  //========================================================================
  
  task automatic test_performance_counters();
    logic [31:0] rdata_low, rdata_high;
    $display("Testing performance counters...");
    
    // Test MCYCLE counter
    csr_read(CSR_MCYCLE, rdata_low);
    repeat(5) @(posedge clk_i);
    csr_read(CSR_MCYCLE, rdata_high);
    check_result("MCYCLE Increment", rdata_high > rdata_low);
    
    // Test MINSTRET counter
    csr_read(CSR_MINSTRET, rdata_low);
    instr_ret_i = 1'b1;
    repeat(3) @(posedge clk_i);
    instr_ret_i = 1'b0;
    @(posedge clk_i);
    csr_read(CSR_MINSTRET, rdata_high);
    check_result("MINSTRET Increment", rdata_high == (rdata_low + 3));
    
    // Test MCOUNTINHIBIT
    csr_write(CSR_MCOUNTINHIBIT, 32'h0000_0001);
    csr_read(CSR_MCYCLE, rdata_low);
    repeat(5) @(posedge clk_i);
    csr_read(CSR_MCYCLE, rdata_high);
    check_result("MCYCLE Inhibited", rdata_high == rdata_low);
    
    // Re-enable counters
    csr_write(CSR_MCOUNTINHIBIT, 32'h0000_0000);
  endtask

  //========================================================================
  // Main Test Sequence
  //========================================================================
  
  initial begin
    $display("=============================================================");
    $display("  Starting ibex_cs_registers Testbench");
    $display("=============================================================");
    
    // Initialize
    init_signals();
    rst_ni = 0;
    
    // Reset sequence
    repeat(3) @(posedge clk_i);
    rst_ni = 1;
    repeat(2) @(posedge clk_i);
    
    // Run all tests
    test_readonly_csrs();
    test_mstatus();
    test_interrupts();
    test_mepc();
    test_mcause_mtval();
    test_mtvec();
    test_mscratch();
    test_exception_handling();
    test_mret();
    test_performance_counters();
    
    // Test summary
    repeat(3) @(posedge clk_i);
    $display("=============================================================");
    $display("  Test Summary");
    $display("=============================================================");
    $display("  Total Tests: %0d", test_count);
    $display("  Passed:      %0d", pass_count);
    $display("  Failed:      %0d", fail_count);
    $display("=============================================================");
    
    if (fail_count == 0) begin
      $display("  ALL TESTS PASSED!");
    end else begin
      $display("  SOME TESTS FAILED!");
    end
    $display("=============================================================");
    
    $finish;
  end
  
  // Timeout watchdog - extended
  initial begin
    #50000; // 50 microseconds
    $display("ERROR: Testbench timeout!");
    $finish;
  end

endmodule
