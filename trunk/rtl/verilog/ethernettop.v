//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ethernettop.v                                               ////
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
//
//
//
//


`timescale 1ns / 1ns

`include "../../rtl/verilog/ethdefines.v"


module ethernettop
(
  // WISHBONE common
  WB_CLK_I, WB_RST_I, WB_DAT_I, WB_DAT_O, 

  // WISHBONE slave
  WB_ADR_I, WB_SEL_I, WB_WE_I, WB_CYC_I, WB_STB_I, WB_ACK_O, WB_ERR_O, 
  WB_REQ_O, WB_ACK_I, WB_ND_O, WB_RD_O, 

  //TX
  MTxClk, MTxD, MTxEn, MTxErr,

  //RX
  MRxClk, MRxD, MRxDV, MRxErr, MColl, MCrs, 
  
  // MIIM
  Mdc, MDIO 
);


parameter Tp = 1;


// WISHBONE common
input           WB_CLK_I;     // WISHBONE clock
input           WB_RST_I;     // WISHBONE reset
input   [31:0]  WB_DAT_I;     // WISHBONE data input
output  [31:0]  WB_DAT_O;     // WISHBONE data output
output          WB_ERR_O;     // WISHBONE error output

// WISHBONE slave
input   [31:0]  WB_ADR_I;     // WISHBONE address input
input    [3:0]  WB_SEL_I;     // WISHBONE byte select input
input           WB_WE_I;      // WISHBONE write enable input
input           WB_CYC_I;     // WISHBONE cycle input
input           WB_STB_I;     // WISHBONE strobe input
output          WB_ACK_O;     // WISHBONE acknowledge output

// DMA
input    [1:0]  WB_ACK_I;     // DMA acknowledge input
output   [1:0]  WB_REQ_O;     // DMA request output
output   [1:0]  WB_ND_O;      // DMA force new descriptor output
output          WB_RD_O;      // DMA restart descriptor output

// Tx
input           MTxClk;       // Transmit clock (from PHY)
output   [3:0]  MTxD;         // Transmit nibble (to PHY)
output          MTxEn;        // Transmit enable (to PHY)
output          MTxErr;       // Transmit error (to PHY)

// Rx
input           MRxClk;       // Receive clock (from PHY)
input    [3:0]  MRxD;         // Receive nibble (from PHY)
input           MRxDV;        // Receive data valid (from PHY)
input           MRxErr;       // Receive data error (from PHY)

// Common Tx and Rx
input           MColl;        // Collision (from PHY)
input           MCrs;         // Carrier sense (from PHY)

// MII Management interface
output          Mdc;          // MII Management data clock (to PHY)
inout           MDIO;         // MII data input/output (to/from PHY)


wire     [7:0]  r_ClkDiv;
wire            r_MiiNoPre;
wire    [15:0]  r_CtrlData;
wire     [4:0]  r_FIAD;
wire     [4:0]  r_RGAD;
wire            r_WCtrlData;
wire            r_RStat;
wire            r_ScanStat;
wire            Mdi;
wire            Mdo;
wire            MdoEn;
wire            Mdc;
wire            Scan_stat;
wire            NValid_stat;
wire            Busy_stat;
wire            Speed_stat;     //kam prideta ta dva signala
wire            Duplex_stat;
wire            LinkFail;
wire            r_MiiMRst;
wire    [15:0]  Prsd;             // Read Status Data (data read from the PHY)
wire            WCtrlDataStart;
wire            RStatStart;

wire            TxStartFrm;
wire            TxEndFrm;
wire            TxUsedData;
wire     [7:0]  TxData;
wire            TxRetry;
wire            TxAbort;
wire            TxUnderRun;
wire            TxDone;




// Connecting Miim module
miim miim1
(
  .Clk(WB_CLK_I),                         .Reset(r_MiiMRst),                  .Divider(r_ClkDiv), 
  .NoPre(r_MiiNoPre),                     .CtrlData(r_CtrlData),              .Rgad(r_RGAD), 
  .Fiad(r_FIAD),                          .WCtrlData(r_WCtrlData),            .RStat(r_RStat), 
  .ScanStat(Scan_stat),                   .Mdi(Mdi),                          .Mdo(Mdo), 
  .MdoEn(MdoEn),                          .Mdc(Mdc),                          .Busy(Busy_stat), 
  .Prsd(Prsd),                            .LinkFail(LinkFail),                .Nvalid(NValid_stat), 
  .WCtrlDataStart(WCtrlDataStart),        .RStatStart(RStatStart),            .UpdateMIIRX_DATAReg()
);

wire        RegCs;          // Connected to registers
wire [31:0] RegDataOut;     // Multiplexed to WB_DAT_O
wire        r_DmaEn;        // DMA enable
wire        r_Rst;          // Reset
wire        r_LoopBck;      // Loopback
wire        r_TxEn;         // Tx Enable
wire        r_RxEn;         // Rx Enable

wire        MRxDV_Lb;       // Muxed MII receive data valid
wire        MRxErr_Lb;      // Muxed MII Receive Error
wire  [3:0] MRxD_Lb;        // Muxed MII Receive Data
wire        Transmitting;   // Indication that TxEthMAC is transmitting
wire        r_HugEn;        // Huge packet enable
wire        r_DlyCrcEn;     // Delayed CRC enabled
wire [15:0] r_MaxFL;        // Maximum frame length

wire [15:0] r_MinFL;        // Minimum frame length
wire [47:0] r_MAC;          // MAC address

wire  [7:0] r_RxBDAddress;  // Receive buffer descriptor base address
wire  [6:0] r_IPGT;         // 
wire  [6:0] r_IPGR1;        // 
wire  [6:0] r_IPGR2;        // 
wire  [5:0] r_CollValid;    // 
wire        r_TPauseRq;     // Transmit PAUSE request pulse

wire  [3:0] r_MaxRet;       //
wire        r_NoBckof;      // 
wire        r_ExDfrEn;      // 
wire        RX_BD_ADR_Wr;   // Write enable that writes RX_BD_ADR to the registers.
wire        TPauseRq;       // Sinhronized Tx PAUSE request
wire [15:0] TxPauseTV;      // Tx PAUSE timer value
wire        r_TxFlow;       // Tx flow control enable
wire        r_IFG;          // Minimum interframe gap for incoming packets

wire        EthAddMatch;
wire        WB_STB_I_eth;
wire        WB_CYC_I_eth;

wire        DWord;
wire        RegAck;
wire        BDAck;
wire [31:0] DMA_WB_DAT_O;   // WB_DAT_O that comes from the WishboneDMA module



assign EthAddMatch = WB_ADR_I[31:16] == `ETHERNET_SPACE;
assign WB_STB_I_eth = WB_STB_I & EthAddMatch;
assign WB_CYC_I_eth = WB_STB_I & EthAddMatch;

assign WB_ERR_O = WB_STB_I & WB_CYC_I & EthAddMatch & ~DWord;
assign DWord = &WB_SEL_I;
assign RegCs = WB_STB_I & WB_CYC_I & DWord & EthAddMatch & (WB_ADR_I[15:12] == `REG_SPACE);
assign RegAck = RegCs;
assign WB_ACK_O = RegAck | BDAck;


// Selecting the WISHBONE output data
assign WB_DAT_O[31:0] = (RegCs & ~WB_WE_I)? RegDataOut : DMA_WB_DAT_O;


// Connecting Ethernet registers
ethregisters ethreg1
(
  .DataIn(WB_DAT_I),                      .Address(WB_ADR_I[7:2]),                    .Rw(WB_WE_I), 
  .Cs(RegCs),                             .Clk(WB_CLK_I),                             .Reset(WB_RST_I), 
  .DataOut(RegDataOut),                   .r_DmaEn(r_DmaEn),                          .r_RecSmall(), 
  .r_Pad(r_Pad),                          .r_HugEn(r_HugEn),                          .r_CrcEn(r_CrcEn), 
  .r_DlyCrcEn(r_DlyCrcEn),                .r_Rst(r_Rst),                              .r_FullD(r_FullD), 
  .r_ExDfrEn(r_ExDfrEn),                  .r_NoBckof(r_NoBckof),                      .r_LoopBck(r_LoopBck), 
  .r_IFG(r_IFG),                          .r_Pro(),                                   .r_Iam(), 
  .r_Bro(),                               .r_NoPre(r_NoPre),                          .r_TxEn(r_TxEn), 
  .r_RxEn(r_RxEn),                        .Busy_IRQ(),                                .RxF_IRQ(), 
  .RxB_IRQ(),                             .TxE_IRQ(),                                 .TxB_IRQ(), 
  .Busy_MASK(),                           .RxF_MASK(),                                .RxB_MASK(), 
  .TxE_MASK(),                            .TxB_MASK(),                                .r_IPGT(r_IPGT), 
  .r_IPGR1(r_IPGR1),                      .r_IPGR2(r_IPGR2),                          .r_MinFL(r_MinFL), 
  .r_MaxFL(r_MaxFL),                      .r_MaxRet(r_MaxRet),                        .r_CollValid(r_CollValid), 
  .r_TxFlow(r_TxFlow),                    .r_RxFlow(r_RxFlow),                        .r_PassAll(r_PassAll), 
  .r_MiiMRst(r_MiiMRst),                  .r_MiiNoPre(r_MiiNoPre),                    .r_ClkDiv(r_ClkDiv), 
  .r_WCtrlData(r_WCtrlData),              .r_RStat(r_RStat),                          .r_ScanStat(r_ScanStat), 
  .r_RGAD(r_RGAD),                        .r_FIAD(r_FIAD),                            .r_CtrlData(r_CtrlData), 
  .r_Prsd(),                              .Scan_stat(Scan_stat),                      .NValid_stat(NValid_stat), 
  .Busy_stat(Busy_stat),                  .Speed_stat(Speed_stat),                    .Duplex_stat(Duplex_stat), 
  .LinkFail(LinkFail),                    .r_MAC(r_MAC),                              .WCtrlDataStart(WCtrlDataStart),
  .RStatStart(RStatStart),                .UpdateMIIRX_DATAReg(UpdateMIIRX_DATAReg),  .Prsd(Prsd), 
  .r_RxBDAddress(r_RxBDAddress),          .RX_BD_ADR_Wr(RX_BD_ADR_Wr)
);



wire  [7:0] RxData;
wire        RxValid;
wire        RxStartFrm;
wire        RxEndFrm;

wire        WillTransmit;            // Will transmit (to RxEthMAC)
wire        ResetCollision;          // Reset Collision (for synchronizing collision)
wire  [7:0] TxDataOut;               // Transmit Packet Data (to TxEthMAC)
wire        WillSendControlFrame;
wire        TxCtrlEndFrm;
wire        ReceivedPauseFrm;
wire        ReceiveEnd;
wire        ReceivedPacketGood;
wire        ReceivedLengthOK;

// Connecting MACControl
maccontrol maccontrol1
(
  .MTxClk(MTxClk),                              .TPauseRq(TPauseRq), 
  .TxPauseTV(TxPauseTV),                        .TxDataIn(TxData), 
  .TxStartFrmIn(TxStartFrm),                    .TxEndFrmIn(TxEndFrm), 
  .TxUsedDataIn(TxUsedDataIn),                  .TxDoneIn(TxDoneIn), 
  .TxAbortIn(TxAbortIn),                        .MRxClk(MRxClk), 
  .RxData(RxData),                              .RxValid(RxValid), 
  .RxStartFrm(RxStartFrm),                      .RxEndFrm(RxEndFrm),
  .ReceiveEnd(ReceiveEnd),                      .ReceivedPacketGood(ReceivedPacketGood),
  .PassAll(r_PassAll),                          .TxFlow(r_TxFlow), 
  .RxFlow(r_RxFlow),                            .DlyCrcEn(r_DlyCrcEn),
  .MAC(r_MAC),                                  .PadIn(r_Pad | PerPacketPad), 
  .PadOut(PadOut),                              .CrcEnIn(r_CrcEn | PerPacketCrcEn), 
  .CrcEnOut(CrcEnOut),                          .TxReset(r_Rst), 
  .RxReset(r_Rst),                              .ReceivedLengthOK(ReceivedLengthOK),
  .TxDataOut(TxDataOut),                        .TxStartFrmOut(TxStartFrmOut), 
  .TxEndFrmOut(TxEndFrmOut),                    .TxUsedDataOut(TxUsedData), 
  .TxDoneOut(TxDone),                           .TxAbortOut(TxAbort), 
  .WillSendControlFrame(WillSendControlFrame),  .TxCtrlEndFrm(TxCtrlEndFrm), 
  .ReceivedPauseFrm(ReceivedPauseFrm)
);



wire TxCarrierSense;          // Synchronized CarrierSense (to Tx clock)
wire Collision;               // Synchronized Collision

reg CarrierSense_Tx1;
reg CarrierSense_Tx2;
reg Collision_Tx1;
reg Collision_Tx2;

reg RxEnSync;                 // Synchronized Receive Enable
reg CarrierSense_Rx1;
reg RxCarrierSense;           // Synchronized CarrierSense (to Rx clock)
reg WillTransmit_q;
reg WillTransmit_q2;



// Muxed MII receive data valid
assign MRxDV_Lb = r_LoopBck? MTxEn : MRxDV & RxEnSync;

// Muxed MII Receive Error
assign MRxErr_Lb = r_LoopBck? MTxErr : MRxErr & RxEnSync;

// Muxed MII Receive Data
assign MRxD_Lb[3:0] = r_LoopBck? MTxD[3:0] : MRxD[3:0];



// Connecting TxEthMAC
txethmac txethmac1
(
  .MTxClk(MTxClk),                    .Reset(r_Rst),                      .CarrierSense(TxCarrierSense), 
  .Collision(Collision),              .TxData(TxDataOut),                 .TxStartFrm(TxStartFrmOut), 
  .TxUnderRun(TxUnderRun),            .TxEndFrm(TxEndFrmOut),             .Pad(PadOut),  
  .MinFL(r_MinFL),                    .CrcEn(CrcEnOut),                   .FullD(r_FullD), 
  .HugEn(r_HugEn),                    .DlyCrcEn(r_DlyCrcEn),              .IPGT(r_IPGT), 
  .IPGR1(r_IPGR1),                    .IPGR2(r_IPGR2),                    .CollValid(r_CollValid), 
  .MaxRet(r_MaxRet),                  .NoBckof(r_NoBckof),                .ExDfrEn(r_ExDfrEn), 
  .MaxFL(r_MaxFL),                    .MTxEn(MTxEn),                      .MTxD(MTxD), 
  .MTxErr(MTxErr),                    .TxUsedData(TxUsedDataIn),          .TxDone(TxDoneIn), 
  .TxRetry(TxRetry),                  .TxAbort(TxAbortIn),                .WillTransmit(WillTransmit), 
  .ResetCollision(ResetCollision)
);




wire  [15:0]  RxByteCnt;
wire          RxByteCntEq0;
wire          RxByteCntGreat2;
wire          RxByteCntMaxFrame;
wire          RxCrcError;
wire          RxStateIdle;
wire          RxStatePreamble;
wire          RxStateSFD;
wire   [1:0]  RxStateData;




// Connecting RxEthMAC
rxethmac rxethmac1
(
  .MRxClk(MRxClk),                      .MRxDV(MRxDV_Lb),                     .MRxD(MRxD_Lb),
  .Transmitting(Transmitting),          .HugEn(r_HugEn),                      .DlyCrcEn(r_DlyCrcEn), 
  .MaxFL(r_MaxFL),                      .r_IFG(r_IFG),                        .Reset(r_Rst),
  .RxData(RxData),                      .RxValid(RxValid),                    .RxStartFrm(RxStartFrm), 
  .RxEndFrm(RxEndFrm),                  .CrcHash(),                           .CrcHashGood(), 
  .Broadcast(),                         .Multicast(),                         .ByteCnt(RxByteCnt), 
  .ByteCntEq0(RxByteCntEq0),            .ByteCntGreat2(RxByteCntGreat2),      .ByteCntMaxFrame(RxByteCntMaxFrame), 
  .CrcError(RxCrcError),                .StateIdle(RxStateIdle),              .StatePreamble(RxStatePreamble), 
  .StateSFD(RxStateSFD),                .StateData(RxStateData)
);


// MII Carrier Sense Synchronization
always @ (posedge MTxClk or posedge r_Rst)
begin
  if(r_Rst)
    begin
      CarrierSense_Tx1 <= #Tp 1'b0;
      CarrierSense_Tx2 <= #Tp 1'b0;
    end
  else
    begin
      CarrierSense_Tx1 <= #Tp MCrs;
      CarrierSense_Tx2 <= #Tp CarrierSense_Tx1;
    end
end

assign TxCarrierSense = ~r_FullD & CarrierSense_Tx2;


// MII Collision Synchronization
always @ (posedge MTxClk or posedge r_Rst)
begin
  if(r_Rst)
    begin
      Collision_Tx1 <= #Tp 1'b0;
      Collision_Tx2 <= #Tp 1'b0;
    end
  else
    begin
      Collision_Tx1 <= #Tp MColl;
      if(ResetCollision)
        Collision_Tx2 <= #Tp 1'b0;
      else
      if(Collision_Tx1)
        Collision_Tx2 <= #Tp 1'b1;
    end
end


// Synchronized Collision
assign Collision = ~r_FullD & Collision_Tx2;



// Carrier sense is synchronized to receive clock.
always @ (posedge MRxClk or posedge r_Rst)
begin
  if(r_Rst)
    begin
      CarrierSense_Rx1 <= #Tp 1'h0;
      RxCarrierSense <= #Tp 1'h0;
    end
  else
    begin
      CarrierSense_Rx1 <= #Tp MCrs;
      RxCarrierSense <= #Tp CarrierSense_Rx1;
    end
end


// Delayed WillTransmit
always @ (posedge MRxClk)
begin
  WillTransmit_q <= #Tp WillTransmit;
  WillTransmit_q2 <= #Tp WillTransmit_q;
end 


assign Transmitting = ~r_FullD & WillTransmit_q2;



// Synchronized Receive Enable
always @ (posedge MRxClk or posedge r_Rst)
begin
  if(r_Rst)
    RxEnSync <= #Tp 1'b0;
  else
  if(~RxCarrierSense | RxCarrierSense & Transmitting)
    RxEnSync <= #Tp r_RxEn;
end 




// Connecting WishboneDMA module
wishbonedma wbdma
(
  .WB_CLK_I(WB_CLK_I),                .WB_RST_I(WB_RST_I),                      .WB_DAT_I(WB_DAT_I), 
  .WB_DAT_O(DMA_WB_DAT_O), 

  // WISHBONE slave
  .WB_ADR_I(WB_ADR_I),                .WB_SEL_I(WB_SEL_I),                      .WB_WE_I(WB_WE_I), 
  .WB_CYC_I(WB_CYC_I_eth),            .WB_STB_I(WB_STB_I_eth),                  .WB_ACK_O(BDAck), 
  .WB_REQ_O(WB_REQ_O),                .WB_ACK_I(WB_ACK_I),                      .WB_ND_O(WB_ND_O), 
  .WB_RD_O(WB_RD_O), 

    //TX
  .MTxClk(MTxClk),                    .TxStartFrm(TxStartFrm),                  .TxEndFrm(TxEndFrm), 
  .TxUsedData(TxUsedData),            .TxData(TxData),                          .StatusIzTxEthMACModula(16'h0), 
  .TxRetry(TxRetry),                  .TxAbort(TxAbort),                        .TxUnderRun(TxUnderRun), 
  .TxDone(TxDone),                    .TPauseRq(TPauseRq),                      .TxPauseTV(TxPauseTV), 
  .PerPacketCrcEn(PerPacketCrcEn),    .PerPacketPad(PerPacketPad),              .WillSendControlFrame(WillSendControlFrame), 
  .TxCtrlEndFrm(TxCtrlEndFrm), 

  // Register
  .r_TxEn(r_TxEn),                    .r_RxEn(r_RxEn),                          .r_RxBDAddress(r_RxBDAddress), 
  .r_DmaEn(r_DmaEn),                  .RX_BD_ADR_Wr(RX_BD_ADR_Wr), 

  //RX
  .MRxClk(MRxClk),                    .RxData(RxData),                          .RxValid(RxValid), 
  .RxStartFrm(RxStartFrm),            .RxEndFrm(RxEndFrm)
);



// Connecting MacStatus module
macstatus macstatus1 
(
  .MRxClk(MRxClk),                    .Reset(r_Rst),                            .TransmitEnd(), 
  .ReceiveEnd(ReceiveEnd),            .ReceivedPacketGood(ReceivedPacketGood),  .ReceivedLengthOK(ReceivedLengthOK), 
  .RxCrcError(RxCrcError),            .MRxErr(MRxErr_Lb),                       .MRxDV(MRxDV_Lb), 
  .RxStateSFD(RxStateSFD),            .RxStateData(RxStateData),                .RxStatePreamble(RxStatePreamble), 
  .RxStateIdle(RxStateIdle),          .Transmitting(Transmitting),              .RxByteCnt(RxByteCnt), 
  .RxByteCntEq0(RxByteCntEq0),        .RxByteCntGreat2(RxByteCntGreat2),        .RxByteCntMaxFrame(RxByteCntMaxFrame), 
  .ReceivedPauseFrm(ReceivedPauseFrm)
);


endmodule
