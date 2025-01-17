////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//File Name: ALU.v
//Created By: Sheetal Swaroop Burada
//Date: 30-04-2019
//Project Name: Design of 32 Bit Floating Point ALU Based on Standard IEEE-754 in Verilog and its implementation on FPGA.
//University: Dayalbagh Educational Institute
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//`include "Addition-Subtraction.v"
//`include "Multiplication.v"
//`include "Division.v"
//`include "Floating_Point_to_Integer.v"

module FALU(
	input [31:0] a_operand,
	input [31:0] b_operand,
	input [3:0] Operation,	
	output [31:0] ALU_Output,
	output Exception,Overflow,Underflow	
	);
	

// wire [31:0] Add_Sub_A,Add_Sub_B,Mul_A,Mul_B,Div_A,Div_B,OR_Output,AND_Output,XOR_Output,L_S_Output,R_S_Output,Floating_Point;
wire [31:0] Add_Sub_A,Add_Sub_B,Mul_A,Mul_B,Div_A,Div_B;

wire Add_Sub_Exception,Mul_Exception,Mul_Overflow,Mul_Underflow,Div_Exception;

wire [31:0] Add_Sub_Output,Mul_Output,Div_Output,Integer_Value;

wire AddBar_Sub;

wire [31:0] Complement_output;

// for the compare instruction
wire [1:0] compare_out;
reg compare_out_alu;



// addition
assign {Add_Sub_A,Add_Sub_B,AddBar_Sub} = (Operation == 4'd0) ? {a_operand,b_operand,1'b0} : 64'dz;
// multiplication
assign {Mul_A,Mul_B} = (Operation == 4'd2) ? {a_operand,b_operand} : 64'dz;
// division
assign {Div_A,Div_B} = (Operation == 4'd3) ? {a_operand,b_operand}	: 64'dz;
// substraction
assign {Add_Sub_A,Add_Sub_B,AddBar_Sub} = (Operation == 4'd1) ? {a_operand,b_operand,1'b1} : 64'dz;

// assign OR_Output = (Operation == 4'd4) ? a_operand | b_operand	: 32'dz;

// assign AND_Output = (Operation == 4'd5) ? a_operand & b_operand	: 32'dz;

// assign XOR_Output = (Operation == 4'd6) ? a_operand ^ b_operand: 32'dz;

// assign L_S_Output = (Operation == 4'd7) ? a_operand << 1'b1 : 32'dz;

// assign R_S_Output = (Operation == 4'd8) ? a_operand >> 1'b1	: 32'dz;

// assign Floating_Point = (Operation == 4'd9) ? a_operand	: 32'dz;

// assign Complement_output = (Operation == 4'd11) ? !a_operand : 32'dz;





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Addition_Subtraction AuI(Add_Sub_A,Add_Sub_B,AddBar_Sub,Add_Sub_Exception,Add_Sub_Output);

Multiplication MuI(Mul_A,Mul_B,Mul_Exception,Mul_Overflow,Mul_Underflow,Mul_Output);

Division DuI(Div_A,Div_B,Div_Exception,Div_Output);

Comparison Comp(a_operand, b_operand, compare_out);

// Floating_Point_to_Integer FuI(Floating_Point,Integer_Value);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd0) ? {Add_Sub_Exception,1'b0,1'b0,Add_Sub_Output}	: 35'dz;

assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd2) ? {Mul_Exception,Mul_Overflow,Mul_Underflow,Mul_Output}	: 35'dz;

assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd3) ? {Div_Exception,1'b0,1'b0,Div_Output}	: 35'dz;

assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd1) ? {Add_Sub_Exception,1'b0,1'b0,Add_Sub_Output}	: 35'dz;

assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd6 | Operation == 4'd5 | Operation == 4'd4) ? {1'b0,1'b0,1'b0, {31'd0, compare_out_alu}}	: 35'dz;



always @(*) begin
	// equal
	if (Operation == 4'd6) begin
		if (compare_out == 2'b00) compare_out_alu = 1'b1;
		else compare_out_alu = 1'b0;
	end
	// less than
	if (Operation == 4'd5) begin
		if (compare_out == 2'b10) compare_out_alu = 1'b1;
		else compare_out_alu = 1'b0;
	end
	// less than or equal
	if (Operation == 4'd4) begin
		if (compare_out == 2'b01) compare_out_alu = 1'b0;
		else compare_out_alu = 1'b1;
	end
end

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd4) ? {1'b0,1'b0,1'b0,OR_Output}	: 35'dz;

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd5) ? {1'b0,1'b0,1'b0,AND_Output}	: 35'dz;

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd6) ? {1'b0,1'b0,1'b0,XOR_Output}	: 35'dz;

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd7) ? {1'b0,1'b0,1'b0,L_S_Output}	: 35'dz;

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd8) ? {1'b0,1'b0,1'b0,R_S_Output}	: 35'dz;

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd9) ? {1'b0,1'b0,1'b0,Integer_Value}	: 35'dz;

// assign {Exception,Overflow,Underflow,ALU_Output} = (Operation == 4'd11) ? {1'b0,1'b0,1'b0,Complement_output} : 35'dz;





endmodule