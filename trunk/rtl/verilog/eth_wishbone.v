// Napravi, pause frame

// Poskusi spremeniti vse signale na wb strani da bodo imeli enake koncnice (npr _wb),
// vsi na MTxClk strani pa _txclk   
// Evaluiraj dato da pre start framom ni prisel abort ali kaj podobnega (kot je bilo v GotData, ki ga zbrisi)

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_wishbone.v                                              ////
////                                                              ////
////  This file is part of the Ethernet IP core project           ////
////  http://www.opencores.org/projects/ethmac/                   ////
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
// Revision 1.1  2002/01/23 10:47:59  mohor
// Initial version. Equals to eth_wishbonedma.v at this moment.
//
//
//
//


`include "eth_defines.v"
`include "timescale.v"


module eth_wishbone
   (

    // WISHBONE common
    WB_CLK_I, WB_RST_I, WB_DAT_I, WB_DAT_O, 

    // WISHBONE slave
 		WB_ADR_I, WB_SEL_I, WB_WE_I, WB_ACK_O, 
 		WB_REQ_O, WB_ACK_I, WB_ND_O, WB_RD_O, BDCs, 

    // WISHBONE master
    m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
    m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
    m_wb_stb_o, m_wb_ack_i, m_wb_err_i, 

    //TX
    MTxClk, TxStartFrm, TxEndFrm, TxUsedData, TxData, StatusIzTxEthMACModula, 
    TxRetry, TxAbort, TxUnderRun, TxDone, TPauseRq, TxPauseTV, PerPacketCrcEn, 
    PerPacketPad, 

    //RX
    MRxClk, RxData, RxValid, RxStartFrm, RxEndFrm, 
    
    // Register
    r_TxEn, r_RxEn, r_TxBDNum, r_DmaEn, TX_BD_NUM_Wr, 

    WillSendControlFrame, TxCtrlEndFrm, // igor !!! WillSendControlFrame gre najbrz ven
    
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

// WISHBONE master
output  [31:0]  m_wb_adr_o;     // 
output   [3:0]  m_wb_sel_o;     // 
output          m_wb_we_o;      // 
output  [31:0]  m_wb_dat_o;     // 
output          m_wb_cyc_o;     // 
output          m_wb_stb_o;     // 
input   [31:0]  m_wb_dat_i;     // 
input           m_wb_ack_i;     // 
input           m_wb_err_i;     // 




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
input   [7:0]   r_TxBDNum;      // Receive buffer descriptor number
input           r_DmaEn;        // DMA enable
input           TX_BD_NUM_Wr;   // RxBDNumber written

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

reg             RxStartFrm_wb;
reg     [31:0]  RxData_wb;
reg             RxDataValid_wb;
reg             RxEndFrm_wb;

reg     [7:0]   BDAddress;    // BD address for access from MAC side
reg             BDRead_q;

reg             TxBDRead;
wire            TxStatusWrite;

reg     [1:0]   TxValidBytesLatched;

reg    [15:0]   TxLength;
reg    [15:0]   TxStatus;

reg    [15:0]   RxStatus;

reg             TxStartFrm_wb;
reg             TxRetry_wb;
reg             TxAbort_wb;
reg             TxDone_wb;

reg             RxStatusWriteOccured;

reg             TxDone_wb_q;
reg             TxAbort_wb_q;
reg             TxRetry_wb_q;
reg             RxBDReady;
reg             TxBDReady;

reg             RxBDRead;
reg             RxStatusWrite;
reg             WbWriteError;

reg    [31:0]   TxDataLatched;
reg     [1:0]   TxByteCnt;
reg             LastWord;
reg             ReadTxDataFromFifo_tck;

reg             Div2;
reg             Flop;

reg             BlockingTxStatusWrite;
reg             BlockingTxBDRead;


reg     [7:0]   TxBDAddress;
reg     [7:0]   RxBDAddress;

reg             GotDataSync1;
reg             GotDataSync2;
wire             GotDataSync3;

reg             GotData;
reg             TxRetrySync1;
reg             TxAbortSync1;
reg             TxDoneSync1;

reg             TxAbort_q;
reg             TxRetry_q;
reg             TxUsedData_q;
reg             TxCtrlEndFrm_q;

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

wire            DWord;                      // Only 32-bit accesses are valid
wire            BDWrite;                    // BD Write Enable for access from WISHBONE side
wire            BDRead;                     // BD Read access from WISHBONE side
wire   [31:0]   RxBDDataIn;                 // Rx BD data in
wire   [31:0]   TxBDDataIn;                 // Tx BD data in
wire   [31:0]   BDDataOut;                  // BD data out

reg             TxEndFrm_wb;

wire            TxRetryPulse;
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
wire            ResetTxDoneSync;
wire            ResetTxRetrySync;
wire            ResetTxAbortSync;

wire            SetTxAbortSync;
wire            ResetShiftEnded;
wire            ResetRxStartFrmSync1;
wire            StartShiftEnded;
wire            StartRxStartFrmSync1;

reg             temp_ack;

`ifdef ETH_REGISTERED_OUTPUTS
reg             temp_ack2;
reg [31:0]      registered_ram_do;
`endif

reg WbEn, WbEn_q;
reg RxEn, RxEn_q;
reg TxEn, TxEn_q;

wire ram_ce;
wire ram_we;
wire ram_oe;
reg [7:0]   ram_addr;
reg [31:0]  ram_di;
wire [31:0] ram_do;

wire StartTxPointerRead;
wire ResetTxPointerRead;
reg  TxPointerRead;
reg TxEn_needed;

//assign BDWrite = BDCs &  WB_WE_I & WbEn & ~WbEn_q;
assign BDWrite = BDCs &  WB_WE_I & WbEn & WbEn_q;
assign BDRead  = BDCs & ~WB_WE_I & WbEn_q;              // Read cycle is longer for one cycle


  always @ (posedge WB_CLK_I or posedge WB_RST_I)
  begin
    if(WB_RST_I)
      begin
        temp_ack <=#Tp 1'b0;
        `ifdef ETH_REGISTERED_OUTPUTS
        temp_ack2 <=#Tp 1'b0;
        registered_ram_do <=#Tp 32'h0;
        `endif
      end
    else
      begin
        temp_ack <=#Tp BDWrite | BDRead & ~WbEn;
        `ifdef ETH_REGISTERED_OUTPUTS
        temp_ack2 <=#Tp temp_ack;
        registered_ram_do <=#Tp ram_do;
        `endif
      end
  end

`ifdef ETH_REGISTERED_OUTPUTS
  assign WB_ACK_O = temp_ack2;
  assign WB_DAT_O = registered_ram_do;
`else
  assign WB_ACK_O = temp_ack;
  assign WB_DAT_O = ram_do;
`endif




// Generic synchronous two-port RAM interface
/*
generic_tpram     #(8, 32)  i_generic_tpram 
(
  .clk_a(WB_CLK_I),   .rst_a(WB_RST_I),         .ce_a(1'b1),        .we_a(BDWrite), 
  .oe_a(EnableRAM),   .addr_a(WB_ADR_I[9:2]),   .di_a(WB_DAT_I),    .do_a(WB_BDDataOut),
  
  .clk_b(WB_CLK_I),   .rst_b(WB_RST_I),         .ce_b(EnableRAM),   .we_b(BDStatusWrite), 
  .oe_b(EnableRAM),   .addr_b(BDAddress[7:0]),  .di_b(BDDataIn),    .do_b(BDDataOut)
);
*/



RAMB4_S16 ram1 (.DO(ram_do[15:0]),  .ADDR(ram_addr), .DI(ram_di[15:0]),  .EN(ram_ce), 
                .CLK(WB_CLK_I),     .WE(ram_we),     .RST(WB_RST_I));
RAMB4_S16 ram2 (.DO(ram_do[31:16]), .ADDR(ram_addr), .DI(ram_di[31:16]), .EN(ram_ce), 
                .CLK(WB_CLK_I),     .WE(ram_we),     .RST(WB_RST_I));



/*
generic_spram #(8, 32) ram (
	// Generic synchronous single-port RAM interface
	.clk(WB_CLK_I), .rst(WB_RST_I), .ce(ram_ce), .we(ram_we), .oe(ram_oe), .addr(ram_addr), .di(ram_di), .do(ram_do)
);
*/
assign ram_ce = 1'b1;
assign ram_we = BDWrite | TxStatusWrite;    // tu manjka se write kad se vpisuje RxBD status
assign ram_oe = BDRead | TxEn & TxEn_q & TxBDRead;     // Tu manjka se read kadar se bere RxBD

reg [3:0] xxx_debug;

//assign TxEn_needed = ~TxBDReady | TxPointerRead;

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxEn_needed <=#Tp 1'b0;
  else
  if(~TxBDReady & WbEn)
    TxEn_needed <=#Tp 1'b1;
  else
  if(TxPointerRead & TxEn & TxEn_q)
    TxEn_needed <=#Tp 1'b0;
end





// Enabling access to the RAM for three devices.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      WbEn <=#Tp 1'b1;
      RxEn <=#Tp 1'b0;
      TxEn <=#Tp 1'b0;
      ram_addr <=#Tp 8'h0;
      ram_di <=#Tp 32'h0;
      xxx_debug <=#Tp 0;      // igor !!! zbrisi xxx_debug, debug, ...
    end
  else
    begin
      // Switching between three stages depends on enable signals
//      casex ({WbEn_q, RxEn_q, TxEn_q, r_RxEn, r_TxEn, TxEn_needed})  // synopsys parallel_case
      casex ({WbEn_q, RxEn_q, TxEn_q, r_RxEn, r_TxEn & TxEn_needed})  // synopsys parallel_case
        5'b100_1x :
          begin
            WbEn <=#Tp 1'b0;
            RxEn <=#Tp 1'b1;  // wb access stage and r_RxEn is enabled
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp RxBDAddress;
            ram_di <=#Tp RxBDDataIn;
      xxx_debug <=#Tp 1;
          end
        5'b100_01 :
          begin
            WbEn <=#Tp 1'b0;
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b1;  // wb access stage, r_RxEn is disabled but r_TxEn is enabled
            ram_addr <=#Tp TxBDAddress + TxPointerRead;
            ram_di <=#Tp TxBDDataIn;
      xxx_debug <=#Tp 2;
          end
        5'b010_x0 :
          begin
            WbEn <=#Tp 1'b1;  // RxEn access stage and r_TxEn is disabled
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
      xxx_debug <=#Tp 3;
          end
        5'b010_x1 :
          begin
            WbEn <=#Tp 1'b0;
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b1;  // RxEn access stage and r_TxEn is enabled
            ram_addr <=#Tp TxBDAddress + TxPointerRead;
            ram_di <=#Tp TxBDDataIn;
      xxx_debug <=#Tp 4;
          end
        5'b001_xx :
          begin
            WbEn <=#Tp 1'b1;  // TxEn access stage (we always go to wb access stage)
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
      xxx_debug <=#Tp 5;
          end
        5'b100_00 :
          begin
            WbEn <=#Tp 1'b0;  // WbEn access stage and there is no need for other stages. WbEn needs to be switched off for a bit
      xxx_debug <=#Tp 6;
          end
        5'b000_00 :
          begin
            WbEn <=#Tp 1'b1;  // Idle state. We go to WbEn access stage.
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
      xxx_debug <=#Tp 7;
          end
        default :
          begin
            WbEn <=#Tp 1'b1;  // We go to wb access stage
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
      xxx_debug <=#Tp 8;
          end
      endcase
    end
end


// Delayed stage signals
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      WbEn_q <=#Tp 1'b0;
      RxEn_q <=#Tp 1'b0;
      TxEn_q <=#Tp 1'b0;
    end
  else
    begin
      WbEn_q <=#Tp WbEn;
      RxEn_q <=#Tp RxEn;
      TxEn_q <=#Tp TxEn;
    end
end

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

wire ResetTxBDReady;
assign ResetTxBDReady = TxDonePulse | TxAbortPulse | TxRetryPulse;

// Latching READY status of the Tx buffer descriptor
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxBDReady <=#Tp 1'b0;
  else
  if(TxEn & TxEn_q & TxBDRead & ~TxPointerRead)
    TxBDReady <=#Tp ram_do[15]; // TxBDReady is sampled only once at the beginning
  else
  if(ResetTxBDReady)
    TxBDReady <=#Tp 1'b0;
end


// Reading the Tx buffer descriptor
assign StartTxBDRead = (TxRetry_wb | TxStatusWrite) & ~BlockingTxBDRead;

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxBDRead <=#Tp 1'b1;
  else
  if(StartTxBDRead)
    TxBDRead <=#Tp 1'b1;
  else
  if(TxBDReady)
    TxBDRead <=#Tp 1'b0;
end


// Reading Tx BD pointer
assign StartTxPointerRead = TxBDRead & TxBDReady;

// Reading Tx BD Pointer
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxPointerRead <=#Tp 1'b0;
  else
  if(StartTxPointerRead)
    TxPointerRead <=#Tp 1'b1;
  else
  if(TxEn_q)
    TxPointerRead <=#Tp 1'b0;
end


// Writing status back to the Tx buffer descriptor
assign TxStatusWrite = (TxDone_wb | TxAbort_wb) & TxEn & TxEn_q & ~BlockingTxStatusWrite;



// Status writing must occur only once. Meanwhile it is blocked.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    BlockingTxStatusWrite <=#Tp 1'b0;
  else
  if(TxStatusWrite)
    BlockingTxStatusWrite <=#Tp 1'b1;
  else
  if(~TxDone_wb & ~TxAbort_wb)
    BlockingTxStatusWrite <=#Tp 1'b0;
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
  if(TxStartFrm_wb)
    BlockingTxBDRead <=#Tp 1'b0;
end


// Latching status from the tx buffer descriptor
// Data is avaliable one cycle after the access is started (at that time signal TxEn is not active)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStatus <=#Tp 15'h0;
  else
  if(TxEn & TxEn_q & TxBDRead & ~TxPointerRead)
    TxStatus <=#Tp ram_do[15:0];
end

reg ReadDataFromTxBuffer;
wire WriteDataToRxBuffer = 0; // igor !!! Popravi to, da bo pravilno

reg MasterWbTX;
reg MasterWbRX;

reg [31:0] m_wb_dat_o;
reg [31:0] m_wb_adr_o;
reg        m_wb_cyc_o;
reg        m_wb_stb_o;
reg        m_wb_we_o;
wire [31:0] rx_fifo_data_out = 0; // Spremeni to, da bo pravilno
wire TxLengthEq0;
wire TxLengthLt4;


//Latching length from the buffer descriptor;
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxLength <=#Tp 16'h0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    TxLength <=#Tp ram_do[31:16];
  else
  if(MasterWbTX & m_wb_ack_i)
    begin
      if(TxLengthLt4)
        TxLength <=#Tp 16'h0;
      else
        TxLength <=#Tp TxLength - 3'h4;    // Length is subtracted at the data request
    end
end

assign TxLengthEq0 = TxLength == 0;
assign TxLengthLt4 = TxLength < 4;


reg BlockingIncrementTxPointer;

reg [31:0] TxPointer;
reg [31:0] RxPointer;

//Latching Tx buffer pointer from buffer descriptor;
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxPointer <=#Tp 0;
  else
  if(TxEn & TxEn_q & TxPointerRead)
    TxPointer <=#Tp ram_do;
  else
  if(MasterWbTX & ~BlockingIncrementTxPointer)
    TxPointer <=#Tp TxPointer + 4;    // Pointer increment
end

wire MasterAccessFinished;


//Latching Tx buffer pointer from buffer descriptor;
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    BlockingIncrementTxPointer <=#Tp 0;
  else
  if(MasterAccessFinished)
    BlockingIncrementTxPointer <=#Tp 0;
  else
  if(MasterWbTX)
    BlockingIncrementTxPointer <=#Tp 1'b1;
end

wire RxPointerRead = 0; // igor !!! spremeni to da bo pravilno
//Latching Rx buffer pointer from buffer descriptor;
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    RxPointer <=#Tp 15'h0;
  else
  if(RxEn & RxEn_q & RxPointerRead)
    RxPointer <=#Tp ram_do;
end

wire TxBufferAlmostFull;
wire TxBufferFull;
wire TxBufferEmpty;
wire TxBufferAlmostEmpty;
wire ResetReadDataFromTxBuffer;
wire SetReadDataFromTxBuffer;

reg BlockReadDataFromTxBuffer;

//assign ResetReadDataFromTxBuffer = (TxLength < 4) | TxAbortPulse | TxRetryPulse;
assign ResetReadDataFromTxBuffer = (TxLengthEq0) | TxAbortPulse | TxRetryPulse;
assign SetReadDataFromTxBuffer = TxEn & TxEn_q & TxPointerRead;

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadDataFromTxBuffer <=#Tp 1'b0;
  else
  if(ResetReadDataFromTxBuffer)
    ReadDataFromTxBuffer <=#Tp 1'b0;
  else
  if(SetReadDataFromTxBuffer)
    ReadDataFromTxBuffer <=#Tp 1'b1;
end

wire ReadDataFromTxBuffer_2 = ReadDataFromTxBuffer & ~BlockReadDataFromTxBuffer;
wire [31:0] TxData_wb;
wire ReadTxDataFromFifo_wb;

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    BlockReadDataFromTxBuffer <=#Tp 1'b0;
  else
  if(ReadTxDataFromFifo_wb)
    BlockReadDataFromTxBuffer <=#Tp 1'b0;
  else
//  if((TxBufferAlmostFull | TxLengthLt4)& MasterWbTX)
  if((TxBufferAlmostFull | TxLength <= 4)& MasterWbTX)
    BlockReadDataFromTxBuffer <=#Tp 1'b1;
end



assign MasterAccessFinished = m_wb_ack_i | m_wb_err_i;

assign m_wb_sel_o = 4'hf;


 reg [3:0]debug;


// Enabling master wishbone access to the memory for two devices TX and RX.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      MasterWbTX <=#Tp 1'b0;
      MasterWbRX <=#Tp 1'b0;
      m_wb_dat_o <=#Tp 32'h0;
      m_wb_adr_o <=#Tp 32'h0;
      m_wb_cyc_o <=#Tp 1'b0;
      m_wb_stb_o <=#Tp 1'b0;
      m_wb_we_o  <=#Tp 1'b0;
      debug <=#Tp 0;
    end
  else
    begin
      // Switching between two stages depends on enable signals
      casex ({MasterWbTX, MasterWbRX, ReadDataFromTxBuffer_2, WriteDataToRxBuffer, MasterAccessFinished})  // synopsys parallel_case full_case
        5'b00_x1_x :
          begin
            MasterWbTX <=#Tp 1'b0;  // idle and master write is needed (data write to rx buffer)
            MasterWbRX <=#Tp 1'b1;
            m_wb_dat_o <=#Tp rx_fifo_data_out;
            m_wb_adr_o <=#Tp RxPointer;
            m_wb_cyc_o <=#Tp 1'b1;
            m_wb_stb_o <=#Tp 1'b1;
            m_wb_we_o  <=#Tp 1'b1;
            debug <=#Tp 1;
          end
        5'b00_10_x :
          begin
            $display("\n\tHere we go again");
            MasterWbTX <=#Tp 1'b1;  // idle and master read is needed (data read from tx buffer)
            MasterWbRX <=#Tp 1'b0;
            m_wb_adr_o <=#Tp TxPointer;
            m_wb_cyc_o <=#Tp 1'b1;
            m_wb_stb_o <=#Tp 1'b1;
            m_wb_we_o  <=#Tp 1'b0;
            debug <=#Tp 2;
          end
        5'b10_10_1 :
          begin
            $display("\n\tHere we go again");
            MasterWbTX <=#Tp 1'b1;  // master read and master read is needed (data read from tx buffer)
            MasterWbRX <=#Tp 1'b0;
            m_wb_adr_o <=#Tp TxPointer;
            m_wb_cyc_o <=#Tp 1'b1;
            m_wb_stb_o <=#Tp 1'b1;
            m_wb_we_o  <=#Tp 1'b0;
            debug <=#Tp 6;
          end
        5'b01_01_1 :
          begin
            MasterWbTX <=#Tp 1'b0;  // master write and master write is needed (data write to rx buffer)
            MasterWbRX <=#Tp 1'b1;
            m_wb_dat_o <=#Tp rx_fifo_data_out;
            m_wb_adr_o <=#Tp RxPointer;
            m_wb_we_o  <=#Tp 1'b1;
            debug <=#Tp 7;
          end
        5'b10_x1_1 :
          begin
            MasterWbTX <=#Tp 1'b0;  // master read and master write is needed (data write to rx buffer)
            MasterWbRX <=#Tp 1'b1;
            m_wb_dat_o <=#Tp rx_fifo_data_out;
            m_wb_adr_o <=#Tp RxPointer;
            m_wb_we_o  <=#Tp 1'b1;
            debug <=#Tp 3;
          end
        5'b01_1x_1 :
          begin
            MasterWbTX <=#Tp 1'b1;  // master write and master read is needed (data read from tx buffer)
            MasterWbRX <=#Tp 1'b0;
            m_wb_adr_o <=#Tp TxPointer;
            m_wb_we_o  <=#Tp 1'b0;
            debug <=#Tp 4;
          end
        5'bxx_00_1 :
          begin
            MasterWbTX <=#Tp 1'b0;  // whatever and no master read or write is needed (ack or err comes finishing previous access)
            MasterWbRX <=#Tp 1'b0;
            m_wb_cyc_o <=#Tp 1'b0;
            m_wb_stb_o <=#Tp 1'b0;
            debug <=#Tp 8;
          end
      endcase
    end
end

wire TxFifoClear;
assign TxFifoClear = (TxAbort_wb | TxRetry_wb) & ~TxBDReady;
eth_fifo tx_fifo (.data_in(m_wb_dat_i),   .data_out(TxData_wb),            .clk(WB_CLK_I), 
                  .reset(WB_RST_I),       .write(MasterWbTX & m_wb_ack_i), .read(ReadTxDataFromFifo_wb),
                  .clear(TxFifoClear),    .full(TxBufferFull),             .almost_full(TxBufferAlmostFull),
                  .almost_empty(TxBufferAlmostEmpty),                      .empty(TxBufferEmpty));





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


reg StartOccured;
reg TxStartFrm_sync1;
reg TxStartFrm_sync2;
reg TxStartFrm_syncb1;
reg TxStartFrm_syncb2;



// Start: Generation of the TxStartFrm_wb which is then synchronized to the MTxClk
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm_wb <=#Tp 1'b0;
  else
  if(TxBDReady & ~StartOccured & (TxBufferFull | TxLengthEq0))
    TxStartFrm_wb <=#Tp 1'b1;
  else
  if(TxStartFrm_syncb2)
    TxStartFrm_wb <=#Tp 1'b0;
end

// StartOccured: TxStartFrm_wb occurs only ones at the beginning. Then it's blocked.
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    StartOccured <=#Tp 1'b0;
  else
  if(TxStartFrm_wb)
    StartOccured <=#Tp 1'b1;
  else
  if(ResetTxBDReady)
    StartOccured <=#Tp 1'b0;
end

// Synchronizing TxStartFrm_wb to MTxClk
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm_sync1 <=#Tp 1'b0;
  else
    TxStartFrm_sync1 <=#Tp TxStartFrm_wb;
end

always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm_sync2 <=#Tp 1'b0;
  else
    TxStartFrm_sync2 <=#Tp TxStartFrm_sync1;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm_syncb1 <=#Tp 1'b0;
  else
    TxStartFrm_syncb1 <=#Tp TxStartFrm_sync2;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm_syncb2 <=#Tp 1'b0;
  else
    TxStartFrm_syncb2 <=#Tp TxStartFrm_syncb1;
end

always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxStartFrm <=#Tp 1'b0;
  else
  if(TxStartFrm_sync2)
    TxStartFrm <=#Tp 1'b1;      // igor !!! Dodaj se pogoj, da ni vmes prisel kaksen abort ali kaj podobnega
  else
  if(TxUsedData_q)
    TxStartFrm <=#Tp 1'b0;
end
// End: Generation of the TxStartFrm_wb which is then synchronized to the MTxClk

















// TxEndFrm_wb: indicator of the end of frame
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxEndFrm_wb <=#Tp 1'b0;
  else
  if(TxLengthLt4 & TxBufferAlmostEmpty & TxUsedData)
    TxEndFrm_wb <=#Tp 1'b1;
  else
  if(TxRetryPulse | TxDonePulse | TxAbortPulse)
    TxEndFrm_wb <=#Tp 1'b0;
end


// Marks which bytes are valid within the word.
assign TxValidBytes = TxLengthLt4 ? TxLength[1:0] : 2'b0;

reg LatchValidBytes;
reg LatchValidBytes_q;

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    LatchValidBytes <=#Tp 1'b0;
  else
  if(TxLengthLt4 & TxBDReady)
    LatchValidBytes <=#Tp 1'b1;
  else
    LatchValidBytes <=#Tp 1'b0;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    LatchValidBytes_q <=#Tp 1'b0;
  else
    LatchValidBytes_q <=#Tp LatchValidBytes;
end


// Latching valid bytes
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxValidBytesLatched <=#Tp 2'h0;
  else
  if(LatchValidBytes & ~LatchValidBytes_q)
    TxValidBytesLatched <=#Tp TxValidBytes;
  else
  if(TxRetryPulse | TxDonePulse | TxAbortPulse)
    TxValidBytesLatched <=#Tp 2'h0;
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
assign TempTxBDAddress[7:0] = {8{ TxStatusWrite     & ~WrapTxStatusBit}} & (TxBDAddress + 2'h2) ; // Tx BD increment or wrap (last BD)
assign TempRxBDAddress[7:0] = {8{ WrapRxStatusBit}} & (r_TxBDNum)       | // Using first Rx BD
                              {8{~WrapRxStatusBit}} & (RxBDAddress + 2'h2) ; // Using next Rx BD (incremenrement address)


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
  if(TX_BD_NUM_Wr)                        // When r_TxBDNum is updated, RxBDAddress is also
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
//assign BDDataIn  = TxStatusWrite ? {TxStatus[31:9], 9'h0} 
//                                 : {RxLength, NewRxStatus};
assign RxBDDataIn = {RxLength, NewRxStatus};  // tu dopolni, da se bo vpisoval status
//assign TxBDDataIn = {16'h0, TxStatus[15:9], 9'h0};   // tu dopolni, da se bo vpisoval status
//assign TxBDDataIn = {32'hdead00ef};   // tu dopolni, da se bo vpisoval status
assign TxBDDataIn = {32'h004380ef};   // tu dopolni, da se bo vpisoval status


// Generating delayed signals
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      TxRetry_wb_q          <=#Tp 1'b0;
      BDRead_q              <=#Tp 1'b0;
    end
  else
    begin
      TxRetry_wb_q          <=#Tp TxRetry_wb;
      BDRead_q              <=#Tp BDRead;
    end                 
end                      


// Signals used for various purposes
assign TxRetryPulse   = TxRetry_wb   & ~TxRetry_wb_q;
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
  if(TxRetryPulse)
    WB_RD_O <=#Tp 1'b1;
  else
  if(WB_RD_O)
    WB_RD_O <=#Tp 1'b0;
end


// assign ClearTxBDReady = ~TxUsedData & TxUsedData_q;

assign TPauseRq = 0; // igor !!! v koncni fazi mora tu biti pause request
assign TxPauseTV[15:0] = TxLength[15:0]; // igor !!! v koncni fazi mora tu biti pause request

// reg  WillSendControlFrameSync1;
// reg  WillSendControlFrameSync2;
// reg  WillSendControlFrameSync3;
// wire WillSendControlFrame_wb;


// always @ (posedge WB_CLK_I or posedge WB_RST_I)
// begin
//   if(WB_RST_I)
//     WillSendControlFrameSync1 <=#Tp 1'b0;
//   else
//     WillSendControlFrameSync1 <=#Tp WillSendControlFrame;
// end
// 
// always @ (posedge WB_CLK_I or posedge WB_RST_I)
// begin
//   if(WB_RST_I)
//     WillSendControlFrameSync2 <=#Tp 1'b0;
//   else
//     WillSendControlFrameSync2 <=#Tp WillSendControlFrameSync1;
// end
// 
// always @ (posedge WB_CLK_I or posedge WB_RST_I)
// begin
//   if(WB_RST_I)
//     WillSendControlFrameSync3 <=#Tp 1'b0;
//   else
//     WillSendControlFrameSync3 <=#Tp WillSendControlFrameSync2;
// end
// 
// assign WillSendControlFrame_wb = WillSendControlFrameSync2 & ~WillSendControlFrameSync3;








// Generating delayed signals
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      TxAbort_q      <=#Tp 1'b0;
      TxRetry_q      <=#Tp 1'b0;
      TxUsedData_q   <=#Tp 1'b0;
      TxCtrlEndFrm_q <=#Tp 1'b0;
    end
  else
    begin
      TxAbort_q      <=#Tp TxAbort;
      TxRetry_q      <=#Tp TxRetry;
      TxUsedData_q   <=#Tp TxUsedData;
      TxCtrlEndFrm_q <=#Tp TxCtrlEndFrm;
    end
end

// Generating delayed signals
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    begin
      TxDone_wb_q   <=#Tp 1'b0;
      TxAbort_wb_q  <=#Tp 1'b0;
    end
  else
    begin
      TxDone_wb_q   <=#Tp TxDone_wb;
      TxAbort_wb_q  <=#Tp TxAbort_wb;
    end
end


// Sinchronizing and evaluating tx data
//assign SetGotData = (TxStartFrm_wb | NewTxDataAvaliable_wb & ~TxAbort_wb & ~TxRetry_wb) & ~WB_CLK_I;
assign SetGotData = (TxStartFrm_wb); // igor namesto zgornje

eth_sync_clk1_clk2 syn2 (.clk1(MTxClk),     .clk2(WB_CLK_I),            .reset1(WB_RST_I),    .reset2(WB_RST_I), 
                         .set2(SetGotData), .sync_out(GotDataSync3));


// Evaluating data. If abort or retry occured meanwhile than data is ignored.
assign GotDataEvaluate = GotDataSync3 & ~GotData & (~TxRetry & ~TxAbort | (TxRetry | TxAbort) & (TxStartFrm));


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


// // Tx start frame generation
// always @ (posedge MTxClk or posedge WB_RST_I)
// begin
//   if(WB_RST_I)
//     TxStartFrm <=#Tp 1'b0;
//   else
//   if(TxUsedData_q | TxAbort & ~TxAbort_q | TxRetry & ~TxRetry_q)
//     TxStartFrm <=#Tp 1'b0;
//   else
//   if(TxBDReady & GotData & TxStartFrmRequest)
//     TxStartFrm <=#Tp 1'b1;
// end
// 

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
//    LastWord <=#Tp TxEndFrm_wbLatched;
    LastWord <=#Tp TxEndFrm_wb;
end


// Tx end frame generation
always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxEndFrm <=#Tp 1'b0;
  else
  if(Flop & TxEndFrm | TxAbort | TxRetry_q)     // igor !!! zakaj je tu TxRetry_q ?
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
  if(TxStartFrm_sync2 & ~TxStartFrm)
    TxData <=#Tp TxData_wb[7:0];
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
  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3)
    TxDataLatched[31:0] <=#Tp TxData_wb[31:0];
end


// Tx under run
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxUnderRun <=#Tp 1'b0;
  else
  if(TxAbortPulse)
    TxUnderRun <=#Tp 1'b0;
  else
  if(TxBufferEmpty & ReadTxDataFromFifo_wb)
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


// Start: Generation of the ReadTxDataFromFifo_tck signal and synchronization to the WB_CLK_I
reg ReadTxDataFromFifo_sync1;
reg ReadTxDataFromFifo_sync2;
reg ReadTxDataFromFifo_sync3;
reg ReadTxDataFromFifo_syncb1;
reg ReadTxDataFromFifo_syncb2;


always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadTxDataFromFifo_tck <=#Tp 1'b0;
  else
  if(ReadTxDataFromFifo_syncb2)
    ReadTxDataFromFifo_tck <=#Tp 1'b0;
  else
//  if(TxUsedData & ~TxEndFrm_wbLatched & TxByteCnt == 2'h3)
//    ReadTxDataFromFifo_tck <=#Tp ~LastWord;
//  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3)
  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3 & ~LastWord)
     ReadTxDataFromFifo_tck <=#Tp 1'b1;
end

// Synchronizing TxStartFrm_wb to MTxClk
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadTxDataFromFifo_sync1 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_sync1 <=#Tp ReadTxDataFromFifo_tck;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadTxDataFromFifo_sync2 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_sync2 <=#Tp ReadTxDataFromFifo_sync1;
end

always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadTxDataFromFifo_syncb1 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_syncb1 <=#Tp ReadTxDataFromFifo_sync2;
end

always @ (posedge MTxClk or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadTxDataFromFifo_syncb2 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_syncb2 <=#Tp ReadTxDataFromFifo_syncb1;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    ReadTxDataFromFifo_sync3 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_sync3 <=#Tp ReadTxDataFromFifo_sync2;
end

assign ReadTxDataFromFifo_wb = ReadTxDataFromFifo_sync2 & ~ReadTxDataFromFifo_sync3;
// End: Generation of the ReadTxDataFromFifo_tck signal and synchronization to the WB_CLK_I


// Synchronizing TxRetry signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxRetrySync1 <=#Tp 1'b0;
  else
    TxRetrySync1 <=#Tp TxRetry;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxRetry_wb <=#Tp 1'b0;
  else
    TxRetry_wb <=#Tp TxRetrySync1;
end


// Synchronized TxDone_wb signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxDoneSync1 <=#Tp 1'b0;
  else
    TxDoneSync1 <=#Tp TxDone;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxDone_wb <=#Tp 1'b0;
  else
    TxDone_wb <=#Tp TxDoneSync1;
end

// Synchronizing TxAbort signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxAbortSync1 <=#Tp 1'b0;
  else
    TxAbortSync1 <=#Tp TxAbort;
end

always @ (posedge WB_CLK_I or posedge WB_RST_I)
begin
  if(WB_RST_I)
    TxAbort_wb <=#Tp 1'b0;
  else
    TxAbort_wb <=#Tp TxAbortSync1;
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
//assign WB_DAT_O[31:0] = BDRead? WB_BDDataOut : RxData_wb;


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

