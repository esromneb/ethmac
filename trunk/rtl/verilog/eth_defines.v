//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_defines.v                                               ////
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
// Revision 1.1  2001/07/30 21:23:42  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//


`define ETH_FPGA                      // Core is going to be implemented in FPGA and contains FPGA specific elements
                                      // Should be cleared for the ASIC implementation


// Address is {`ETHERNET_SPACE, REG_SPACE, 12'hx}
`define ETH_ETHERNET_SPACE 16'hf000   // Ethernet space is allocated from 0xF0000000 to 0xF000FFFF
`define ETH_REG_SPACE         4'h0    // Register space is allocated to 0xF0000000
`define ETH_BD_SPACE          4'h1    // Buffer descriptor space is allocated to 0xF0001000
`define ETH_TX_DATA           4'h2    // Tx data is written to address 0xF0002000. Since DMA is used, TX_DATA is not used in equations.
`define ETH_RX_DATA           4'h3    // Rx data is read from address 0xF0003000. Since DMA is used, RX_DATA is not used in equations.


`define ETH_PACKET_SEND_ADR   32'h20  // Packet for TX are written to the address 0x20

`define ETH_MODER_ADR         6'h0
`define ETH_INT_SOURCE_ADR    6'h1
`define ETH_INT_MASK_ADR      6'h2
`define ETH_IPGT_ADR          6'h3
`define ETH_IPGR1_ADR         6'h4
`define ETH_IPGR2_ADR         6'h5
`define ETH_PACKETLEN_ADR     6'h6
`define ETH_COLLCONF_ADR      6'h7
`define ETH_RX_BD_ADR_ADR     6'h8
`define ETH_CTRLMODER_ADR     6'hA
`define ETH_MIIMODER_ADR      6'hB
`define ETH_MIICOMMAND_ADR    6'hC
`define ETH_MIIADDRESS_ADR    6'hD
`define ETH_MIITX_DATA_ADR    6'hE
`define ETH_MIIRX_DATA_ADR    6'hF
`define ETH_MIISTATUS_ADR     6'h10
`define ETH_MAC_ADDR0_ADR     6'h11
`define ETH_MAC_ADDR1_ADR     6'h12



`define ETH_MODER_DEF         32'h0000A000
`define ETH_INT_SOURCE_DEF    32'h00000000
`define ETH_INT_MASK_DEF      32'h00000000
`define ETH_IPGT_DEF          32'h00000012
`define ETH_IPGR1_DEF         32'h0000000C
`define ETH_IPGR2_DEF         32'h00000012
`define ETH_PACKETLEN_DEF     32'h003C0600
`define ETH_COLLCONF_DEF      32'h000F0040
`define ETH_CTRLMODER_DEF     32'h00000000
`define ETH_MIIMODER_DEF      32'h00000064
`define ETH_MIICOMMAND_DEF    32'h00000000
`define ETH_MIIADDRESS_DEF    32'h00000000
`define ETH_MIITX_DATA_DEF    32'h00000000
`define ETH_MIIRX_DATA_DEF    32'h00000000
`define ETH_MIISTATUS_DEF     32'h00000000
`define ETH_MAC_ADDR0_DEF     32'h00000000
`define ETH_MAC_ADDR1_DEF     32'h00000000

`define ETH_RX_BD_ADR_DEF     8'h0
