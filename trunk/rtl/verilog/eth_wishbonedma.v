//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_wishbonedma.v                                           ////
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
// Revision 1.5  2001/10/19 08:43:51  mohor
// eth_timescale.v changed to timescale.v This is done because of the
// simulation of the few cores in a one joined project.
//
// Revision 1.4  2001/10/18 12:07:11  mohor
// Status signals changed, Adress decoding changed, interrupt controller
// added.
//
// Revision 1.3  2001/09/24 15:02:56  mohor
// Defines changed (All precede with ETH_). Small changes because some
// tools generate warnings when two operands are together. Synchronization
// between two clocks domains in eth_wishbonedma.v is changed (due to ASIC
// demands).
//
// Revision 1.2  2001/08/08 08:28:21  mohor
// "else" was missing within the always block in file eth_wishbonedma.v.
//
// Revision 1.1  2001/08/06 14:44:29  mohor
// A define FPGA added to select between Artisan RAM (for ASIC) and Block Ram (For Virtex).
// Include files fixed to contain no path.
// File names and module names changed ta have a eth_ prologue in the name.
// File eth_timescale.v is used to define timescale
// All pin names on the top module are changed to contain _I, _O or _OE at the end.
// Bidirectional signal MDIO is changed to three signals (Mdc_O, Mdi_I, Mdo_O
// and Mdo_OE. The bidirectional signal must be created on the top level. This
// is done due to the ASIC tools.
//
// Revision 1.1  2001/07/30 21:23:42  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//


`include "eth_defines.v"
`include "timescale.v"


module eth_wishbonedma
   (

    // WISHBONE common
    WB_CLK_I, WB_RST_I, WB_DAT_I, WB_DAT_O, 

    // WISHBONE slave
 		WB_ADR_I, WB_SEL_I, WB_WE_I, WB_ACK_O, 
 		WB_REQ_O, WB_ACK_I, WB_ND_O, WB_RD_O, BDCs, 

    //TX
    MTxClk, TxStartFrm, TxEndFrm, TxUsedData, TxData, StatusIzTxEthMACModula, 
    TxRetry, TxAbort, TxUnderRun, TxDone, TPauseRq, TxPauseTV, PerPacketCrcEn, 
    PerPacketPad, 

    //RX
    MRxClk, RxData, RxValid, RxStartFrm, RxEndFrm, 
    
    // Register
    r_TxEn, r_RxEn, r_RxBDAddress, r_DmaEn, RX_BD_ADR_Wr, 

    WillSendControlFrame, TxCtrlEndFrm, 
    
    // Interrupts
    TxB_IRQ, TxE_IRQ, RxB_IRQ, RxF_IRQ, Busy_IRQ

		);


parameter Tp = 1;

// WISHBONE common
input           WB_CLK_I;       // WISHBONE clock
input           WB_RST_I;       // WISHBONE reset
input  [31:0]   WB_DAT_I;       // WISHBONE data input
output [31:0]   WB_DAT_O;       // WISHBONE data output

// WISHBONE slave
input   [9:2]   WB_ADR_I;       // WISHBONE address input
input   [3:0]   WB_SEL_I;       // WISHBONE byte select input
input           WB_WE_I;        // WISHBONE write enable input
input           BDCs;           // Buffer descriptors are selected
output          WB_ACK_O;       // WISHBONE acknowledge output

// DMA
input   [1:0]   WB_ACK_I;       // DMA acknowledge input
output  [1:0]   WB_REQ_O;       // DMA request output
output  [1:0]   WB_ND_O;        // DMA force new descriptor output
output          WB_RD_O;        // DMA restart descriptor output

// Tx
input           MTxClk;         // Transmit clock (from PHY)
input           TxUsedData;     // Transmit packet used data
input  [15:0]   StatusIzTxEthMACModula;
input           TxRetry;        // Transmit packet retry
input           TxAbort;        // Transmit packet abort
input           TxDone;         // Transmission ended
output          TxStartFrm;     // Transmit packet start frame
output          TxEndFrm;       // Transmit packet end frame
output  [7:0]   TxData;         // Transmit packet data byte
output          TxUnderRun;     // Transmit packet under-run
output          PerPacketCrcEn; // Per packet crc enable
output          PerPacketPad;   // Per packet pading
output          TPauseRq;       // Tx PAUSE control frame
output [15:0]   TxPauseTV;      // PAUSE timer value
input           WillSendControlFrame;
input           TxCtrlEndFrm;

// Rx
input           MRxClk;         // Receive clock (from PHY)
input   [7:0]   RxData;         // Received data byte (from PHY)
input           RxValid;        // 
input           RxStartFrm;     // 
input           RxEndFrm;       // 

//Register
input           r_TxEn;         // Transmit enable
input           r_RxEn;         // Receive enable
input   [7:0]   r_RxBDAddress;  // Receive buffer descriptor address
input           r_DmaEn;        // DMA enable
input           RX_BD_ADR_Wr;   // RxBDAddress written

// Interrupts
output TxB_IRQ;
output TxE_IRQ;
output RxB_IRQ;
output RxF_IRQ;
output Busy_IRQ;

reg             WB_REQ_O_RX;    
reg             WB_ND_O_TX;     // New descriptor
reg             WB_RD_O;        // Restart descriptor

reg             TxStartFrm;
reg             TxEndFrm;
reg     [7:0]   TxData;

reg             TxUnderRun;
reg             TPauseRq;
reg             TxPauseRq;

reg             RxStartFrm_wb;
reg     [31:0]  RxData_wb;
reg             RxDataValid_wb;
reg             RxEndFrm_wb;

reg     [7:0]   BDAddress;    // BD address for access from MAC side
reg             BDRead_q;

reg             TxBDRead;
reg             TxDataRead;
reg             TxStatusWrite;

reg     [1:0]   TxValidBytesLatched;
reg             TxEndFrm_wbLatched;

reg    [15:0]   TxLength;
reg    [31:0]   TxStatus;

reg    [15:0]   RxStatus;

reg             TxStartFrm_wb;
reg             TxRetry_wb;
reg             GetNewTxData_wb;
reg             TxDone_wb;
reg             TxAbort_wb;


reg             TxStartFrmRequest;
reg    [31:0]   TxDataLatched_wb;

reg             RxStatusWriteOccured;

reg             TxRestart_wb_q;
reg             TxDone_wb_q;
reg             TxAbort_wb_q;
reg             RxBDReady;
reg             TxBDReady;

reg             RxBDRead;
reg             RxStatusWrite;
reg             WbWriteError;

reg    [31:0]   TxDataLatched;
reg     [1:0]   TxByteCnt;
reg             LastWord;
reg             GetNewTxData;
reg             TxRetryLatched;

reg             Div2;
reg             Flop;

reg             BlockingTxStatusWrite;
reg             TxStatusWriteOccured;
reg             BlockingTxBDRead;

reg             GetNewTxData_wb_latched;

reg             NewTxDataAvaliable_wb;

reg             TxBDAccessed;

reg     [7:0]   TxBDAddress;
reg     [7:0]   RxBDAddress;

reg             GotDataSync1;
reg             GotDataSync2;
wire            TPauseRqSync2;
wire             GotDataSync3;
reg             GotData;
reg             SyncGetNewTxData_wb1;
reg             SyncGetNewTxData_wb2;
reg             SyncGetNewTxData_wb3;
reg             TxDoneSync1;
reg             TxDoneSync2;
wire             TxDoneSync3;
reg             TxRetrySync1;
reg             TxRetrySync2;
wire            TxRetrySync3;
reg             TxAbortSync1;
reg             TxAbortSync2;
wire            TxAbortSync3;

reg             TxAbort_q;
reg             TxDone_q;
reg             TxRetry_q;
reg             TxUsedData_q;

reg    [31:0]   RxDataLatched2;
reg    [15:0]   RxDataLatched1;
reg     [1:0]   RxValidBytes;
reg     [1:0]   RxByteCnt;
reg             LastByteIn;
reg             ShiftWillEnd;

reg             StartShifting;
reg             Shifting_wb_Sync1;
reg             Shifting_wb_Sync2;
reg             LatchNow_wb;

reg             ShiftEndedSync1;
reg             ShiftEndedSync2;
reg             ShiftEndedSync3;
wire            ShiftEnded;

reg             RxStartFrmSync1;
reg             RxStartFrmSync2;
wire            RxStartFrmSync3;

reg             DMACycleFinishedTx_q;
reg             DataNotAvaliable;

reg             ClearTxBDReadySync1;
reg             ClearTxBDReadySync2;
reg             ClearTxBDReady;

reg             TxCtrlEndFrm_wbSync1;
reg             TxCtrlEndFrm_wbSync2;
wire            TxCtrlEndFrm_wbSync3;
reg             TxCtrlEndFrm_wb;

wire    [15:0]  TxPauseTV;
wire            ResetDataNotAvaliable;
wire            SetDataNotAvaliable;
wire            DWord;                      // Only 32-bit accesses are valid
wire            BDWe;                       // BD Write Enable for access from WISHBONE side
wire            BDRead;                     // BD Read access from WISHBONE side
wire   [31:0]   BDDataIn;                   // BD data in
wire   [31:0]   BDDataOut;                  // BD data out

wire            TxEndFrm_wb;

wire            DMACycleFinishedTx;
wire            BDStatusWrite;

wire            TxEn;
wire            RxEn;
wire            TxRestartPulse;
wire            TxDonePulse;
wire            TxAbortPulse;

wire            StartRxBDRead;
wire            ResetRxBDRead;
wire            StartRxStatusWrite;

wire            ResetShifting_wb;
wire            StartShifting_wb;
wire            DMACycleFinishedRx;

wire   [31:0]   WB_BDDataOut;

wire            StartTxBDRead;
wire            StartTxDataRead;
wire            ResetTxDataRead;
wire            StartTxStatusWrite;
wire            ResetTxStatusWrite;

wire            TxIRQEn;
wire            WrapTxStatusBit;

wire            WrapRxStatusBit;

wire    [1:0]   TxValidBytes;

wire    [7:0]   TempTxBDAddress;
wire    [7:0]   TempRxBDAddress;

wire   [15:0]   RxLength;
wire   [15:0]   NewRxStatus;

wire            SetGotData;
wire            ResetGotData;
wire            GotDataEvaluate;
wire            ResetSyncGetNewTxData_wb;
wire            ResetTxDoneSync;
wire            ResetTxRetrySync;
wire            ResetTxAbortSync;
wire            SetSyncGetNewTxData_wb;

wire            SetTxAbortSync;
wire            ResetShiftEnded;
wire            ResetRxStartFrmSync1;
wire            StartShiftEnded;
wire            StartRxStartFrmSync1;

wire            SetClearTxBDReady;
wire            ResetClearTxBDReady;

wire            ResetTxCtrlEndFrm_wb;
wire            SetTxCtrlEndFrm_wb;
     
     
     
      
assign BDWe   = BDCs &  WB_WE_I;
assign BDRead = BDCs & ~WB_WE_I;
assign WB_ACK_O = BDWe | BDRead & BDRead_q;  // ACK is delayed one clock because of BLOCKRAM properties when performing read



reg EnableRAM;
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    EnableRAM   <=#Tp 1'b0;
  else
  if(BDWe)
    EnableRAM   <=#Tp 1'b1;
  else
    EnableRAM   <=#Tp EnableRAM;
end

`ifdef ETH_FPGA
  // Xilinx BlockRAM for storing Tx and Rx buffer descriptors
  
  RAMB4_S16_S16 RAM1 ( .DIA(WB_DAT_I[15:0]),     .DOA(WB_BDDataOut[15:0]),  .ADDRA(WB_ADR_I[9:2]), 
                       .WEA(BDWe),               .CLKA(WB_CLK_I),           .ENA(1'b1), 
                       .RSTA(WB_RST_I),          .DIB(BDDataIn[15:0]),      .DOB(BDDataOut[15:0]), 
                       .ADDRB(BDAddress[7:0]),   .WEB(BDStatusWrite),       .CLKB(WB_CLK_I), 
                       .ENB(EnableRAM),          .RSTB(WB_RST_I) ); 
  RAMB4_S16_S16 RAM2 ( .DIA(WB_DAT_I[31:16]),    .DOA(WB_BDDataOut[31:16]), .ADDRA(WB_ADR_I[9:2]), 
                       .WEA(BDWe),               .CLKA(WB_CLK_I),           .ENA(1'b1), 
                       .RSTA(WB_RST_I),          .DIB(BDDataIn[31:16]),     .DOB(BDDataOut[31:16]), 
                       .ADDRB(BDAddress[7:0]),   .WEB(BDStatusWrite),       .CLKB(WB_CLK_I), 
                       .ENB(EnableRAM), .RSTB(WB_RST_I) ); 
`else
  // Artisan RAM (ASIC implementation) for storing Tx and Rx buffer descriptors
  // Size will be reduced before implementation to 256 x 32
  
  wire [63:32] qa_dummy;
  wire [63:32] qb_dummy;
  art_hddp_8192x64 RAM1 ( .qa({qa_dummy[63:32], WB_BDDataOut[31:0]}), .clka(WB_CLK_I), 
                          .cena(1'b0),                                .wena(~BDWe), 
                          .aa({5'h0, WB_ADR_I[9:2]}),                 .da({32'h0, WB_DAT_I[31:0]}),
                          .oena(1'b0),      
                          .qb({qb_dummy[63:32], BDDataOut[31:0]}),    .clkb(WB_CLK_I), 
                          .cenb(1'b0),                                .wenb(~BDStatusWrite), 
                          .ab({5'h0, BDAddress[7:0]}),                .db({32'h0, BDDataIn[31:0]}), 
                          .oenb(1'b0)
                        );
`endif


// WB_CLK_I is divided by 2. This signal is used for enabling tx and rx operations sequentially
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    Div2 <=#Tp 1'h0;
  else
    Div2 <=#Tp ~Div2;
end


// Tx_En and Rx_En select who can access the BD memory (Tx or Rx)
assign TxEn =  Div2 & r_TxEn;
assign RxEn = ~Div2 & r_RxEn;


// Changes for tx occur every second clock. Flop is used for this manner.
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    Flop <=#Tp 1'b0;
  else
  if(TxDone | TxAbort | TxRetry_q)
    Flop <=#Tp 1'b0;
  else
  if(TxUsedData)
    Flop <=#Tp ~Flop;
end


// Latching READY status of the Tx buffer descriptor
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxBDReady <=#Tp 1'b0;
  else
  if(TxEn & TxBDRead)
    TxBDReady <=#Tp BDDataOut[15]; // TxBDReady=BDDataOut[15]   // TxBDReady is sampled only once at the beginning
  else
  if(TxDone & ~TxDone_q | TxAbort & ~TxAbort_q | TxRetry & ~TxRetry_q | ClearTxBDReady | TxPauseRq)
    TxBDReady <=#Tp 1'b0;
end


// Latching READY status of the Tx buffer descriptor
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      TxPauseRq <=#Tp 1'b0;
    end
  else
  if(TxEn & TxBDRead)
    begin
      TxPauseRq <=#Tp BDDataOut[9];    // Tx PAUSE request
    end
  else
      TxPauseRq <=#Tp 1'b0;
end


assign TxPauseTV[15:0] = TxLength[15:0];

// Reading the Tx buffer descriptor
assign StartTxBDRead = TxEn & ~BlockingTxBDRead & (TxRetry_wb | TxStatusWriteOccured);

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxBDRead <=#Tp 1'b1;
  else
  if(StartTxBDRead)
    TxBDRead <=#Tp 1'b1;
  else
  if(StartTxDataRead | TxPauseRq)
    TxBDRead <=#Tp 1'b0;
end



// Requesting data (DMA)
assign StartTxDataRead = TxBDRead & TxBDReady & ~TxPauseRq | GetNewTxData_wb;
assign ResetTxDataRead = DMACycleFinishedTx | TxRestartPulse | TxAbortPulse | TxDonePulse;


// Reading data
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxDataRead <=#Tp 1'b0;
  else
  if(StartTxDataRead & r_DmaEn)
    TxDataRead <=#Tp 1'b1;
  else
  if(ResetTxDataRead)
    TxDataRead <=#Tp 1'b0;
end

// Requesting tx data from the DMA
assign WB_REQ_O[0] = TxDataRead;
assign DMACycleFinishedTx = WB_REQ_O[0] & WB_ACK_I[0] & TxBDReady;


// Writing status back to the Tx buffer descriptor
assign StartTxStatusWrite = TxEn & ~BlockingTxStatusWrite & (TxDone_wb | TxAbort_wb | TxCtrlEndFrm_wb);
assign ResetTxStatusWrite = TxStatusWrite;

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStatusWrite <=#Tp 1'b0;
  else
  if(StartTxStatusWrite)
    TxStatusWrite <=#Tp 1'b1;
  else
  if(ResetTxStatusWrite)
    TxStatusWrite <=#Tp 1'b0;
end


// Status writing must occur only once. Meanwhile it is blocked.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    BlockingTxStatusWrite <=#Tp 1'b0;
  else
  if(StartTxStatusWrite)
    BlockingTxStatusWrite <=#Tp 1'b1;
  else
  if(~TxDone_wb & ~TxAbort_wb)
    BlockingTxStatusWrite <=#Tp 1'b0;
end


// After a tx status write is finished, a new tx buffer descriptor is read. Signal must be
// latched because new BD read doesn't occur immediately.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStatusWriteOccured <=#Tp 1'b0;
  else
  if(StartTxStatusWrite)
    TxStatusWriteOccured <=#Tp 1'b1;
  else
  if(StartTxBDRead)
    TxStatusWriteOccured <=#Tp 1'b0;
end


// TxBDRead state is activated only once. 
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    BlockingTxBDRead <=#Tp 1'b0;
  else
  if(StartTxBDRead)
    BlockingTxBDRead <=#Tp 1'b1;
  else
  if(TxStartFrm_wb | TxCtrlEndFrm_wb)
    BlockingTxBDRead <=#Tp 1'b0;
end


// Latching status from the tx buffer descriptor
// Data is avaliable one cycle after the access is started (at that time signal TxEn is not active)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStatus <=#Tp 32'h0;
  else
  if(TxBDRead & TxEn)
    TxStatus <=#Tp BDDataOut;
end


//Latching length from the buffer descriptor;
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxLength <=#Tp 16'h0;
  else
  if(TxBDRead & TxEn)
    TxLength <=#Tp BDDataOut[31:16];
  else
  if(GetNewTxData_wb & ~WillSendControlFrame)
    begin
      if(TxLength > 4)
        TxLength <=#Tp TxLength - 4;    // Length is subtracted at the data request
      else
        TxLength <=#Tp 16'h0;
    end
end


// Latching Rx buffer descriptor status
// Data is avaliable one cycle after the access is started (at that time signal RxEn is not active)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxStatus <=#Tp 16'h0;
  else
  if(RxBDRead & RxEn)
    RxStatus <=#Tp BDDataOut[15:0];
end


// Signal GetNewTxData_wb that requests new data from the DMA must be latched since the DMA response
// might be delayed.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    GetNewTxData_wb_latched <=#Tp 1'b0;
  else
  if(GetNewTxData_wb)
    GetNewTxData_wb_latched <=#Tp 1'b1;
  else
  if(DMACycleFinishedTx)
    GetNewTxData_wb_latched <=#Tp 1'b0;
end


// New tx data is avaliable after the DMA access is finished
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    NewTxDataAvaliable_wb <=#Tp 1'b0;
  else
  if(DMACycleFinishedTx & GetNewTxData_wb_latched)
    NewTxDataAvaliable_wb <=#Tp 1'b1;
  else
  if(NewTxDataAvaliable_wb)
    NewTxDataAvaliable_wb <=#Tp 1'b0;
end


// Tx Buffer descriptor is only read at the beginning. This signal is used for generation of the
// TxStartFrm_wb signal.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxBDAccessed <=#Tp 1'b0;
  else
  if(TxBDRead)
    TxBDAccessed <=#Tp 1'b1;
  else
  if(TxStartFrm_wb)
    TxBDAccessed <=#Tp 1'b0;
end


// TxStartFrm_wb: indicator of the start frame (synchronized to WB_CLK_I)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm_wb <=#Tp 1'b0;
  else
  if(DMACycleFinishedTx & TxBDAccessed & ~TxStartFrm_wb)
    TxStartFrm_wb <=#Tp 1'b1;
  else
  if(TxStartFrm_wb)
    TxStartFrm_wb <=#Tp 1'b0;
end


// TxEndFrm_wb: indicator of the end of frame
assign TxEndFrm_wb = (TxLength <= 4) & TxUsedData;


// Input latch of the end-of-frame indicator
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxEndFrm_wbLatched <=#Tp 1'b0;
  else
  if(TxEndFrm_wb)
    TxEndFrm_wbLatched <=#Tp 1'b1;
  else
  if(TxRestartPulse | TxDonePulse | TxAbortPulse)
    TxEndFrm_wbLatched <=#Tp 1'b0;
end


// Marks which bytes are valid within the word.
assign TxValidBytes = (TxLength >= 4)? 2'b0 : TxLength[1:0];


// Latching valid bytes
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxValidBytesLatched <=#Tp 2'h0;
  else
  if(TxEndFrm_wb & ~TxEndFrm_wbLatched)
    TxValidBytesLatched <=#Tp TxValidBytes;
  else
  if(TxRestartPulse | TxDonePulse | TxAbortPulse)
    TxValidBytesLatched <=#Tp 2'h0;
end


// Input Tx data latch 
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxDataLatched_wb <=#Tp 32'h0;
  else
  if(DMACycleFinishedTx)
    TxDataLatched_wb <=#Tp WB_DAT_I;
end


// TxStartFrmRequest is set when a new frame is avaliable or when new data of the same frame is avaliable)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrmRequest <=#Tp 1'b0;
  else
  if(TxStartFrm_wb | NewTxDataAvaliable_wb)
    TxStartFrmRequest <=#Tp TxStartFrm_wb;
end


// Bit 14 is used as a wrap bit. When active it indicates the last buffer descriptor in a row. After
// using this descriptor, first BD will be used again.



// TX
// bit 15 od tx je ready
// bit 14 od tx je interrupt (Tx buffer ali tx error bit se postavi v interrupt registru, ko se ta buffer odda)
// bit 13 od tx je wrap
// bit 12 od tx je pad
// bit 11 od tx je crc
// bit 10 od tx je last (crc se doda le ce je bit 11 in hkrati bit 10)
// bit 9  od tx je pause request (control frame)
    // Vsi zgornji biti gredo ven, spodnji biti (od 8 do 0) pa so statusni in se vpisejo po koncu oddajanja
// bit 8  od tx je defer indication
// bit 7  od tx je late collision
// bit 6  od tx je retransmittion limit
// bit 5  od tx je underrun
// bit 4  od tx je carrier sense lost
// bit [3:0] od tx je retry count

//assign TxBDReady      = TxStatus[15];     // already used
assign TxIRQEn          = TxStatus[14];
assign WrapTxStatusBit  = TxStatus[13];                                                   // ok povezan
assign PerPacketPad     = TxStatus[12];                                                   // ok povezan
assign PerPacketCrcEn   = TxStatus[11] & TxStatus[10];      // When last is also set      // ok povezan
//assign TxPauseRq      = TxStatus[9];      // already used



// RX
// bit 15 od rx je empty
// bit 14 od rx je interrupt (Rx buffer ali rx frame received se postavi v interrupt registru, ko se ta buffer zapre)
// bit 13 od rx je wrap
// bit 12 od rx je reserved
// bit 11 od rx je reserved
// bit 10 od rx je last (crc se doda le ce je bit 11 in hkrati bit 10)
// bit 9  od rx je pause request (control frame)
    // Vsi zgornji biti gredo ven, spodnji biti (od 8 do 0) pa so statusni in se vpisejo po koncu oddajanja
// bit 8  od rx je defer indication
// bit 7  od rx je late collision
// bit 6  od rx je retransmittion limit
// bit 5  od rx je underrun
// bit 4  od rx je carrier sense lost
// bit [3:0] od rx je retry count

assign WrapRxStatusBit = RxStatus[13];


// Temporary Tx and Rx buffer descriptor address 
assign TempTxBDAddress[7:0] = {8{ TxStatusWrite    & ~WrapTxStatusBit}} & (TxBDAddress + 1) ; // Tx BD increment or wrap (last BD)
assign TempRxBDAddress[7:0] = {8{ WrapRxStatusBit}} & (r_RxBDAddress)   | // Using first Rx BD
                              {8{~WrapRxStatusBit}} & (RxBDAddress + 1) ; // Using next Rx BD (incremenrement address)


// Latching Tx buffer descriptor address
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxBDAddress <=#Tp 8'h0;
  else
  if(TxStatusWrite)
    TxBDAddress <=#Tp TempTxBDAddress;
end


// Latching Rx buffer descriptor address
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxBDAddress <=#Tp 8'h0;
  else
  if(RX_BD_ADR_Wr)                        // When r_RxBDAddress is updated, RxBDAddress is also
    RxBDAddress <=#Tp WB_DAT_I[7:0];
  else
  if(RxStatusWrite)
    RxBDAddress <=#Tp TempRxBDAddress;
end


// Selecting Tx or Rx buffer descriptor address
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    BDAddress <=#Tp 8'h0;
  else
  if(TxEn)
    BDAddress <=#Tp TxBDAddress;
  else
    BDAddress <=#Tp RxBDAddress;
end


assign RxLength[15:0]  = 16'h1399;
assign NewRxStatus[15:0] = {1'b0, WbWriteError, RxStatus[13:0]};


//assign BDDataIn  = TxStatusWrite ? {TxLength[15:0], StatusIzTxEthMACModula} : {RxLength, NewRxStatus};
assign BDDataIn  = TxStatusWrite ? {TxStatus[31:9], 9'h0} 
                                 : {RxLength, NewRxStatus};

assign BDStatusWrite = TxStatusWrite | RxStatusWrite;


// Generating delayed signals
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      TxRestart_wb_q        <=#Tp 1'b0;
      TxDone_wb_q           <=#Tp 1'b0;
      TxAbort_wb_q          <=#Tp 1'b0;
      BDRead_q              <=#Tp 1'b0;
      DMACycleFinishedTx_q  <=#Tp 1'b0;
    end
  else
    begin
      TxRestart_wb_q        <=#Tp TxRetry_wb;
      TxDone_wb_q           <=#Tp TxDone_wb;
      TxAbort_wb_q          <=#Tp TxAbort_wb;
      BDRead_q              <=#Tp BDRead;
      DMACycleFinishedTx_q  <=#Tp DMACycleFinishedTx;
    end                 
end                      


// Signals used for various purposes
assign TxRestartPulse = TxRetry_wb   & ~TxRestart_wb_q;
assign TxDonePulse    = TxDone_wb    & ~TxDone_wb_q;
assign TxAbortPulse   = TxAbort_wb   & ~TxAbort_wb_q;


// Next descriptor for Tx DMA channel
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    WB_ND_O_TX <=#Tp 1'b0;
  else
  if(TxDonePulse | TxAbortPulse)
    WB_ND_O_TX <=#Tp 1'b1;
  else
  if(WB_ND_O_TX)
    WB_ND_O_TX <=#Tp 1'b0;
end


// Force next descriptor on DMA channel 0 (Tx)
assign WB_ND_O[0] = WB_ND_O_TX;



// Restart descriptor for DMA channel 0 (Tx)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    WB_RD_O <=#Tp 1'b0;
  else
  if(TxRestartPulse)
    WB_RD_O <=#Tp 1'b1;
  else
  if(WB_RD_O)
    WB_RD_O <=#Tp 1'b0;
end


assign SetClearTxBDReady = ~TxUsedData & TxUsedData_q;
assign ResetClearTxBDReady = ClearTxBDReady | WB_RST_I;


always @ (posedge SetClearTxBDReady or posedge ResetClearTxBDReady)
begin
  if(ResetClearTxBDReady)
    ClearTxBDReadySync1 <=#Tp 1'b0;
  else
    ClearTxBDReadySync1 <=#Tp 1'b1;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ClearTxBDReadySync2 <=#Tp 1'b0;
  else
  if(ClearTxBDReadySync1 & ~ClearTxBDReady)
    ClearTxBDReadySync2 <=#Tp 1'b1;
  else
    ClearTxBDReadySync2 <=#Tp 1'b0;
end


always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ClearTxBDReady <=#Tp 1'b0;
  else
  if(ClearTxBDReadySync2 & ~ClearTxBDReady)
    ClearTxBDReady <=#Tp 1'b1;
  else
    ClearTxBDReady <=#Tp 1'b0;
end



// Latching and synchronizing the Tx pause request signal
eth_sync_clk1_clk2 syn1 (.clk1(MTxClk),     .clk2(WB_CLK_I),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(TxPauseRq),  .sync_out(TPauseRqSync2)
                        );


always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TPauseRq <=#Tp 1'b0;
  else
  if(TPauseRq )
    TPauseRq <=#Tp 1'b0;
  else
  if(TPauseRqSync2)
    TPauseRq <=#Tp 1'b1;
end



// Generating delayed signals
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      TxAbort_q     <=#Tp 1'b0;
      TxDone_q      <=#Tp 1'b0;
      TxRetry_q     <=#Tp 1'b0;
      TxUsedData_q  <=#Tp 1'b0;
    end
  else
    begin
      TxAbort_q     <=#Tp TxAbort;
      TxDone_q      <=#Tp TxDone;
      TxRetry_q     <=#Tp TxRetry;
      TxUsedData_q  <=#Tp TxUsedData;
    end
end



// Sinchronizing and evaluating tx data
assign SetGotData = (TxStartFrm_wb | NewTxDataAvaliable_wb & ~TxAbort_wb & ~TxRetry_wb) & ~WB_CLK_I;

eth_sync_clk1_clk2 syn2 (.clk1(MTxClk),     .clk2(WB_CLK_I),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(SetGotData), .sync_out(GotDataSync3));


// Evaluating data. If abort or retry occured meanwhile than data is ignored.
assign GotDataEvaluate = GotDataSync3 & ~GotData & (~TxRetry & ~TxAbort | (TxRetry | TxAbort) & (TxStartFrmRequest | TxStartFrm));


// Indication of good data
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    GotData <=#Tp 1'b0;
  else
  if(GotDataEvaluate)
    GotData <=#Tp 1'b1;
  else
    GotData <=#Tp 1'b0;
end


// Tx start frame generation
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm <=#Tp 1'b0;
  else
  if(TxUsedData_q | TxAbort & ~TxAbort_q | TxRetry & ~TxRetry_q)
    TxStartFrm <=#Tp 1'b0;
  else
  if(TxBDReady & GotData & TxStartFrmRequest)
    TxStartFrm <=#Tp 1'b1;
end


// Indication of the last word
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    LastWord <=#Tp 1'b0;
  else
  if((TxEndFrm | TxAbort | TxRetry) & Flop)
    LastWord <=#Tp 1'b0;
  else
  if(TxUsedData & Flop & TxByteCnt == 2'h3)
    LastWord <=#Tp TxEndFrm_wbLatched;
end


// Tx end frame generation
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxEndFrm <=#Tp 1'b0;
  else
  if(Flop & TxEndFrm | TxAbort | TxRetry_q)
    TxEndFrm <=#Tp 1'b0;        
  else
  if(Flop & LastWord)
    begin
      case (TxValidBytesLatched)
        1 : TxEndFrm <=#Tp TxByteCnt == 2'h0;
        2 : TxEndFrm <=#Tp TxByteCnt == 2'h1;
        3 : TxEndFrm <=#Tp TxByteCnt == 2'h2;
        0 : TxEndFrm <=#Tp TxByteCnt == 2'h3;
        default : TxEndFrm <=#Tp 1'b0;
      endcase
    end
end


// Tx data selection (latching)
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxData <=#Tp 8'h0;
  else
  if(GotData & ~TxStartFrm & ~TxUsedData)
    TxData <=#Tp TxDataLatched_wb[7:0];
  else
  if(TxUsedData & Flop)
    begin
      case(TxByteCnt)
        0 : TxData <=#Tp TxDataLatched[7:0];
        1 : TxData <=#Tp TxDataLatched[15:8];
        2 : TxData <=#Tp TxDataLatched[23:16];
        3 : TxData <=#Tp TxDataLatched[31:24];
      endcase
    end
end


// Latching tx data
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxDataLatched[31:0] <=#Tp 32'h0;
  else
  if(GotData & ~TxUsedData & ~TxStartFrm)
    TxDataLatched[31:0] <=#Tp TxDataLatched_wb[31:0];
  else
  if(TxUsedData & Flop & TxByteCnt == 2'h3)
    TxDataLatched[31:0] <=#Tp TxDataLatched_wb[31:0];
end


// Generation of the DataNotAvaliable signal which is used for the generation of the TxUnderRun signal
assign ResetDataNotAvaliable = DMACycleFinishedTx_q | WB_RST_I;
assign SetDataNotAvaliable = GotData & ~TxUsedData & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3;

always @ (posedge MTxClk or posedge ResetDataNotAvaliable)
begin
  if(ResetDataNotAvaliable)
    DataNotAvaliable <=#Tp 1'b0;
  else
  if(SetDataNotAvaliable) // data is latched here
    DataNotAvaliable <=#Tp 1'b1;
end


// Tx under run
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxUnderRun <=#Tp 1'b0;
  else
  if(TxAbort & ~TxAbort_q)
    TxUnderRun <=#Tp 1'b0;
  else
  if(TxUsedData & Flop & TxByteCnt == 2'h3 & ~LastWord & DataNotAvaliable)
    TxUnderRun <=#Tp 1'b1;
end



// Tx Byte counter
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxByteCnt <=#Tp 2'h0;
  else
  if(TxAbort_q | TxRetry_q)
    TxByteCnt <=#Tp 2'h0;
  else
  if(TxStartFrm & ~TxUsedData)
    TxByteCnt <=#Tp 2'h1;
  else
  if(TxUsedData & Flop)
    TxByteCnt <=#Tp TxByteCnt + 1;
end


// Generation of the GetNewTxData signal
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    GetNewTxData <=#Tp 1'b0;
  else
  if(GetNewTxData)
    GetNewTxData <=#Tp 1'b0;
  else
  if(TxBDReady & GotData & ~(TxStartFrm | TxUsedData))
     GetNewTxData <=#Tp 1'b1;
  else
  if(TxUsedData & ~TxEndFrm_wbLatched & TxByteCnt == 2'h3)
    GetNewTxData <=#Tp ~LastWord;
end


// TxRetryLatched
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxRetryLatched <=#Tp 1'b0;
  else
  if(TxStartFrm)
    TxRetryLatched <=#Tp 1'b0;
  else
  if(TxRetry)
    TxRetryLatched <=#Tp 1'b1;
end    



// Synchronizing request for a new tx data

//ne eth_sync_clk1_clk2 syn3 (.clk1(MTxClk),     .clk2(WB_CLK_I),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
//                         .set2(SetGotData), .sync_out(GotDataSync3));

// This section still needs to be changed due to ASIC demands
assign ResetSyncGetNewTxData_wb = SyncGetNewTxData_wb3 | TxAbort_wb | TxRetry_wb | WB_RST_I;
assign SetSyncGetNewTxData_wb = GetNewTxData;


// Sync. stage 1
always @ (posedge SetSyncGetNewTxData_wb or posedge ResetSyncGetNewTxData_wb)
begin
  if(ResetSyncGetNewTxData_wb)
    SyncGetNewTxData_wb1 <=#Tp 1'b0;
  else
    SyncGetNewTxData_wb1 <=#Tp 1'b1;
end


// Sync. stage 2
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    SyncGetNewTxData_wb2 <=#Tp 1'b0;
  else
  if(SyncGetNewTxData_wb1 & ~GetNewTxData_wb & ~TxAbort_wb & ~TxRetry_wb)
    SyncGetNewTxData_wb2 <=#Tp 1'b1;
  else
    SyncGetNewTxData_wb2 <=#Tp 1'b0;
end


// Sync. stage 3
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    SyncGetNewTxData_wb3 <=#Tp 1'b0;
  else
  if(SyncGetNewTxData_wb2 & ~GetNewTxData_wb & ~TxAbort_wb & ~TxRetry_wb)
    SyncGetNewTxData_wb3 <=#Tp 1'b1;
  else
    SyncGetNewTxData_wb3 <=#Tp 1'b0;
end


// Synchronized request for a new tx data
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    GetNewTxData_wb <=#Tp 1'b0;
  else
  if(GetNewTxData_wb)
    GetNewTxData_wb <=#Tp 1'b0;
  else
  if(SyncGetNewTxData_wb3 & ~GetNewTxData_wb & ~TxAbort_wb & ~TxRetry_wb)
    GetNewTxData_wb <=#Tp 1'b1;
end


// Synchronizine transmit done signal
// Sinchronizing and evaluating tx data
eth_sync_clk1_clk2 syn4 (.clk1(WB_CLK_I),     .clk2(MTxClk),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(TxDone),       .sync_out(TxDoneSync3)
                        );


// Syncronized signal TxDone_wb (sync. to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxDone_wb <=#Tp 1'b0;
  else
  if(TxStartFrm_wb | WillSendControlFrame)
    TxDone_wb <=#Tp 1'b0;
  else
  if(TxDoneSync3 & ~TxStartFrmRequest)
    TxDone_wb <=#Tp 1'b1;
end


assign ResetTxCtrlEndFrm_wb = TxCtrlEndFrm_wb | WB_RST_I;
assign SetTxCtrlEndFrm_wb = TxCtrlEndFrm;


// Sync stage 1
always @ (posedge SetTxCtrlEndFrm_wb or posedge ResetTxCtrlEndFrm_wb)
begin
  if(ResetTxCtrlEndFrm_wb)
    TxCtrlEndFrm_wbSync1 <=#Tp 1'b0;
  else
    TxCtrlEndFrm_wbSync1 <=#Tp 1'b1;
end


// Sync stage 2
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxCtrlEndFrm_wbSync2 <=#Tp 1'b0;
  else
  if(TxCtrlEndFrm_wbSync1 & ~TxCtrlEndFrm_wb)
    TxCtrlEndFrm_wbSync2 <=#Tp 1'b1;
  else
    TxCtrlEndFrm_wbSync2 <=#Tp 1'b0;
end


// Synchronized Tx  control end frame
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxCtrlEndFrm_wb <=#Tp 1'b0;
  else
  if(TxCtrlEndFrm_wbSync2 & ~TxCtrlEndFrm_wb)
    TxCtrlEndFrm_wb <=#Tp 1'b1;
  else
  if(StartTxStatusWrite)
    TxCtrlEndFrm_wb <=#Tp 1'b0;
end


// Synchronizing TxRetry signal
eth_sync_clk1_clk2 syn6 (.clk1(WB_CLK_I),       .clk2(MTxClk),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(TxRetryLatched), .sync_out(TxRetrySync3));


// Synchronized signal TxRetry_wb (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxRetry_wb <=#Tp 1'b0;
  else
  if(TxStartFrm_wb | WillSendControlFrame)
    TxRetry_wb <=#Tp 1'b0;
  else
  if(TxRetrySync3)
    TxRetry_wb <=#Tp 1'b1;
end


// Synchronizing TxAbort signal
eth_sync_clk1_clk2 syn7 (.clk1(WB_CLK_I), .clk2(MTxClk),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(TxAbort),  .sync_out(TxAbortSync3));


// Synchronized TxAbort_wb signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxAbort_wb <=#Tp 1'b0;
  else
  if(TxStartFrm_wb)
    TxAbort_wb <=#Tp 1'b0;
  else
  if(TxAbortSync3 & ~TxStartFrmRequest)
    TxAbort_wb <=#Tp 1'b1;
end


// Reading of the next receive buffer descriptor starts after reception status is
// written to the previous one.
assign StartRxBDRead = RxEn & RxStatusWriteOccured;
assign ResetRxBDRead = RxBDRead & RxBDReady;          // Rx BD is read until READY bit is set.


// Latching READY status of the Rx buffer descriptor
always @ (negedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxBDReady <=#Tp 1'b0;
  else
  if(RxEn & RxBDRead)
    RxBDReady <=#Tp BDDataOut[15];
  else
  if(RxStatusWrite)
    RxBDReady <=#Tp 1'b0;
end


// Reading the Rx buffer descriptor
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxBDRead <=#Tp 1'b1;
  else
  if(StartRxBDRead)
    RxBDRead <=#Tp 1'b1;
  else
  if(ResetRxBDRead)
    RxBDRead <=#Tp 1'b0;
end


// Reception status is written back to the buffer descriptor after the end of frame is detected.
//assign StartRxStatusWrite = RxEn & RxEndFrm_wb;
assign StartRxStatusWrite = RxEn & RxEndFrm_wb;


// Writing status back to the Rx buffer descriptor
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxStatusWrite <=#Tp 1'b0;
  else
  if(StartRxStatusWrite)
    RxStatusWrite <=#Tp 1'b1;
  else
    RxStatusWrite <=#Tp 1'b0;
end


// Forcing next descriptor on DMA channel 1 (Rx)
assign WB_ND_O[1] = RxStatusWrite; 


// Latched status that a status write occured.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxStatusWriteOccured <=#Tp 1'b0;
  else
  if(StartRxStatusWrite)
    RxStatusWriteOccured <=#Tp 1'b1;
  else
  if(StartRxBDRead)
    RxStatusWriteOccured <=#Tp 1'b0;
end



// Generation of the synchronized signal ShiftEnded that indicates end of reception
eth_sync_clk1_clk2 syn8 (.clk1(MRxClk),       .clk2(WB_CLK_I),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(RxEndFrm_wb),  .sync_out(ShiftEnded)
                        );


// Indicating that last byte is being reveived
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    LastByteIn <=#Tp 1'b0;
  else
  if(ShiftWillEnd & (&RxByteCnt))
    LastByteIn <=#Tp 1'b0;
  else
  if(RxValid & RxBDReady & RxEndFrm & ~(&RxByteCnt))
    LastByteIn <=#Tp 1'b1;
end


// Indicating that data reception will end
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ShiftWillEnd <=#Tp 1'b0;
  else
  if(ShiftEnded)
    ShiftWillEnd <=#Tp 1'b0;
  else
  if(LastByteIn & (&RxByteCnt) | RxValid & RxEndFrm & (&RxByteCnt))
    ShiftWillEnd <=#Tp 1'b1;
end


// Receive byte counter
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxByteCnt <=#Tp 2'h0;
  else
  if(ShiftEnded)
    RxByteCnt <=#Tp 2'h0;
  else
  if(RxValid & RxBDReady | LastByteIn)
    RxByteCnt <=#Tp RxByteCnt + 1;
end


// Indicates how many bytes are valid within the last word
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxValidBytes <=#Tp 2'h1;
  else
  if(ShiftEnded)
    RxValidBytes <=#Tp 2'h1;
  else
  if(RxValid & ~LastByteIn & ~RxStartFrm)
    RxValidBytes <=#Tp RxValidBytes + 1;
end


// There is a maximum 3 MRxClk delay between RxDataLatched2 and RxData_wb. In the meantime data
// is stored to the RxDataLatched1. 
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxDataLatched1       <=#Tp 16'h0;
  else
  if(RxValid & RxBDReady & ~LastByteIn & RxByteCnt == 2'h0)
    RxDataLatched1[7:0]  <=#Tp RxData;
  else
  if(RxValid & RxBDReady & ~LastByteIn & RxByteCnt == 2'h1)
    RxDataLatched1[15:8] <=#Tp RxData;
end


// Latching incoming data to buffer
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxDataLatched2        <=#Tp 32'h0;
  else
  if(RxValid & RxBDReady & ~LastByteIn & RxByteCnt == 2'h2)
    RxDataLatched2[23:0]  <=#Tp {RxData,RxDataLatched1};
  else
  if(RxValid & RxBDReady & ~LastByteIn & RxByteCnt == 2'h3)
    RxDataLatched2[31:24] <=#Tp RxData;
end


// Indicating start of the reception process
always @ (posedge MRxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    StartShifting <=#Tp 1'b0;
  else
  if((RxValid & RxBDReady & ~RxStartFrm & (&RxByteCnt)) | (ShiftWillEnd &  LastByteIn & (&RxByteCnt)))
    StartShifting <=#Tp 1'b1;
  else
    StartShifting <=#Tp 1'b0;
end


// Synchronizing Rx start frame to the WISHBONE clock
assign StartRxStartFrmSync1 = RxStartFrm & RxBDReady;

eth_sync_clk1_clk2 syn9 (.clk1(WB_CLK_I),     .clk2(MRxClk),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(SetGotData), .sync_out(RxStartFrmSync3)
                        );


// Generating synchronized Rx start frame
always @ ( posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxStartFrm_wb <=#Tp 1'b0;
  else
  if(RxStartFrmSync3 & ~RxStartFrm_wb)
    RxStartFrm_wb <=#Tp 1'b1;
  else
    RxStartFrm_wb <=#Tp 1'b0;
end


//Synchronizing signal for latching data that will be written to the WISHBONE
//eth_sync_clk1_clk2 syn10 (.clk1(WB_CLK_I),     .clk2(MRxClk),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
//                         .set2(StartShifting), .sync_out(LatchNow_wb)
//                        );

// This section still needs to be changed due to ASIC demands
assign ResetShifting_wb = LatchNow_wb | WB_RST_I;
assign StartShifting_wb = StartShifting;


// Sync. stage 1
always @ (posedge StartShifting_wb or posedge ResetShifting_wb)
begin
  if(ResetShifting_wb)
    Shifting_wb_Sync1 <=#Tp 1'b0;
  else
    Shifting_wb_Sync1 <=#Tp 1'b1;
end


// Sync. stage 2
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    Shifting_wb_Sync2 <=#Tp 1'b0;
  else
  if(Shifting_wb_Sync1 & ~RxDataValid_wb)
    Shifting_wb_Sync2 <=#Tp 1'b1;
  else
    Shifting_wb_Sync2 <=#Tp 1'b0;
end


// Generating synchronized signal that will latch data for writing to the WISHBONE
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    LatchNow_wb <=#Tp 1'b0;
  else
  if(Shifting_wb_Sync2 & ~RxDataValid_wb)
    LatchNow_wb <=#Tp 1'b1;
  else
    LatchNow_wb <=#Tp 1'b0;
end                                             


// Indicating that valid data is avaliable
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxDataValid_wb <=#Tp 1'b0;
  else
  if(LatchNow_wb & ~RxDataValid_wb)
    RxDataValid_wb <=#Tp 1'b1;
  else
  if(RxDataValid_wb)
    RxDataValid_wb <=#Tp 1'b0;
end


// Forcing next descriptor in the DMA (Channel 1 is used for rx)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    WB_REQ_O_RX <=#Tp 1'b0;
  else
  if(LatchNow_wb & ~RxDataValid_wb & r_DmaEn)
    WB_REQ_O_RX <=#Tp 1'b1;
  else
  if(DMACycleFinishedRx)
    WB_REQ_O_RX <=#Tp 1'b0;
end


assign WB_REQ_O[1] = WB_REQ_O_RX;
assign DMACycleFinishedRx = WB_REQ_O[1] & WB_ACK_I[1];


// WbWriteError is generated when the previous word is not written to the wishbone on time
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    WbWriteError <=#Tp 1'b0;
  else
  if(LatchNow_wb & ~RxDataValid_wb)
    begin
      if(WB_REQ_O[1] & ~WB_ACK_I[1])
        WbWriteError <=#Tp 1'b1;
    end
  else
  if(RxStartFrm_wb)
    WbWriteError <=#Tp 1'b0;
end


// Assembling data that will be written to the WISHBONE
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxData_wb <=#Tp 32'h0;
  else
  if(LatchNow_wb & ~RxDataValid_wb & ~ShiftWillEnd)
    RxData_wb <=#Tp RxDataLatched2;
  else
  if(LatchNow_wb & ~RxDataValid_wb & ShiftWillEnd)
    case(RxValidBytes)
      0 : RxData_wb <=#Tp {RxDataLatched2[31:16],       RxDataLatched1[15:0]};
      1 : RxData_wb <=#Tp {24'h0,                       RxDataLatched1[7:0]};
      2 : RxData_wb <=#Tp {16'h0,                       RxDataLatched1[15:0]};
      3 : RxData_wb <=#Tp {8'h0, RxDataLatched2[23:16], RxDataLatched1[15:0]};
    endcase
end


// Selecting the data for the WISHBONE
assign WB_DAT_O[31:0] = BDRead? WB_BDDataOut : RxData_wb;


// Generation of the end-of-frame signal
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxEndFrm_wb <=#Tp 1'b0;
  else
  if(LatchNow_wb & ~RxDataValid_wb & ShiftWillEnd)
    RxEndFrm_wb <=#Tp 1'b1;
  else
  if(StartRxStatusWrite)
    RxEndFrm_wb <=#Tp 1'b0;
end


// Interrupts
assign TxB_IRQ = 1'b0;
assign TxE_IRQ = 1'b0;
assign RxB_IRQ = 1'b0;
assign RxF_IRQ = 1'b0;
assign Busy_IRQ = 1'b0;


endmodule

