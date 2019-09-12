`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:37:59 03/03/2019 
// Design Name: 
// Module Name:    ProgramCounter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ProgramCounter(clk, reset, PC_In, PC_ld, PC_inc, PC_out);
	
	input clk, reset, PC_ld, PC_inc;
	input [31:0] PC_In;
	output reg [31:0] PC_out;
	
	always @ (posedge clk, posedge reset) begin
		if 	(reset)  PC_out <= 32'b0;
		else 
			case ({PC_inc, PC_ld}) 
				2'b01: 	PC_out <= PC_In;
				2'b10: 	PC_out <= PC_out + 4;
				default: PC_out <= PC_out;
			endcase
	end 

endmodule
