/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/
`timescale 1ns/1ns

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  #(parameter NUMBER_OF_TRANSANCTIONS = 5,
  parameter seed = 555,
  parameter RND_CASE = 0,
  parameter TEST_NAME = "N/A")
  (/*input  logic          test_clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
   */
   tb_ifc.master i_tb_ifc
  );

  int wrong = 0;
  result_t result;

  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    i_tb_ifc.write_pointer  = 5'h00;         // initialize write pointer
    i_tb_ifc.read_pointer   = 5'h1F;         // initialize read pointer
    i_tb_ifc.load_en        = 1'b0;          // initialize load control line
    i_tb_ifc.reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge i_tb_ifc.test_clk) ;     // hold in reset for 2 clock cycles
    i_tb_ifc.reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge i_tb_ifc.test_clk) i_tb_ifc.load_en = 1'b1;  // enable writing to register
    repeat (NUMBER_OF_TRANSANCTIONS) begin // nr tranzactii
      @(posedge i_tb_ifc.test_clk) randomize_transaction;
      @(negedge i_tb_ifc.test_clk) print_transaction;
    end
    @(posedge i_tb_ifc.test_clk) i_tb_ifc.load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    for (int i=0; i<NUMBER_OF_TRANSANCTIONS; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      if (RND_CASE == 0 || RND_CASE == 2)
        @(posedge i_tb_ifc.test_clk) i_tb_ifc.read_pointer = i;
      else
        @(posedge i_tb_ifc.test_clk) i_tb_ifc.read_pointer = $unsigned($random)%32;
      @(negedge i_tb_ifc.test_clk) print_results;
      check_result;
    end

    @(posedge i_tb_ifc.test_clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $display("\nRunned test %s", TEST_NAME);
    if (wrong == 0)
      $display("Result: test passed");
    else
      $display("Result: test failed");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;
    i_tb_ifc.operand_a     <= $random(seed)%16;                 // between -15 and 15
    i_tb_ifc.operand_b     <= $unsigned($random)%16;            // between 0 and 15
    i_tb_ifc.opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    if (RND_CASE == 0 || RND_CASE == 1)
       i_tb_ifc.write_pointer <= temp++;
    else
      i_tb_ifc.write_pointer <= $unsigned($random)%32;
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", i_tb_ifc.write_pointer);
    $display("  opcode = %0d (%s)", i_tb_ifc.opcode, i_tb_ifc.opcode.name);
    $display("  operand_a = %0d",   i_tb_ifc.operand_a);
    $display("  operand_b = %0d\n", i_tb_ifc.operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", i_tb_ifc.read_pointer);
    $display("  opcode = %0d (%s)", i_tb_ifc.instruction_word.opc, i_tb_ifc.instruction_word.opc.name);
    $display("  operand_a = %0d",   i_tb_ifc.instruction_word.op_a);
    $display("  operand_b = %0d", i_tb_ifc.instruction_word.op_b);
    $display("  result = %0d\n", i_tb_ifc.instruction_word.rez);
  endfunction: print_results

  function void check_result;
    result = 'x;
    unique case (i_tb_ifc.instruction_word.opc)
      ZERO: result = 0;
      PASSA: result = i_tb_ifc.instruction_word.op_b; // TODO: change this in order to pass tests
      PASSB: result = i_tb_ifc.instruction_word.op_b;
      ADD: result = i_tb_ifc.instruction_word.op_a + i_tb_ifc.instruction_word.op_b;
      SUB: result = i_tb_ifc.instruction_word.op_a - i_tb_ifc.instruction_word.op_b;
      MULT: result = i_tb_ifc.instruction_word.op_a * i_tb_ifc.instruction_word.op_b;
      DIV: result = i_tb_ifc.instruction_word.op_a / i_tb_ifc.instruction_word.op_b;
      MOD: result = i_tb_ifc.instruction_word.op_a % i_tb_ifc.instruction_word.op_a;
    endcase

    if (i_tb_ifc.instruction_word.rez != result)
      wrong++;
  endfunction: check_result

endmodule: instr_register_test
