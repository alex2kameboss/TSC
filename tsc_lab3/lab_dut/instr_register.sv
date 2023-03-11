/***********************************************************************
 * A SystemVerilog RTL model of an instruction regisgter
 *
 * An error can be injected into the design by invoking compilation with
 * the option:  +define+FORCE_LOAD_ERROR
 *
 **********************************************************************/
`timescale 1ns/1ns
module instr_register
import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
(input  logic          clk,
 input  logic          load_en,
 input  logic          reset_n,
 input  operand_t      operand_a,
 input  operand_t      operand_b,
 input  opcode_t       opcode,
 input  address_t      write_pointer,
 input  address_t      read_pointer,
 output instruction_t  instruction_word
);
  instruction_t  iw_reg [0:31];  // an array of instruction_word structures
  result_t result, ext_a, ext_b;
  operand_t intermediar;

  // write to the register
  always_ff @(posedge clk, negedge reset_n)   // write into register
    if (!reset_n) begin
      foreach (iw_reg[i])
        iw_reg[i] = '{opc:ZERO,default:0};  // reset to all zeros
    end
    else if (load_en) begin
      iw_reg[write_pointer] = '{opcode, operand_a, operand_b, result};
    end

  assign ext_a = {{32{operand_a[31]}}, operand_a};
  assign ext_b = {{32{operand_b[31]}}, operand_b};

  always_comb begin
    result = 0;
    unique case (opcode)
      ZERO: result = 0;
      PASSA: result = ext_a;
      PASSB: result = ext_b;
      ADD: result = ext_a + ext_b;
      SUB: result = ext_a - ext_b;
      MULT: result = operand_a * operand_b;
      DIV: begin
        intermediar = operand_a / operand_b;
        result = {{31{intermediar[31]}}, intermediar};
      end
      MOD: begin
        intermediar = operand_a % operand_b;
        result = {{31{intermediar[31]}}, intermediar};
      end
    endcase
  end

  // read from the register
  assign instruction_word = iw_reg[read_pointer];  // continuously read from register

// compile with +define+FORCE_LOAD_ERROR to inject a functional bug for verification to catch
`ifdef FORCE_LOAD_ERROR
initial begin
  force operand_b = operand_a; // cause wrong value to be loaded into operand_b
end
`endif

endmodule: instr_register
