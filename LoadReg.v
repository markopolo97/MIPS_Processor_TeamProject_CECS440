`timescale 1ns / 1ps
/***************************************************************************
*
* Author: 	TrieuVy Le
* Filename: LoadReg 
* Date: 	Feb. 26, 2019
* Version:	1
*
* Notes:    The register allows data in to output only if load is enabled. 
* Otherwise data out is held at its previous value. Reset will zeros the array. 
*
***************************************************************************/
module LoadReg(clk, reset, load, D, Q);
	
	/**********************************************************************
	* Initilize input, output, and register used within the module.
	* Registers are to use non-blocking assignment. 
	* Always block to cycle the loop at positive edge of the clock. 
	* Continuous assignment to output the enabled data. 
	**********************************************************************/
	input 	      clk, reset, load;
	input [31:0]  D;
	
	output reg [31:0] Q;
	
	
	always @(posedge clk or posedge reset) begin
		if      (reset)  Q <= 32'h0;
		else if (load)   	  Q <= D;
		else 		        Q <= Q;
	end
	
endmodule
