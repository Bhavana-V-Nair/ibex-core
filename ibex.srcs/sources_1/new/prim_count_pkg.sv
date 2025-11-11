`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.07.2025 22:36:51
// Design Name: 
// Module Name: prim_count_pkg
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

package prim_count_pkg;

  // An enum that names the possible actions that the inputs might ask for. See the PossibleActions
  // parameter in prim_count for how this is used.
  typedef logic [3:0] action_mask_t;
  typedef enum action_mask_t {Clr  = 4'h1,
                              Set  = 4'h2,
                              Incr = 4'h4,
                              Decr = 4'h8} action_e;

endpackage : prim_count_pkg
