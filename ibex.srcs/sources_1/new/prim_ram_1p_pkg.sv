`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 11:12:14
// Design Name: 
// Module Name: prim_ram_1p_pkg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//

package prim_ram_1p_pkg;

  typedef struct packed {
    logic       test;
    logic       cfg_en;
    logic [3:0] cfg;
  } cfg_t;

  typedef struct packed {
    cfg_t ram_cfg;  // configuration for ram
    cfg_t rf_cfg;   // configuration for regfile
  } ram_1p_cfg_t;

  typedef struct packed {
    logic done;
  } ram_1p_cfg_rsp_t;

  parameter ram_1p_cfg_t RAM_1P_CFG_DEFAULT = '0;

endpackage // prim_ram_1p_pkg
