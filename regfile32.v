`timescale 1ns / 1ps
/***************************************************************************
*
* Author: 	TrieuVy Le
* Filename: regfile32
* Date: 	Feb. 26, 2019
* Version:	2.0
*
* Notes:    Reading the register file is asynchronous and 
*			Writing the register file is to be synchronous
*			Both S and T ports are asynch outputs from the RF 
* Which register to write to is 'synchronously controlled" by the clk in 
* conjunction with the D_Addr. 
* A register specified, to be written to only on the rising edge of clk 
* iff (if and only if) D_En is asserted 
*
***************************************************************************/
module regfile32(clk, reset, D, D_Addr, S_Addr, T_Addr, D_En, S, T);

	input			clk, reset, D_En;
	input	 [4:0]  D_Addr, S_Addr, T_Addr;
	input  [31:0]   D;
	output [31:0]	S, T;
	
	reg [31:0] 		data [31:0];
	
	// Read section asynchronusly 
	assign S = data[S_Addr];
	assign T = data[T_Addr];
	
	/**********************************************************************
	* The WRITE section of this module is to be modeled behaviorally and
	* is sensitive to posedge clk and posedge reset.
	* The READ section is to be modeled with two contiuous statements. 
	**********************************************************************/
	always@ (posedge clk, posedge reset) begin
		
		if (reset) 	
			data[0] 	 <= 32'h0;
		
		else if ( D_En  && D_Addr != 5'b0)
			data[D_Addr] <= D;
		
		else 
			data[D_Addr] <= data[D_Addr];
	end 
	
endmodule
