//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_macstatus.v                                             ////
////                                                              ////
////  This file is part of the Ethernet IP core project           ////
////  http://www.opencores.org/cores/ethmac/                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Igor Mohor (igorM@opencores.org)                      ////
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
// Revision 1.1  2001/07/30 21:23:42  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//

`include "eth_timescale.v"


module eth_macstatus(
                      MRxClk, Reset, ReceivedLengthOK, ReceiveEnd, TransmitEnd, ReceivedPacketGood, RxCrcError, 
                      MRxErr, MRxDV, RxStateSFD, RxStateData, RxStatePreamble, RxStateIdle, Transmitting, 
                      RxByteCnt, RxByteCntEq0, RxByteCntGreat2, RxByteCntMaxFrame, ReceivedPauseFrm
                    );



parameter Tp = 1;


input         MRxClk;
input         Reset;
input         RxCrcError;
input         MRxErr;
input         MRxDV;

input         RxStateSFD;
input   [1:0] RxStateData;
input         RxStatePreamble;
input         RxStateIdle;
input         Transmitting;
input  [15:0] RxByteCnt;
input         RxByteCntEq0;
input         RxByteCntGreat2;
input         RxByteCntMaxFrame;
input         ReceivedPauseFrm;

output        ReceivedLengthOK;
output        ReceiveEnd;
output        ReceivedPacketGood;
output        TransmitEnd;

reg           ReceiveEnd;

reg           LatchedCrcError;
reg           LatchedMRxErr;
reg           PreloadRxStatus;
reg    [15:0] LatchedRxByteCnt;

wire          TakeSample;


// Crc error
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedCrcError <=#Tp 1'b0;
  else
    begin 
      if(RxStateSFD)
        LatchedCrcError <=#Tp 1'b0;
      else
      if(RxStateData[0])
        LatchedCrcError <=#Tp RxCrcError & ~RxByteCntEq0;
    end
end


// LatchedMRxErr
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedMRxErr <=#Tp 1'b0;
  else
  if(~MRxErr & MRxDV & RxStateIdle & ~Transmitting)
    LatchedMRxErr <=#Tp 1'b0;
  else
  if(MRxErr & MRxDV & (RxStatePreamble | RxStateSFD | |RxStateData | RxStateIdle & ~Transmitting))
    LatchedMRxErr <=#Tp 1'b1;
end


// ReceivedPacketGood
assign ReceivedPacketGood = ~LatchedCrcError & ~LatchedMRxErr;


// ReceivedLengthOK
assign ReceivedLengthOK = LatchedRxByteCnt[15:0] > 63 & LatchedRxByteCnt[15:0] < 1519;



// LatchedRxByteCnt[15:0]
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedRxByteCnt[15:0] <=#Tp 16'h0;
  else
    begin 
      if(RxStateSFD)
        LatchedRxByteCnt[15:0] <=#Tp RxByteCnt[15:0];
      else
      if(RxStateData[0])
        LatchedRxByteCnt[15:0] <=#Tp RxByteCnt[15:0];
    end
end



// Time to take a sample
assign TakeSample = |RxStateData     & ~MRxDV & RxByteCntGreat2  |
                     RxStateData[0]  &  MRxDV & RxByteCntMaxFrame;


// PreloadRxStatus
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    PreloadRxStatus <=#Tp 1'b0;
  else
    PreloadRxStatus <=#Tp TakeSample;
end



// ReceiveEnd
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ReceiveEnd  <=#Tp 1'b0;
  else
    ReceiveEnd  <=#Tp PreloadRxStatus;                     
end


endmodule
