//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_rxethmac.v                                              ////
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
// Revision 1.1  2001/07/30 21:23:42  mohor
// Directory structure changed. Files checked and joind together.
//
// Revision 1.1  2001/06/27 21:26:19  mohor
// Initial release of the RxEthMAC module.
//
//
//
//
//

`include "eth_timescale.v"


module eth_rxethmac (MRxClk, MRxDV, MRxD, Reset, Transmitting, MaxFL, r_IFG, HugEn, DlyCrcEn, 
                     RxData, RxValid, RxStartFrm, RxEndFrm, CrcHash, CrcHashGood, Broadcast, 
                     Multicast, ByteCnt, ByteCntEq0, ByteCntGreat2, ByteCntMaxFrame, 
                     CrcError, StateIdle, StatePreamble, StateSFD, StateData
                    );

parameter Tp = 1;



input         MRxClk;
input         MRxDV;
input   [3:0] MRxD;
input         Transmitting;
input         HugEn;
input         DlyCrcEn;
input  [15:0] MaxFL;
input         r_IFG;
input         Reset;

output  [7:0] RxData;
output        RxValid;
output        RxStartFrm;
output        RxEndFrm;
output  [8:0] CrcHash;
output        CrcHashGood;
output        Broadcast;
output        Multicast;
output [15:0] ByteCnt;
output        ByteCntEq0;
output        ByteCntGreat2;
output        ByteCntMaxFrame;
output        CrcError;
output        StateIdle;
output        StatePreamble;
output        StateSFD;
output  [1:0] StateData;

reg     [7:0] RxData;
reg           RxValid;
reg           RxStartFrm;
reg           RxEndFrm;
reg           Broadcast;
reg           Multicast;
reg     [8:0] CrcHash;
reg           CrcHashGood;
reg           DelayData;
reg     [3:0] LatchedNibble;
reg     [7:0] LatchedByte;
reg     [7:0] RxData_d;
reg           RxValid_d;
reg           RxStartFrm_d;
reg           RxEndFrm_d;

wire          MRxDEqD;
wire          MRxDEq5;
wire          StateDrop;
wire          ByteCntEq1;
wire          ByteCntEq6;
wire          ByteCntSmall7;
wire   [31:0] Crc;
wire          Enable_Crc;
wire          Initialize_Crc;
wire    [3:0] Data_Crc;
wire          GenerateRxValid;
wire          GenerateRxStartFrm;
wire          GenerateRxEndFrm;
wire          DribbleRxEndFrm;
wire    [3:0] DlyCrcCnt;



assign MRxDEqD = MRxD == 4'hd;
assign MRxDEq5 = MRxD == 4'h5;


// Rx State Machine module
eth_rxstatem rxstatem1 (.MRxClk(MRxClk), .Reset(Reset), .MRxDV(MRxDV), .ByteCntEq0(ByteCntEq0), 
                        .ByteCntGreat2(ByteCntGreat2), .Transmitting(Transmitting), .MRxDEq5(MRxDEq5), 
                        .MRxDEqD(MRxDEqD), .IFGCounterEq24(IFGCounterEq24), .ByteCntMaxFrame(ByteCntMaxFrame), 
                        .StateData(StateData), .StateIdle(StateIdle), .StatePreamble(StatePreamble), 
                        .StateSFD(StateSFD), .StateDrop(StateDrop)
                       );


// Rx Counters module
eth_rxcounters rxcounters1 (.MRxClk(MRxClk), .Reset(Reset), .MRxDV(MRxDV), .StateIdle(StateIdle), 
                            .StateSFD(StateSFD), .StateData(StateData), .StateDrop(StateDrop), 
                            .StatePreamble(StatePreamble), .MRxDEqD(MRxDEqD), .DlyCrcEn(DlyCrcEn), 
                            .DlyCrcCnt(DlyCrcCnt), .Transmitting(Transmitting), .MaxFL(MaxFL), .r_IFG(r_IFG), 
                            .HugEn(HugEn), .IFGCounterEq24(IFGCounterEq24), .ByteCntEq0(ByteCntEq0), 
                            .ByteCntEq1(ByteCntEq1), .ByteCntEq6(ByteCntEq6), .ByteCntGreat2(ByteCntGreat2), 
                            .ByteCntSmall7(ByteCntSmall7), .ByteCntMaxFrame(ByteCntMaxFrame), 
                            .ByteCnt(ByteCnt)
                           );



assign Enable_Crc = MRxDV & (|StateData & ~ByteCntMaxFrame);
assign Initialize_Crc = StateSFD | DlyCrcEn & (|DlyCrcCnt[3:0]) & DlyCrcCnt[3:0] < 4'h9;

assign Data_Crc[0] = MRxD[3];
assign Data_Crc[1] = MRxD[2];
assign Data_Crc[2] = MRxD[1];
assign Data_Crc[3] = MRxD[0];


// Connecting module Crc
eth_crc crcrx (.Clk(MRxClk), .Reset(Reset), .Data(Data_Crc), .Enable(Enable_Crc), .Initialize(Initialize_Crc), 
               .Crc(Crc), .CrcError(CrcError)
          );



// Latching CRC for use in the hash table

always @ (posedge MRxClk)
begin
  CrcHashGood <= #Tp StateData[0] & ByteCntEq6;
end

always @ (posedge MRxClk)
begin
  if(Reset | StateIdle)
    CrcHash[8:0] <= #Tp 9'h0;
  else
  if(StateData[0] & ByteCntEq6)
    CrcHash[8:0] <= #Tp Crc[31:23];
end


// Output byte stream
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxData_d[7:0]      <= #Tp 8'h0;
      DelayData          <= #Tp 1'b0;
      LatchedNibble[3:0] <= #Tp 4'h0;
      LatchedByte[7:0]   <= #Tp 8'h0;
      RxData[7:0]        <= #Tp 8'h0;
    end
  else
    begin
      LatchedNibble[3:0] <= #Tp MRxD[3:0];                        // Latched nibble
      LatchedByte[7:0]   <= #Tp {MRxD[3:0], LatchedNibble[3:0]};  // Latched byte
      DelayData          <= #Tp StateData[0];

      if(GenerateRxValid)
        RxData_d[7:0] <= #Tp LatchedByte[7:0] & {8{|StateData}};  // Data goes through only in data state 
      else
      if(~DelayData)
        RxData_d[7:0] <= #Tp 8'h0;                                // Delaying data to be valid for two cycles. Zero when not active.

      RxData[7:0] <= #Tp RxData_d[7:0];                           // Output data byte
    end
end

    

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    Broadcast <= #Tp 1'b0;
  else
    begin      
      if(StateData[0] & ~(&LatchedByte[7:0]) & ByteCntSmall7)
        Broadcast <= #Tp 1'b0;
      else
      if(StateData[0] & &LatchedByte[7:0] & ByteCntEq1)
        Broadcast <= #Tp 1'b1;
    end
end


always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    Multicast <= #Tp 1'b0;
  else
    begin      
      if(Reset)
        Multicast <= #Tp 1'b0;
      else
      if(StateData[0] & ByteCntEq1)
        Multicast <= #Tp LatchedByte[0];
    end
end


assign GenerateRxValid = StateData[0] & (~ByteCntEq0 | DlyCrcCnt >= 4'h3);

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxValid_d <= #Tp 1'b0;
      RxValid   <= #Tp 1'b0;
    end
  else
    begin
      RxValid_d <= #Tp GenerateRxValid;
      RxValid   <= #Tp RxValid_d;
    end
end


assign GenerateRxStartFrm = StateData[0] & (ByteCntEq1 & ~DlyCrcEn | DlyCrcCnt == 4'h3 & DlyCrcEn);

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxStartFrm_d <= #Tp 1'b0;
      RxStartFrm   <= #Tp 1'b0;
    end
  else
    begin
      RxStartFrm_d <= #Tp GenerateRxStartFrm;
      RxStartFrm   <= #Tp RxStartFrm_d;
    end
end


assign GenerateRxEndFrm = StateData[0] & (~MRxDV & ByteCntGreat2 | ByteCntMaxFrame);
assign DribbleRxEndFrm  = StateData[1] &  ~MRxDV & ByteCntGreat2;


always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxEndFrm_d <= #Tp 1'b0;
      RxEndFrm   <= #Tp 1'b0;
    end
  else
    begin
      RxEndFrm_d <= #Tp GenerateRxEndFrm;
      RxEndFrm   <= #Tp RxEndFrm_d | DribbleRxEndFrm;
    end
end


endmodule
