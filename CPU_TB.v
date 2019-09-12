`timescale 1ns / 1ps

/******************************* C E C S  4 4 0 ******************************
 * File Name:  CU_TB.v
 * Project:    Final Project
 * Designers:  TrieuVy Le and Mark Aquiapao
 * Rev. No.:   Version 1.0
 * Rev. Date:  April 5, 2019 
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

module CPU_TB;

	// Inputs
	reg clk;
	reg reset;
	reg [31:0] DM_out;
	reg [31:0] IO_Out;

	// Outputs
	wire inta;
	wire [31:0] Address;
	wire [31:0] D_OUT;
	wire [31:0] IO_In;
	wire dm_cs;
	wire dm_rd;
	wire dm_wr;
	wire io_cs;
	wire io_rd;
	wire io_wr;

	// Instantiate the Unit Under Test (UUT)
	CPU uut (
		.clk(clk), 
		.reset(reset), 
		.intr(intr), 
		.inta(inta), 
		.DM_out(DM_out), 
		.Address(Address), 
		.D_OUT(D_OUT), 
		.IO_In(IO_In),
		.IO_Out(IO_Out),
		.dm_cs(dm_cs), 
		.dm_rd(dm_rd), 
		.dm_wr(dm_wr), 
		.io_cs(io_cs), 
		.io_rd(io_rd), 
		.io_wr(io_wr)
	);
	
	// Generate 10ns clock period
	always #5 clk = ~clk;

	initial begin
		$timeformat(-9, 1, " ns", 9);
		// Initialize Inputs
		clk 	 = 0;
      reset  = 1;
		DM_out = 0;
		IO_Out = 0;

      // Reset Clock        
		@(negedge clk)
		reset  = 0;

		// Read the initial data memory and instruction memory modules
		// CHANGE THIS!
		@(negedge clk) 
		$readmemh("iMem_Lab6_with_isr.dat",iu.im.IMem);
		// CHANGE THIS!
		@(negedge clk)
		$readmemh("dMem_Lab6.dat",dm.DataMem);
        
		/*******************************************************************
		* Testing Interrupt 
		* We will turn on the request after certain amount of time has propagated 
		* executed a few instructions from IM and DM. 
		* We then instroduced the interrupt request, once received 
		* the program will automatically acknowledge and we will wait for the posedge
		* of inta from the MCU then turn off the request from here.
		*******************************************************************/

	end
      
endmodule

