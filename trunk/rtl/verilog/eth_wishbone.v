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
// Revision 1.5  2002/02/08 16:21:54  mohor
// Rx status is written back to the BD.
//
// Revision 1.4  2002/02/06 14:10:21  mohor
// non-DMA host interface added. Select the right configutation in eth_defines.
//
// Revision 1.3  2002/02/05 16:44:39  mohor
// Both rx and tx part are finished. Tested with wb_clk_i between 10 and 200
// MHz. Statuses, overrun, control frame transmission and reception still  need
// to be fixed.
//
// Revision 1.2  2002/02/01 12:46:51  mohor
// Tx part finished. TxStatus needs to be fixed. Pause request needs to be
// added.
//
// Revision 1.1  2002/01/23 10:47:59  mohor
// Initial version. Equals to eth_wishbonedma.v at this moment.
//
//
//
//

// igor !!!
// Napravi, pause frame

// Poskusi spremeniti vse signale na wb strani da bodo imeli enake koncnice (npr _wb),
// vsi na MTxClk strani pa _txclk   
// Evaluiraj dato da pre start framom ni prisel abort ali kaj podobnega (kot je bilo v GotData, ki ga zbrisi)

// Naj m_wb_err_i vzge status underrun ali uverrun

`include "eth_defines.v"
`include "timescale.v"


module eth_wishbone
   (

    // WISHBONE common
    WB_CLK_I, WB_DAT_I, WB_DAT_O, 

    // WISHBONE slave
 		WB_ADR_I, WB_SEL_I, WB_WE_I, WB_ACK_O, 
    BDCs, 

    Reset, 

    // WISHBONE master
    m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
    m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
    m_wb_stb_o, m_wb_ack_i, m_wb_err_i, 

    //TX
    MTxClk, TxStartFrm, TxEndFrm, TxUsedData, TxData, StatusIzTxEthMACModula, 
    TxRetry, TxAbort, TxUnderRun, TxDone, TPauseRq, TxPauseTV, PerPacketCrcEn, 
    PerPacketPad, 

    //RX
    MRxClk, RxData, RxValid, RxStartFrm, RxEndFrm, RxAbort, 
    
    // Register
    r_TxEn, r_RxEn, r_TxBDNum, r_DmaEn, TX_BD_NUM_Wr, r_RecSmall, 

    WillSendControlFrame, TxCtrlEndFrm, // igor !!! WillSendControlFrame gre najbrz ven
    
    // Interrupts
    TxB_IRQ, TxE_IRQ, RxB_IRQ, RxF_IRQ, Busy_IRQ,
    
    InvalidSymbol, LatchedCrcError, RxLateCollision, ShortFrame, DribbleNibble,
    ReceivedPacketTooBig, RxLength, LoadRxStatus

		);


parameter Tp = 1;

// WISHBONE common
input           WB_CLK_I;       // WISHBONE clock
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

input           Reset;       // Reset signal

// Status signals
input           InvalidSymbol;    // Invalid symbol was received during reception in 100 Mbps mode
input           LatchedCrcError;  // CRC error
input           RxLateCollision;  // Late collision occured while receiving frame
input           ShortFrame;       // Frame shorter then the minimum size (r_MinFL) was received while small packets are enabled (r_RecSmall)
input           DribbleNibble;    // Extra nibble received
input           ReceivedPacketTooBig;// Received packet is bigger than r_MaxFL
input    [15:0] RxLength;         // Length of the incoming frame
input           LoadRxStatus;     // Rx status was loaded

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
input           RxAbort;        // This signal is set when address doesn't match.

//Register
input           r_TxEn;         // Transmit enable
input           r_RxEn;         // Receive enable
input   [7:0]   r_TxBDNum;      // Receive buffer descriptor number
input           r_DmaEn;        // DMA enable
input           TX_BD_NUM_Wr;   // RxBDNumber written
input           r_RecSmall;     // Receive small frames igor !!! tega uporabi

// Interrupts
output TxB_IRQ;
output TxE_IRQ;
output RxB_IRQ;
output RxF_IRQ;
output Busy_IRQ;

reg             TxStartFrm;
reg             TxEndFrm;
reg     [7:0]   TxData;

reg             TxUnderRun;

reg             TxBDRead;
wire            TxStatusWrite;

reg     [1:0]   TxValidBytesLatched;

reg    [15:0]   TxLength;
reg    [15:0]   TxStatus;

reg   [14:13]   RxStatusOld;

reg             TxStartFrm_wb;
reg             TxRetry_wb;
reg             TxAbort_wb;
reg             TxDone_wb;

reg             TxDone_wb_q;
reg             TxAbort_wb_q;
reg             TxRetry_wb_q;
reg             RxBDReady;
reg             TxBDReady;

reg             RxBDRead;
wire            RxStatusWrite;

reg    [31:0]   TxDataLatched;
reg     [1:0]   TxByteCnt;
reg             LastWord;
reg             ReadTxDataFromFifo_tck;

reg             BlockingTxStatusWrite;
reg             BlockingTxBDRead;

reg             Flop;

reg     [7:0]   TxBDAddress;
reg     [7:0]   RxBDAddress;

reg             TxRetrySync1;
reg             TxAbortSync1;
reg             TxDoneSync1;

reg             TxAbort_q;
reg             TxRetry_q;
reg             TxUsedData_q;

reg    [31:0]   RxDataLatched2;
reg    [23:0]   RxDataLatched1;
reg     [1:0]   RxValidBytes;
reg     [1:0]   RxByteCnt;
reg             LastByteIn;
reg             ShiftWillEnd;

reg             WriteRxDataToFifo;
reg    [15:0]   LatchedRxLength;

reg             ShiftEnded;

reg             BDWrite;                    // BD Write Enable for access from WISHBONE side
reg             BDRead;                     // BD Read access from WISHBONE side
wire   [31:0]   RxBDDataIn;                 // Rx BD data in
wire   [31:0]   TxBDDataIn;                 // Tx BD data in

reg             TxEndFrm_wb;

wire            TxRetryPulse;
wire            TxDonePulse;
wire            TxAbortPulse;

wire            StartRxBDRead;
wire            StartRxStatusWrite;

wire            StartTxBDRead;

wire            TxIRQEn;
wire            WrapTxStatusBit;

wire            WrapRxStatusBit;

wire    [1:0]   TxValidBytes;

wire    [7:0]   TempTxBDAddress;
wire    [7:0]   TempRxBDAddress;

wire            SetGotData;
wire            GotDataEvaluate;

reg             temp_ack;

wire    [5:0]   RxStatusIn;
reg     [5:0]   RxStatusInLatched;

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
reg RxEn_needed;

wire StartRxPointerRead;
reg RxPointerRead; 


always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      temp_ack <=#Tp 1'b0;
      `ifdef ETH_REGISTERED_OUTPUTS
      temp_ack2 <=#Tp 1'b0;
      registered_ram_do <=#Tp 32'h0;
      `endif
    end
  else
    begin
      temp_ack <=#Tp BDWrite & WbEn & WbEn_q | BDRead & WbEn & ~WbEn_q;
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


// Generic synchronous single-port RAM interface
generic_spram #(8, 32) ram (
	// Generic synchronous single-port RAM interface
	.clk(WB_CLK_I), .rst(Reset), .ce(ram_ce), .we(ram_we), .oe(ram_oe), .addr(ram_addr), .di(ram_di), .do(ram_do)
);

assign ram_ce = 1'b1;
assign ram_we = BDWrite & WbEn & WbEn_q | TxStatusWrite | RxStatusWrite;
assign ram_oe = BDRead & WbEn & WbEn_q | TxEn & TxEn_q & (TxBDRead | TxPointerRead) | RxEn & RxEn_q & (RxBDRead | RxPointerRead);     // Tu manjka se read kadar se bere RxBD


always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxEn_needed <=#Tp 1'b0;
  else
  if(~TxBDReady & r_TxEn & WbEn & ~WbEn_q)
    TxEn_needed <=#Tp 1'b1;
  else
  if(TxPointerRead & TxEn & TxEn_q)
    TxEn_needed <=#Tp 1'b0;
end


// Enabling access to the RAM for three devices.
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      WbEn <=#Tp 1'b1;
      RxEn <=#Tp 1'b0;
      TxEn <=#Tp 1'b0;
      ram_addr <=#Tp 8'h0;
      ram_di <=#Tp 32'h0;
    end
  else
    begin
      // Switching between three stages depends on enable signals
      casex ({WbEn_q, RxEn_q, TxEn_q, RxEn_needed, TxEn_needed})  // synopsys parallel_case
        5'b100_1x :
          begin
            WbEn <=#Tp 1'b0;
            RxEn <=#Tp 1'b1;  // wb access stage and r_RxEn is enabled
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp RxBDAddress + RxPointerRead;
            ram_di <=#Tp RxBDDataIn;
          end
        5'b100_01 :
          begin
            WbEn <=#Tp 1'b0;
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b1;  // wb access stage, r_RxEn is disabled but r_TxEn is enabled
            ram_addr <=#Tp TxBDAddress + TxPointerRead;
            ram_di <=#Tp TxBDDataIn;
          end
        5'b010_x0 :
          begin
            WbEn <=#Tp 1'b1;  // RxEn access stage and r_TxEn is disabled
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
            BDWrite <=#Tp BDCs & WB_WE_I;
            BDRead <=#Tp BDCs & ~WB_WE_I;
          end
        5'b010_x1 :
          begin
            WbEn <=#Tp 1'b0;
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b1;  // RxEn access stage and r_TxEn is enabled
            ram_addr <=#Tp TxBDAddress + TxPointerRead;
            ram_di <=#Tp TxBDDataIn;
          end
        5'b001_xx :
          begin
            WbEn <=#Tp 1'b1;  // TxEn access stage (we always go to wb access stage)
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
            BDWrite <=#Tp BDCs & WB_WE_I;
            BDRead <=#Tp BDCs & ~WB_WE_I;
          end
        5'b100_00 :
          begin
            WbEn <=#Tp 1'b0;  // WbEn access stage and there is no need for other stages. WbEn needs to be switched off for a bit
          end
        5'b000_00 :
          begin
            WbEn <=#Tp 1'b1;  // Idle state. We go to WbEn access stage.
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
            BDWrite <=#Tp BDCs & WB_WE_I;
            BDRead <=#Tp BDCs & ~WB_WE_I;
          end
        default :
          begin
            WbEn <=#Tp 1'b1;  // We go to wb access stage
            RxEn <=#Tp 1'b0;
            TxEn <=#Tp 1'b0;
            ram_addr <=#Tp WB_ADR_I[9:2];
            ram_di <=#Tp WB_DAT_I;
            BDWrite <=#Tp BDCs & WB_WE_I;
            BDRead <=#Tp BDCs & ~WB_WE_I;
          end
      endcase
    end
end


// Delayed stage signals
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxBDReady <=#Tp 1'b0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    TxBDReady <=#Tp ram_do[15] & (ram_do[31:16] > 4); // TxBDReady is sampled only once at the beginning.
  else                                                // Only packets larger then 4 bytes are transmitted.
  if(ResetTxBDReady)
    TxBDReady <=#Tp 1'b0;
end


// Reading the Tx buffer descriptor
assign StartTxBDRead = (TxRetry_wb | TxStatusWrite) & ~BlockingTxBDRead;

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockingTxStatusWrite <=#Tp 1'b0;
  else
  if(TxStatusWrite)
    BlockingTxStatusWrite <=#Tp 1'b1;
  else
  if(~TxDone_wb & ~TxAbort_wb)
    BlockingTxStatusWrite <=#Tp 1'b0;
end


// TxBDRead state is activated only once. 
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStatus <=#Tp 15'h0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    TxStatus <=#Tp ram_do[15:0];
end

reg ReadTxDataFromMemory;
wire WriteRxDataToMemory;

reg MasterWbTX;
reg MasterWbRX;

reg [31:0] m_wb_adr_o;
reg        m_wb_cyc_o;
reg        m_wb_stb_o;
reg        m_wb_we_o;

wire TxLengthEq0;
wire TxLengthLt4;


//Latching length from the buffer descriptor;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockingIncrementTxPointer <=#Tp 0;
  else
  if(MasterAccessFinished)
    BlockingIncrementTxPointer <=#Tp 0;
  else
  if(MasterWbTX)
    BlockingIncrementTxPointer <=#Tp 1'b1;
end


wire TxBufferAlmostFull;
wire TxBufferFull;
wire TxBufferEmpty;
wire TxBufferAlmostEmpty;
wire ResetReadTxDataFromMemory;
wire SetReadTxDataFromMemory;

reg BlockReadTxDataFromMemory;

assign ResetReadTxDataFromMemory = (TxLengthEq0) | TxAbortPulse | TxRetryPulse;
assign SetReadTxDataFromMemory = TxEn & TxEn_q & TxPointerRead;

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromMemory <=#Tp 1'b0;
  else
  if(ResetReadTxDataFromMemory)
    ReadTxDataFromMemory <=#Tp 1'b0;
  else
  if(SetReadTxDataFromMemory)
    ReadTxDataFromMemory <=#Tp 1'b1;
end

wire ReadTxDataFromMemory_2 = ReadTxDataFromMemory & ~BlockReadTxDataFromMemory;
wire [31:0] TxData_wb;
wire ReadTxDataFromFifo_wb;

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockReadTxDataFromMemory <=#Tp 1'b0;
  else
  if(ReadTxDataFromFifo_wb)
    BlockReadTxDataFromMemory <=#Tp 1'b0;
  else
  if((TxBufferAlmostFull | TxLength <= 4)& MasterWbTX)
    BlockReadTxDataFromMemory <=#Tp 1'b1;
end



assign MasterAccessFinished = m_wb_ack_i | m_wb_err_i;

assign m_wb_sel_o = 4'hf;


// Enabling master wishbone access to the memory for two devices TX and RX.
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      MasterWbTX <=#Tp 1'b0;
      MasterWbRX <=#Tp 1'b0;
      m_wb_adr_o <=#Tp 32'h0;
      m_wb_cyc_o <=#Tp 1'b0;
      m_wb_stb_o <=#Tp 1'b0;
      m_wb_we_o  <=#Tp 1'b0;
    end
  else
    begin
      // Switching between two stages depends on enable signals
      casex ({MasterWbTX, MasterWbRX, ReadTxDataFromMemory_2, WriteRxDataToMemory, MasterAccessFinished})  // synopsys parallel_case full_case
        5'b00_x1_x :
          begin
            MasterWbTX <=#Tp 1'b0;  // idle and master write is needed (data write to rx buffer)
            MasterWbRX <=#Tp 1'b1;
            m_wb_adr_o <=#Tp RxPointer;
            m_wb_cyc_o <=#Tp 1'b1;
            m_wb_stb_o <=#Tp 1'b1;
            m_wb_we_o  <=#Tp 1'b1;
          end
        5'b00_10_x :
          begin
            MasterWbTX <=#Tp 1'b1;  // idle and master read is needed (data read from tx buffer)
            MasterWbRX <=#Tp 1'b0;
            m_wb_adr_o <=#Tp TxPointer;
            m_wb_cyc_o <=#Tp 1'b1;
            m_wb_stb_o <=#Tp 1'b1;
            m_wb_we_o  <=#Tp 1'b0;
          end
        5'b10_10_1 :
          begin
            MasterWbTX <=#Tp 1'b1;  // master read and master read is needed (data read from tx buffer)
            MasterWbRX <=#Tp 1'b0;
            m_wb_adr_o <=#Tp TxPointer;
            m_wb_cyc_o <=#Tp 1'b1;
            m_wb_stb_o <=#Tp 1'b1;
            m_wb_we_o  <=#Tp 1'b0;
          end
        5'b01_01_1 :
          begin
            MasterWbTX <=#Tp 1'b0;  // master write and master write is needed (data write to rx buffer)
            MasterWbRX <=#Tp 1'b1;
            m_wb_adr_o <=#Tp RxPointer;
            m_wb_we_o  <=#Tp 1'b1;
          end
        5'b10_x1_1 :
          begin
            MasterWbTX <=#Tp 1'b0;  // master read and master write is needed (data write to rx buffer)
            MasterWbRX <=#Tp 1'b1;
            m_wb_adr_o <=#Tp RxPointer;
            m_wb_we_o  <=#Tp 1'b1;
          end
        5'b01_1x_1 :
          begin
            MasterWbTX <=#Tp 1'b1;  // master write and master read is needed (data read from tx buffer)
            MasterWbRX <=#Tp 1'b0;
            m_wb_adr_o <=#Tp TxPointer;
            m_wb_we_o  <=#Tp 1'b0;
          end
        5'bxx_00_1 :
          begin
            MasterWbTX <=#Tp 1'b0;  // whatever and no master read or write is needed (ack or err comes finishing previous access)
            MasterWbRX <=#Tp 1'b0;
            m_wb_cyc_o <=#Tp 1'b0;
            m_wb_stb_o <=#Tp 1'b0;
          end
      endcase
    end
end

wire TxFifoClear;
assign TxFifoClear = (TxAbort_wb | TxRetry_wb) & ~TxBDReady;

eth_fifo #(`TX_FIFO_DATA_WIDTH, `TX_FIFO_DEPTH, `TX_FIFO_CNT_WIDTH)
tx_fifo (.data_in(m_wb_dat_i),               .data_out(TxData_wb),            .clk(WB_CLK_I), 
         .reset(Reset),                   .write(MasterWbTX & m_wb_ack_i), .read(ReadTxDataFromFifo_wb),
         .clear(TxFifoClear),                .full(TxBufferFull),             .almost_full(TxBufferAlmostFull),
         .almost_empty(TxBufferAlmostEmpty), .empty(TxBufferEmpty));


reg StartOccured;
reg TxStartFrm_sync1;
reg TxStartFrm_sync2;
reg TxStartFrm_syncb1;
reg TxStartFrm_syncb2;



// Start: Generation of the TxStartFrm_wb which is then synchronized to the MTxClk
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStartFrm_wb <=#Tp 1'b0;
  else
  if(TxBDReady & ~StartOccured & (TxBufferFull | TxLengthEq0))
    TxStartFrm_wb <=#Tp 1'b1;
  else
  if(TxStartFrm_syncb2)
    TxStartFrm_wb <=#Tp 1'b0;
end

// StartOccured: TxStartFrm_wb occurs only ones at the beginning. Then it's blocked.
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    StartOccured <=#Tp 1'b0;
  else
  if(TxStartFrm_wb)
    StartOccured <=#Tp 1'b1;
  else
  if(ResetTxBDReady)
    StartOccured <=#Tp 1'b0;
end

// Synchronizing TxStartFrm_wb to MTxClk
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxStartFrm_sync1 <=#Tp 1'b0;
  else
    TxStartFrm_sync1 <=#Tp TxStartFrm_wb;
end

always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxStartFrm_sync2 <=#Tp 1'b0;
  else
    TxStartFrm_sync2 <=#Tp TxStartFrm_sync1;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStartFrm_syncb1 <=#Tp 1'b0;
  else
    TxStartFrm_syncb1 <=#Tp TxStartFrm_sync2;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStartFrm_syncb2 <=#Tp 1'b0;
  else
    TxStartFrm_syncb2 <=#Tp TxStartFrm_syncb1;
end

always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
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
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    LatchValidBytes <=#Tp 1'b0;
  else
  if(TxLengthLt4 & TxBDReady)
    LatchValidBytes <=#Tp 1'b1;
  else
    LatchValidBytes <=#Tp 1'b0;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    LatchValidBytes_q <=#Tp 1'b0;
  else
    LatchValidBytes_q <=#Tp LatchValidBytes;
end


// Latching valid bytes
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
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
//assign TxPauseRq      = TxStatus[9];      // already used     Ta gre ven, ker bo stvar izvedena preko registrov



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

assign WrapRxStatusBit = RxStatusOld[13];


// Temporary Tx and Rx buffer descriptor address 
assign TempTxBDAddress[7:0] = {8{ TxStatusWrite     & ~WrapTxStatusBit}} & (TxBDAddress + 2'h2) ; // Tx BD increment or wrap (last BD)
assign TempRxBDAddress[7:0] = {8{ WrapRxStatusBit}} & (r_TxBDNum)       | // Using first Rx BD
                              {8{~WrapRxStatusBit}} & (RxBDAddress + 2'h2) ; // Using next Rx BD (incremenrement address)


// Latching Tx buffer descriptor address
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxBDAddress <=#Tp 8'h0;
  else
  if(TxStatusWrite)
    TxBDAddress <=#Tp TempTxBDAddress;
end


// Latching Rx buffer descriptor address
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxBDAddress <=#Tp 8'h0;
  else
  if(TX_BD_NUM_Wr)                        // When r_TxBDNum is updated, RxBDAddress is also igor !!! ta del bi se lahko popravil
    RxBDAddress <=#Tp WB_DAT_I[7:0];
  else
  if(RxStatusWrite)
    RxBDAddress <=#Tp TempRxBDAddress;
end

assign RxBDDataIn = {LatchedRxLength, 1'b0, RxStatusOld, 7'h0, RxStatusInLatched};  // tu dopolni, da se bo vpisoval status
assign TxBDDataIn = {32'h004380ef};   // tu dopolni, da se bo vpisoval status


// Signals used for various purposes
assign TxRetryPulse   = TxRetry_wb   & ~TxRetry_wb_q;
assign TxDonePulse    = TxDone_wb    & ~TxDone_wb_q;
assign TxAbortPulse   = TxAbort_wb   & ~TxAbort_wb_q;


// assign ClearTxBDReady = ~TxUsedData & TxUsedData_q;

assign TPauseRq = 0; // igor !!! v koncni fazi mora tu biti pause request
assign TxPauseTV[15:0] = TxLength[15:0]; // igor !!! v koncni fazi mora tu biti pause request


// Generating delayed signals
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    begin
      TxAbort_q      <=#Tp 1'b0;
      TxRetry_q      <=#Tp 1'b0;
      TxUsedData_q   <=#Tp 1'b0;
    end
  else
    begin
      TxAbort_q      <=#Tp TxAbort;
      TxRetry_q      <=#Tp TxRetry;
      TxUsedData_q   <=#Tp TxUsedData;
    end
end

// Generating delayed signals
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      TxDone_wb_q   <=#Tp 1'b0;
      TxAbort_wb_q  <=#Tp 1'b0;
      TxRetry_wb_q  <=#Tp 1'b0;
    end
  else
    begin
      TxDone_wb_q   <=#Tp TxDone_wb;
      TxAbort_wb_q  <=#Tp TxAbort_wb;
      TxRetry_wb_q  <=#Tp TxRetry_wb;
    end
end


// Sinchronizing and evaluating tx data
//assign SetGotData = (TxStartFrm_wb | NewTxDataAvaliable_wb & ~TxAbort_wb & ~TxRetry_wb) & ~WB_CLK_I;
assign SetGotData = (TxStartFrm_wb); // igor namesto zgornje

// Evaluating data. If abort or retry occured meanwhile than data is ignored.
//assign GotDataEvaluate = GotDataSync3 & ~GotData & (~TxRetry & ~TxAbort | (TxRetry | TxAbort) & (TxStartFrm));
assign GotDataEvaluate = (~TxRetry & ~TxAbort | (TxRetry | TxAbort) & (TxStartFrm));


// Indication of the last word
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    LastWord <=#Tp 1'b0;
  else
  if((TxEndFrm | TxAbort | TxRetry) & Flop)
    LastWord <=#Tp 1'b0;
  else
  if(TxUsedData & Flop & TxByteCnt == 2'h3)
    LastWord <=#Tp TxEndFrm_wb;
end


// Tx end frame generation
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
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
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
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
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxDataLatched[31:0] <=#Tp 32'h0;
  else
  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3)
    TxDataLatched[31:0] <=#Tp TxData_wb[31:0];
end


// Tx under run
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxUnderRun <=#Tp 1'b0;
  else
  if(TxAbortPulse)
    TxUnderRun <=#Tp 1'b0;
  else
  if(TxBufferEmpty & ReadTxDataFromFifo_wb)
    TxUnderRun <=#Tp 1'b1;
end



// Tx Byte counter
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
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


always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_tck <=#Tp 1'b0;
  else
  if(ReadTxDataFromFifo_syncb2)
    ReadTxDataFromFifo_tck <=#Tp 1'b0;
  else
  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3 & ~LastWord)
     ReadTxDataFromFifo_tck <=#Tp 1'b1;
end

// Synchronizing TxStartFrm_wb to MTxClk
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_sync1 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_sync1 <=#Tp ReadTxDataFromFifo_tck;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_sync2 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_sync2 <=#Tp ReadTxDataFromFifo_sync1;
end

always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_syncb1 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_syncb1 <=#Tp ReadTxDataFromFifo_sync2;
end

always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_syncb2 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_syncb2 <=#Tp ReadTxDataFromFifo_syncb1;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_sync3 <=#Tp 1'b0;
  else
    ReadTxDataFromFifo_sync3 <=#Tp ReadTxDataFromFifo_sync2;
end

assign ReadTxDataFromFifo_wb = ReadTxDataFromFifo_sync2 & ~ReadTxDataFromFifo_sync3;
// End: Generation of the ReadTxDataFromFifo_tck signal and synchronization to the WB_CLK_I


// Synchronizing TxRetry signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetrySync1 <=#Tp 1'b0;
  else
    TxRetrySync1 <=#Tp TxRetry;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetry_wb <=#Tp 1'b0;
  else
    TxRetry_wb <=#Tp TxRetrySync1;
end


// Synchronized TxDone_wb signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDoneSync1 <=#Tp 1'b0;
  else
    TxDoneSync1 <=#Tp TxDone;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDone_wb <=#Tp 1'b0;
  else
    TxDone_wb <=#Tp TxDoneSync1;
end

// Synchronizing TxAbort signal (synchronized to WISHBONE clock)
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbortSync1 <=#Tp 1'b0;
  else
    TxAbortSync1 <=#Tp TxAbort;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbort_wb <=#Tp 1'b0;
  else
    TxAbort_wb <=#Tp TxAbortSync1;
end


assign StartRxBDRead = RxStatusWrite | RxAbort;

// Reading the Rx buffer descriptor
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxBDRead <=#Tp 1'b1;
  else
  if(StartRxBDRead)
    RxBDRead <=#Tp 1'b1;
  else
  if(RxBDReady)
    RxBDRead <=#Tp 1'b0;
end


// Reading of the next receive buffer descriptor starts after reception status is
// written to the previous one.

// Latching READY status of the Rx buffer descriptor
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxBDReady <=#Tp 1'b0;
  else
  if(RxEn & RxEn_q & RxBDRead)
    RxBDReady <=#Tp ram_do[15]; // RxBDReady is sampled only once at the beginning
  else
  if(ShiftEnded | RxAbort)   // igor !!! tx del ima tu ResetTxBDReady
    RxBDReady <=#Tp 1'b0;
end

// Latching Rx buffer descriptor status
// Data is avaliable one cycle after the access is started (at that time signal RxEn is not active)
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxStatusOld <=#Tp 2'h0;
  else
  if(RxEn & RxEn_q & RxBDRead)
    RxStatusOld <=#Tp ram_do[14:13];
end




// Reading Rx BD pointer


assign StartRxPointerRead = RxBDRead & RxBDReady;

// Reading Tx BD Pointer
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxPointerRead <=#Tp 1'b0;
  else
  if(StartRxPointerRead)
    RxPointerRead <=#Tp 1'b1;
  else
  if(RxEn_q)
    RxPointerRead <=#Tp 1'b0;
end

reg BlockingIncrementRxPointer;
//Latching Rx buffer pointer from buffer descriptor;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxPointer <=#Tp 32'h0;
  else
  if(RxEn & RxEn_q & RxPointerRead)
    RxPointer <=#Tp ram_do;
  else
  if(MasterWbRX & ~BlockingIncrementRxPointer)
    RxPointer <=#Tp RxPointer + 4;    // Pointer increment
end


always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockingIncrementRxPointer <=#Tp 0;
  else
  if(MasterAccessFinished)
    BlockingIncrementRxPointer <=#Tp 0;
  else
  if(MasterWbRX)
    BlockingIncrementRxPointer <=#Tp 1'b1;
end
 

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxEn_needed <=#Tp 1'b0;
  else
  if(~RxBDReady & r_RxEn & WbEn & ~WbEn_q)
    RxEn_needed <=#Tp 1'b1;
  else
  if(RxPointerRead & RxEn & RxEn_q)
    RxEn_needed <=#Tp 1'b0;
end


// Reception status is written back to the buffer descriptor after the end of frame is detected.
assign RxStatusWrite = ShiftEnded & RxEn & RxEn_q;

reg RxStatusWriteLatched;
reg RxStatusWrite_rck;

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxStatusWriteLatched <=#Tp 1'b0;
  else
  if(RxStatusWrite)
    RxStatusWriteLatched <=#Tp 1'b1;
  else
  if(RxStatusWrite_rck)
    RxStatusWriteLatched <=#Tp 1'b0;
end


always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxStatusWrite_rck <=#Tp 1'b0;
  else
    RxStatusWrite_rck <=#Tp RxStatusWriteLatched;
end


reg RxEnableWindow;

// Indicating that last byte is being reveived
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LastByteIn <=#Tp 1'b0;
  else
  if(ShiftWillEnd & (&RxByteCnt) | RxAbort)
    LastByteIn <=#Tp 1'b0;
  else
  if(RxValid & RxBDReady & RxEndFrm & ~(&RxByteCnt) & RxEnableWindow)
    LastByteIn <=#Tp 1'b1;
end

reg ShiftEnded_tck;
reg ShiftEndedSync1;
reg ShiftEndedSync2;
wire StartShiftWillEnd;
assign StartShiftWillEnd = LastByteIn & (&RxByteCnt) | RxValid & RxEndFrm & (&RxByteCnt) & RxEnableWindow;

// Indicating that data reception will end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShiftWillEnd <=#Tp 1'b0;
  else
  if(ShiftEnded_tck | RxAbort)
    ShiftWillEnd <=#Tp 1'b0;
  else
  if(StartShiftWillEnd)
    ShiftWillEnd <=#Tp 1'b1;
end



// Receive byte counter
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxByteCnt <=#Tp 2'h0;
  else
  if(ShiftEnded_tck | RxAbort)
    RxByteCnt <=#Tp 2'h0;
  else
  if(RxValid & (RxStartFrm | RxEnableWindow) & RxBDReady | LastByteIn)
    RxByteCnt <=#Tp RxByteCnt + 1'b1;
end


// Indicates how many bytes are valid within the last word
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxValidBytes <=#Tp 2'h1;
  else
  if(ShiftEnded_tck | RxAbort)
    RxValidBytes <=#Tp 2'h1;
  else
  if(RxValid & ~LastByteIn & ~RxStartFrm & RxEnableWindow)
    RxValidBytes <=#Tp RxValidBytes + 1;
end


always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxDataLatched1       <=#Tp 24'h0;
  else
  if(RxValid & RxBDReady & ~LastByteIn & (RxStartFrm | RxEnableWindow))
    begin
      case(RxByteCnt)     // synopsys parallel_case
        2'h0:        RxDataLatched1[7:0]   <=#Tp RxData;
        2'h1:        RxDataLatched1[15:8]  <=#Tp RxData;
        2'h2:        RxDataLatched1[23:16] <=#Tp RxData;
        2'h3:        RxDataLatched1        <=#Tp RxDataLatched1;
      endcase
    end
end

wire SetWriteRxDataToFifo;

// Assembling data that will be written to the rx_fifo
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxDataLatched2 <=#Tp 32'h0;
  else
  if(SetWriteRxDataToFifo & ~ShiftWillEnd)
    RxDataLatched2 <=#Tp {RxData, RxDataLatched1[23:0]};
  else
  if(SetWriteRxDataToFifo & ShiftWillEnd)
    case(RxValidBytes)
      0 : RxDataLatched2 <=#Tp {RxData, RxDataLatched1[23:0]};
      1 : RxDataLatched2 <=#Tp { 24'h0, RxDataLatched1[7:0]};
      2 : RxDataLatched2 <=#Tp { 16'h0, RxDataLatched1[15:0]};
      3 : RxDataLatched2 <=#Tp {  8'h0, RxDataLatched1[23:0]};
    endcase
end


reg WriteRxDataToFifoSync1;
reg WriteRxDataToFifoSync2;


// Indicating start of the reception process
assign SetWriteRxDataToFifo = (RxValid & RxBDReady & ~RxStartFrm & RxEnableWindow & (&RxByteCnt)) | (ShiftWillEnd & LastByteIn & (&RxByteCnt));

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifo <=#Tp 1'b0;
  else
  if(SetWriteRxDataToFifo & ~RxAbort)
    WriteRxDataToFifo <=#Tp 1'b1;
  else
  if(WriteRxDataToFifoSync1 | RxAbort)
    WriteRxDataToFifo <=#Tp 1'b0;
end



always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifoSync1 <=#Tp 1'b0;
  else
  if(WriteRxDataToFifo)
    WriteRxDataToFifoSync1 <=#Tp 1'b1;
  else
    WriteRxDataToFifoSync1 <=#Tp 1'b0;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifoSync2 <=#Tp 1'b0;
  else
    WriteRxDataToFifoSync2 <=#Tp WriteRxDataToFifoSync1;
end

wire WriteRxDataToFifo_wb;
assign WriteRxDataToFifo_wb = WriteRxDataToFifoSync1 & ~WriteRxDataToFifoSync2;

reg RxAbortSync1;
reg RxAbortSync2;
reg RxAbortSyncb1;
reg RxAbortSyncb2;


eth_fifo #(`RX_FIFO_DATA_WIDTH, `RX_FIFO_DEPTH, `RX_FIFO_CNT_WIDTH)
rx_fifo (.data_in(RxDataLatched2),        .data_out(m_wb_dat_o),        .clk(WB_CLK_I), 
         .reset(Reset),                   .write(WriteRxDataToFifo_wb), .read(MasterWbRX & m_wb_ack_i),
         .clear(RxAbortSync2),            .full(RxBufferFull),          .almost_full(RxBufferAlmostFull),
         .almost_empty(RxBufferAlmostEmpty), .empty(RxBufferEmpty));

assign WriteRxDataToMemory = ~RxBufferEmpty & (~MasterWbRX | ~RxBufferAlmostEmpty);



// Generation of the end-of-frame signal
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShiftEnded_tck <=#Tp 1'b0;
  else
  if(SetWriteRxDataToFifo & StartShiftWillEnd & ~RxAbort)
    ShiftEnded_tck <=#Tp 1'b1;
  else
  if(ShiftEndedSync2 | RxAbort)
    ShiftEnded_tck <=#Tp 1'b0;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync1 <=#Tp 1'b0;
  else
    ShiftEndedSync1 <=#Tp ShiftEnded_tck;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync2 <=#Tp 1'b0;
  else
  if(ShiftEndedSync1)
    ShiftEndedSync2 <=#Tp 1'b1;
  else
  if(ShiftEnded)
    ShiftEndedSync2 <=#Tp 1'b0;
end


// Generation of the end-of-frame signal
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEnded <=#Tp 1'b0;
  else
  if(ShiftEndedSync2 & MasterWbRX & m_wb_ack_i & RxBufferAlmostEmpty)
    ShiftEnded <=#Tp 1'b1;
  else
  if(RxStatusWrite)
    ShiftEnded <=#Tp 1'b0;
end


// Generation of the end-of-frame signal
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxEnableWindow <=#Tp 1'b0;
  else
  if(RxStartFrm)
    RxEnableWindow <=#Tp 1'b1;
  else
  if(RxEndFrm | RxAbort)
    RxEnableWindow <=#Tp 1'b0;
end


always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxAbortSync1 <=#Tp 1'b0;
  else
    RxAbortSync1 <=#Tp RxAbort;
end

always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxAbortSync2 <=#Tp 1'b0;
  else
    RxAbortSync2 <=#Tp RxAbortSync1;
end

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxAbortSyncb1 <=#Tp 1'b0;
  else
    RxAbortSyncb1 <=#Tp RxAbortSync2;
end

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxAbortSyncb2 <=#Tp 1'b0;
  else
    RxAbortSyncb2 <=#Tp RxAbortSyncb1;
end






// Interrupts
assign TxB_IRQ = 1'b0;
assign TxE_IRQ = 1'b0;
assign RxB_IRQ = 1'b0;
assign RxF_IRQ = 1'b0;
assign Busy_IRQ = 1'b0;



reg LoadStatusBlocked;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LoadStatusBlocked <=#Tp 1'b0;
  else
  if(LoadRxStatus)
    LoadStatusBlocked <=#Tp 1'b1;
  else
  if(RxStatusWrite_rck)
    LoadStatusBlocked <=#Tp 1'b0;
end

// LatchedRxLength[15:0]
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedRxLength[15:0] <=#Tp 16'h0;
  else
  if(LoadRxStatus & ~LoadStatusBlocked)
    LatchedRxLength[15:0] <=#Tp RxLength[15:0];
end



assign RxStatusIn = {InvalidSymbol, DribbleNibble, ReceivedPacketTooBig, ShortFrame, LatchedCrcError, RxLateCollision};

always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxStatusInLatched <=#Tp 'h0;
  else
  if(LoadRxStatus & ~LoadStatusBlocked)
    RxStatusInLatched <=#Tp RxStatusIn;
end



endmodule

