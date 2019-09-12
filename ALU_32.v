`timescale 1ns / 1ps
/************************************************************************************
*
* Author: 	TrieuVy Le
* Filename: ALU_32
* Date: 	Feb. 26, 2019
* Version:	1
*
* Notes:    This top module is to instantiate the following:
*			1. MIPS_32
*			2. DIV_32
*			3. MPY_32
*			The module includes 2 32-bit S and T inputs, 5-bit opcodes FS, 
*			2 32-bit Y_LO and Y_HI outputs, and 4 status flags: 
*			Carry (C), Negative (N), Overflow (V), Zero (Z).
*			For MUL and DIV operations, we used the the multiplexer to select 
* 			the correct outputs for {Y_LO, Y_HI, C, N, V, Z} otherwise based on FS, 
*			the program will choose MIPS settings as the default case.
*			There are certain operations that do not require the update of 
*			the status flags C, N, V, Z due to the types of instructions 
*			Unsigned #: positive numbers. MSB bit is 2^n - 1.
*			Signed #: requires an arithmetic sign. MSB is used to represent 
*			the sign bit. If MSB is 0 - positive and 1 - negative. 
* 			ADDU, SUBU, STLU do not require signed bit due to unsigned operations.
***************************************************************************************/
module ALU_32(S, T, FS, shtamt, Y_HI, Y_LO, C, V, N, Z);       
	
	/*******************************************
	* Initilize inputs and outputs to process data
	* Signals utilize by MUL and DIV
	* MIPS module interfacing variable 
	*********************************************/
	input [31:0]  S, T;
	input [4:0]   FS, shtamt;// shtamt;
	output [31:0] Y_LO, Y_HI;
	output        C, N, Z, V;
	
	wire  [31:0]  Hi_DIV, Lo_DIV, Hi_MUL, Lo_MUL;
	wire 			  MUL_N, MUL_Z, DIV_N, DIV_Z;
	
	wire [31:0]	  mipsS, mipsT, mipsY_LO, mipsY_HI;
	wire 			  mipsC, mipsN, mipsZ, mipsV;
	wire [4:0]	  mipsFS;
	
	wire 		    bs_C, bs_N, bs_Z, bs_V;
	wire [31:0]   bs_YLO;
	
	parameter [4:0] 	 MUL  = 5'h1E,
					  	 DIV  = 5'h1F,
						 SRL = 5'h0C,
						 SRA = 5'h0D,
						 SLL = 5'h0E;
	
	
	MIPS_32  mips32	(	.mipsS(S), .mipsT(T), .mipsFS(FS), 
								.C(mipsC), .V(mipsV), .N(mipsN), .Z(mipsZ), 
								.Y_hi(mipsY_HI), .Y_lo(mipsY_LO));
							
	DIV_32   div32	(		.S_DIV(S), .T_DIV(T), .Quotient(Lo_DIV), 
								.Remainder(Hi_DIV), .N_DIV(DIV_N), .Z_DIV(DIV_Z));
	
	MPY_32   mpy32  (.S_MUL(S), .T_MUL(T), .HI_MUL(Hi_MUL),  
				     .LO_MUL(Lo_MUL), .N_MUL(MUL_N), .Z_MUL(MUL_Z));
	
	BS_32    bs32   (.T(T), .shtamt(shtamt), .S_type(FS),.C(bs_C), .YLO(bs_YLO));
	
	
	
	

	/*****************************************************************************
	* The multiplexer is determined based on the FS .
	* FS = 5'h1E is reserved for MUL op.
	* FS = 5'h1F is reserved for DIV op.
	* The respective value of Y_HI, Y_LO, and status flags are interconnected 
	* depending on FS opcodes for MUL & DIV, otherwise default will be MIPS contents.
	* DIV: Quotient = Y_LO and Remainder = Y_HI
	* MUL: 64-bit Product = {Y_HI, Y_LO}
	*****************************************************************************/
	assign   bs_Z = ~|{Y_LO};
	assign {Y_HI, Y_LO, N, Z, C, V} = 
					(FS == MUL) ? {Hi_MUL,   Lo_MUL,   MUL_N, MUL_Z, 1'bx,  1'bx} :
					(FS == DIV) ? {Hi_DIV,   Lo_DIV,   DIV_N, DIV_Z, 1'bx,  1'bx} :
					(FS == SLL || FS == SRL || FS == SRA) ? 
					
									{31'h0,   bs_YLO,    1'bx,  bs_Z,  bs_C,  1'bx} :
					
									{mipsY_HI, mipsY_LO, mipsN, mipsZ, mipsC, mipsV};

endmodule
