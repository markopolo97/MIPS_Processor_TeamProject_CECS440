`timescale 1ns / 1ps
/****************************** C E C S 4 4 0 *********************************
 *
 * File Name:  CPU_IU.v
 * Project:    Final Project
 * Designers:  Mark Aquiapao and TrieuVy Le
 * Rev. No.:   1.13
 * Version 1.1  (3/29): TrieuVy added barrel and flags
 * Version 1.2  (4/3) : Mark added SLL, SRL, SRA, ADDU, SUB, SUBU, SLT, SLTU, MUL,
 *					    DIV, SETIE
 * Version 1.3  (4/4) : TrieuVy added JR, LW, BEQ, BNE, MUL, DIV, J, JAL, MFHI, MFLO,
				
 * Version 1.4  (4/11): TrieuVy added SETIE, BLEZ, BGEZ
 * Version 1.5  (4/13): Mark edited and organized parameter values of states 
 * Version 1.6  (4/15): Updated the flags with the barrel shifter and added the signals 
 * Version 1.7  (4/16): Tested out the 2, 3, 4 modules for the shifting instructions.
   Wiring/port mapping issue really affected output
 * Version 1.8  (4/17): Debugged and tested for memory modules 4 to 9 because they
   all use the same DataMem 
 * Debugged control signals for some new instructions
 * Version 1.9  (4/18): Commented most of the instructions.
   Also added a few more instructions for enhancements. 
 * Version 1.10 (4/19): Rearranged the formatting of the instructions due to the fact 
 * it is too clustered, needs to be organized better.
 * Version 1.11 (4/21): Debugged SETIE due to the introduction of the instruction 
   in the memory.
 * Version 1.12 (4/22): Added the RETI instruction which takes in total of 8 cycles
   We saved the updated PC and flags to stack pointers and return at appropriate cycle
   Revised last time before submitting.
						
					
 
				
 * Rev. Date:  April 22, 2019 
 * Purpose:    A state machine implementing the MIPS Control Unit (MCU) 
 *             for the major cycles of fetch, execute and some MIPS instructions 
 *             from memory, including checking for interrupts. 
 *			   Each state represents one clock cyle where EVERY control signal 
 *			   is updated at the negative edge of the clock. 
 *
 * Notes:		This control unit is a modified MOORE FSM that will change states
 *				on the rising edge of the clock. 
 *				
 * If using INTERRUPT then we will print out all 32 registers otherwise
 * if not, we will print out the first 16 registers.
 *
 ******************************************************************************
 
 *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
 * MCU CONTROL WORDS TEMPLATE FOR EVERY SINGLE CYCLE
 *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
 *
 * 	 inta = 0;	 
 *   FS   = 5'h00;
 *   {pc_sel, pc_ld, pc_inc, ir_ld}        = 5'b00_0_0_0;
 *   {im_cs, im_rd, im_wr}                 = 3'b0_0_0;
 *   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
 *   {dm_cs, dm_rd, dm_wr} 				   = 3'b0_0_0;
 *   {io_cs, io_rd, io_wr} 				   = 3'b0_0_0;
 *   {sp_sel, s_sel} 					   = 2'b0_0;
 *
 *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/


module MCU (clk, reset, intr, 					// system inputs
			C, N, Z, V, 						// ALU status inputs
			IR, 								// Instruction Register input
			inta, 								// output to I/O subsystem
			pc_sel,  pc_ld,  pc_inc, ir_ld, 	// rest of control word fields
			im_cs,   im_rd,  im_wr,				// instruction mem control signals
			D_En,    							// enable to write data to reg signal
			DA_sel, 							// destination register to write to 2 bit
			T_Sel,  							// select either T, DT, PC_IN, or flags
			HILO_ld,  							// enables to write data to HI or LO regs
			Y_Sel,								// selects 1 out of 5 preset 32-bit values
//												   between ALU_OUT, HI, LO, D_IN, PC_IN 
			s_sel, 								// selects value for S register, ALU_OUT or RS
			sp_sel, 							// write to S_Addr with either $r29/$ra or S_Addr
			stack_InFlags, stack_OutFlags,		// carries flags from IDP after calculations,
// 												   then transfer to MCU for control words
			dm_cs,   dm_rd,  dm_wr,				// data memory control signals
			io_cs,   io_rd,  io_wr,				// instruction memory control signals
			FS);								// function select depends on operations
//*****************************************************************************

	// Initialize input, output, integer for port mapping purposes
	input    		   clk, reset, intr; 		// system clock, reset, intr
	input 		       C, N, Z, V; 		   		// Integer ALU status inputs
	input 	 [4:0] 	   stack_InFlags;			// out from IDP to MCu
	input    [31:0]    IR; 						// Instruction register
	
	output   reg	   inta; 			    	// Interrupt acknowledge
     
	// Program Counter Controls
	output   reg	   pc_ld, pc_inc, ir_ld;    // Program Counter Register
	
	//Instruction Memory Controls
	output   reg	   im_cs, im_rd,  im_wr;    // Instruction Memory
	
    // Data Memory Controls 
	output   reg	   dm_cs, dm_rd,  dm_wr;    // Data Memory
	
	// IO Module Controls
	output   reg       io_cs,   io_rd,  io_wr;  // Input/Output Module
	
	// Integer Datapath (IDP) Controls
    output   reg	   D_En, HILO_ld; 			// Register File
	output   reg [1:0] pc_sel, DA_sel, T_Sel;   // T-MUX and DA_MUX for T or D_Addr
	output   reg [2:0] Y_Sel;                   // ALU_Out select
	output   reg [4:0] FS;						// Function select
	output 	 reg 	   s_sel, sp_sel;			// Stack pointer and S_Addr selects
	output   reg [4:0] stack_OutFlags;			// flags received from IDP operations 
	
	// Loop counter, Data and Instruction Memory variables
	integer i, DM_Dump, IOM_Dump;				
		      
	
	  
	// Function select assignments 
	parameter [4:0] 		 pass_s  = 5'h00,
							 pass_t  = 5'h01,
							 add     = 5'h02,
							 addu    = 5'h03,
							 sub	 = 5'h04,
							 subu    = 5'h05,
							 slt	 = 5'h06,
							 sltu    = 5'h07,
							 mul     = 5'h1E,
							 div     = 5'h1F,
							 
							 and_op  = 5'h08,
							 or_op   = 5'h09,
							 xor_op  = 5'h0A,
							 nor_op  = 5'h0B,
							 
							 srl     = 5'h0C,
							 sra     = 5'h0D,
							 sll     = 5'h0E,
							 
							 andi    = 5'h16,
							 ori     = 5'h17,
							 lui     = 5'h18,
							 xori    = 5'h19,
							      
							 inc     = 5'h0F,
							 inc4    = 5'h10,
							 dec     = 5'h11,
							 dec4    = 5'h12,
							 zeros   = 5'h13,
							 ones    = 5'h14,
							 sp_init = 5'h15;
							 



	// state assignments
	 parameter
		RESET 	= 00,  	FETCH  = 01,  DECODE = 02,
		
		// R-Types
		SLL		= 03,  	SRL	   = 04,  SRA	 = 05,
		ADD 	= 06,  	ADDU   = 07,  SUB 	 = 08,	
		SUBU    = 09,	AND    = 10,  OR 	 = 11,  
		NOR     = 12,   XOR    = 13,   SLT	 = 14,  
		SLTU	= 15, 	MUL    = 16,  DIV    = 17,
		MFHI    = 29,   MFLO   = 30,  SETIE  = 18,  
		
		// I-Types
		ORI	    = 19,   LUI    = 20,  LW 	 = 21, 	
		LW2     = 22,  	SW     = 23,  XORI	 = 24,	
		ADDI    = 25,  	SLTI   = 26,  SLTIU  = 27,	
		ANDI    = 28,   
		
		// Jumps
		JR = 31, JR2 = 32, 
		J  = 35, JAL = 36, 
		
		// Branches
		BEQ    = 37, BEQ2  = 38, 
		BNE    = 39, BNE2  = 40,
		BLEZ   = 41, BLEZ2 = 42, 
		BGTZ   = 43, BGTZ2 = 44, 
		BLT    = 62, BLT2  = 63, 
		BGE    = 64, BGE2  = 65,
		
		// Write Backs
		
		WB_alu 	= 45,  WB_imm = 46,  WB_Din = 47,
		WB_hi 	= 48,  WB_lo  = 49,  WB_mem = 50,
		
		// Interrupts and Others
		INTR1 	= 501, INTR2     = 502, INTR3 = 503,
		INTR4 	= 504, INTR5     = 505, INTR6 = 506,
		BREAK 	= 510, ILLEGAL_OP = 511, 
		
		
		//Enhancement type instructions
		INPUT  = 51, INPUT2  = 52,
		OUTPUT = 53, OUTPUT2 = 54,
		RETI   = 56, RETI2   = 57, RETI3 = 58, 
		RETI4  = 59, RETI5   = 60, RETI6 = 61,
		CLR    = 66, CLR2    = 67, 
		MOV    = 68, MOV2    = 69, 
		NOP    = 70,
		PUSH   = 71, PUSH2   = 72, PUSH3 = 73, PUSH4 = 74,
		POP    = 75, POP2    = 76, POP3  = 77, POP4  = 78,   POP5 = 79; 
		

	//state register (up to 512 states)
	reg [8:0] state;

   /******************
    * Flags register *
    ******************/
   reg   psi, psc, psv, psn, psz;   // flags present state registers
   reg   nsi, nsc, nsv, nsn, nsz;   // flags next state registers

   // Updating flags register
   always @(posedge clk, posedge reset)
      if(reset)
         {psi, psc, psv, psn, psz} = 5'b0;
      else
         {psi, psc, psv, psn, psz} = {nsi, nsc, nsv, nsn, nsz};

	/************************************************
	 * 440 MIPS CONTROL UNIT (Finite State Machine) *
	 ************************************************/
	always @(posedge clk, posedge reset)
	  if (reset)
		 begin
			// ALU_Out <- 32'h3FC
			@(negedge clk)
				inta = 0;   FS = sp_init;
                {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				{D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                {sp_sel, s_sel}						  = 2'b0_0;
			 #1 {nsi, nsc, nsv, nsn, nsz} 			  = 5'b0;
			state = RESET;
		 end
	  else
		 case (state)
		    FETCH:
				if ((inta==0 & (intr==1 & psi==1))) // Recieve Interrupt Signal
				  begin //*** new interrupt pending; prepare for ISR ***
					// control word assignments for "deasserting" everything
					
				   @(negedge clk)
				   inta = 0;   FS = 5'h0;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
			    #1 {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
					state = INTR1;
				  end
				else  // No Interrupt Signal involved
				  begin //*** no new interrupt pending; fetch and instruction ***
					if(((inta==1 & intr==1) || (psi==1 & intr==0))) inta=1'b0;
					// control word assignments for IR <- iM[PC]; PC <- PC+4

					@(negedge clk)
				    inta = 0;   FS = 5'h0;
                    {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_1_1;
                    {im_cs, im_rd, im_wr} 		   		  = 3'b1_1_0;
				    {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                    {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                    {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                    {sp_sel, s_sel}						  = 2'b0_0;
			    #1  {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
			         state = DECODE;
				  end

			 RESET:
				begin
				  // control word assignments for $sp <- ALU_Out(32'h3FC)
				  @(negedge clk)
                  inta=0;   FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld} 		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 				  = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_11_00_0_000; 	
                  {dm_cs, dm_rd, dm_wr} 			      = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
				end

			 DECODE:
				begin
				  @(negedge clk)
              // check for MIPS format
			  // R Type
				  if (IR[31:26] == 6'h0)
					begin 
                  // it is an R-type format
			      	// control word assignments: RS <- $rs, RT <- $rt (default)
                    inta = 0;   FS = 5'h0;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
			    #1 {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
                  // check for function for R type
                  case (IR[5:0])
                    6'h00 :  state = SLL;
                    6'h02 :  state = SRL;
                    6'h03 :  state = SRA;
                    6'h08 :  state = JR;
                    6'h10 :  state = MFHI;
                    6'h12 :  state = MFLO;
                    6'h18 :  state = MUL;
                    6'h1A :  state = DIV;
                    6'h20 :  state = ADD;
                    6'h21 :  state = ADDU;
					6'h22 :  state = SUB;
					6'h23 :  state = SUBU;
					6'h24 :  state = AND;
					6'h25 :  state = OR;
					6'h26 :  state = XOR;
					6'h27 :  state = NOR;
					6'h2A :  state = SLT;
					6'h2B :  state = SLTU;
					6'h0D :  state = BREAK;
					6'h1F :  state = SETIE;
                    default: state = ILLEGAL_OP;
					   endcase
				    end // end of if for R-type Format
					
              else if(IR[31:26] == 6'h1F)
					 begin 
					/*************************************************************
					* Enhancement Type instructions 
					* Since it is still decode state, the default is to load $rs and $rt 
					**************************************************************/
                    inta = 0;   FS = 5'h0;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
			    #1 {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
                  
                  // The available states for the enhancement type
                  case (IR[5:0])
                     6'h33  : state = CLR;
                     6'h44  : state = MOV;
                     6'h55  : state = NOP;
                     6'h66  : state = PUSH;
                     6'h77  : state = POP;
                     default: state = ILLEGAL_OP;
                  endcase
                end  // end of if E-key format
				  else
					 begin 
                  // control word assignments: RS <- $rs, RT <- DT(se_16)
                    inta = 0;   FS = 5'h0;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_01_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
			    #1 {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
                  
                  // Check opcode for I and J type
					   case (IR[31:26])
                    6'h02 : state = J;
                    6'h03 : state = JAL;
                    6'h04 : state = BEQ;
                    6'h05 : state = BNE;
                    6'h06 : state = BLEZ;
                    6'h07 : state = BGTZ;
					6'h30 : state = BLT;
                    6'h31 : state = BGE;
                    6'h08 : state = ADDI;
                    6'h0A : state = SLTI;
                    6'h0B : state = SLTIU;
                    6'h0C : state = ANDI;
					6'h0D : state = ORI;
                    6'h0E : state = XORI;
					6'h0F : state = LUI;
                    6'h23 : state = LW;
					6'h2B : state = SW;
                    6'h1C : state = INPUT;
                    6'h1D : state = OUTPUT;
                    6'h1E : state = RETI;

			       default: state = ILLEGAL_OP;
						endcase
				  
				/******************************************************************
				* Calculations for the branches.
				* T_Sel selects 0: $RT <= $rt, take the IR[15:0] imme16 to calculate
				* branch address because if any branch states, the default is to grab T
				* and calculate branch address. 
				******************************************************************/
				
                  if(state == BEQ || state == BNE || state == BLEZ|| state == BGTZ||
                     state == BLT || state == BGE  )
                     T_Sel = 2'b00;
                  else
                     T_Sel = 2'b01;
                  
					 end 
				end // end of DECODE
            
   /***************************************************************************
   * 					R TYPE INSTRUCTIONS
   ***************************************************************************/ 
			SLL:
				begin
				  // control word assignments: ALU_Out <- $rt << shamt
				  @(negedge clk)
                    inta=0;	 FS=sll;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
			    #1 {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
                   state = WB_alu;
				end
				
			SRL:
				begin
				  // control word assignments: ALU_Out <- $rt >> shamt
				  @(negedge clk)
                   inta=0;	FS=srl;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
			    #1 {nsi, nsc, nsv, nsn, nsz} 			  = {psi, psc, psv, psn, psz};
                    state = WB_alu;
				end
				
			SRA:
				begin
				  // control word assignments: ALU_Out <- $rt >> shamt
				  inta = 1'b0; FS = sra;
				  @(negedge clk)
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		              = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
				
				 
			
			 ADD:
				begin
				  // control word assignments: ALU_Out <- $rs + $rt
				  @(negedge clk)
                  inta=0;	 FS=add;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
			
			ADDU:
				begin
				  // control word assignments: ALU_Out <- $rs + $rt
				  @(negedge clk)
                  inta=0;	 FS=addu;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
				
			SUB:
				begin
				  // control word assignments: ALU_Out <- $rs - $rt
				  @(negedge clk)
                  inta=0;	 FS=sub;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
				
			SUBU:
				begin
				  // control word assignments: 
				  @(negedge clk)
				  // control word assignments: ALU_Out <- $rs - $rt
				  @(negedge clk)
                  inta=0;	 FS=subu;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
				
			AND:
				begin
				  // control word assignments: ALU_Out <- $rs & $rt
				  @(negedge clk)
                  inta=0;	 FS=and_op;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end

			OR:
				begin
				  // control word assignments: ALU_Out <- $rs | $rt
				  @(negedge clk)
                  inta=0;	 FS=or_op;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			NOR:
				begin
				  // control word assignments: ALU_Out <- ~($rs | $rt)
				  @(negedge clk)
                  inta=0;	 FS=nor_op;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			XOR:
				begin
				  // control word assignments: ALU_Out <- $rs ^ $rt
				  @(negedge clk)
                  inta=0;	 FS=xor_op;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			
				
			SLT:
				begin
				  // control word assignments: ALU_Out <- $rs < $rt ? 1 : 0
				  @(negedge clk)
                  inta=0;	 FS=slt;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
				
			SLTU:
				begin
				  // control word assignments: ALU_Out <- $rs < $rt ? 1 : 0
				  @(negedge clk)
                  inta=0;	 FS=sltu;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
				
			
			MUL:
				begin
				  // control word assignments: {Hi,Lo} <- R[$rs] * R[$rt]
				  @(negedge clk)
                  inta=0;	 FS=mul;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_1_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = FETCH;
				end
				
			DIV:
				begin
				  // control word assignments: Lo <- R[$rs] / R[$rt], Hi <- R[$rs] % R[$rt]
				  @(negedge clk)
                  inta=0;	 FS=div;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_1_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_alu;
				end
			
			MFHI:
				begin
				  // control word assignments: R[$rd] <- Hi
				  
				  @(negedge clk)
				  inta=0;	 FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_00_00_0_001;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 			  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				
			MFLO:
				begin
				  // control word assignments: R[$rd] <- Lo
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_00_00_0_010;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				
            
         
			SETIE:
				begin
				  // control word assignments: psi <- 1'b1
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {1'b1, psc, psv, psn, psz};
                 state = FETCH;
				end
            
   /***************************************************************************
   * 					I TYPE INSTRUCTIONS
   ***************************************************************************/    
	

		ORI: 
            begin
			// ALU_OUT <= RS($rs) | {16'h0, RT(SE_16)} 
				  @(negedge clk)
                  inta=0;	 FS=ori;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          XORI: 
            begin
			// ALU_OUT <= RS($rs) ^ {16'h0, RT(SE_16)} 
				  @(negedge clk)
                  inta=0;	 FS=xori;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          LUI: 
			begin
			// ALU_OUT <= {RT(SE_16), 16'h0} 
				  // control word assignments for ALU_Out <- { RT[15:0], 16'h0}
				  @(negedge clk)
                  inta=0;	 FS=lui;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          LW: 
            begin
			// Effective Address calculation
			// ALU_OUT <= RS($rs) + RT(SE_16) 
				  @(negedge clk)
                  inta=0;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = LW2;
				end
          LW2: 
            begin
			// Read the memory content and store in D_IN 
			// D_IN <= M[ALU_OUT] 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_1_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_Din;
				end
            
			SW: 
				begin
				// Effective Address calculation
				// ALU_OUT <= RS($rs) + RT(SE_16) 
				  @(negedge clk)
                  inta=0;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_mem;
				end
			
			ADDI: 
            begin
			// ALU_OUT <= RS($rs) + RT(SE_16)
				  @(negedge clk)
                  inta=0;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;	
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_imm;
				end
            
         SLTI: 
            begin
			// This instruction compares if ( RS($rs) < RT(SE_16) )? 1:0;
			// ALU_OUT <= ( RS($rs) < RT(SE_16) )? 1:0
				  @(negedge clk)
                  inta=0;	 FS=slt;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;	
				  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_imm;
				end
            
          SLTIU: 
            begin
			// This instruction compares if ( RS($rs) < RT(unsigned(SE_16)) )? 1:0;
			// ALU_OUT <= ( RS($rs) < RT(SE_16) )? 1:0
				  @(negedge clk)
                  inta=0;	 FS=sltu;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = WB_imm;
				end
            
          ANDI: 
            begin
			// ALU_OUT <= RS($rs) & RT(SE_16) 
				  @(negedge clk)
                  inta=0;	 FS=andi;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
				
		
		/***************************************************************************
		 * 					J TYPE INSTRUCTIONS
		 ***************************************************************************/ 
				
				
			
         J:
            begin
				  // PC <= PC + SE_16(IR[25:0]) << 2 (Calculate the effective address
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b01_1_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
             
         JAL: 
            begin
			// Update PC with the calculation of Jump effective address and also
			// save the current PC in $r31
			// PC  <= PC + SE_16(IR[25:0]) << 2
			// $ra <= PC
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b01_1_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_10_00_0_100;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				
			JR:
				begin
				  // control word assignments: PC <- [$rt]
				  @(negedge clk)
                   inta=0;	 FS=5'h0;
                   {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = JR2;
				end
				
			JR2:
				begin
				  // control word assignments: PC <- [$rt]
				  @(negedge clk)
                   inta=0;	 FS=5'h0;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_1_0_0;
                   {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}  = 9'b0_00_00_0_000;
                   {dm_cs, dm_rd, dm_wr}		          = 3'b0_0_0; 								
                   {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                   {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
		/***************************************************************************
		* 					Branches INSTRUCTIONS
		***************************************************************************/ 
 
         BEQ:
            begin
               // The comparison using subtraction
				  // ALU_OUT <= RS - RT
				  @(negedge clk)
                  inta=0;	 FS=sub;
                  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                  state = BEQ2;    
				end
         BEQ2:
            begin
			// If zero flag is 1 meaning s = t, then branch to the label address
			// else go back to fetch state. 
			// PC <= PC + SE_16(IR[25:0] << 2) 
                  inta=0;   FS=5'h00;
                  if(psz == 1)
                         {pc_sel, pc_ld, pc_inc, ir_ld}   = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld}   = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
                  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
                  {sp_sel, s_sel}						  = 2'b0_0;						
              #1    {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
            end
            
         BNE:
            begin
            // The comparison using subtraction
				  // ALU_OUT <= RS - RT
              @(negedge clk)
              inta=0;	 FS=sub;
              {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
              {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
			  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
              {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
              {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
              {sp_sel, s_sel}						  = 2'b0_0;								
          #1  {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
              state = BNE2;   
				end
         BNE2:
            begin
			// If zero flag is 0 meaning s != t, then branch to the label address
			// else go back to fetch state. 
			// PC <= PC + SE_16(IR[25:0] << 2)
				  
				  @(negedge clk)
                                             inta=0;   FS=5'h00;
                  if(psz == 1'b0) 
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
				end
          
         BLEZ:
            begin
               // The comparison using subtraction
				  // ALU_OUT <= RS - RT
				  @(negedge clk)
                  inta=0;	 FS=sub;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;									
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                  state = BLEZ2;
				end
         BLEZ2:
            begin
			// In this case, we are checking for RS against RT(0x0000_0000) if RS = 0's 
			// then we will check for both senarios:
			// Less than would result in a negative 
			// Equal would result in a zero 
			// So if either both is active then branch to the effective address. 
			// PC <= PC + SE_16(IR[25:0] << 2)
              @(negedge clk)
                  inta=0;   FS=5'h00;
                  if(psn == 1 || psz == 1) 
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                  inta=0;	 FS=sub;
              
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;	
                  state = FETCH;
				end  
            
         BGTZ:
            begin
				  // The comparison using subtraction
				  // ALU_OUT <= RS - RT
				  @(negedge clk)
                  inta=0;	 FS=sub;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;	
				  #1  {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                  state = BGTZ2;
				end
         BGTZ2:
            begin
			// In this case, we are checking for RS against RT(0x0000_0000) if RS = 0's 
			// then we will check for both senarios:
			// Greater than would result in a positive, meaning negative flag stays low 
			// Equal would result in a zero 
			// So if either senarios is true then branch to the effective address. 
			// PC <= PC + SE_16(IR[25:0] << 2)
				  @(negedge clk)
                  inta=0;   FS=5'h00;
                  if(psn == 0 || psz == 1) 
                         {pc_sel, pc_ld, pc_inc, ir_ld}   = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld}   = 5'b00_0_0_0;
                  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;	 							
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
				end
				
		BLT: 
				begin
				// The comparison using subtraction
				// ALU_OUT <= RS - RT 
				  @(negedge clk)
                  inta=0;	 FS=sub;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = BLT2;
				end
         BLT2: 
				begin
				  // If negative flag is 1 meaning s < t, then branch to the ea
				  // PC <= PC + SE_16 << 2 
				  @(negedge clk)
                  inta=0;	 FS=5'h00;
				  if (psn) 
							{pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
				  else
							{pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
         
         BGE: 
				begin
				  // The comparison using subtraction
				  // ALU_OUT <= RS - RT
				  @(negedge clk)
                  inta=0;	 FS=sub;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = BGE2;
				end
         BGE2: 
				begin
				  // If zero flag is 1 meaning s = t,
				  // forcing to check for less than case, then branch to the ea
				  // PC <= PC + SE_16 << 2
				  @(negedge clk)
                  inta=0;	 FS=5'h00;
				  if(psn == 0 || psz == 1) 
						   {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
				  else
						   {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end

       /***************************************************************************
	   * 					Write Backs INSTRUCTIONS
	   ***************************************************************************/ 
			 WB_alu: 
				begin
				// R($rd) <= ALU_OUT 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end

			 WB_imm: 
				begin
				// R($rt) <= ALU_OUT 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_01_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end

			 WB_mem: 
				begin
				// M[ALU_OUT($rs + SE_16) <= RT($rt) 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_0_1; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				
			WB_Din: 
				begin
				// R($rt) <= D_IN(M[ALU_OUT])
					  @(negedge clk)	
					  inta=0;	 FS=5'h0;
					  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
					  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
					  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_01_00_0_011;
					  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
					  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
					  {sp_sel, s_sel}						  = 2'b0_0;
				  #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
					 state = FETCH;
					end
					
					
	/***************************************************************************
   * 					Interrupt and other INSTRUCTIONS
   ***************************************************************************/ 			           
			 INTR1:
				begin
				// $ra <= PC and RS <= $sp
				// The return addr will get the copy of program counter ($r31)
				// The RS register will get the content of stack pointer ($r29)
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_10_00_0_100;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b1_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
               state = INTR2;
				end
			 INTR2:
				begin
				  
				  // The ALU_OUT register will get the content of stack pointer reg
				  // ALU_OUT <= $r29
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR3;
				end
          INTR3:
				begin
				// Since we have a fixed interrupt service routine addr of 0x3FC 
				// we can now read that address into D_IN
				// D_IN <= M[ALU_OUT(0x3FC)]
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_1_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR4;
				end
			 INTR4:
				begin
				// Copy the content of the memory address of the stack pointer reg to PC
				// ALU_OUT reg gets the pre-decremented by 4 of stack pointer reg
				// RT register is loaded with the current PC
				// PC <= D_IN(M[$sp]), ALU_OUT <= $sp - 4, $RT <= PC
				  @(negedge clk)
                  inta=0;	 FS=dec4;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_1_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_10_0_011;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR5;
				end
          INTR5:
				begin
				// To make a PUSH instruction to PC onto the stack, $r29 gets decremented
				// push the flags on stack too through RT register
				// M[$r29] <= RT(PC), ALU_OUT <= ALU_OUT($r29 - 4) - 4, RT <= 5-bit Flags
				  @(negedge clk)
                  inta=0;	 FS=dec4;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_11_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_0_1; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR6;
				end
          INTR6:
				begin
				// Again we will push the flags like such {27'h0, 5-bit flags} 
				// The stack pointer reg gets the address of current stack pointer after 
				// being pushed twice then we can set the acknowledge of interrupt
				// M[ALU_OUT($r29 - 8) <= RT({27'h0, 5-bit flags})
				// R($29) <= ALU_OUT($r29 - 8) and inta = 1'b1
				  @(negedge clk)
                  inta=1'b1;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_11_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_0_1; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {1'b0, psc, psv, psn, psz};
                 state = FETCH;
				end
            
		 
		 ILLEGAL_OP:
				begin
				  $display("ILLEGAL OPCODE FETCHED %t",$time);
				  // control word assignments for "deasserting" everything
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
				  $display(" ");
				  $display("Memory:");
				  $display(" ");
				  Dump_Registers;
				  $display(" ");
				  Dump_PC_and_IR;
				$finish;
				end
	 
	 
		BREAK:
			begin
			  $display("BREAK INSTRUCTION FETCHED %t",$time);
			  // control word assignments for "deasserting" everything
			  @(negedge clk)
                 inta=0;	 FS=5'h0;
                 {pc_sel, pc_ld, pc_inc, ir_ld}		      = 5'b00_0_0_0;
                 {im_cs, im_rd, im_wr} 		   		  	  = 3'b0_0_0;
			     {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}    = 9'b0_00_00_0_000;
                 {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
                 {io_cs, io_rd, io_wr} 				  	  = 3'b0_0_0;
                 {sp_sel, s_sel}						  = 2'b0_0;
             #1 {nsi, nsc, nsv, nsn, nsz} 				  = {psi, psc, psv, psn, psz};
			  $display(" R E G I S T E R ' S  A F T E R  B R E A K");
			  
			  $display(" ");
			  $display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			  $display(" Register File Content of $r0 - $r31 ");
			  $display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			  $display(" ");
			  Dump_Registers; // task to output MIPS RegFile
			  
			  $display(" ");
			  $display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			  $display("Memory Location at M[0x3FC]");
			  $display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			  $display(" ");
			  $display("Time=%t M[0x3FC]=%h", $time, {MIPS_CPU_TB.dm.DataMem[12'h3F0],
													  MIPS_CPU_TB.dm.DataMem[12'h3F1],
													  MIPS_CPU_TB.dm.DataMem[12'h3F2],
													  MIPS_CPU_TB.dm.DataMem[12'h3F3]});
			  $display(" ");
			  $display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			  $display("DATA MEMORY && I/O MEMORY of Memory locations 0xC0h to 0xFFh");
			  $display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			  $display(" ");
			  Dump_Memory;
				  
			  $finish;                              
			end
 
            
   /***************************************************************************
    * 					ENHANCEMENT INSTRUCTIONS 
    ***************************************************************************/
         INPUT: 
				begin
				  // ALU_OUT <= RS($rs) + RT(SE_16) to calculate the effective address.
				  @(negedge clk)
                  inta=0;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = INPUT2;
				end
         INPUT2: 
				begin
				  // D_IN <= I/OM[ALU_OUT] 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b1_1_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_Din;
				end
            
         OUTPUT: 
				begin
				  // ALU_OUT <= RS($rs) + RT(SE_16) to calculate the effective address.
				  @(negedge clk)
                  inta=0;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = OUTPUT2;
				end
         OUTPUT2: 
				begin
				  // I/OM[ALU_OUT] <= D_IN
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b1_0_1;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
          
         RETI: 
				begin
				// ALU_OUT <= RS($r29)
				// Pass S, which is the current stack pointer register through the ALU
				  @(negedge clk)
                  inta=0;	 FS=add;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = RETI2;
				end
          RETI2: 
				begin
				// D_IN <= M[$r29], D_IN register carries the flags
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_1_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = RETI3;
				end
         RETI3: 
		 
				begin
				// Since we passed the status flags to the least 5 bit of D_IN, we can 
				// collect the 5 bit and increment the stack pointer due to a POP
				// Y_MUX <= D_IN and ALU_OUT <= $r29 + 4                 
				  @(negedge clk)
                  inta=0;	 FS=inc4;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {stack_InFlags};
                 state = RETI4;
				end
          RETI4: 
				begin
				// Pop the current stack of the $ra to D_IN and increment $r29 
				// D_IN <= M[$r29 + 4] and ALU_OUT <= ALU_OUT($r29 + 4), because 
				// POP is post increment so after every POP, we increment stack pointer register
                  inta=0;	 FS=inc4;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_1_0; 								
				  {sp_sel, s_sel}						  = 2'b0_1;
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = RETI5;
				end
         RETI5: 
				begin
				// Load the current D_IN carries PC to Program Counter
				// PC <= D_IN and ALU_OUT <= $r29 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_1_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_011;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz}; 
                 state = RETI6;
				end
         RETI6: 
				begin
				// WB the stack pointer popped twiced 
				// $r29 <= ALU_OUT($r29) 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_11_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz}; 
                 state = FETCH;
				end

         
         
           
         CLR: 
				begin
				  // ALU_OUT <= 0x0000_0000
				  @(negedge clk)
                  inta=0;	 FS=zeros;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = CLR2;
				end
         CLR2: 
				begin
				// WB to T_Addr as the destination whatever the result from ALU_OUT
				// R($rt) <= ALU_OUT
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_01_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            

            
         MOV: 
				begin
				// $rt <= $rs 
                // ALU_OUT <= RS($rs)
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = MOV2;
				end
         MOV2: 
				begin
				  // R($rt) <= ALU_OUT($rs)
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_01_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
           
         NOP: 
				begin
				  // Nothing happens during this clock, due to that fact the ALU result
				  // gets stored back to itself (register) 
				  // control word assignments ALU_Out <- ALU_Out
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
         PUSH: 
				begin
				// Pre decrement the $r29 and save $rt content into that register
				// Load RS and RT 
				// RS <= [$r29] , RT = $rt
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = PUSH2;
				end
         PUSH2: 
				begin
				// Push content onto stack, and the operation is to subtract 4 from 
				// the stack address. Load RT with the appropriate content
				// ALU_OUT <= ($r29 - 4) and RT <= $rt
				  @(negedge clk)
                  inta=0;	 FS=dec4;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = PUSH3;
				end
         PUSH3: 
				begin
				// The current content in RT is stored into memory location 
				// ALU_OUT reg also gets the stack pointer decremented by 4
				// M[ALU_OUT] <= RT and ALU_OUT <= $r29 - 4
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_0_1; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = PUSH4;
				end
         PUSH4: 
				begin
				// Stack pointer register gets the calculation of $r29 decremented by 4
				// $r29 <= ALU_OUT($r29 - 4)
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_11_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
         
         POP: 
				begin
				  // R($rt) <= M[$r29] +  The post increment type of POP
				  // RS <= $r29 
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b1_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = POP2;
				end
         POP2: 
				begin
				// ALU_OUT <= RS($r29) 
				// The ALU_OUT register gets the calculation through the ALU 
				// and passes on the data of stack pointer reg.
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = POP3;
				end
         POP3: 
				begin
				// D_IN reg gets the memory location of ALU_OUT result. 
				// ALU_OUT gets the calculation with the stack pointer. 
				// D_IN <= M[ALU_OUT] and ALU_OUT <= ALU_OUT($r29)
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b0_00_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b1_1_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = POP4;
				end
         POP4: 
				begin
				// R($rt) <= D_IN  and ALU_OUT <= ALU_OUT($r29 + 4)
				// D_IN data content gets copied to RT register,
				// ALU_OUT loops back and increment stack pointer by 4. 
				  @(negedge clk)
                  inta=0;	 FS=inc4;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_01_00_0_011;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, C, V, N, Z};
                 state = POP5;
				end
         POP5: 
				begin
				// The final calculation of ALU_OUT($r29 + 4) gets copied to $r29
				  // R($r29) <= ALU_OUT($r29 + 4)
				  @(negedge clk)
                  inta=0;	 FS=5'h0;
				  {pc_sel, pc_ld, pc_inc, ir_ld}		  = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} 		   		  = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel}   = 9'b1_11_00_0_000;
				  {dm_cs, dm_rd, dm_wr}		          	  = 3'b0_0_0; 								
				  {io_cs, io_rd, io_wr} 				  = 3'b0_0_0;
				  {sp_sel, s_sel}						  = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
   endcase
   

	/******************************************************************
	* DUMP REGISTERS TASK 
	* Print the first 16 registers contents in the register file
	* We have to use the dot method to pinpoint exactly which signal we 
	* would like to pull out from a module. 
	******************************************************************/
	task Dump_Registers;
	
		begin
			for(i = 0; i < 16; i = i + 1) 
            begin
				$display ("Time=%t   $r%0d = %h  ||  Time=%t   $r%0d = %h",
				$time, i, 	 MIPS_CPU_TB.cpu.idp.rf32.data[i],
				$time, i+16, MIPS_CPU_TB.cpu.idp.rf32.data[i + 16]);
			 end
		end
	endtask
	
	/*******************************************************************************
	* DUMP CURRENT PROGRAM COUNTER AND INSTRUCTION REGISTER TASK
	* The task to print out the current program counter and the instruction register
	* Once again we will print these signals with the dot method.
	*******************************************************************************/
	task Dump_PC_and_IR;
		begin
			$display(" ");
			$display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			$display(" PC and IR Registers");
			$display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-");
			$display(" ");
			$display(" "); $display("PC Register:");
			$display("Time=%t PC=%h", $time, MIPS_CPU_TB.cpu.iu.pc.PC_out);
			$display(" ");                
			$display("IR Register:");
			$display("Time=%t IR=%h", $time, MIPS_CPU_TB.cpu.iu.ir.Q);
			$display(" "); $display(" ");
		end
	endtask
	

   
   /***************************************************************************
   * DUMP DATA AND INPUT/OUPUT INSTRUCTIONS TASK
   * The task asks to be printed out the input/output memory from the memory location 
   * from the 9-bit address of 0xC0h - 0xFFh.
   ****************************************************************************/
   task Dump_Memory; 
   begin 
	  $display("             Data Memory           " );
      for(i = 8'hC0; i <= 8'hFF; i = i + 4) begin 
         DM_Dump  = {MIPS_CPU_TB.dm.DataMem[i], 
					 MIPS_CPU_TB.dm.DataMem[i+1], 
					 MIPS_CPU_TB.dm.DataMem[i+2], 
					 MIPS_CPU_TB.dm.DataMem[i+3]}; 
					 
         IOM_Dump = {MIPS_CPU_TB.io.IOMem[i], 
					 MIPS_CPU_TB.io.IOMem[i+1], 
					 MIPS_CPU_TB.io.IOMem[i+2],    
					 MIPS_CPU_TB.io.IOMem[i+3]}; 
         $display("Time=%t DM[%h] = %h", $time, i, DM_Dump);  
      end 
   end 
   endtask
   
endmodule
					 
	
