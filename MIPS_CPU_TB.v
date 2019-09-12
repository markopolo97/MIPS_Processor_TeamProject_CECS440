`timescale 1ns / 1ps
/******************************* C E C S  4 4 0 ******************************
 * File Name:  MIPS_CPU_TB.v
 * Project:    Final Project
 * Designers:  TrieuVy Le and Mark Aquiapao
 * Rev. No.:   Version 1.0
 * Rev. Date:  April 22, 2019 
   Rev. No.:   Version 1.1(4/13): Debugged testing out the first module
   Rev. No.:   Version 1.1(4/20): Rewired due to the addition of I/O Memory 
 *
 * Purpose: This modules serves as the testbench that verifies the performance of 
 *			 	MIPS CPU that includes the Control Unit, Instruction Unit, 
 *				Integer Datapath, IO Memory, and Data Memory. 
 * 			We start off with the reset to get the MCU module going. 
 *
 * The control unit will execute the machine instructions load from .dat files,
 * eventually will end with the BREAK instruction. 
 *
 *	- Interrupt: we will introduce the interrupt once after a certain amount of 
 * instructions are executed. Once received, wait for posedge clk of inta. 
 * We can turn off and print all registers, PC, and IR. 
 *		
 *	WHEN RUNNING SIMULATION, PLEASE TURN YOUR TIME SCALE TO 10.00 us 
 *
 * ©R.W Allison 2019
 ****************************************************************************/
module MIPS_CPU_TB;

	// Inputs
	reg clk;
	reg reset;
	
	// Outputs
	wire intr, inta;			// Interrupt request and acknowledge
	
	wire [31:0] Address ;		// From CPU to access both DM and IM
	wire [31:0] D_OUT;			// CPU output to access both memories
	wire [31:0] DM_out;			// data out from both memories
	
	// Data Memory output
	wire dm_cs;
	wire dm_rd;
	wire dm_wr;
	
	// I/O Memory output
	wire io_cs;
	wire io_rd;
	wire io_wr;

	// Instantiate the Unit Under Test (UUT)
	CPU	cpu  (		.clk(clk),
					.reset(reset), 
					.intr(intr),
					.inta(inta),
					.dm_cs(dm_cs), .dm_rd(dm_rd), .dm_wr(dm_wr), 
					.io_cs(io_cs), .io_rd(io_rd), .io_wr(io_wr),
					
					.DM_out(DM_out), 				//DM bus signal
					.Address(Address), 				//Bus to access both memories
					.D_OUT(D_OUT));					// ALU result to access both memories
					
					
	Data_Memory dm(
					.clk(clk),
					.Address(Address[11:0]),  		// Extract bottom 12 bits
					.DM_In(D_OUT),					// Address result from CPU 
					.dm_cs(dm_cs), 
					.dm_wr(dm_wr), 
					.dm_rd(dm_rd), 
					.DM_Out(DM_out));  				// Results from both memories
							
	IOMemory io(
					.clk(clk),
					.Address({20'h0, Address[11:0]}), 	// only bottom 12 bits
					.IO_In(D_OUT), 
					.io_cs(io_cs),
					.io_wr(io_wr), 
					.io_rd(io_rd),
					.intr(intr), 
					.inta(inta), 
					
					.IO_Out(DM_out));		

		
	
	// Generate 10ns clock period
	always #5 clk = ~clk;

	// Set time format and input signals to start 
	initial begin
		$timeformat(-9, 1, " ns", 9);
		clk    = 0;
        reset  = 1;

		// Read both Instruction and Data Memory .dat files
		
		// Instruction Memory
		@(negedge clk) 
		$readmemh("iMem01_Sp19.dat", cpu.iu.im.IMem);
		
		//Data Memory
		@(negedge clk)
		$readmemh("dMem01_Sp19.dat", dm.DataMem);
        
		/*******************************************************************
		* Testing Interrupt 
		* We will turn on the request after certain amount of time has propagated 
		* executed a few instructions from IM and DM. 
		* We then instroduced the interrupt request, once received 
		* the program will automatically acknowledge and we will wait for the posedge
		* of inta from the MCU then turn off the request from here.
		*******************************************************************/
		
		@(negedge clk)
		reset  = 0;
		$display(" ");
		$display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*");
		$display("******CECS 440 FINAL MIPS PROJECT RESULTS**********"); 
		$display("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*");
		$display(" ");
	end
      
endmodule

