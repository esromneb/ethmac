//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_registers.v                                             ////
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
// Revision 1.2  2001/08/02 09:25:31  mohor
// Unconnected signals are now connected.
//
// Revision 1.1  2001/07/30 21:23:42  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//
//

`include "eth_defines.v"
`include "eth_timescale.v"


module eth_registers( DataIn, Address, Rw, Cs, Clk, Reset, DataOut, r_DmaEn, 
                      r_RecSmall, r_Pad, r_HugEn, r_CrcEn, r_DlyCrcEn, 
                      r_Rst, r_FullD, r_ExDfrEn, r_NoBckof, r_LoopBck, r_IFG, 
                      r_Pro, r_Iam, r_Bro, r_NoPre, r_TxEn, r_RxEn, Busy_IRQ, RxF_IRQ, 
                      RxB_IRQ, TxE_IRQ, TxB_IRQ, Busy_MASK, RxF_MASK, RxB_MASK, TxE_MASK, 
                      TxB_MASK, r_IPGT, r_IPGR1, r_IPGR2, r_MinFL, r_MaxFL, r_MaxRet, 
                      r_CollValid, r_TxFlow, r_RxFlow, r_PassAll, 
                      r_MiiMRst, r_MiiNoPre, r_ClkDiv, r_WCtrlData, r_RStat, r_ScanStat, 
                      r_RGAD, r_FIAD, r_CtrlData, NValid_stat, Busy_stat, 
                      LinkFail, r_MAC, WCtrlDataStart, RStatStart,
                      UpdateMIIRX_DATAReg, Prsd, r_RxBDAddress, RX_BD_ADR_Wr 
                    );

parameter Tp = 1;

input [31:0] DataIn;
input [5:0] Address;

input Rw;
input Cs;
input Clk;
input Reset;

input WCtrlDataStart;
input RStatStart;

input UpdateMIIRX_DATAReg;
input [15:0] Prsd;

output [31:0] DataOut;
reg    [31:0] DataOut;

output r_DmaEn;
output r_RecSmall;
output r_Pad;
output r_HugEn;
output r_CrcEn;
output r_DlyCrcEn;
output r_Rst;
output r_FullD;
output r_ExDfrEn;
output r_NoBckof;
output r_LoopBck;
output r_IFG;
output r_Pro;
output r_Iam;
output r_Bro;
output r_NoPre;
output r_TxEn;
output r_RxEn;

output Busy_IRQ;
output RxF_IRQ;
output RxB_IRQ;
output TxE_IRQ;
output TxB_IRQ;

output Busy_MASK;
output RxF_MASK;
output RxB_MASK;
output TxE_MASK;
output TxB_MASK;

output [6:0] r_IPGT;

output [6:0] r_IPGR1;

output [6:0] r_IPGR2;

output [15:0] r_MinFL;
output [15:0] r_MaxFL;

output [3:0] r_MaxRet;
output [5:0] r_CollValid;

output r_TxFlow;
output r_RxFlow;
output r_PassAll;

output r_MiiMRst;
output r_MiiNoPre;
output [7:0] r_ClkDiv;

output r_WCtrlData;
output r_RStat;
output r_ScanStat;

output [4:0] r_RGAD;
output [4:0] r_FIAD;

output [15:0] r_CtrlData;


input NValid_stat;
input Busy_stat;
input LinkFail;

output [47:0] r_MAC;

output [7:0] r_RxBDAddress;

output       RX_BD_ADR_Wr;



wire Write = Cs &  Rw;
wire Read  = Cs & ~Rw;

wire MODER_Wr       = (Address == `ETH_MODER_ADR)       & Write;
wire INT_SOURCE_Wr  = (Address == `ETH_INT_SOURCE_ADR)  & Write;
wire INT_MASK_Wr    = (Address == `ETH_INT_MASK_ADR)    & Write;
wire IPGT_Wr        = (Address == `ETH_IPGT_ADR)        & Write;
wire IPGR1_Wr       = (Address == `ETH_IPGR1_ADR)       & Write;
wire IPGR2_Wr       = (Address == `ETH_IPGR2_ADR)       & Write;
wire PACKETLEN_Wr   = (Address == `ETH_PACKETLEN_ADR)   & Write;
wire COLLCONF_Wr    = (Address == `ETH_COLLCONF_ADR)    & Write;

wire CTRLMODER_Wr   = (Address == `ETH_CTRLMODER_ADR)   & Write;
wire MIIMODER_Wr    = (Address == `ETH_MIIMODER_ADR)    & Write;
wire MIICOMMAND_Wr  = (Address == `ETH_MIICOMMAND_ADR)  & Write;
wire MIIADDRESS_Wr  = (Address == `ETH_MIIADDRESS_ADR)  & Write;
wire MIITX_DATA_Wr  = (Address == `ETH_MIITX_DATA_ADR)  & Write;
wire MIIRX_DATA_Wr  = UpdateMIIRX_DATAReg;
wire MIISTATUS_Wr   = (Address == `ETH_MIISTATUS_ADR)   & Write;
wire MAC_ADDR0_Wr   = (Address == `ETH_MAC_ADDR0_ADR)   & Write;
wire MAC_ADDR1_Wr   = (Address == `ETH_MAC_ADDR1_ADR)   & Write;
assign RX_BD_ADR_Wr = (Address == `ETH_RX_BD_ADR_ADR)   & Write;



wire [31:0] MODEROut;
wire [31:0] INT_SOURCEOut;
wire [31:0] INT_MASKOut;
wire [31:0] IPGTOut;
wire [31:0] IPGR1Out;
wire [31:0] IPGR2Out;
wire [31:0] PACKETLENOut;
wire [31:0] COLLCONFOut;
wire [31:0] CTRLMODEROut;
wire [31:0] MIIMODEROut;
wire [31:0] MIICOMMANDOut;
wire [31:0] MIIADDRESSOut;
wire [31:0] MIITX_DATAOut;
wire [31:0] MIIRX_DATAOut;
wire [31:0] MIISTATUSOut;
wire [31:0] MAC_ADDR0Out;
wire [31:0] MAC_ADDR1Out;
wire [31:0] RX_BD_ADROut;

eth_register #(32) MODER       (.DataIn(DataIn), .DataOut(MODEROut),      .Write(MODER_Wr),      .Clk(Clk), .Reset(Reset), .Default(`ETH_MODER_DEF));
eth_register #(32) INT_SOURCE  (.DataIn(DataIn), .DataOut(INT_SOURCEOut), .Write(INT_SOURCE_Wr), .Clk(Clk), .Reset(Reset), .Default(`ETH_INT_SOURCE_DEF));
eth_register #(32) INT_MASK    (.DataIn(DataIn), .DataOut(INT_MASKOut),   .Write(INT_MASK_Wr),   .Clk(Clk), .Reset(Reset), .Default(`ETH_INT_MASK_DEF));
eth_register #(32) IPGT        (.DataIn(DataIn), .DataOut(IPGTOut),       .Write(IPGT_Wr),       .Clk(Clk), .Reset(Reset), .Default(`ETH_IPGT_DEF));
eth_register #(32) IPGR1       (.DataIn(DataIn), .DataOut(IPGR1Out),      .Write(IPGR1_Wr),      .Clk(Clk), .Reset(Reset), .Default(`ETH_IPGR1_DEF));
eth_register #(32) IPGR2       (.DataIn(DataIn), .DataOut(IPGR2Out),      .Write(IPGR2_Wr),      .Clk(Clk), .Reset(Reset), .Default(`ETH_IPGR2_DEF));
eth_register #(32) PACKETLEN   (.DataIn(DataIn), .DataOut(PACKETLENOut),  .Write(PACKETLEN_Wr),  .Clk(Clk), .Reset(Reset), .Default(`ETH_PACKETLEN_DEF));
eth_register #(32) COLLCONF    (.DataIn(DataIn), .DataOut(COLLCONFOut),   .Write(COLLCONF_Wr),   .Clk(Clk), .Reset(Reset), .Default(`ETH_COLLCONF_DEF));

// CTRLMODER registers
wire [31:0] DefaultCtrlModer = `ETH_CTRLMODER_DEF;
assign CTRLMODEROut[31:3] = 29'h0;
eth_register #(3)  CTRLMODER2  (.DataIn(DataIn[2:0]),   .DataOut(CTRLMODEROut[2:0]),   .Write(CTRLMODER_Wr),  .Clk(Clk), .Reset(Reset), .Default(DefaultCtrlModer[2:0]));
// End: CTRLMODER registers





eth_register #(32) MIIMODER    (.DataIn(DataIn), .DataOut(MIIMODEROut),   .Write(MIIMODER_Wr),   .Clk(Clk), .Reset(Reset), .Default(`ETH_MIIMODER_DEF));

assign MIICOMMANDOut[31:3] = 29'h0;
eth_register #(1) MIICOMMAND2  (.DataIn(DataIn[2]), .DataOut(MIICOMMANDOut[2]), .Write(MIICOMMAND_Wr), .Clk(Clk), .Reset(Reset | WCtrlDataStart), .Default(1'b0));
eth_register #(1) MIICOMMAND1  (.DataIn(DataIn[1]), .DataOut(MIICOMMANDOut[1]), .Write(MIICOMMAND_Wr), .Clk(Clk), .Reset(Reset | RStatStart), .Default(1'b0));
eth_register #(1) MIICOMMAND0  (.DataIn(DataIn[0]), .DataOut(MIICOMMANDOut[0]), .Write(MIICOMMAND_Wr), .Clk(Clk), .Reset(Reset), .Default(1'b0));

eth_register #(32) MIIADDRESS  (.DataIn(DataIn), .DataOut(MIIADDRESSOut), .Write(MIIADDRESS_Wr), .Clk(Clk), .Reset(Reset), .Default(`ETH_MIIADDRESS_DEF));
eth_register #(32) MIITX_DATA  (.DataIn(DataIn), .DataOut(MIITX_DATAOut), .Write(MIITX_DATA_Wr), .Clk(Clk), .Reset(Reset), .Default(`ETH_MIITX_DATA_DEF));
eth_register #(32) MIIRX_DATA  (.DataIn({16'h0, Prsd}),   .DataOut(MIIRX_DATAOut), .Write(MIIRX_DATA_Wr), .Clk(Clk), .Reset(Reset), .Default(`ETH_MIIRX_DATA_DEF));
//eth_register #(32) MIISTATUS   (.DataIn(DataIn), .DataOut(MIISTATUSOut),  .Write(MIISTATUS_Wr),  .Clk(Clk), .Reset(Reset), .Default(`ETH_MIISTATUS_DEF));
eth_register #(32) MAC_ADDR0   (.DataIn(DataIn), .DataOut(MAC_ADDR0Out),  .Write(MAC_ADDR0_Wr),  .Clk(Clk), .Reset(Reset), .Default(`ETH_MAC_ADDR0_DEF));
eth_register #(32) MAC_ADDR1   (.DataIn(DataIn), .DataOut(MAC_ADDR1Out),  .Write(MAC_ADDR1_Wr),  .Clk(Clk), .Reset(Reset), .Default(`ETH_MAC_ADDR1_DEF));

assign RX_BD_ADROut[31:8] = 24'h0;
eth_register #(8) RX_BD_ADR   (.DataIn(DataIn[7:0]), .DataOut(RX_BD_ADROut[7:0]), .Write(RX_BD_ADR_Wr),  .Clk(Clk), .Reset(Reset), .Default(`ETH_RX_BD_ADR_DEF));


reg LinkFailRegister;
wire ResetLinkFailRegister = Address == `ETH_MIISTATUS_ADR & Read;
reg ResetLinkFailRegister_q1;
reg ResetLinkFailRegister_q2;

always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      LinkFailRegister <= #Tp 0;
      ResetLinkFailRegister_q1 <= #Tp 0;
      ResetLinkFailRegister_q2 <= #Tp 0;
    end
  else
    begin
      ResetLinkFailRegister_q1 <= #Tp ResetLinkFailRegister;
      ResetLinkFailRegister_q2 <= #Tp ResetLinkFailRegister_q1;
      if(LinkFail)
        LinkFailRegister <= #Tp 1;
      if(~ResetLinkFailRegister_q1 & ResetLinkFailRegister_q2)
        LinkFailRegister <= #Tp 0;    
    end
end


always @ (Address or Read or MODEROut or INT_SOURCEOut or INT_MASKOut or IPGTOut or 
          IPGR1Out or IPGR2Out or PACKETLENOut or COLLCONFOut or CTRLMODEROut or 
          MIIMODEROut or MIICOMMANDOut or MIIADDRESSOut or MIITX_DATAOut or 
          MIIRX_DATAOut or MIISTATUSOut or MAC_ADDR0Out or MAC_ADDR1Out or 
          RX_BD_ADROut)
begin
  if(Read)  // read
    begin
      case(Address)
        `ETH_MODER_ADR        :  DataOut<=MODEROut;
        `ETH_INT_SOURCE_ADR   :  DataOut<=INT_SOURCEOut;
        `ETH_INT_MASK_ADR     :  DataOut<=INT_MASKOut;
        `ETH_IPGT_ADR         :  DataOut<=IPGTOut;
        `ETH_IPGR1_ADR        :  DataOut<=IPGR1Out;
        `ETH_IPGR2_ADR        :  DataOut<=IPGR2Out;
        `ETH_PACKETLEN_ADR    :  DataOut<=PACKETLENOut;
        `ETH_COLLCONF_ADR     :  DataOut<=COLLCONFOut;
        `ETH_CTRLMODER_ADR    :  DataOut<=CTRLMODEROut;
        `ETH_MIIMODER_ADR     :  DataOut<=MIIMODEROut;
        `ETH_MIICOMMAND_ADR   :  DataOut<=MIICOMMANDOut;
        `ETH_MIIADDRESS_ADR   :  DataOut<=MIIADDRESSOut;
        `ETH_MIITX_DATA_ADR   :  DataOut<=MIITX_DATAOut;
        `ETH_MIIRX_DATA_ADR   :  DataOut<=MIIRX_DATAOut;
        `ETH_MIISTATUS_ADR    :  DataOut<=MIISTATUSOut;
        `ETH_MAC_ADDR0_ADR    :  DataOut<=MAC_ADDR0Out;
        `ETH_MAC_ADDR1_ADR    :  DataOut<=MAC_ADDR1Out;
        `ETH_RX_BD_ADR_ADR    :  DataOut<=RX_BD_ADROut;
        default:             DataOut<=32'h0;
      endcase
    end
  else
    DataOut<=32'h0;
end


assign r_DmaEn            = MODEROut[17];
assign r_RecSmall         = MODEROut[16];
assign r_Pad              = MODEROut[15];
assign r_HugEn            = MODEROut[14];
assign r_CrcEn            = MODEROut[13];
assign r_DlyCrcEn         = MODEROut[12];
assign r_Rst              = MODEROut[11];
assign r_FullD            = MODEROut[10];
assign r_ExDfrEn          = MODEROut[9];
assign r_NoBckof          = MODEROut[8];
assign r_LoopBck          = MODEROut[7];
assign r_IFG              = MODEROut[6];
assign r_Pro              = MODEROut[5];
assign r_Iam              = MODEROut[4];
assign r_Bro              = MODEROut[3];
assign r_NoPre            = MODEROut[2];
assign r_TxEn             = MODEROut[1];
assign r_RxEn             = MODEROut[0];

assign Busy_IRQ           = INT_SOURCEOut[4];
assign RxF_IRQ            = INT_SOURCEOut[3];
assign RxB_IRQ            = INT_SOURCEOut[2];
assign TxE_IRQ            = INT_SOURCEOut[1];
assign TxB_IRQ            = INT_SOURCEOut[0];

assign Busy_MASK          = INT_MASKOut[4];
assign RxF_MASK           = INT_MASKOut[3];
assign RxB_MASK           = INT_MASKOut[2];
assign TxE_MASK           = INT_MASKOut[1];
assign TxB_MASK           = INT_MASKOut[0];

assign r_IPGT[6:0]        = IPGTOut[6:0];

assign r_IPGR1[6:0]       = IPGR1Out[6:0];

assign r_IPGR2[6:0]       = IPGR2Out[6:0];

assign r_MinFL[15:0]      = PACKETLENOut[31:16];
assign r_MaxFL[15:0]      = PACKETLENOut[15:0];

assign r_MaxRet[3:0]     = COLLCONFOut[19:16];
assign r_CollValid[5:0]  = COLLCONFOut[5:0];

assign r_TxFlow           = CTRLMODEROut[2];
assign r_RxFlow           = CTRLMODEROut[1];
assign r_PassAll          = CTRLMODEROut[0];

assign r_MiiMRst          = MIIMODEROut[10];
assign r_MiiNoPre         = MIIMODEROut[8];
assign r_ClkDiv[7:0]      = MIIMODEROut[7:0];

assign r_WCtrlData        = MIICOMMANDOut[2];
assign r_RStat            = MIICOMMANDOut[1];
assign r_ScanStat         = MIICOMMANDOut[0];

assign r_RGAD[4:0]        = MIIADDRESSOut[12:8];
assign r_FIAD[4:0]        = MIIADDRESSOut[4:0];

assign r_CtrlData[15:0]   = MIITX_DATAOut[15:0];

assign MIISTATUSOut[31:10] = 22'h0           ; 
assign MIISTATUSOut[9]  = NValid_stat        ; 
assign MIISTATUSOut[8]  = Busy_stat          ; 
assign MIISTATUSOut[7:3]= 5'h0               ; 
assign MIISTATUSOut[2]  = 1'b0;
assign MIISTATUSOut[1]  = 1'b0;
assign MIISTATUSOut[0]  = LinkFailRegister   ; 

assign r_MAC[31:0]        = MAC_ADDR0Out[31:0];
assign r_MAC[47:32]       = MAC_ADDR1Out[15:0];

assign r_RxBDAddress[7:0] = RX_BD_ADROut[7:0];


endmodule
