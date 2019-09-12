`timescale 1ns / 1ps
/***************************************************************************
*
* Author: 	TrieuVy Le
* Filename: MIPS_32
* Date: 	Feb. 26, 2019
* Version:	1
*
* Notes:    The module includes (all - 2)operations (MUL and DIV) 
*           The 5-bit FS will select which ALU operation is to be performed.
*			N flag is determined by the MSB Y_LO[31].
*			Z flag is determined by the content of Y_LO if all 0's .
*			Y_HI is always 0's due to data is assigned to Y_LO.
*			>>  or <<  : Logical shift and fill with zero.
*			>>> or <<< : Arithmetic shift and keep sign  .
*			Signed -- Arithmetic -- Integer -- >>> <<< -- MSB
*			Unsigned -- Logical -- Regular -- >> << -- No negative
*			If a status flag is not affected by the ALU operation, set to X.
*			To any unsigned operations including ADDU, SUBU, SLTU, the negative
*			flag is set to 0, by definition, it's positive number thus 
*			do not require an arithmetic sign.
***************************************************************************/
module MIPS_32(mipsS, mipsT, mipsFS, C, V,N, Z, Y_hi, Y_lo);

	/****************************************************************************
	* 32 bit inputs S, T and 5 bit OpCode.
	* Flag C, N, Z, V and lower 32 bit output (do not utilize upper 32 in MIPS).
	****************************************************************************/
	input [31:0] mipsS;
	input [31:0] mipsT;
	input [4:0]  mipsFS;
	
	output reg C, V, N, Z;
	output reg [31:0] Y_lo, Y_hi;

	parameter [4:0] PASS_S  = 5'h00,
					  	 PASS_T  = 5'h01,
						 ADD     = 5'h02,
						 ADDU    = 5'h03,
						 SUB	 = 5'h04,
						 SUBU    = 5'h05,
						 SLT	 = 5'h06,
						 SLTU    = 5'h07,
						 MUL     = 5'h1E,
						 DIV     = 5'h1F,
						 
						 AND     = 5'h08,
						 OR      = 5'h09,
						 XOR     = 5'h0A,
						 NOR     = 5'h0B,
						 SRL     = 5'h0C,
						 SRA     = 5'h0D,
						 SLL     = 5'h0E,
						 ANDI    = 5'h16,
						 ORI     = 5'h17,
						 LUI     = 5'h18,
						 XORI    = 5'h19,
						 
						 INC     = 5'h0F,
						 INC4    = 5'h10,
						 DEC     = 5'h11,
						 DEC4    = 5'h12,
						 ZEROS   = 5'h13,
						 ONES    = 5'h14,
						 SP_INIT = 5'h15;
						 
						 
						 
						 
						 
						 
						 
		/*******************************************************************************
		* Casting integers using for MUL, DIV, SLT, or/SRA.
		* Combinational logic depending on the hex values of FS.
		*******************************************************************************/
		integer 	INT_S, INT_T;

		
		always @ (*) begin
			INT_S = mipsS;
			INT_T = mipsT;
						
			case (mipsFS)
				PASS_S: {C, V, Y_lo}	= {1'bx, 1'bx, mipsS};
				PASS_T: {C, V, Y_lo}	= {1'bx, 1'bx, mipsT};
				/********************************************************************
				* Signed operations ADD: We compare the MSB of both operands, 
				* If both MSB are positive and sum is negative => Overflow
				* If both MSB are negative and sum is positve  => Overflow 
				********************************************************************/
				ADD     : begin												
						  {C, Y_lo} = mipsS + mipsT; 
							  case ({mipsS[31], mipsT[31], Y_lo[31]})
									3'b001: 	V = 1'b1;
									3'b110: 	V = 1'b1;
									default: V = 1'b0;
								endcase
						  end
				
				ADDU    : begin
						  {C, Y_lo} = mipsS + mipsT;
						  V = (C == 1'b1) ? 1'b1 : 1'b0; 
							 end 
				
				/********************************************************************
				* Signed operations SUB: We compare the MSB of both operands & result 
				* If (+) - (-) and result is negative => Overflow  
				* If (-) - (+) and result is positive => Overflow
				*******************************************************************/
				
				SUB     : begin
						  {C, Y_lo} = mipsS - mipsT; 
							  case ({mipsS[31], mipsT[31], Y_lo[31]})
									3'b011: 	V = 1'b1;
									3'b100: 	V = 1'b1;
									default: V = 1'b0;
								endcase
							 end
				
				SUBU    : begin
						  {C, Y_lo} = mipsS - mipsT;
						  V = (C == 1'b1) ? 1'b1 : 1'b0; 
							 end
				
				SLT     : {C, V, Y_lo} = {1'bx, 1'bx, ((INT_S < INT_T) ? 32'b1 : 32'b0)};
				SLTU    : {C, V, Y_lo} = {1'bx, 1'bx, ((mipsS < mipsT) ? 32'b1 : 32'b0)};
				AND     : {C, V, Y_lo} = {1'bx, 1'bx, mipsS & mipsT}; 
				OR      : {C, V, Y_lo} = {1'bx, 1'bx, mipsS | mipsT};
				XOR	  : {C, V, Y_lo} = {1'bx, 1'bx, mipsS ^ mipsT};
				NOR	  : {C, V, Y_lo} = {1'bx, 1'bx, ~(mipsS | mipsT)};
				SRL     : {C, V, Y_lo} = {mipsT[0], 1'bx, mipsT >> 1};			
				SRA	  : {C, V, Y_lo} = {mipsT[0] , 1'bx, mipsT[31], mipsT[31:1]};
				SLL     : {C, V, Y_lo} = {mipsT[31], 1'bx, mipsT << 1};
				ANDI    : {C, V, Y_lo} = {1'bx, 1'bx, mipsS & ({16'h0, mipsT[15:0]})};
				ORI     : {C, V, Y_lo} = {1'bx, 1'bx, mipsS | ({16'h0, mipsT[15:0]})};
				LUI     : {C, V, Y_lo} = {1'bx, 1'bx, ({mipsT[15:0], 16'b0})};
				XORI    : {C, V, Y_lo} = {1'bx, 1'bx, mipsS ^({16'b0, mipsT[15:0]})};
				
				INC     : begin
							{C, V, Y_lo} = (mipsS + 1);
							V = (mipsS[31] == 1'b0 && Y_lo[31] == 1'b1) ? 1'b1 : 1'b0;
						  end
						  
				INC4    : begin 
							{C, V, Y_lo} = (mipsS + 4);
							V = (mipsS[31] == 1'b0 && Y_lo[31] == 1'b1) ? 1'b1 : 1'b0;
						  end
				DEC     : begin
							{C, V, Y_lo} = (mipsS - 1);
							V = (mipsS[31] == 1'b1 && Y_lo[31] == 1'b0) ? 1'b1 : 1'b0;
						  end
						  
				DEC4    : begin 
							{C, V, Y_lo} = (mipsS - 4);
							V = (mipsS[31] == 1'b1 && Y_lo[31] == 1'b0) ? 1'b1 : 1'b0;
						  end		  
						  
				ZEROS   : {C, V, Y_lo} = {1'bx, 1'bx, 32'b0};
				ONES    : {C, V, Y_lo} = {1'bx, 1'bx, 32'hFFFFFFFF};
				SP_INIT : {C, V, Y_lo} = {1'bx, 1'bx, 32'h3FC};
				
				default : {C, V, Y_lo} = {1'bx, 1'bx, 32'h0F0F0F0F};
 			endcase
			/***********************************************************
			* Negative status flag is determined by Y_LO MSB
			* Zero status flag is determined if all bits are 0's
			* Y_HI is default to be = 32'b0 unless specified otherwise.
			* To differentiate the unsigned operations, we do not take in
			* consideration of MSB due to that they are positive numbers,
			* thus do not require the arithmetic sign bit.
			************************************************************/
			N = (mipsFS == ADDU || mipsFS == SUBU || mipsFS == SLTU) ? 1'b0 : Y_lo[31]; 
			Z = (Y_lo ==  32'b0) ? 1'b1 : 1'b0; 
			Y_hi = 32'h0;
		end	
endmodule
