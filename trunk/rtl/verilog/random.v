//////////////////////////////////////////////////////////////////////
////                                                              ////
////  random.v                                                    ////
////                                                              ////
////  This file is part of the Ethernet IP core project           ////
////  http://www.opencores.org/cores/ethmac/                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Igor Mohor (igorM@opencores.org)                      ////
////      - Novan Hartadi (novan@vlsi.itb.ac.id)                  ////
////      - Mahmud Galela (mgalela@vlsi.itb.ac.id)                ////
////                                                              ////
////  All additional information is avaliable in the Readme.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.3  2001/06/19 18:16:40  mohor
// TxClk changed to MTxClk (as discribed in the documentation).
// Crc changed so only one file can be used instead of two.
//
// Revision 1.2  2001/06/19 10:38:07  mohor
// Minor changes in header.
//
// Revision 1.1  2001/06/19 10:27:57  mohor
// TxEthMAC initial release.
//
//
//
//

`timescale 1ns / 1ns

module random (MTxClk, Reset, StateJam, StateJam_q, RetryCnt, NibCnt, ByteCnt, 
               RandomEq0, RandomEqByteCnt);

parameter Tp = 1;

input MTxClk;
input Reset;
input StateJam;
input StateJam_q;
input [3:0] RetryCnt;
input [15:0] NibCnt;
input [9:0] ByteCnt;
output RandomEq0;
output RandomEqByteCnt;

wire Feedback;
reg [9:0] x;
wire [9:0] Random;
reg  [9:0] RandomLatched;


always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    x[9:0] <= #Tp 0;
  else
    x[9:0] <= #Tp {x[8:0], Feedback};
end

assign Feedback = x[2] ~^ x[9];

assign Random [0] = x[0];
assign Random [1] = (RetryCnt > 1) ? x[1] : 1'b0;
assign Random [2] = (RetryCnt > 2) ? x[2] : 1'b0;
assign Random [3] = (RetryCnt > 3) ? x[3] : 1'b0;
assign Random [4] = (RetryCnt > 4) ? x[4] : 1'b0;
assign Random [5] = (RetryCnt > 5) ? x[5] : 1'b0;
assign Random [6] = (RetryCnt > 6) ? x[6] : 1'b0;
assign Random [7] = (RetryCnt > 7) ? x[7] : 1'b0;
assign Random [8] = (RetryCnt > 8) ? x[8] : 1'b0;
assign Random [9] = (RetryCnt > 9) ? x[9] : 1'b0;


always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    RandomLatched <= #Tp 10'h000;
  else
    begin
      if(StateJam & StateJam_q)
        RandomLatched <= #Tp Random;
    end
end

// Random Number == 0      IEEE 802.3 page 68. If 0 we go to defer and not to backoff.
assign RandomEq0 = RandomLatched == 10'h0; 

assign RandomEqByteCnt = ByteCnt[9:0] == RandomLatched & (&NibCnt[6:0]);

endmodule
