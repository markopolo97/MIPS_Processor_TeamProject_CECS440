`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  IDP.v
 * Project:    Lab_Assignment_6
 * Designers:  TrieuVy Le and Mark Aquiapao
 * Rev. No.:   Version 1.0
 * Rev. Date:  April 22, 2019 
   Version 1.1: 4/13 removed pc_jr wire and use $rt as the jump reg.
   Version 1.2: 4/16 expaned T_sel to 2 bit to pass either T, DT, or status flags
   Version 1.3: 4/20 added sp_sel and s_sel for stack pointer and S_addr
				also added the 5-bit status flags from the operations of 
				barrel shifting
 *
 * Purpose: This modules serves as instantiation of the Register File and ALU. 
 *				The datapath plays an important role in the execution phase of the 
 *				instruction cycle.
 * 	- T_MUX and Y_MUX: 	Allows data to be sent into the Datapath through DT 
 *						and DY inputs coming from destinations such as 
 *						memory, I/O, or applicable instrcution register 
 *						fields.
 *
 *		- RS, RT, ALU_Out, and D_in Registers: Were added to the Integer Datapath 
 *				2.0 in order connect the data memory and the integer datapath. These added 
 *				registers do not need any load controls.
 *
 *		- DA Select : Allows the destination register of each instruction to 
 *			change from RD = IR[15:11] or  RT= IR[2016] depending 
 *						  on what type of instruction is executed.
 * 
 * Notes: HI and LO are 32-bit registers that will be used ONLY during MUL 
 *	      and DIV in the ALU for the results. 
 * ©R.W Allison 2019
 ****************************************************************************/
module IntegerDatapath(clk, reset, D_En, DA_sel , D_Addr, S_Addr, T_Addr, DT, T_Sel, 
					    FS, shtamt, HILO_ld, DY, PC_In, Y_Sel, N, C, Z, V, 
						D_OUT, ALU_OUT, stack_InFlags, stack_OutFlags, sp_sel, s_sel); 

	/***********************************************************************
	* Initialize input, output, and wire used for port mapping purposes. 
	* These control signals are to direct the operation control.
	* DT, DY, PC_in are 32-bit constants used as operands for certain ops. 
	* Wires are used for interconnection for T-MUX and Y-MUX selecting proper
	* data contents. 
	***********************************************************************/
    input 			clk, reset, D_En, HILO_ld;
	input 			sp_sel, s_sel;
	input  [1:0] 	DA_sel, T_Sel ;
    input  [4:0] 	D_Addr, S_Addr, T_Addr;
    input  [31:0] 	DT, DY, PC_In;
    input  [4:0] 	FS, shtamt;
	input  [4:0]    stack_InFlags;
	input  [2:0] 	Y_Sel; 
	
	output [4:0]    stack_OutFlags;
    output 			N, Z, C, V;
    output [31:0]   D_OUT, ALU_OUT;   
	
	wire 	 [31:0] 	T, S, T_MUX;
	wire   [31:0] 	Y_hi, Y_lo, HI_out, LO_out;
	wire   [31:0] 	RS, ALU_Out, D_in, S_MUX;
	wire   [4:0]	DA_out, stack_MUX   ; 
   
	// RegFile contains $r0 - $r31
	regfile32 		rf32 (	.clk(clk), 			
							.reset(reset), 
							.D(ALU_OUT),		
							.D_Addr(DA_out), 
							.S_Addr(stack_MUX), 	
							.T_Addr(T_Addr), 
							.D_En(D_En), 		
							.S(S), 	
							.T(T)	);
							
							
									
	// If I-Type Instruction DA_Sel = 1, RT is destination
	// If R-Type Instrcution DA_sel = 0, RD is destination 
	assign DA_out = (DA_sel  == 2'b00) ? D_Addr :
					(DA_sel  == 2'b01) ? T_Addr :
					(DA_sel  == 2'b10) ? 5'd31  :   // $ra 1Fh
					(DA_sel  == 2'b11) ? 5'd29  :   // $sp 1Dh
					   				    D_Addr ;   // default $rd
	
	// Thhe multiplexer controlled by sp_sel scalar choosing 
	// 1. selects $r29 or stack pointer register
	// 0. selects S_Addr
	assign stack_MUX = (sp_sel) ? 5'h1D : S_Addr;
	
	
	// The multiplexer is controlled by a scalar s_sel choosing betwwen
	// 1. selects the ALU_OUT result stored in the ALU_OUT or RS registers 
	assign S_MUX     = (s_sel)  ? ALU_Out: RS;
	
	
	
	
	// T-MUX to select either T data or DT as constant for MUL.
	assign T_MUX = (T_Sel == 2'h0) ?  T:
						(T_Sel == 2'h1) ?  DT:
						(T_Sel == 2'h2) ?  PC_In:
						(T_Sel == 2'h3) ?  {27'h0, stack_InFlags}:
												 T;
	
	
	
	// ALU module contains most of the operations referenced in the test fixture.
	ALU_32 	 		alu32 (	.S(S_MUX), 
							.T(D_OUT), 
							.FS(FS), 
							.shtamt(shtamt),
							.Y_HI(Y_hi), 
							.Y_LO(Y_lo), 
							.C(C), 
							.V(V), 
							.N(N), 
							.Z(Z)	);
									
			
	// Loadable Registers to either load 32-bit of HI or LO registers for MUL and DIV
	LoadReg  		hireg 	(	.clk(clk), 
										.reset(reset), 
										.load(HILO_ld),
										.D(Y_hi), 
										.Q(HI_out)	),
										
						loreg 	(	.clk(clk), 		
										.reset(reset), 
										.load(HILO_ld),
										.D(Y_lo), 	
										.Q(LO_out)	),
						
						rs 		(	.clk(clk), 		
										.reset(reset), 
										.load(1'b1), 	
										.D(S),     
										.Q(RS)		),
										
						rt 	 	(	.clk(clk), 
										.reset(reset), 
										.load(1'b1), 
										.D(T_MUX), 
										.Q(D_OUT)	),
									
									
						alu_out  (	.clk(clk), 
										.reset(reset), 
										.load(1'b1), 
										.D(Y_lo),  
										.Q(ALU_Out)	),
										
						d_in		(	.clk(clk), 
										.reset(reset), 
										.load(1'b1), 
										.D(DY),    
										.Q(D_in));


	assign stack_OutFlags = D_in[4:0];
	
	// ALU_OUT MUX selects accordingly depending on the preset value for each 32-bit
	assign ALU_OUT = 	(Y_Sel == 3'h0) ? ALU_Out	:
						(Y_Sel == 3'h1) ? HI_out 	:
						(Y_Sel == 3'h2) ? LO_out 	:
						(Y_Sel == 3'h3) ? D_in   	:
						(Y_Sel == 3'h4) ? PC_In  	: 
										  ALU_Out 	;

endmodule
