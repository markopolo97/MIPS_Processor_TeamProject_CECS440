`timescale 1ns / 1ps
/***************************************************************************
*
* Author: 	TrieuVy Le
* Filename: DIV_32
* Date: 	Feb. 26, 2019
* Version:	1
*
* Notes:    The DIV module yields a 32-bit Quotient (Y_LO) 
*			and 32-bit Remainder (Y_HI)
*			The remainder of the operations are to be implemented in ALU_32,
*			it yields a 32-bit result (Y_LO) where ALU_hi will be set to all 0's
*			N status flags is solely dependent on Y_LO/Quotient[31] 
*			irrespective to Remainder 
*			Z status flags is also dependent on the content of Y_LO/Quotient 
*			if all 32'b0 then, Zero flag is set irrespective to Remainder
***************************************************************************/
module DIV_32(S_DIV, T_DIV, Quotient, Remainder, N_DIV, Z_DIV);
	
	// Initialize inputs and outputs used within the module
	input 	  [31:0] S_DIV, T_DIV;
	
	output reg [31:0] Quotient, Remainder;
	output reg        N_DIV, Z_DIV;
	
	integer     	  INT_S, INT_T;
	
	/***********************************************************************
	* Combinational logic, cast integers to be used for MUL and DIV operations
	* due to the signs of MSB so we account for signed bit
	***********************************************************************/
	always @(*) begin
		INT_S = S_DIV;
		INT_T = T_DIV;
		
		/************************************************************************
		* Quotient = Y_LO, Remainder = Y_HI
		* Update the Negative status flag based on the MSB bit of the bus
		* Update the Zero status flag if variable content is all 0 -> 1'b0 
		************************************************************************/
		Quotient  = INT_S / INT_T;
		Remainder = INT_S % INT_T;
		
		N_DIV = Quotient[31];
		Z_DIV = (Quotient == 32'b0) ? 1'b1 : 1'b0;
	end
endmodule

