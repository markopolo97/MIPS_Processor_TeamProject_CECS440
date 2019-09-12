`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * File Name:  BS_32
 * Project:    Final Project
 * Designers:  TrieuVy Le and Mark Aquiapao
 * Rev. No.:   Version 1.0
 * Rev. Date:  April 22, 2019 
 
 * Purpose:		To perform 3 types of shifting with a specified amount then 
	store result back to Register File.
				1. SRL = 5'h0C, logical shift right 
				2. SRA = 5'h0D, arithmetic shift right
				3. SLL = 5'h0E, logical left shift 
	
 * ©R.W Allison 2019
 ****************************************************************************/
module BS_32(T, shtamt, S_type, YLO, C);
	
	// Initialize input and output 
	input [31:0] 	  T;
	input [4:0] 	  shtamt, S_type;
	
	output reg [31:0] YLO;
	output reg C;
	
	parameter 	SRL = 5'h0C,
				SRA = 5'h0D,
				SLL = 5'h0E;
				
	// We care about the carry flag 
	always @ (*) begin
    case (S_type)
	  // Logical shift right
      SRL:
        case (shtamt)
			  5'd0  : {C, YLO} = {1'b0, T};
              5'd1  : {C, YLO} = {T[0], 1'b0,  T[31:1]  };
              5'd2  : {C, YLO} = {T[1], 2'b0,  T[31:2]  };
              5'd3  : {C, YLO} = {T[2], 3'b0,  T[31:3]  };
              5'd4  : {C, YLO} = {T[3], 4'b0,  T[31:4]  };
              5'd5  : {C, YLO} = {T[4], 5'b0,  T[31:5]  };
              5'd6  : {C, YLO} = {T[5], 6'b0,  T[31:6]  };
              5'd7  : {C, YLO} = {T[6], 7'b0,  T[31:7]  };
              5'd8  : {C, YLO} = {T[7], 8'b0,  T[31:8]  };
              5'd9  : {C, YLO} = {T[8], 9'b0,  T[31:9]  };
              5'd10 : {C, YLO} = {T[9], 10'b0, T[31:10] };
              5'd11 : {C, YLO} = {T[10],11'b0, T[31:11] };
              5'd12 : {C, YLO} = {T[11],12'b0, T[31:12] };
              5'd13 : {C, YLO} = {T[12],13'b0, T[31:13] };
              5'd14 : {C, YLO} = {T[13],14'b0, T[31:14] };
              5'd15 : {C, YLO} = {T[14],15'b0, T[31:15] };
              5'd16 : {C, YLO} = {T[15],16'b0, T[31:16] };
              5'd17 : {C, YLO} = {T[16],17'b0, T[31:17] };
              5'd18 : {C, YLO} = {T[17],18'b0, T[31:18] };
              5'd19 : {C, YLO} = {T[18],19'b0, T[31:19] };
              5'd20 : {C, YLO} = {T[19],20'b0, T[31:20] };
              5'd21 : {C, YLO} = {T[20],21'b0, T[31:21] };
              5'd22 : {C, YLO} = {T[21],22'b0, T[31:22] };
              5'd23 : {C, YLO} = {T[22],23'b0, T[31:23] };
              5'd24 : {C, YLO} = {T[23],24'b0, T[31:24] };
              5'd25 : {C, YLO} = {T[24],25'b0, T[31:25] };
              5'd26 : {C, YLO} = {T[25],26'b0, T[31:26] };
              5'd27 : {C, YLO} = {T[26],27'b0, T[31:27] };
              5'd28 : {C, YLO} = {T[27],28'b0, T[31:28] };
              5'd29 : {C, YLO} = {T[28],29'b0, T[31:29] };
              5'd30 : {C, YLO} = {T[29],30'b0, T[31:30] };
              5'd31 : {C, YLO} = {T[30],31'b0, T[31] };
              default :{C ,YLO} = {33'b0};
            endcase



	  // Arithmetic shift right 
      SRA:
            case (shtamt)
			  5'd0  : {C, YLO} = {1'b0, T};
              5'd1  : {C, YLO} = {T[0],{1{T[31]}},T[31:1]};
              5'd2  : {C, YLO} = {T[1],{2{T[31]}},T[31:2]};
              5'd3  : {C, YLO} = {T[2],{3{T[31]}},T[31:3]};
              5'd4  : {C, YLO} = {T[3],{4{T[31]}},T[31:4]};
              5'd5  : {C, YLO} = {T[4],{5{T[31]}},T[31:5]};
              5'd6  : {C, YLO} = {T[5],{6{T[31]}},T[31:6]};
              5'd7  : {C, YLO} = {T[6],{7{T[31]}},T[31:7]};
              5'd8  : {C, YLO} = {T[7],{8{T[31]}},T[31:8]};
              5'd9  : {C, YLO} = {T[8],{9{T[31]}},T[31:9]};
              5'd10 : {C, YLO} = {T[9],{10{T[31]}},T[31:10]};
              5'd11 : {C, YLO} = {T[10],{11{T[31]}},T[31:11]};
              5'd12 : {C, YLO} = {T[11],{12{T[31]}},T[31:12]};
              5'd13 : {C, YLO} = {T[12],{13{T[31]}},T[31:13]};
              5'd14 : {C, YLO} = {T[13],{14{T[31]}},T[31:14]};
              5'd15 : {C, YLO} = {T[14],{15{T[31]}},T[31:15]};
              5'd16 : {C, YLO} = {T[15],{16{T[31]}},T[31:16]};
              5'd17 : {C, YLO} = {T[16],{17{T[31]}},T[31:17]};
              5'd18 : {C, YLO} = {T[17],{18{T[31]}},T[31:18]};
              5'd19 : {C, YLO} = {T[18],{19{T[31]}},T[31:19]};
              5'd20 : {C, YLO} = {T[19],{20{T[31]}},T[31:20]};
              5'd21 : {C, YLO} = {T[20],{21{T[31]}},T[31:21]};
              5'd22 : {C, YLO} = {T[21],{22{T[31]}},T[31:22]};
              5'd23 : {C, YLO} = {T[22],{23{T[31]}},T[31:23]};
              5'd24 : {C, YLO} = {T[23],{24{T[31]}},T[31:24]};
              5'd25 : {C, YLO} = {T[24],{25{T[31]}},T[31:25]};
              5'd26 : {C, YLO} = {T[25],{26{T[31]}},T[31:26]};
              5'd27 : {C, YLO} = {T[26],{27{T[31]}},T[31:27]};
              5'd28 : {C, YLO} = {T[27],{28{T[31]}},T[31:28]};
              5'd29 : {C, YLO} = {T[28],{29{T[31]}},T[31:29]};
              5'd30 : {C, YLO} = {T[29],{30{T[31]}},T[31:30]};
              5'd31 : {C, YLO} = {T[30],{31{T[31]}},T[31:31]};
              default : {C,YLO} = {33'b0};
            endcase
	  // Logical shift left
      SLL:
           case(shtamt)
		    5'd0  : {C, YLO} = {1'b0, T};
            5'd1  : {C, YLO} = {T[31],T[30:0],1'b0};
            5'd2  : {C, YLO} = {T[30],T[29:0],2'b0};
            5'd3  : {C, YLO} = {T[29],T[28:0],3'b0};
            5'd4  : {C, YLO} = {T[28],T[27:0],4'b0};
            5'd5  : {C, YLO} = {T[27],T[26:0],5'b0};
            5'd6  : {C, YLO} = {T[26],T[25:0],6'b0};
            5'd7  : {C, YLO} = {T[25],T[24:0],7'b0};
            5'd8  : {C, YLO} = {T[24],T[23:0],8'b0};
            5'd9  : {C, YLO} = {T[23],T[22:0],9'b0};
            5'd10 : {C, YLO} = {T[22],T[21:0],10'b0};
            5'd11 : {C, YLO} = {T[21],T[20:0],11'b0};
            5'd12 : {C, YLO} = {T[20],T[19:0],12'b0};
            5'd13 : {C, YLO} = {T[19],T[18:0],13'b0};
            5'd14 : {C, YLO} = {T[18],T[17:0],14'b0};
            5'd15 : {C, YLO} = {T[17],T[16:0],15'b0};
            5'd16 : {C, YLO} = {T[16],T[15:0],16'b0};
            5'd17 : {C, YLO} = {T[15],T[14:0],17'b0};
            5'd18 : {C, YLO} = {T[14],T[13:0],18'b0};
            5'd19 : {C, YLO} = {T[13],T[12:0],19'b0};
            5'd20 : {C, YLO} = {T[12],T[11:0],20'b0};
            5'd21 : {C, YLO} = {T[11],T[10:0],21'b0};
            5'd22 : {C, YLO} = {T[10],T[9:0], 22'b0};
            5'd23 : {C, YLO} = {T[9], T[8:0], 23'b0};
            5'd24 : {C, YLO} = {T[8], T[7:0], 24'b0};
            5'd25 : {C, YLO} = {T[7], T[6:0], 25'b0};
            5'd26 : {C, YLO} = {T[6], T[5:0], 26'b0};
            5'd27 : {C, YLO} = {T[5], T[4:0], 27'b0};
            5'd28 : {C, YLO} = {T[4], T[3:0], 28'b0};
            5'd29 : {C, YLO} = {T[3], T[2:0], 29'b0};
            5'd30 : {C, YLO} = {T[2], T[1:0], 30'b0};
            5'd31 : {C, YLO} = {T[1], T[0:0], 31'b0};
            default : {C,YLO} = {33'b0};
          endcase  
        endcase //end shift
    end
endmodule
