//////////////////////////////////////////////////////////////////////
////                                                              ////
////  outputcontrol.v                                             ////
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
// Revision 1.3  2001/06/01 22:28:56  mohor
// This files (MIIM) are fully working. They were thoroughly tested. The testbench is not updated.
//
//

`timescale 1ns / 1ns

module outputcontrol(Clk, Reset, InProgress, ShiftedBit, BitCounter, WriteOp, NoPre, MdcEn_n, Mdo, MdoEn);

parameter Tp = 1;

input         Clk;                // Host Clock
input         Reset;              // General Reset
input         WriteOp;            // Write Operation Latch (When asserted, write operation is in progress)
input         NoPre;              // No Preamble (no 32-bit preamble)
input         InProgress;         // Operation in progress
input         ShiftedBit;         // This bit is output of the shift register and is connected to the Mdo signal
input   [6:0] BitCounter;         // Bit Counter
input         MdcEn_n;            // MII Management Data Clock Enable signal is asserted for one Clk period before Mdc falls.

output        Mdo;                // MII Management Data Output
output        MdoEn;              // MII Management Data Output Enable

wire          SerialEn;

reg           MdoEn_2d;
reg           MdoEn_d;
reg           MdoEn;

reg           Mdo_2d;
reg           Mdo_d;
reg           Mdo;                // MII Management Data Output



// Generation of the Serial Enable signal (enables the serialization of the data)
assign SerialEn =  WriteOp & InProgress & ( BitCounter>31 | ( ( BitCounter == 0 ) & NoPre ) )
                | ~WriteOp & InProgress & (( BitCounter>31 & BitCounter<46 ) | ( ( BitCounter == 0 ) & NoPre )); // igor !!!  ali je tu res <46. To je veljalo, ko sem imel se >31 in napako 32 preamble bitov


// Generation of the MdoEn signal
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      MdoEn_2d <= #Tp 1'b0;
      MdoEn_d <= #Tp 1'b0;
      MdoEn <= #Tp 1'b0;
    end
  else
    begin
      if(MdcEn_n)
        begin
          MdoEn_2d <= #Tp SerialEn | InProgress & BitCounter<32;
          MdoEn_d <= #Tp MdoEn_2d;
          MdoEn <= #Tp MdoEn_d;
        end
    end
end


// Generation of the Mdo signal.
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      Mdo_2d <= #Tp 1'b0;
      Mdo_d <= #Tp 1'b0;
      Mdo <= #Tp 1'b0;
    end
  else
    begin
      if(MdcEn_n)
        begin
          Mdo_2d <= #Tp ~SerialEn & BitCounter<32;
          Mdo_d <= #Tp ShiftedBit | Mdo_2d;
          Mdo <= #Tp Mdo_d;
        end
    end
end



endmodule
