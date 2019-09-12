`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  DataMemory.v
 * Project:    Final Project
 * Designers:  Mark Aquiapao and TrieuVy Le
 * Rev. No.:   Version 1.0
 * Rev. Date:  April 22, 2019 
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
module Data_Memory(clk, Address, DM_In, dm_cs, dm_wr, dm_rd, DM_Out);
		
   input 		  clk, dm_cs, dm_wr, dm_rd;
   input [31:0]  DM_In;
	input [11:0]  Address;
	output [31:0] DM_Out;
	 
	reg [7:0]     DataMem [4095:0];

	always @ (posedge clk) begin
		if (dm_cs && dm_wr) 
			{DataMem[Address], 
			 DataMem[Address+1], 
			 DataMem[Address+2], 
			 DataMem[Address+3]} <= 
			 
			{DM_In[31:24],      
			 DM_In[23:16],        
			 DM_In[15:8],         
			 DM_In[7:0]};
			
		else 
			{DataMem[Address], 
			 DataMem[Address+1], 
			 DataMem[Address+2], 
			 DataMem[Address+3]} <= 
			 
			{DataMem[Address], 
			 DataMem[Address+1], 
			 DataMem[Address+2], 
			 DataMem[Address+3]};
	end 

	/**************************************************************************
	* The output is to have tri-state outputs labeled as z. 
	* If DataMemory is being read, output will pass 32-bit content at the Address.
	* If not read, output myst in the high impedance state of z. 
	***************************************************************************/
	assign DM_Out = {dm_cs && dm_rd} ? 
										{DataMem[Address], 
										DataMem[Address+1],
										DataMem[Address+2], 
										DataMem[Address+3]} : 32'hz;


endmodule
