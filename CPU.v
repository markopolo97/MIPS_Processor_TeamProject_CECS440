`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  CPU.v
 * Project:    Final Project
 * Designers:  Mark Aquiapao and TrieuVy Le
 * Rev. No.:   Version 1.0
 * Rev. No.:   Version 1.1: port mapped the barrel shifter and signals 
 * Rev. No.:   Version 1.2: added flags stored in stack pointer register 
 * and select signals for those regsiters  
 * Rev. No.:   Version 1.3: added the IO memory module contains the interrupt

 * Rev. Date:  April 22, 2019 
 *
 * Purpose: This modules serves as the Top Level of the Integer Datapath,
 *				Data Memory, IO Memory, MCU, and Instruction Unit. 
 *
 * Notes: The Address going into the Data Mmeory will only take 12 bits of 
 * 		 32-bit ALU_Out coming out of the Integer Datapath.
 
 * ©R.W Allison 2019
 ****************************************************************************/
module CPU(		clk, reset, 
				DM_out, Address, D_OUT, 
				intr, inta,
				dm_cs, dm_rd, dm_wr, 
				io_cs, io_rd, io_wr		);
		 
	input 			clk, reset;
	input  [31:0] 	DM_out;
	input 			intr; 
	
	
	output 			inta;
	output [31:0] 	Address, D_OUT;
	output 			dm_cs, dm_rd, dm_wr, io_cs, io_rd, io_wr;
	
	wire 			pc_ld, pc_inc, ir_ld;
	wire 			im_cs, im_rd, im_wr;
	wire			intr, inta;
	
	wire 			D_En,   HILO_ld;
	wire 			SP_Sel, S_Sel;
	wire [1:0] 		T_Sel,  pc_sel, DA_sel;
	wire [2:0] 		Y_Sel; 
	wire [4:0] 		FS, in_flagsToMCU, out_flagsFromMCU;
	
	
	wire 			C, N, V, Z;
	wire [31:0] 	IR_out, PC_out, SE_16;
	
	
	// Instantiation of MCU, IU, IDP
	MCU mcu (   .clk(clk), 		
				.reset(reset),   
				.intr(intr), 
				.C(C), .N(N), .Z(Z), .V(V), 						   
				.IR(IR_out), 	
				.inta(inta), 									
            
				//Program Counter signals 
				.pc_sel(pc_sel),   
				.pc_ld(pc_ld),   
				.pc_inc(pc_inc), 
				.ir_ld(ir_ld), 
				
				//Instruction Memory signals
				.im_cs(im_cs),     
				.im_rd(im_rd),   
				.im_wr(im_wr),
			
			
			
				// 5-bit status flags and selects 
				.stack_InFlags(in_flagsToMCU), 
				.stack_OutFlags(out_flagsFromMCU), 
				.sp_sel(sp_sel), 
				.s_sel(s_sel),
				
				// IDP signals 
				.D_En(D_En),       
				.DA_sel(DA_sel), 
				.T_Sel(T_Sel),   
				.HILO_ld(HILO_ld), 
				.Y_Sel(Y_Sel),   
				.FS(FS),
				
				// Data Memorysignals
				.dm_cs(dm_cs),     
				.dm_rd(dm_rd),   
				.dm_wr(dm_wr), 
				
				// I/O Memory signals
 				.io_cs(io_cs),     
				.io_rd(io_rd),   
				.io_wr(io_wr));			 
             
  
	Instruction_Unit iu(
				.clk(clk),   	  
				.reset(reset),  
				
				.PC_sel(pc_sel), 
				.PC_ld(pc_ld), 
				.PC_inc(pc_inc),
				.ir_ld(ir_ld), 
				
				// Instruction Memory signals
				.im_cs(im_cs),   
				.im_wr(im_wr), 
				.im_rd(im_rd),
				
				.PC_In(Address),   
				.PC_out(PC_out),     
				.IR_out(IR_out), 
				.SE_16(SE_16));

	IntegerDatapath idp( 
				.clk(clk), 
				.reset(reset), 
				.D_En(D_En),         
				.DA_sel(DA_sel),   
				.shtamt(IR_out[10:6]),
				.D_Addr(IR_out[15:11]), 
				.T_Addr(IR_out[20:16]), 				
				.S_Addr(IR_out[25:21]),        
				       
				.DT(SE_16),
				.stack_InFlags(out_flagsFromMCU), 
				.stack_OutFlags(in_flagsToMCU), 
				.sp_sel(sp_sel), 
				.s_sel(s_sel),
				.T_Sel(T_Sel),    
				.FS(FS),                            
				.HILO_ld(HILO_ld),   
				.DY(DM_out),                  
				.PC_In(PC_out),               
				.Y_Sel(Y_Sel),     
				.C(C), .V(V), .N(N), .Z(Z), 
				.ALU_OUT(Address), 
				.D_OUT(D_OUT));
				
endmodule
