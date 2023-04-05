/***********************************************************************
 * A SystemVerilog top-level netlist to connect testbench to DUT
 **********************************************************************/
`timescale 1ns/1ns
module top;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  // clock variables
  logic clk;
  logic test_clk;
  logic reset_n;

  tb_ifc i_tb_ifc(.clk(clk), .test_clk(test_clk));

  // interconnecting signals
  /*logic          load_en;
  opcode_t       opcode;
  operand_t      operand_a, operand_b;
  address_t      write_pointer, read_pointer;
  instruction_t  instruction_word;
  */

  // instantiate testbench and connect ports
  instr_register_test #(.NUMBER_OF_TRANSANCTIONS(10), 
                        .RND_CASE(3)) test (
    .i_tb_ifc(i_tb_ifc.master)
    /*.clk(test_clk),
    .load_en(load_en),
    .reset_n(reset_n),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .opcode(opcode),
    .write_pointer(write_pointer),
    .read_pointer(read_pointer),
    .instruction_word(instruction_word)*/
   );

  // instantiate design and connect ports
  instr_register dut (
    .i_tb_ifc(i_tb_ifc.slave)
    /*.clk(clk),
    .load_en(load_en),
    .reset_n(reset_n),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .opcode(opcode),
    .write_pointer(write_pointer),
    .read_pointer(read_pointer),
    .instruction_word(instruction_word)*/
   );

  // clock oscillators
  initial begin
    clk <= 0;
    forever #5ns  clk = ~clk;
  end

  initial begin
    test_clk <=0;
    // offset test_clk edges from clk to prevent races between
    // the testbench and the design
    #4ns forever begin
      #2ns test_clk = 1'b1;
      #8ns test_clk = 1'b0;
    end
  end

endmodule: top
