/***********************************************************************
 * A SystemVerilog testbench for an instruction register; This file
 * contains the interface to connect the testbench to the design
 **********************************************************************/
`timescale 1ns/1ns
interface tb_ifc (input logic clk, input logic test_clk);
  import instr_register_pkg::*;

logic          load_en;
operand_t      operand_a;
operand_t      operand_b;
opcode_t       opcode;
address_t      write_pointer;
address_t      read_pointer;
instruction_t  instruction_word;
logic reset_n;

modport slave (
  input            clk,
  input            load_en,
  input            reset_n,
  input        operand_a,
  input        operand_b,
  input         opcode,
  input        write_pointer,
  input        read_pointer,
  output   instruction_word
);

modport master(
  input            test_clk,
  output           load_en,
  output           reset_n,
  output       operand_a,
  output       operand_b,
  output        opcode,
  output       write_pointer,
  output       read_pointer,
  input    instruction_word
);

endinterface: tb_ifc

