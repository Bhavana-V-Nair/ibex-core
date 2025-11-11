`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 11:36:58
// Design Name: 
// Module Name: prim_and2
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

`include "prim_assert.sv"

// Prevent Vivado from performing optimizations on/across this module.
(* DONT_TOUCH = "yes" *)
module prim_and2 #(
  parameter int Width = 1
) (
  input [Width-1:0] in0_i,
  input [Width-1:0] in1_i,
  output logic [Width-1:0] out_o
);

  assign out_o = in0_i & in1_i;

endmodule