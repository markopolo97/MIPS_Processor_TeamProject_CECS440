`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  Data_Memory.v
 * Project:    Lab 4
 * Designers:  Mark Aquiapao and TrieuVy Le
 * Rev. No.:   Version 1.0
 * Rev. Date:  Mar. 5, 2019 
 *
 * Purpose:    The module is to be organized as a 4096x8 Byte addressable MEM.
 * When writing to Data_Memory, it is to be synchrous with the clock.
 * When reading to Data_Memory, it is to be asynchrous due to that it is not 
 * depending on the clock. 
 * Either to read/write to memory, the chip select signal (dm_cs) must be 
 * asserted with the proper read or write control signals. 
 * The output is to have tri-state outputs labeled as z. 
 
 * ©R.W Allison 2019
 ****************************************************************************/
module InstructionMemory(clk, Address, IM_In, im_cs, im_wr, im_rd, IM_Out);
		
    input 		  clk, im_cs, im_wr, im_rd;
    input [31:0]  IM_In;
	input [11:0]  Address;
	output [31:0] IM_Out;
	 
	reg [7:0]     IMem [4095:0];

	always @ (posedge clk) begin
		if (im_cs && im_wr) 
			{IMem[Address], 
			 IMem[Address+1], 
			 IMem[Address+2], 
			 IMem[Address+3]} <= 
			 
			{IM_In[31:24],      
			 IM_In[23:16],        
			 IM_In[15:8],         
			 IM_In[7:0]};
			
		else 
			{IMem[Address], 
			 IMem[Address+1], 
			 IMem[Address+2], 
			 IMem[Address+3]} <= 
			 
			{IMem[Address], 
			 IMem[Address+1], 
			 IMem[Address+2], 
			 IMem[Address+3]};
	end 

	/**************************************************************************
	* The output is to have tri-state outputs labeled as z. 
	* If DataMemory is being read, output will pass 32-bit content at the Address.
	* If not read, output myst in the high impedance state of z. 
	***************************************************************************/
	assign IM_Out = {im_cs && im_rd} ? 
										{IMem[Address], 
										IMem[Address+1],
										IMem[Address+2], 
										IMem[Address+3]} : 32'hz;


endmodule
