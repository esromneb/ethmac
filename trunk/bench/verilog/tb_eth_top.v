//////////////////////////////////////////////////////////////////////
////                                                              ////
////  tb_eth_top.v                                                ////
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
// Revision 1.1  2001/07/30 21:46:09  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//



`include "eth_defines.v"
`include "eth_timescale.v"

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
reg    [1:0]  WB_ACK_I;

wire  [31:0]  WB_DAT_O;
wire          WB_ACK_O;
wire          WB_ERR_O;
wire   [1:0]  WB_REQ_O;
wire   [1:0]  WB_ND_O;
wire          WB_RD_O;

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



reg GSR;

reg WishboneBusy;
reg StartTB;
reg [9:0] TxBDIndex;
reg [9:0] RxBDIndex;



// Connecting Ethernet top module

eth_top ethtop
(
  // WISHBONE common
  .WB_CLK_I(WB_CLK_I), .WB_RST_I(WB_RST_I), .WB_DAT_I(WB_DAT_I), .WB_DAT_O(WB_DAT_O), 

  // WISHBONE slave
 	.WB_ADR_I(WB_ADR_I), .WB_SEL_I(WB_SEL_I), .WB_WE_I(WB_WE_I),   .WB_CYC_I(WB_CYC_I), 
 	.WB_STB_I(WB_STB_I), .WB_ACK_O(WB_ACK_O), .WB_ERR_O(WB_ERR_O), .WB_REQ_O(WB_REQ_O), 
 	.WB_ACK_I(WB_ACK_I), .WB_ND_O(WB_ND_O),   .WB_RD_O(WB_RD_O), 

  //TX
  .MTxClk_I(MTxClk), .MTxD_O(MTxD), .MTxEn_O(MTxEn), .MTxErr_O(MTxErr),

  //RX
  .MRxClk_I(MRxClk), .MRxD_I(MRxD), .MRxDV_I(MRxDV), .MRxErr_I(MRxErr), .MColl_I(MColl), .MCrs_I(MCrs), 
  
  // MIIM
  .Mdc_O(Mdc_O), .Mdi_I(Mdi_I), .Mdo_O(Mdo_O), .Mdo_OE(Mdo_OE)
);







initial
begin
  WB_CLK_I  =  1'b0;
  WB_DAT_I  = 32'hx;
  WB_ADR_I  = 32'hx;
  WB_SEL_I  =  4'hx;
  WB_WE_I   =  1'bx;
  WB_CYC_I  =  1'b0;
  WB_STB_I  =  1'b0;
  WB_ACK_I  =  2'h0;
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
  GSR           =  1'b0;
  WB_RST_I      =  1'b0;
  #100 WB_RST_I =  1'b1;
  GSR           =  1'b1;
  #100 WB_RST_I =  1'b0;
  GSR           =  1'b0;
  #100 StartTB  =  1'b1;
end


assign glbl.GSR = GSR;



// Generating WB_CLK_I clock
always
begin
//  forever #10 WB_CLK_I = ~WB_CLK_I;  // 2*10 ns -> 50.0 MHz    
  forever #15 WB_CLK_I = ~WB_CLK_I;  // 2*10 ns -> 33.3 MHz    
//  forever #18 WB_CLK_I = ~WB_CLK_I;  // 2*18 ns -> 27.7 MHz    
//  forever #100 WB_CLK_I = ~WB_CLK_I;
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



initial
begin
  wait(StartTB);  // Start of testbench
  
  WishboneWrite(32'h00000800, {`ETHERNET_SPACE, `REG_SPACE, 6'h0, `MODER_ADR<<2});    // r_Rst = 1
  WishboneWrite(32'h00000000, {`ETHERNET_SPACE, `REG_SPACE, 6'h0, `MODER_ADR<<2});    // r_Rst = 0
  WishboneWrite(32'h00000080, {`ETHERNET_SPACE, `REG_SPACE, 6'h0, `RX_BD_ADR_ADR<<2});// r_RxBDAddress = 0x80
  WishboneWrite(32'h0002A443, {`ETHERNET_SPACE, `REG_SPACE, 6'h0, `MODER_ADR<<2});    // RxEn, Txen, FullD, CrcEn, Pad, DmaEn, r_IFG
  WishboneWrite(32'h00000004, {`ETHERNET_SPACE, `REG_SPACE, 6'h0, `CTRLMODER_ADR<<2});//r_TxFlow = 1




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


  WishboneRead({`ETHERNET_SPACE, `REG_SPACE, 6'h0, `MODER_ADR<<2});   // Read from MODER register

  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h0<<2)});       // Read from TxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h1<<2)});       // Read from TxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h2<<2)});       // Read from TxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h3<<2)});       // Read from TxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h4<<2)});       // Read from TxBD register
    
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h80<<2)});       // Read from RxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h81<<2)});       // Read from RxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h82<<2)});       // Read from RxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h83<<2)});       // Read from RxBD register
  WishboneRead({`ETHERNET_SPACE, `BD_SPACE, 2'h0, (10'h84<<2)});       // Read from RxBD register

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

    for(ii=0; (ii<20 & ~WB_ACK_O); ii=ii+1)   // Response on the WISHBONE is limited to 20 WB_CLK_I cycles
    begin
      @ (posedge WB_CLK_I);
    end

    if(ii==20)
      begin
        $display("\nERROR: Task WishboneWrite(Data=0x%0h, Address=0x%0h): Too late or no appeariance of the WB_ACK_O signal, (Time=%0t)", 
          Data, Address, $time);
        #50 $stop;
      end

    @ (posedge WB_CLK_I);
    if(Address[31:16] == `ETHERNET_SPACE)
      if(Address[15:12] == `REG_SPACE)
        $write("\nWrite to register (Data: 0x%x, Reg. Addr: 0x%0x)", Data, Address[9:2]);
      else
      if(Address[15:12] == `BD_SPACE)
        if(Address[9:2] < tb_eth_top.ethtop.r_RxBDAddress)
          begin
            $write("\nWrite to TxBD (Data: 0x%x, TxBD Addr: 0x%0x)\n", Data, Address[9:2]);
            if(Data[13])
              $write("Send Control packet (PAUSE = 0x%0h)\n", Data[31:16]);
          end
        else
          $write("\nWrite to RxBD (Data: 0x%x, RxBD Addr: 0x%0x)", Data, Address[9:2]);
      else
        $write("\nWB write      Data: 0x%x      Addr: 0x%0x", Data, Address);
    else
      $write("\nWARNING !!! WB write to non-ethernet space (Data: 0x%x, Addr: 0x%0x)", Data, Address);
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
    if(Address[31:16] == `ETHERNET_SPACE)
      if(Address[15:12] == `REG_SPACE)
        $write("\nRead from register (Data: 0x%x, Reg. Addr: 0x%0x)", Data, Address[9:2]);
      else
      if(Address[15:12] == `BD_SPACE)
        if(Address[9:2] < tb_eth_top.ethtop.r_RxBDAddress)
          begin
            $write("\nRead from TxBD (Data: 0x%x, TxBD Addr: 0x%0x)", Data, Address[9:2]);
          end
        else
          $write("\nRead from RxBD (Data: 0x%x, RxBD Addr: 0x%0x)", Data, Address[9:2]);
      else
        $write("\nWB read      Data: 0x%x      Addr: 0x%0x", Data, Address);
    else
      $write("\nWARNING !!! WB read to non-ethernet space (Data: 0x%x, Addr: 0x%0x)", Data, Address);
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

    TempAddr = {`ETHERNET_SPACE, `BD_SPACE, 2'h0, (TxBDIndex<<2)};
    TempData = {Length[15:0], 1'b1, Wrap, ControlFrame, 5'h0, TxBDIndex[7:0]};  // Ready and Wrap = 1

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

    TempRxAddr = {`ETHERNET_SPACE, `BD_SPACE, 2'h0, ((tb_eth_top.ethtop.r_RxBDAddress + RxBDIndex)<<2)};

    TempRxData = {LengthRx[15:0], 1'b1, WrapRx, 6'h0, RxBDIndex[7:0]};  // Ready and WrapRx = 1 or 0

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
    WB_ADR_I = {`ETHERNET_SPACE, `TX_DATA, pp[11:0]};
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
    WB_ADR_I = {`ETHERNET_SPACE, `RX_DATA, rr[11:0]};
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



endmodule
