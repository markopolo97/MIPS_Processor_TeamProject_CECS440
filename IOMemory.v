`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  I/OMemory.v
 * Project:    Final Project
 * Designers:  Mark Aquiapao and TrieuVy Le
 * Rev. No.:   Version 1.0
 * Rev. Date:  April 22, 2019 
 *
 * Purpose:    IO Memory module using Big Endian format,
 * used to store data and instructions that could be accessed using Address 
 * as the base location ( Address/ + 1, 2, 3) 
 
 * Â©R.W Allison 2019
 ****************************************************************************/
module IOMemory(clk, 
				Address, IO_In,
				io_cs, io_wr, io_rd, 
				intr, inta,  
				IO_Out);
   
   input      	  clk, io_cs, io_wr, io_rd, inta;   
   input  [31:0]  Address, IO_In;  
   
   output  reg    intr;   
   output [31:0]  IO_Out;       

   reg    [7:0]   IOMem [4095:0];  
   
   /***************************************************************************
   * After a certain amount of time has propagated, we can introduce an interrupt 
   * request.
   * Note that: although the interrupt request is set, if the SETIE instruction is
   * not called, then the processor will not get interrupted.
   * Once acknowledged by observing the rising edge of the interrupt acknowledge flag
   * we can turn off the request. 
   ***************************************************************************/
   initial begin
      intr=0;
      #1000 intr=1;
      @(posedge inta) intr=0;
   end
   
   
   /***************************************************************************
   * Similar to data memory 
   * Reading the memory asynchronously in chunks of bytes, even if we want to 
   * read a certain byte, we would have to select the whole word
   ***************************************************************************/
   
   assign IO_Out = (io_cs & io_rd)? {IOMem[Address + 0],
									 IOMem[Address + 1],
									 IOMem[Address + 2],
									 IOMem[Address + 3]	} : 32'hz; 

   /***************************************************************************
   * Similar to data memory 
   * Writing data synchronously with the clock only with the assertion of cs and wr
   
   ***************************************************************************/
   always@(posedge clk)
      if(io_cs & io_wr) // Write Data Input into the Memory
									 {IOMem[Address+0], 
									  IOMem[Address+1], 
									  IOMem[Address+2], 
									  IOMem[Address+3]} <= IO_In;      
      else begin 
									  IOMem[Address+0] <= IOMem[Address+0];
									  IOMem[Address+1] <= IOMem[Address+1];
									  IOMem[Address+2] <= IOMem[Address+2];
									  IOMem[Address+3] <= IOMem[Address+3];
      end

endmodule
