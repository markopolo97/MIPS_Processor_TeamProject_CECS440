`timescale 1ns / 1ps
/***************************************************************************
*
* Author: 	TrieuVy Le
* Filename: MPY_32
* Date: 	Feb. 26, 2019
* Version:	1
*
* Notes:    The MUL module yields a 64-bit product {Y_LO, Y_HI}
*				N status flags is solely dependent on the MSB of the 64-bit product
*				Z status flags is also dependent on the content of the 64-bit product 
***************************************************************************/
module MPY_32(S_MUL, T_MUL, HI_MUL, LO_MUL, N_MUL, Z_MUL);
	
	input      [31:0] S_MUL, T_MUL;
	output reg [31:0] HI_MUL, LO_MUL;
	output reg 			N_MUL, Z_MUL;
	
	// Integers used to cast signed operations
	integer 	  INT_S, INT_T;
	
	/***********************************************************************
	* Combinational logic, cast integers to be used for MUL and DIV operations
	* due to the signs of MSB so we account for
	* The operation yields a 64-bit product assigned to the concatenation of
	* Y_HI and Y_LO
	***********************************************************************/
	always @(*) begin
	
		INT_S = S_MUL;
		INT_T = T_MUL;
			
		{HI_MUL, LO_MUL} = INT_S * INT_T;
		
		/************************************************************************
		* Quotient = Y_LO, Remainder = Y_HI
		* Update the Negative status flag based on the MSB bit of the bus
		* Update the Zero status flag if variable content is all 0 -> 1'b0 
		************************************************************************/
		N_MUL = HI_MUL[31];
		Z_MUL = ({HI_MUL, LO_MUL} == 64'b0) ? 1'b1 : 1'b0;
	end
endmodule
