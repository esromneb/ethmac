//////////////////////////////////////////////////////////////////////
////                                                              ////
////  tb_eth_top.v                                                ////
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
// Revision 1.9  2002/02/14 20:14:38  billditt
// Added separate tests for Multicast, Unicast, Broadcast
//
// Revision 1.8  2002/02/12 20:24:00  mohor
// HASH0 and HASH1 register read/write added.
//
// Revision 1.7  2002/02/06 14:11:35  mohor
// non-DMA host interface added. Select the right configutation in eth_defines.
//
// Revision 1.6  2001/12/08 12:36:00  mohor
// TX_BD_NUM register added instead of the RB_BD_ADDR.
//
// Revision 1.5  2001/10/19 11:24:04  mohor
// Number of addresses (wb_adr_i) minimized.
//
// Revision 1.4  2001/10/19 08:46:53  mohor
// eth_timescale.v changed to timescale.v This is done because of the
// simulation of the few cores in a one joined project.
//
// Revision 1.3  2001/09/24 14:55:49  mohor
// Defines changed (All precede with ETH_). Small changes because some
// tools generate warnings when two operands are together. Synchronization
// between two clocks domains in eth_wishbonedma.v is changed (due to ASIC
// demands).
//
// Revision 1.2  2001/08/15 14:04:30  mohor
// Signal names changed on the top level for easier pad insertion (ASIC).
//
// Revision 1.1  2001/08/06 14:41:09  mohor
// A define FPGA added to select between Artisan RAM (for ASIC) and Block Ram (For Virtex).
// Include files fixed to contain no path.
// File names and module names changed ta have a eth_ prologue in the name.
// File eth_timescale.v is used to define timescale
// All pin names on the top module are changed to contain _I, _O or _OE at the end.
// Bidirectional signal MDIO is changed to three signals (Mdc_O, Mdi_I, Mdo_O
// and Mdo_OE. The bidirectional signal must be created on the top level. This
// is done due to the ASIC tools.
//
// Revision 1.1  2001/07/30 21:46:09  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//



`include "eth_defines.v"
`include "timescale.v"

module tb_eth_top();


parameter Tp = 1;


reg           WB_CLK_I;
reg           WB_RST_I;
reg   [31:0]  WB_DAT_I;

reg   [31:0]  WB_ADR_I;
reg    [3:0]  WB_SEL_I;
reg           WB_WE_I;
reg           WB_CYC_I;
reg           WB_STB_I;

wire  [31:0]  WB_DAT_O;
wire          WB_ACK_O;
wire          WB_ERR_O;
reg    [1:0]  WB_ACK_I;

`ifdef WISHBONE_DMA
wire   [1:0]  WB_REQ_O;
wire   [1:0]  WB_ND_O;
wire          WB_RD_O;
`else
// WISHBONE master
wire    [31:0]    m_wb_adr_o;
wire     [3:0]    m_wb_sel_o;
wire              m_wb_we_o;
reg     [31:0]    m_wb_dat_i;
wire    [31:0]    m_wb_dat_o;
wire              m_wb_cyc_o;
wire              m_wb_stb_o;
reg               m_wb_ack_i;
reg               m_wb_err_i;
`endif

reg           MTxClk;
wire   [3:0]  MTxD;
wire          MTxEn;
wire          MTxErr;

reg           MRxClk;
reg    [3:0]  MRxD;
reg           MRxDV;
reg           MRxErr;
reg           MColl;
reg           MCrs;

reg           Mdi_I;
wire          Mdo_O;
wire          Mdo_OE;
wire          Mdc_O;



reg WishboneBusy;
reg StartTB;
reg [9:0] TxBDIndex;
reg [9:0] RxBDIndex;

`ifdef WISHBONE_DMA
`else
  integer mcd1;
  integer mcd2;
`endif

// Connecting Ethernet top module

eth_top ethtop
(
  // WISHBONE common
  .wb_clk_i(WB_CLK_I), .wb_rst_i(WB_RST_I), .wb_dat_i(WB_DAT_I), .wb_dat_o(WB_DAT_O), 

  // WISHBONE slave
 	.wb_adr_i(WB_ADR_I[11:2]), .wb_sel_i(WB_SEL_I), .wb_we_i(WB_WE_I),   .wb_cyc_i(WB_CYC_I), 
 	.wb_stb_i(WB_STB_I),       .wb_ack_o(WB_ACK_O), .wb_err_o(WB_ERR_O), .wb_ack_i(WB_ACK_I), 
 	
`ifdef WISHBONE_DMA
 	.wb_req_o(WB_REQ_O), .wb_nd_o(WB_ND_O),   .wb_rd_o(WB_RD_O), 
`else
// WISHBONE master
  .m_wb_adr_o(m_wb_adr_o), .m_wb_sel_o(m_wb_sel_o), .m_wb_we_o(m_wb_we_o), .m_wb_dat_i(m_wb_dat_i), 
  .m_wb_dat_o(m_wb_dat_o), .m_wb_cyc_o(m_wb_cyc_o), .m_wb_stb_o(m_wb_stb_o), .m_wb_ack_i(m_wb_ack_i), 
  .m_wb_err_i(m_wb_err_i), 
`endif

  //TX
  .mtx_clk_pad_i(MTxClk), .mtxd_pad_o(MTxD), .mtxen_pad_o(MTxEn), .mtxerr_pad_o(MTxErr),

  //RX
  .mrx_clk_pad_i(MRxClk), .mrxd_pad_i(MRxD), .mrxdv_pad_i(MRxDV), .mrxerr_pad_i(MRxErr), 
  .mcoll_pad_i(MColl), .mcrs_pad_i(MCrs), 
  
  // MIIM
  .mdc_pad_o(Mdc_O), .md_pad_i(Mdi_I), .md_pad_o(Mdo_O), .md_padoen_o(Mdo_OE),
  
  .int_o()
);







initial
begin
  WB_CLK_I  =  1'b0;
  WB_DAT_I  = 32'h0;
  WB_ADR_I  = 32'h0;
  WB_SEL_I  =  4'h0;
  WB_WE_I   =  1'b0;
  WB_CYC_I  =  1'b0;
  WB_STB_I  =  1'b0;

`ifdef WISHBONE_DMA
  WB_ACK_I  =  2'h0;
`else
  m_wb_ack_i = 0;
  m_wb_err_i = 0;
`endif
  MTxClk    =  1'b0;
  MRxClk    =  1'b0;
  MRxD      =  4'h0;
  MRxDV     =  1'b0;
  MRxErr    =  1'b0;
  MColl     =  1'b0;
  MCrs      =  1'b0;
  Mdi_I     =  1'b0;

  WishboneBusy = 1'b0;
  TxBDIndex = 10'h0;
  RxBDIndex = 10'h0;
end


// Reset pulse
initial
begin
`ifdef WISHBONE_DMA
`else
  mcd1 = $fopen("ethernet_tx.log");
  mcd2 = $fopen("ethernet_rx.log");
`endif
  WB_RST_I =  1'b1;
  #100 WB_RST_I =  1'b0;
  #100 StartTB  =  1'b1;
end



// Generating WB_CLK_I clock
always
begin
//  forever #2.5 WB_CLK_I = ~WB_CLK_I;  // 2*2.5 ns -> 200.0 MHz    
//  forever #5 WB_CLK_I = ~WB_CLK_I;  // 2*5 ns -> 100.0 MHz    
//  forever #10 WB_CLK_I = ~WB_CLK_I;  // 2*10 ns -> 50.0 MHz    
  forever #15 WB_CLK_I = ~WB_CLK_I;  // 2*10 ns -> 33.3 MHz    
//  forever #18 WB_CLK_I = ~WB_CLK_I;  // 2*18 ns -> 27.7 MHz    
//  forever #25 WB_CLK_I = ~WB_CLK_I;  // 2*25 ns -> 20.0 MHz
//  forever #50 WB_CLK_I = ~WB_CLK_I;  // 2*50 ns -> 10.0 MHz
//  forever #55 WB_CLK_I = ~WB_CLK_I;  // 2*55 ns ->  9.1 MHz    
end

// Generating MTxClk clock
always
begin
  #3 forever #20 MTxClk = ~MTxClk;   // 2*20 ns -> 25 MHz
//  #3 forever #200 MTxClk = ~MTxClk;
end

// Generating MRxClk clock
always
begin
  #16 forever #20 MRxClk = ~MRxClk;   // 2*20 ns -> 25 MHz
//  #16 forever #250 MRxClk = ~MRxClk;
end

`ifdef WISHBONE_DMA
initial
begin
  wait(StartTB);  // Start of testbench
  
  WishboneWrite(32'h00000800, {26'h0, `ETH_MODER_ADR<<2});     // r_Rst = 1
  WishboneWrite(32'h00000000, {26'h0, `ETH_MODER_ADR<<2});     // r_Rst = 0
  WishboneWrite(32'h00000080, {26'h0, `ETH_TX_BD_NUM_ADR<<2}); // r_RxBDAddress = 0x80
  WishboneWrite(32'h0002A443, {26'h0, `ETH_MODER_ADR<<2});     // RxEn, Txen, FullD, CrcEn, Pad, DmaEn, r_IFG
  WishboneWrite(32'h00000004, {26'h0, `ETH_CTRLMODER_ADR<<2}); //r_TxFlow = 1

  SendPacket(16'h0015, 1'b0);
  SendPacket(16'h0043, 1'b1);   // Control frame
  SendPacket(16'h0025, 1'b0);
  SendPacket(16'h0045, 1'b0);
  SendPacket(16'h0025, 1'b0);

  ReceivePacket(16'h0012, 1'b1);    // Initializes RxBD and then Sends a control packet on the MRxD[3:0] signals.
  ReceivePacket(16'h0011, 1'b0);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0016, 1'b0);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0017, 1'b0);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0018, 1'b0);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.


  WishboneRead({26'h0, `ETH_MODER_ADR});   // Read from MODER register

  WishboneRead({24'h04, (8'h0<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h1<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h2<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h3<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h4<<2)});       // Read from TxBD register
    
  WishboneRead({22'h01, (10'h80<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h81<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h82<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h83<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h84<<2)});       // Read from RxBD register

  #10000 $stop;
end







task WishboneWrite;
  input [31:0] Data;
  input [31:0] Address;
  integer ii;

  begin
    wait (~WishboneBusy);
    WishboneBusy = 1;
    @ (posedge WB_CLK_I);
    #1;
    WB_ADR_I = Address;
    WB_DAT_I = Data;
    WB_WE_I  = 1'b1;
    WB_CYC_I = 1'b1;
    WB_STB_I = 1'b1;
    WB_SEL_I = 4'hf;

    wait(WB_ACK_O);   // waiting for acknowledge response

    // Writing information about the access to the screen
    @ (posedge WB_CLK_I);
      if(~Address[11] & ~Address[10])
        $write("\nWrite to register (Data: 0x%x, Reg. Addr: 0x%0x)", Data, Address);
      else
      if(~Address[11] & Address[10])
        if(Address[9:2] < tb_eth_top.ethtop.r_TxBDNum)
          begin
            $write("\nWrite to TxBD (Data: 0x%x, TxBD Addr: 0x%0x)\n", Data, Address);
            if(Data[9])
              $write("Send Control packet (PAUSE = 0x%0h)\n", Data[31:16]);
          end
        else
          $write("\nWrite to RxBD (Data: 0x%x, RxBD Addr: 0x%0x)", Data, Address);
      else
        $write("\nWB write ??????????????     Data: 0x%x      Addr: 0x%0x", Data, Address);
    #1;
    WB_ADR_I = 32'hx;
    WB_DAT_I = 32'hx;
    WB_WE_I  = 1'bx;
    WB_CYC_I = 1'b0;
    WB_STB_I = 1'b0;
    WB_SEL_I = 4'hx;
    #5 WishboneBusy = 0;
  end
endtask


task WishboneRead;
  input [31:0] Address;
  reg   [31:0] Data;
  integer ii;

  begin
    wait (~WishboneBusy);
    WishboneBusy = 1;
    @ (posedge WB_CLK_I);
    #1;
    WB_ADR_I = Address;
    WB_WE_I  = 1'b0;
    WB_CYC_I = 1'b1;
    WB_STB_I = 1'b1;
    WB_SEL_I = 4'hf;

    for(ii=0; (ii<20 & ~WB_ACK_O); ii=ii+1)   // Response on the WISHBONE is limited to 20 WB_CLK_I cycles
    begin
      @ (posedge WB_CLK_I);
      Data = WB_DAT_O;
    end

    if(ii==20)
      begin
        $display("\nERROR: Task WishboneRead(Address=0x%0h): Too late or no appeariance of the WB_ACK_O signal, (Time=%0t)", 
          Address, $time);
        #50 $stop;
      end

    @ (posedge WB_CLK_I);
      if(~Address[11] & ~Address[10])
        $write("\nRead from register (Data: 0x%x, Reg. Addr: 0x%0x)", Data, Address);
      else
      if(~Address[11] & Address[10])
        if(Address[9:2] < tb_eth_top.ethtop.r_TxBDNum)
          begin
            $write("\nRead from TxBD (Data: 0x%x, TxBD Addr: 0x%0x)", Data, Address);
          end
        else
          $write("\nRead from RxBD (Data: 0x%x, RxBD Addr: 0x%0x)", Data, Address);
      else
        $write("\nWB read  ?????????    Data: 0x%x      Addr: 0x%0x", Data, Address);
    #1;
    WB_ADR_I = 32'hx;
    WB_WE_I  = 1'bx;
    WB_CYC_I = 1'b0;
    WB_STB_I = 1'b0;
    WB_SEL_I = 4'hx;
    #5 WishboneBusy = 0;
  end
endtask




task SendPacket;
  input [15:0]  Length;
  input         ControlFrame;
  reg           Wrap;
  reg [31:0]    TempAddr;
  reg [31:0]    TempData;
  
  begin
    if(TxBDIndex == 3)    // Only 4 buffer descriptors are used
      Wrap = 1'b1;
    else
      Wrap = 1'b0;

    TempAddr = {22'h01, (TxBDIndex<<2)};
    TempData = {Length[15:0], 1'b1, 1'b0, Wrap, 3'h0, ControlFrame, 1'b0, TxBDIndex[7:0]};  // Ready and Wrap = 1

    #1;
    if(TxBDIndex == 3)    // Only 4 buffer descriptors are used
      TxBDIndex = 0;
    else
      TxBDIndex = TxBDIndex + 1;

    fork
      begin
        WishboneWrite(TempData, TempAddr); // Writing status to TxBD
      end
      
      begin
        if(~ControlFrame)
        WaitingForTxDMARequest(4'h1, Length); // Delay, DMALength
      end
    join
  end
endtask



task ReceivePacket;    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  input [15:0] LengthRx;
  input        RxControlFrame;
  reg        WrapRx;
  reg [31:0] TempRxAddr;
  reg [31:0] TempRxData;
  reg abc;
  begin
    if(RxBDIndex == 3)    // Only 4 buffer descriptors are used
      WrapRx = 1'b1;
    else
      WrapRx = 1'b0;

    TempRxAddr = {22'h01, ((tb_eth_top.ethtop.r_TxBDNum + RxBDIndex)<<2)};

    TempRxData = {LengthRx[15:0], 1'b1, 1'b0, WrapRx, 5'h0, RxBDIndex[7:0]};  // Ready and WrapRx = 1 or 0

    #1;
    if(RxBDIndex == 3)    // Only 4 buffer descriptors are used
      RxBDIndex = 0;
    else
      RxBDIndex = RxBDIndex + 1;

    abc=1;
    WishboneWrite(TempRxData, TempRxAddr); // Writing status to RxBD
    abc=0;
    fork
      begin
        #200;
        if(RxControlFrame)
          GetControlDataOnMRxD(LengthRx); // LengthRx = PAUSE timer value.
        else
          GetDataOnMRxD(LengthRx); // LengthRx bytes is comming on MRxD[3:0] signals
      end

      begin
        if(RxControlFrame)
          WaitingForRxDMARequest(4'h1, 16'h40); // Delay, DMALength = 64 bytes.
        else
          WaitingForRxDMARequest(4'h1, LengthRx); // Delay, DMALength
      end
    join
  end
endtask



task WaitingForTxDMARequest;
  input [3:0] Delay;
  input [15:0] DMALength;
  integer pp;
  reg [7:0]a, b, c, d;

  for(pp=0; pp*4<DMALength; pp=pp+1)
  begin
    a = 4*pp[7:0]+3;
    b = 4*pp[7:0]+2;
    c = 4*pp[7:0]+1;
    d = 4*pp[7:0]  ;
    @ (posedge WB_REQ_O[0]);
    repeat(Delay) @(posedge WB_CLK_I);
    
    wait (~WishboneBusy);
    WishboneBusy = 1;
    #1;
    WB_DAT_I = {a, b, c, d};
    WB_ADR_I = {22'h02, pp[9:0]};
    $display("task WaitingForTxDMARequest: pp=%0d, WB_ADR_I=0x%0h, WB_DAT_I=0x%0h", pp, WB_ADR_I, WB_DAT_I);

    WB_WE_I  = 1'b1;
    WB_CYC_I = 1'b1;
    WB_STB_I = 1'b1;
    WB_SEL_I = 4'hf;
    WB_ACK_I[0] = 1'b1;

    @ (posedge WB_CLK_I);
    #1;
    WB_ADR_I = 32'hx;
    WB_DAT_I = 32'hx;
    WB_WE_I  = 1'bx;
    WB_CYC_I = 1'b0;
    WB_STB_I = 1'b0;
    WB_SEL_I = 4'hx;
    WB_ACK_I[0] = 1'b0;
    #5 WishboneBusy = 0;
  end
endtask


task WaitingForRxDMARequest;
  input [3:0] Delay;
  input [15:0] DMALengthRx;
  integer rr;

  for(rr=0; rr*4<DMALengthRx; rr=rr+1)
  begin
    @ (posedge WB_REQ_O[1]);
    repeat(Delay) @(posedge WB_CLK_I);
    
    wait (~WishboneBusy);
    WishboneBusy = 1;
    #1;
    WB_ADR_I = {22'h02, rr[9:0]};
    $display("task WaitingForRxDMARequest: rr=%0d, WB_ADR_I=0x%0h, WB_DAT_O=0x%0h", rr, WB_ADR_I, WB_DAT_O);

    WB_WE_I  = 1'b1;
    WB_CYC_I = 1'b1;
    WB_STB_I = 1'b1;
    WB_SEL_I = 4'hf;
    WB_ACK_I[1] = 1'b1;

    @ (posedge WB_CLK_I);
    #1;
    WB_ADR_I = 32'hx;
    WB_WE_I  = 1'bx;
    WB_CYC_I = 1'b0;
    WB_STB_I = 1'b0;
    WB_SEL_I = 4'hx;
    WB_ACK_I[1] = 1'b0;
    #5 WishboneBusy = 0;
  end
endtask



task GetDataOnMRxD;
  input [15:0] Len;
  integer tt;

  begin
    @ (posedge MRxClk);
    MRxDV=1'b1;
    
    for(tt=0; tt<15; tt=tt+1)
    begin
      MRxD=4'h5;              // preamble
      @ (posedge MRxClk);
    end
    MRxD=4'hd;                // SFD
    
    for(tt=0; tt<Len; tt=tt+1)
    begin
      @ (posedge MRxClk);
      MRxD=tt[3:0];
      @ (posedge MRxClk);
      MRxD=tt[7:4];
    end
    @ (posedge MRxClk);
    MRxDV=1'b0;
  end
endtask


task GetControlDataOnMRxD;
  input [15:0] Timer;
  reg [127:0] Packet;
  reg [127:0] Data;
  reg [31:0] Crc;
  integer tt;

  begin
  Packet = 128'h10082C000010_deadbeef0013_8880_0010; // 0180c2000001 + 8808 + 0001
  Crc = 32'h6014fe08; // not a correct value
  
    @ (posedge MRxClk);
    MRxDV=1'b1;
    
    for(tt=0; tt<15; tt=tt+1)
    begin
      MRxD=4'h5;              // preamble
      @ (posedge MRxClk);
    end
    MRxD=4'hd;                // SFD
    
    for(tt=0; tt<32; tt=tt+1)
    begin
      Data = Packet << (tt*4);
      @ (posedge MRxClk);
      MRxD=Data[127:124];
    end
    
    for(tt=0; tt<2; tt=tt+1)    // timer
    begin
      Data[15:0] = Timer << (tt*8);
      @ (posedge MRxClk);
      MRxD=Data[11:8];
      @ (posedge MRxClk);
      MRxD=Data[15:12];
    end
    
    for(tt=0; tt<42; tt=tt+1)   // padding
    begin
      Data[7:0] = 8'h0;
      @ (posedge MRxClk);
      MRxD=Data[3:0];
      @ (posedge MRxClk);
      MRxD=Data[3:0];
    end
    
    for(tt=0; tt<4; tt=tt+1)    // crc
    begin
      Data[31:0] = Crc << (tt*8);
      @ (posedge MRxClk);
      MRxD=Data[27:24];
      @ (posedge MRxClk);
      MRxD=Data[31:28];
    end
    
    
    
    @ (posedge MRxClk);
    MRxDV=1'b0;
  end
endtask

`else // No WISHBONE_DMA

initial
begin
  wait(StartTB);  // Start of testbench
  
  InitializeMemory;

// Select which test you want to run:
    TestTxAndRx;
  //  TestUnicast;
  //  TestBroadcast;
  //  TestMulticast;
end
  
task TestTxAndRx;
 begin
  WishboneWrite(32'h00000800, {26'h0, `ETH_MODER_ADR<<2});     // r_Rst = 1
  WishboneWrite(32'h00000000, {26'h0, `ETH_MODER_ADR<<2});     // r_Rst = 0
  WishboneWrite(32'h00000080, {26'h0, `ETH_TX_BD_NUM_ADR<<2}); // r_RxBDAddress = 0x80

  WishboneWrite(32'h00002463, {26'h0, `ETH_MODER_ADR<<2});     // RxEn, Txen, CrcEn, Pad off, full duplex, r_IFG, promisc ON

  WishboneWrite(32'h00000004, {26'h0, `ETH_CTRLMODER_ADR<<2}); //r_TxFlow = 1

  SendPacket(16'h0007, 1'b0);
  SendPacket(16'h0011, 1'b0);
  SendPacket(16'h0012, 1'b0);
  SendPacket(16'h0013, 1'b0);
  SendPacket(16'h0014, 1'b0);

  SendPacket(16'h0030, 1'b0);
  SendPacket(16'h0031, 1'b0);
  SendPacket(16'h0032, 1'b0);
  SendPacket(16'h0033, 1'b0);
  SendPacket(16'h0025, 1'b0);
  SendPacket(16'h0045, 1'b0);
  SendPacket(16'h0025, 1'b0);
  SendPacket(16'h0017, 1'b0);

  ReceivePacket(16'h0015, 1'b0, `MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0016, 1'b0, `MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0017, 1'b0, `MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0018, 1'b0, `MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.

  repeat(5000) @ (posedge MRxClk);        // Waiting some time for all accesses to finish before reading out the statuses.

  WishboneRead({26'h0, `ETH_MODER_ADR});   // Read from MODER register

  WishboneRead({24'h04, (8'h0<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h1<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h2<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h3<<2)});       // Read from TxBD register
  WishboneRead({24'h04, (8'h4<<2)});       // Read from TxBD register

  
  WishboneRead({22'h01, (10'h80<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h81<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h82<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h83<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h84<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h85<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h86<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h87<<2)});       // Read from RxBD register

  #100000 $stop;
 end
endtask //TestTxAndRx


task TestUnicast;
 begin
  $display("\nBegin TestUnicast \n");
  WishboneWrite(32'h00000800, {26'h0, `ETH_MODER_ADR, 2'h0});     // r_Rst = 1
  WishboneWrite(32'h00000000, {26'h0, `ETH_MODER_ADR, 2'h0});     // r_Rst = 0
  WishboneWrite(32'h00000080, {26'h0, `ETH_TX_BD_NUM_ADR, 2'h0}); // r_RxBDAddress = 0x80
  WishboneWrite(32'h00002043, {26'h0, `ETH_MODER_ADR, 2'h0});     // RxEn, Txen, CrcEn, no Pad, r_IFG, promisc off, broadcast on
  WishboneWrite(32'h00000004, {26'h0, `ETH_CTRLMODER_ADR, 2'h0}); //r_TxFlow = 1

  $display("\n This Uniicast packet will be rejected, wrong address in MAC Address Regs\n");
 
  ReceivePacket(16'h0014, 1'b0,`UNICAST_XFR);    
  
  WishboneWrite(32'h04030200, {26'h0,`ETH_MAC_ADDR0_ADR ,2'h0}); // Mac Address 
  WishboneWrite(32'h00000605, {26'h0,`ETH_MAC_ADDR1_ADR ,2'h0}); // Mac Address
  
  $display("\n Set Proper Unicast Address in MAC_ADDRESS regs, resend packet\n");
  
  ReceivePacket(16'h0015, 1'b0,`UNICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0016, 1'b0,`UNICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0017, 1'b0,`UNICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0018, 1'b0,`UNICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.

  repeat(5000) @ (posedge MRxClk);        // Waiting some time for all accesses to finish before reading out the statuses.

  WishboneRead({26'h0, `ETH_MODER_ADR});   // Read from MODER register

  WishboneRead({22'h01, (10'h80<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h81<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h82<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h83<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h84<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h85<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h86<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h87<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h88<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h89<<2)});       // Read from RxBD register
  
  #100000 $stop;
  $display("\nEnd TestUnicast \n");
end
endtask //TestUnicast

task TestMulticast;
 begin
  $display("\nBegin TestMulticast \n");
  WishboneWrite(32'h00000800, {26'h0, `ETH_MODER_ADR, 2'h0});     // r_Rst = 1
  WishboneWrite(32'h00000000, {26'h0, `ETH_MODER_ADR, 2'h0});     // r_Rst = 0
  WishboneWrite(32'h00000080, {26'h0, `ETH_TX_BD_NUM_ADR, 2'h0}); // r_RxBDAddress = 0x80
  WishboneWrite(32'h00002043, {26'h0, `ETH_MODER_ADR, 2'h0});     // RxEn, Txen, CrcEn, No Pad, r_IFG, promiscuos off, broadcast enable
  WishboneWrite(32'h00000004, {26'h0, `ETH_CTRLMODER_ADR, 2'h0}); // r_TxFlow = 1
  
  $display("\n This Multicast packet will be rejected by Hash Filter\n");
 
  ReceivePacket(16'h0014, 1'b0,`MULTICAST_XFR);    
  
  WishboneWrite(32'h00400000, {26'h0, `ETH_HASH1_ADR,2'h0}); // set bit 16, multicast hash 36
  WishboneRead({26'h0, `ETH_HASH1_ADR, 2'h0});  // read back
  
  $display("\n Set Hash Filter to accept this Multicast packet, resend packet\n");
  
  ReceivePacket(16'h0015, 1'b0,`MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0016, 1'b0,`MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0017, 1'b0,`MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0018, 1'b0,`MULTICAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.

  repeat(5000) @ (posedge MRxClk);        // Waiting some time for all accesses to finish before reading out the statuses.

  WishboneRead({26'h0, `ETH_MODER_ADR});   // Read from MODER register

  WishboneRead({22'h01, (10'h80<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h81<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h82<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h83<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h84<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h85<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h86<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h87<<2)});       // Read from RxBD register

  $display("\nEnd TestMulticast \n");
  #100000 $stop;
end
endtask //TestMulticast


task TestBroadcast;
 begin
  $display("\n\n\nBegin TestBroadcast");
  WishboneWrite(32'h00000800, {26'h0, `ETH_MODER_ADR, 2'h0});     // r_Rst = 1
  WishboneWrite(32'h00000000, {26'h0, `ETH_MODER_ADR, 2'h0});     // r_Rst = 0
  WishboneWrite(32'h00000080, {26'h0, `ETH_TX_BD_NUM_ADR, 2'h0}); // r_RxBDAddress = 0x80

  WishboneWrite(32'h0000A04b, {26'h0, `ETH_MODER_ADR, 2'h0});     // PadEn, CrcEn, IFG=accept, Reject Broadcast, TxEn, RxEn
  WishboneWrite(32'h00000004, {26'h0, `ETH_CTRLMODER_ADR, 2'h0}); // r_TxFlow = 1

  $display("\nThis Broadcast packet will be rejected, r_BRO = 1");
  ReceivePacket(16'h0014, 1'b0,`BROADCAST_XFR);
  
  $display("\nSet r_Bro = 0, resend packet");
  WishboneWrite(32'h0000A043, {26'h0, `ETH_MODER_ADR, 2'h0});  // PadEn, CrcEn, IFG=accept, Accept Broadcast, TxEn, RxEn
  ReceivePacket(16'h0015, 1'b0,`BROADCAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.

  $display("\n This Broadcast packet will be rejected, r_BRO = 1");
  WishboneWrite(32'h0000A04b, {26'h0, `ETH_MODER_ADR, 2'h0});     // PadEn, CrcEn, IFG=accept, Reject Broadcast, TxEn, RxEn
  ReceivePacket(16'h0016, 1'b0,`BROADCAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  ReceivePacket(16'h0017, 1'b0,`BROADCAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.

  $display("\n Set r_Bro = 0, resend packet");
  WishboneWrite(32'h0000A043, {26'h0, `ETH_MODER_ADR, 2'h0});  // PadEn, CrcEn, IFG=accept, Accept Broadcast, TxEn, RxEn
  ReceivePacket(16'h0018, 1'b0,`BROADCAST_XFR);    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.

  repeat(5000) @ (posedge MRxClk);        // Waiting some time for all accesses to finish before reading out the statuses.

  WishboneRead({26'h0, `ETH_MODER_ADR});   // Read from MODER register

  WishboneRead({22'h01, (10'h80<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h81<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h82<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h83<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h84<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h85<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h86<<2)});       // Read from RxBD register
  WishboneRead({22'h01, (10'h87<<2)});       // Read from RxBD register

  #100000 $stop;
  $display("\nEnd TestBroadcast \n");
end
endtask //TestBroadcast


always @ (posedge WB_CLK_I)
begin
  if(m_wb_cyc_o & m_wb_stb_o) // Add valid address range
    begin
      repeat(3) @ (posedge WB_CLK_I);
        begin
          m_wb_ack_i <=#Tp 1'b1;
          if(~m_wb_we_o)
            begin
              #Tp m_wb_dat_i = m_wb_adr_o + 1'b1; // For easier following of the data
              $fdisplay(mcd1, "(%0t) master read (0x%0x) = 0x%0x", $time, m_wb_adr_o, m_wb_dat_i);
            end
          else
            $fdisplay(mcd2, "(%0t) master write (0x%0x) = 0x%0x", $time, m_wb_adr_o, m_wb_dat_o);
        end
      @ (posedge WB_CLK_I);
      m_wb_ack_i <=#Tp 1'b0;
    end
end

// Generating error
always @ (posedge WB_CLK_I)
begin
  if(m_wb_cyc_o & m_wb_stb_o & ~(&m_wb_sel_o))  // Add false address range
    m_wb_err_i <=#Tp 1'b1;
end

always @ (posedge WB_CLK_I)
  if(tb_eth_top.ethtop.wishbone.RxStatusWrite)
    $fdisplay(mcd2, "");  // newline added

task WishboneWrite;
  input [31:0] Data;
  input [31:0] Address;
  integer ii;

  begin
    wait (~WishboneBusy);
    WishboneBusy = 1;
    @ (posedge WB_CLK_I);
    #1;
    WB_ADR_I = Address;
    WB_DAT_I = Data;
    WB_WE_I  = 1'b1;
    WB_CYC_I = 1'b1;
    WB_STB_I = 1'b1;
    WB_SEL_I = 4'hf;


    wait(WB_ACK_O);   // waiting for acknowledge response

    // Writing information about the access to the screen
    @ (posedge WB_CLK_I);
      if(~Address[11] & ~Address[10])
        $write("\n(%0t) Write to register (Data: 0x%x, Reg. Addr: 0x%0x)", $time, Data, Address);
      else
      if(~Address[11] & Address[10])
        if(Address[9:2] < tb_eth_top.ethtop.r_TxBDNum)
          begin
            $write("\n(%0t) Write to TxBD (Data: 0x%x, TxBD Addr: 0x%0x)", $time, Data, Address);
            if(Address[9:2] == tb_eth_top.ethtop.r_TxBDNum-2'h2)
              $write("(%0t) Send Control packet\n", $time);
          end
        else
          $write("\n(%0t) Write to RxBD (Data: 0x%x, RxBD Addr: 0x%0x)", $time, Data, Address);
      else
        $write("\n(%0t) WB write ??????????????     Data: 0x%x      Addr: 0x%0x", $time, Data, Address);
    #1;
    WB_ADR_I = 32'hx;
    WB_DAT_I = 32'hx;
    WB_WE_I  = 1'bx;
    WB_CYC_I = 1'b0;
    WB_STB_I = 1'b0;
    WB_SEL_I = 4'hx;
    #5 WishboneBusy = 0;
  end
endtask


task WishboneRead;
  input [31:0] Address;

  begin
    wait (~WishboneBusy);
    WishboneBusy = 1;
    @ (posedge WB_CLK_I);
    #1;
    WB_ADR_I = Address;
    WB_WE_I  = 1'b0;
    WB_CYC_I = 1'b1;
    WB_STB_I = 1'b1;
    WB_SEL_I = 4'hf;

    wait(WB_ACK_O);   // waiting for acknowledge response
    @ (posedge WB_CLK_I);

      if(~Address[11] & ~Address[10])
        $write("\n(%0t) Read from register (Data: 0x%x, Reg. Addr: 0x%0x)", $time, WB_DAT_O, Address);
      else
      if(~Address[11] & Address[10])
        if(Address[9:2] < tb_eth_top.ethtop.r_TxBDNum)
          begin
            $write("\n(%0t) Read from TxBD (Data: 0x%x, TxBD Addr: 0x%0x)", $time, WB_DAT_O, Address);
          end
        else
          $write("\n(%0t) Read from RxBD (Data: 0x%x, RxBD Addr: 0x%0x)", $time, WB_DAT_O, Address);
      else
        $write("\n(%0t) WB read  ?????????    Data: 0x%x      Addr: 0x%0x", $time, WB_DAT_O, Address);
    #1;
    WB_ADR_I = 32'hx;
    WB_WE_I  = 1'bx;
    WB_CYC_I = 1'b0;
    WB_STB_I = 1'b0;
    WB_SEL_I = 4'hx;
    #5 WishboneBusy = 0;
  end
endtask




task SendPacket;
  input [15:0]  Length;
  input         ControlFrame;
  reg           Wrap;
  reg [31:0]    TempAddr;
  reg [31:0]    TempData;
  
  begin
//    if(TxBDIndex == 6)    // Only 3 buffer descriptors are used 
//      Wrap = 1'b1;
//    else
      Wrap = 1'b0;    // At the moment no wrap bit is set

    // Writing buffer pointer
    TempAddr = {22'h01, ((TxBDIndex + 1'b1)<<2)};
    TempData = 32'h78563411;
    WishboneWrite(TempData, TempAddr); // buffer pointer


    TempAddr = {22'h01, (TxBDIndex<<2)};

    TempData = {Length[15:0], 1'b1, 1'b0, Wrap, 3'h0, ControlFrame, 1'b0, TxBDIndex[7:0]};  // Ready and Wrap = 1

    #1;
//    if(TxBDIndex == 6)    // Only 4 buffer descriptors are used
//      TxBDIndex = 0;
//    else
      TxBDIndex = TxBDIndex + 2;

    WishboneWrite(TempData, TempAddr); // Writing status to TxBD
  end
endtask



task ReceivePacket;    // Initializes RxBD and then generates traffic on the MRxD[3:0] signals.
  input [15:0] LengthRx;
  input        RxControlFrame;
  input [31:0] TransferType;  //Broadcast,Unicast,Multicast
  reg        WrapRx;
  reg [31:0] TempRxAddr;
  reg [31:0] TempRxData;
  reg abc;
  begin
//    if(RxBDIndex == 6)    // Only 3 buffer descriptors are used
//      WrapRx = 1'b1;
//    else
      WrapRx = 1'b0;

    TempRxAddr = {22'h01, ((tb_eth_top.ethtop.r_TxBDNum + RxBDIndex + 1'b1)<<2)};
    TempRxData = 32'h73507350 + RxBDIndex;
    WishboneWrite(TempRxData, TempRxAddr); // Writing Rx pointer


    TempRxAddr = {22'h01, ((tb_eth_top.ethtop.r_TxBDNum + RxBDIndex)<<2)};
//    TempRxData = {LengthRx[15:0], 1'b1, 1'b0, WrapRx, 5'h0, RxBDIndex[7:0]};  // Ready and WrapRx = 1 or 0
    TempRxData = {16'h0, 1'b1, 1'b0, WrapRx, 5'h0, RxBDIndex[7:0]};  // Ready and WrapRx = 1 or 0

    #1;
//    if(RxBDIndex == 6)    // Only 4 buffer descriptors are used
//      RxBDIndex = 0;
//    else
      RxBDIndex = RxBDIndex + 2;

    abc=1;
    WishboneWrite(TempRxData, TempRxAddr); // Writing status to RxBD
    abc=0;

      begin
        #200;
        if(RxControlFrame)
          GetControlDataOnMRxD(LengthRx); // LengthRx = PAUSE timer value.
        else
          GetDataOnMRxD(LengthRx, TransferType); // LengthRx bytes is comming on MRxD[3:0] signals
      end

  end
endtask


task GetDataOnMRxD;
  input [15:0] Len;
  input [31:0] TransferType;
  integer tt;

  begin
    @ (posedge MRxClk);
    MRxDV=1'b1;
    
    for(tt=0; tt<15; tt=tt+1)
    begin
      MRxD=4'h5;              // preamble
      @ (posedge MRxClk);
    end
    MRxD=4'hd;                // SFD
    
  for(tt=1; tt<(Len+1); tt=tt+1)
     
    begin
	
      @ (posedge MRxClk);
	  if(TransferType == `UNICAST_XFR && tt == 1)
	   MRxD= 4'h0;   // Unicast transfer
	  else if(TransferType == `BROADCAST_XFR && tt < 7)
	   MRxD = 4'hf;
	  else
       MRxD=tt[3:0]; // Multicast transfer

    @ (posedge MRxClk);
	  
	   if(TransferType == `BROADCAST_XFR && tt < 7)
	    MRxD = 4'hf;
	  else
        MRxD=tt[7:4];
    end

    @ (posedge MRxClk);
    MRxDV=1'b0;
  end
endtask


task GetControlDataOnMRxD;
  input [15:0] Timer;
  reg [127:0] Packet;
  reg [127:0] Data;
  reg [31:0] Crc;
  integer tt;

  begin
  Packet = 128'h10082C000010_deadbeef0013_8880_0010; // 0180c2000001 + 8808 + 0001
  Crc = 32'h6014fe08; // not a correct value
  
    @ (posedge MRxClk);
    MRxDV=1'b1;
    
    for(tt=0; tt<15; tt=tt+1)
    begin
      MRxD=4'h5;              // preamble
      @ (posedge MRxClk);
    end
    MRxD=4'hd;                // SFD
    
    for(tt=0; tt<32; tt=tt+1)
    begin
      Data = Packet << (tt*4);
      @ (posedge MRxClk);
      MRxD=Data[127:124];
    end
    
    for(tt=0; tt<2; tt=tt+1)    // timer
    begin
      Data[15:0] = Timer << (tt*8);
      @ (posedge MRxClk);
      MRxD=Data[11:8];
      @ (posedge MRxClk);
      MRxD=Data[15:12];
    end
    
    for(tt=0; tt<42; tt=tt+1)   // padding
    begin
      Data[7:0] = 8'h0;
      @ (posedge MRxClk);
      MRxD=Data[3:0];
      @ (posedge MRxClk);
      MRxD=Data[3:0];
    end
    
    for(tt=0; tt<4; tt=tt+1)    // crc
    begin
      Data[31:0] = Crc << (tt*8);
      @ (posedge MRxClk);
      MRxD=Data[27:24];
      @ (posedge MRxClk);
      MRxD=Data[31:28];
    end
    
    
    
    @ (posedge MRxClk);
    MRxDV=1'b0;
  end
endtask

task InitializeMemory;
  reg [9:0] mem_addr;
  
  begin
    for(mem_addr=0; mem_addr<=10'h0ff; mem_addr=mem_addr+1'b1)
      WishboneWrite(32'h0, {22'h01, mem_addr<<2}); // Writing status to RxBD
  end
endtask


`endif


endmodule
