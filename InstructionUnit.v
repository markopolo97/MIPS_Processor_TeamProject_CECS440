`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  CPU_IU.v
 * Project:    Lab_Assignment_6
 * Designers:  Mark Aquiapao and TrieuVy Le
 * Rev. No.:   Version 1.0: Original
			   Version 1.1: Lab 5
			   Version 1.2: Lab 6, add PC_Sel to pass to PC_In
			   Version 1.3: Updated the PC_Sel 
 * Rev. Date:  April 22, 2019 
 *
 * Purpose: This modules serves as the Instruction Unit that instantiates the
 *				Program Counter register, Instruction Memory, and the Instruction 
 *				register.
 *
 *
 * ©R.W Allison 2019
 ****************************************************************************/
module Instruction_Unit(clk, reset, 
						PC_ld, PC_inc, PC_In, PC_out, PC_sel, 
						im_cs, im_rd, im_wr, 
						ir_ld, IR_out, 
						SE_16);
	
		input 		 	clk, reset, PC_ld, PC_inc, im_cs, im_rd, im_wr, ir_ld;
		input  [31:0] 	PC_In;
		input  [1:0]  	PC_sel;
		
		output [31:0] 	PC_out, IR_out, SE_16;

		wire   [31:0] 	IM_out, PC_MUX;

		// Calculate the effective address of either Branch or Jump
		assign PC_MUX =   (PC_sel==2'h0) ?  PC_In:
                          (PC_sel==2'h1) ?  {PC_out[31:28],IR_out[25:0],2'b00}:
						  (PC_sel==2'h2) ?  {PC_out + {SE_16[29:0],2'b00}}    :
										    PC_In;
										   
		
		// Program Counter to either inc or ld the EA to PC
		ProgramCounter pc	(	.clk(clk), 		 	
								.reset(reset), 
								.PC_In(PC_MUX), 	
								.PC_ld(PC_ld), 
								.PC_inc(PC_inc), 	
								.PC_out(PC_out)	);
			
		// 4096x8 Instruction Memory
		InstructionMemory im (	.clk(clk), 
								.Address(PC_out[11:0]), 
								.IM_In(32'b0), 
								.im_cs(im_cs), 
								.im_wr(im_wr), 
								.im_rd(im_rd), 
								.IM_Out(IM_out));
		

		// Initialize Register 
		InstructionRegister	ir	(.clk(clk), 		
								.reset(reset), 
								.load(ir_ld),	
								.D(IM_out), 	
								.Q(IR_out)	);
				
		// Sign Extend 16-bit to 32-bit for I-Type Instructions for RT
		assign SE_16 = { {16{IR_out[15]}}, IR_out[15:0]}; 							 
									 
endmodule
