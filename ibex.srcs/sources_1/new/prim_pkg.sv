`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2025 20:44:00
// Design Name: 
// Module Name: prim_pkg
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
// Legacy constants that were used in some IPs
// These are deprecated and should be removed.

package prim_pkg;

  // Implementation target specialization
  typedef enum integer {
    ImplGeneric,
    ImplXilinx,
    ImplBadbit,
    ImplXilinx_ultrascale
  } impl_e;

  `ifndef PRIM_DEFAULT_IMPL
    `define PRIM_DEFAULT_IMPL prim_pkg::ImplGeneric
  `endif

endpackage : prim_pkg