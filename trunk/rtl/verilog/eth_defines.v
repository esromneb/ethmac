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
// Revision 1.1  2001/07/30 21:23:42  mohor
// Directory structure changed. Files checked and joind together.
//
//
//
//
//


`define FPGA                        // Core is going to be implemented in FPGA and contains FPGA specific elements
                                    // Should be cleared for the ASIC implementation


// Address is {`ETHERNET_SPACE, REG_SPACE, 12'hx}
`define ETHERNET_SPACE    16'hf000  // Ethernet space is allocated from 0xF0000000 to 0xF000FFFF
`define REG_SPACE         4'h0      // Register space is allocated to 0xF0000000
`define BD_SPACE          4'h1      // Buffer descriptor space is allocated to 0xF0001000
`define TX_DATA           4'h2      // Tx data is written to address 0xF0002000. Since DMA is used, TX_DATA is not used in equations.
`define RX_DATA           4'h3      // Rx data is read from address 0xF0003000. Since DMA is used, RX_DATA is not used in equations.


`define PACKET_SEND_ADR   32'h20   // Packet for TX are written to the address 0x20

`define MODER_ADR         6'h0
`define INT_SOURCE_ADR    6'h1
`define INT_MASK_ADR      6'h2
`define IPGT_ADR          6'h3
`define IPGR1_ADR         6'h4
`define IPGR2_ADR         6'h5
`define PACKETLEN_ADR     6'h6
`define COLLCONF_ADR      6'h7
`define RX_BD_ADR_ADR     6'h8
`define CTRLMODER_ADR     6'hA
`define MIIMODER_ADR      6'hB
`define MIICOMMAND_ADR    6'hC
`define MIIADDRESS_ADR    6'hD
`define MIITX_DATA_ADR    6'hE
`define MIIRX_DATA_ADR    6'hF
`define MIISTATUS_ADR     6'h10
`define MAC_ADDR0_ADR     6'h11
`define MAC_ADDR1_ADR     6'h12



`define MODER_DEF         32'h0000A000
`define INT_SOURCE_DEF    32'h00000000
`define INT_MASK_DEF      32'h00000000
`define IPGT_DEF          32'h00000012
`define IPGR1_DEF         32'h0000000C
`define IPGR2_DEF         32'h00000012
`define PACKETLEN_DEF     32'h003C0600
`define COLLCONF_DEF      32'h000F0040
`define CTRLMODER_DEF     32'h00000000
`define MIIMODER_DEF      32'h00000064
`define MIICOMMAND_DEF    32'h00000000
`define MIIADDRESS_DEF    32'h00000000
`define MIITX_DATA_DEF    32'h00000000
`define MIIRX_DATA_DEF    32'h00000000
`define MIISTATUS_DEF     32'h00000000
`define MAC_ADDR0_DEF     32'h00000000
`define MAC_ADDR1_DEF     32'h00000000

`define RX_BD_ADR_DEF     8'h0
