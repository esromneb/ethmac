//////////////////////////////////////////////////////////////////////
////                                                              ////
////  tb_ethernet.v                                               ////
////                                                              ////
////  This file is part of the Ethernet IP core project           ////
////  http://www.opencores.org/projects/ethmac/                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Tadej Markovic, tadej@opencores.org                   ////
////      - Igor Mohor,     igormM@opencores.org                  ////
////                                                              ////
////  All additional information is available in the Readme.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001, 2002 Authors                             ////
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
// Revision 1.13  2002/09/16 17:53:49  tadej
// Full duplex test improved.
//
// Revision 1.12  2002/09/16 15:10:42  mohor
// MIIM test look better.
//
// Revision 1.11  2002/09/13 19:18:04  mohor
// Bench outputs data to display every 128 bytes.
//
// Revision 1.10  2002/09/13 18:44:29  mohor
// Beautiful tests merget together
//
// Revision 1.9  2002/09/13 18:41:45  mohor
// Rearanged testcases
//
// Revision 1.8  2002/09/13 14:50:15  mohor
// Bug in MIIM fixed.
//
// Revision 1.7  2002/09/13 12:29:14  mohor
// Headers changed.
//
// Revision 1.6  2002/09/13 11:57:20  mohor
// New testbench. Thanks to Tadej M - "The Spammer".
//
// Revision 1.2  2002/07/19 14:02:47  mohor
// Clock mrx_clk set to 2.5 MHz.
//
// Revision 1.1  2002/07/19 13:57:53  mohor
// Testing environment also includes traffic cop, memory interface and host
// interface.
//
//
//
//
//


`include "eth_phy_defines.v"
`include "wb_model_defines.v"
`include "tb_eth_defines.v"
`include "eth_defines.v"
`include "timescale.v"

module tb_ethernet();


reg           wb_clk;
reg           wb_rst;
wire          wb_int;

wire          mtx_clk;  // This goes to PHY
wire          mrx_clk;  // This goes to PHY

wire   [3:0]  MTxD;
wire          MTxEn;
wire          MTxErr;

wire   [3:0]  MRxD;     // This goes to PHY
wire          MRxDV;    // This goes to PHY
wire          MRxErr;   // This goes to PHY
wire          MColl;    // This goes to PHY
wire          MCrs;     // This goes to PHY

wire          Mdi_I;
wire          Mdo_O;
wire          Mdo_OE;
tri           Mdio_IO;
wire          Mdc_O;


parameter Tp = 1;


// Ethernet Slave Interface signals
wire [31:0] eth_sl_wb_adr;
wire [31:0] eth_sl_wb_adr_i, eth_sl_wb_dat_o, eth_sl_wb_dat_i;
wire  [3:0] eth_sl_wb_sel_i;
wire        eth_sl_wb_we_i, eth_sl_wb_cyc_i, eth_sl_wb_stb_i, eth_sl_wb_ack_o, eth_sl_wb_err_o;

// Ethernet Master Interface signals
wire [31:0] eth_ma_wb_adr_o, eth_ma_wb_dat_i, eth_ma_wb_dat_o;
wire  [3:0] eth_ma_wb_sel_o;
wire        eth_ma_wb_we_o, eth_ma_wb_cyc_o, eth_ma_wb_stb_o, eth_ma_wb_ack_i, eth_ma_wb_err_i;




// Connecting Ethernet top module
eth_top eth_top
(
  // WISHBONE common
  .wb_clk_i(wb_clk),              .wb_rst_i(wb_rst), 

  // WISHBONE slave
  .wb_adr_i(eth_sl_wb_adr_i[11:2]), .wb_sel_i(eth_sl_wb_sel_i),   .wb_we_i(eth_sl_wb_we_i), 
  .wb_cyc_i(eth_sl_wb_cyc_i),       .wb_stb_i(eth_sl_wb_stb_i),   .wb_ack_o(eth_sl_wb_ack_o), 
  .wb_err_o(eth_sl_wb_err_o),       .wb_dat_i(eth_sl_wb_dat_i),   .wb_dat_o(eth_sl_wb_dat_o), 
 	
  // WISHBONE master
  .m_wb_adr_o(eth_ma_wb_adr_o),     .m_wb_sel_o(eth_ma_wb_sel_o), .m_wb_we_o(eth_ma_wb_we_o), 
  .m_wb_dat_i(eth_ma_wb_dat_i),     .m_wb_dat_o(eth_ma_wb_dat_o), .m_wb_cyc_o(eth_ma_wb_cyc_o), 
  .m_wb_stb_o(eth_ma_wb_stb_o),     .m_wb_ack_i(eth_ma_wb_ack_i), .m_wb_err_i(eth_ma_wb_err_i), 

  //TX
  .mtx_clk_pad_i(mtx_clk), .mtxd_pad_o(MTxD), .mtxen_pad_o(MTxEn), .mtxerr_pad_o(MTxErr),

  //RX
  .mrx_clk_pad_i(mrx_clk), .mrxd_pad_i(MRxD), .mrxdv_pad_i(MRxDV), .mrxerr_pad_i(MRxErr), 
  .mcoll_pad_i(MColl),    .mcrs_pad_i(MCrs), 
  
  // MIIM
  .mdc_pad_o(Mdc_O), .md_pad_i(Mdi_I), .md_pad_o(Mdo_O), .md_padoe_o(Mdo_OE),
  
  .int_o(wb_int)
);



// Connecting Ethernet PHY Module
assign Mdio_IO = Mdo_OE ? Mdo_O : 1'bz ;
assign Mdi_I   = Mdio_IO;
integer phy_log_file_desc;

eth_phy eth_phy
(
  // WISHBONE reset
  .m_rst_n_i(!wb_rst),

  // MAC TX
  .mtx_clk_o(mtx_clk),    .mtxd_i(MTxD),    .mtxen_i(MTxEn),    .mtxerr_i(MTxErr),

  // MAC RX
  .mrx_clk_o(mrx_clk),    .mrxd_o(MRxD),    .mrxdv_o(MRxDV),    .mrxerr_o(MRxErr),
  .mcoll_o(MColl),        .mcrs_o(MCrs),

  // MIIM
  .mdc_i(Mdc_O),          .md_io(Mdio_IO),

  // SYSTEM
  .phy_log(phy_log_file_desc)
);



// Connecting WB Master as Host Interface
integer host_log_file_desc;

WB_MASTER_BEHAVIORAL wb_master
(
    .CLK_I(wb_clk),
    .RST_I(wb_rst),
    .TAG_I({`WB_TAG_WIDTH{1'b0}}),
    .TAG_O(),
    .ACK_I(eth_sl_wb_ack_o),
    .ADR_O(eth_sl_wb_adr), // only eth_sl_wb_adr_i[11:2] used
    .CYC_O(eth_sl_wb_cyc_i),
    .DAT_I(eth_sl_wb_dat_o),
    .DAT_O(eth_sl_wb_dat_i),
    .ERR_I(eth_sl_wb_err_o),
    .RTY_I(1'b0),  // inactive (1'b0)
    .SEL_O(eth_sl_wb_sel_i),
    .STB_O(eth_sl_wb_stb_i),
    .WE_O (eth_sl_wb_we_i),
    .CAB_O()       // NOT USED for now!
);

assign eth_sl_wb_adr_i = {20'h0, eth_sl_wb_adr[11:2], 2'h0};



// Connecting WB Slave as Memory Interface Module
integer memory_log_file_desc;

WB_SLAVE_BEHAVIORAL wb_slave
(
    .CLK_I(wb_clk),
    .RST_I(wb_rst),
    .ACK_O(eth_ma_wb_ack_i),
    .ADR_I(eth_ma_wb_adr_o),
    .CYC_I(eth_ma_wb_cyc_o),
    .DAT_O(eth_ma_wb_dat_i),
    .DAT_I(eth_ma_wb_dat_o),
    .ERR_O(eth_ma_wb_err_i),
    .RTY_O(),      // NOT USED for now!
    .SEL_I(eth_ma_wb_sel_o),
    .STB_I(eth_ma_wb_stb_o),
    .WE_I (eth_ma_wb_we_o),
    .CAB_I(1'b0)   // inactive (1'b0)
);



// Connecting WISHBONE Bus Monitors to ethernet master and slave interfaces
integer wb_s_mon_log_file_desc ;
integer wb_m_mon_log_file_desc ;

WB_BUS_MON wb_eth_slave_bus_mon
(
  // WISHBONE common
  .CLK_I(wb_clk),
  .RST_I(wb_rst),

  // WISHBONE slave
  .ACK_I(eth_sl_wb_ack_o),
  .ADDR_O({20'h0, eth_sl_wb_adr_i[11:2], 2'b0}),
  .CYC_O(eth_sl_wb_cyc_i),
  .DAT_I(eth_sl_wb_dat_o),
  .DAT_O(eth_sl_wb_dat_i),
  .ERR_I(eth_sl_wb_err_o),
  .RTY_I(1'b0),
  .SEL_O(eth_sl_wb_sel_i),
  .STB_O(eth_sl_wb_stb_i),
  .WE_O (eth_sl_wb_we_i),
  .TAG_I({`WB_TAG_WIDTH{1'b0}}),
  .TAG_O(),
  .CAB_O(1'b0),
  .log_file_desc (wb_s_mon_log_file_desc)
);

WB_BUS_MON wb_eth_master_bus_mon
(
  // WISHBONE common
  .CLK_I(wb_clk),
  .RST_I(wb_rst),

  // WISHBONE master
  .ACK_I(eth_ma_wb_ack_i),
  .ADDR_O(eth_ma_wb_adr_o),
  .CYC_O(eth_ma_wb_cyc_o),
  .DAT_I(eth_ma_wb_dat_i),
  .DAT_O(eth_ma_wb_dat_o),
  .ERR_I(eth_ma_wb_err_i),
  .RTY_I(1'b0),
  .SEL_O(eth_ma_wb_sel_o),
  .STB_O(eth_ma_wb_stb_o),
  .WE_O (eth_ma_wb_we_o),
  .TAG_I({`WB_TAG_WIDTH{1'b0}}),
  .TAG_O(),
  .CAB_O(1'b0),
  .log_file_desc(wb_m_mon_log_file_desc)
);



reg         StartTB;
integer     tb_log_file;

initial
begin
  tb_log_file = $fopen("../log/eth_tb.log");
  if (tb_log_file < 2)
  begin
    $display("*E Could not open/create testbench log file in ../log/ directory!");
    $finish;
  end
  $fdisplay(tb_log_file, "========================== ETHERNET IP Core Testbench results ===========================");
  $fdisplay(tb_log_file, " ");

  phy_log_file_desc = $fopen("../log/eth_tb_phy.log");
  if (phy_log_file_desc < 2)
  begin
    $fdisplay(tb_log_file, "*E Could not open/create eth_tb_phy.log file in ../log/ directory!");
    $finish;
  end
  $fdisplay(phy_log_file_desc, "================ PHY Module  Testbench access log ================");
  $fdisplay(phy_log_file_desc, " ");

  memory_log_file_desc = $fopen("../log/eth_tb_memory.log");
  if (memory_log_file_desc < 2)
  begin
    $fdisplay(tb_log_file, "*E Could not open/create eth_tb_memory.log file in ../log/ directory!");
    $finish;
  end
  $fdisplay(memory_log_file_desc, "=============== MEMORY Module Testbench access log ===============");
  $fdisplay(memory_log_file_desc, " ");

  host_log_file_desc = $fopen("../log/eth_tb_host.log");
  if (host_log_file_desc < 2)
  begin
    $fdisplay(tb_log_file, "*E Could not open/create eth_tb_host.log file in ../log/ directory!");
    $finish;
  end
  $fdisplay(host_log_file_desc, "================ HOST Module Testbench access log ================");
  $fdisplay(host_log_file_desc, " ");

  wb_s_mon_log_file_desc = $fopen("../log/eth_tb_wb_s_mon.log");
  if (wb_s_mon_log_file_desc < 2)
  begin
    $fdisplay(tb_log_file, "*E Could not open/create eth_tb_wb_s_mon.log file in ../log/ directory!");
    $finish;
  end
  $fdisplay(wb_s_mon_log_file_desc, "============== WISHBONE Slave Bus Monitor error log ==============");
  $fdisplay(wb_s_mon_log_file_desc, " ");
  $fdisplay(wb_s_mon_log_file_desc, "   Only ERRONEOUS conditions are logged !");
  $fdisplay(wb_s_mon_log_file_desc, " ");

  wb_m_mon_log_file_desc = $fopen("../log/eth_tb_wb_m_mon.log");
  if (wb_m_mon_log_file_desc < 2)
  begin
    $fdisplay(tb_log_file, "*E Could not open/create eth_tb_wb_m_mon.log file in ../log/ directory!");
    $finish;
  end
  $fdisplay(wb_m_mon_log_file_desc, "============= WISHBONE Master Bus Monitor  error log =============");
  $fdisplay(wb_m_mon_log_file_desc, " ");
  $fdisplay(wb_m_mon_log_file_desc, "   Only ERRONEOUS conditions are logged !");
  $fdisplay(wb_m_mon_log_file_desc, " ");

  // Clear memories
  clear_memories;

  // Reset pulse
  wb_rst =  1'b1;
  #423 wb_rst =  1'b0;
  #423 StartTB  =  1'b1;
end



// Generating wb_clk clock
initial
begin
  wb_clk=0;
//  forever #2.5 wb_clk = ~wb_clk;  // 2*2.5 ns -> 200.0 MHz    
//  forever #5 wb_clk = ~wb_clk;  // 2*5 ns -> 100.0 MHz    
//  forever #10 wb_clk = ~wb_clk;  // 2*10 ns -> 50.0 MHz    
//  forever #12.5 wb_clk = ~wb_clk;  // 2*12.5 ns -> 40 MHz    
//  forever #15 wb_clk = ~wb_clk;  // 2*10 ns -> 33.3 MHz    
  forever #20 wb_clk = ~wb_clk;  // 2*20 ns -> 25 MHz    
//  forever #25 wb_clk = ~wb_clk;  // 2*25 ns -> 20.0 MHz
//  forever #31.25 wb_clk = ~wb_clk;  // 2*31.25 ns -> 16.0 MHz    
//  forever #50 wb_clk = ~wb_clk;  // 2*50 ns -> 10.0 MHz
//  forever #55 wb_clk = ~wb_clk;  // 2*55 ns ->  9.1 MHz    
end



integer      tests_successfull;
integer      tests_failed;
reg [799:0]  test_name; // used for tb_log_file

reg   [3:0]  wbm_init_waits; // initial wait cycles between CYC_O and STB_O of WB Master
reg   [3:0]  wbm_subseq_waits; // subsequent wait cycles between STB_Os of WB Master
reg   [2:0]  wbs_waits; // wait cycles befor WB Slave responds
reg   [7:0]  wbs_retries; // if RTY response, then this is the number of retries before ACK

initial
begin
  wait(StartTB);  // Start of testbench

  // Initial global values
  tests_successfull = 0;
  tests_failed = 0;

  wbm_init_waits = 4'h1;
  wbm_subseq_waits = 4'h3;
  wbs_waits = 4'h1;
  wbs_retries = 8'h2; 
  wb_slave.cycle_response(`ACK_RESPONSE, wbs_waits, wbs_retries);


  //  Call tests
  //  ----------
    test_access_to_mac_reg(0, 3);           // 0 - 3
    test_mii(0, 17);                        // 0 - 17
  test_note("PHY generates ideal Carrier sense and Collision signals for following tests");
  eth_phy.carrier_sense_real_delay(0);
    test_mac_full_duplex_transmit(0, 3);    // 0 - (3)

  test_note("PHY generates 'real' Carrier sense and Collision signals for following tests");
  eth_phy.carrier_sense_real_delay(1);


  // Finish test's logs
  test_summary;
  $display("\n\n END of SIMULATION");
  $fclose(tb_log_file | phy_log_file_desc | memory_log_file_desc | host_log_file_desc);
  $fclose(wb_s_mon_log_file_desc | wb_m_mon_log_file_desc);

  $stop;
end
  


//////////////////////////////////////////////////////////////
// Test tasks
//////////////////////////////////////////////////////////////

task test_access_to_mac_reg;
  input  [31:0]  start_task;
  input  [31:0]  end_task;
  integer        bit_start_1;
  integer        bit_end_1;
  integer        bit_start_2;
  integer        bit_end_2;
  integer        num_of_reg;
  integer        i_addr;
  integer        i_data;
  integer        i_length;
  integer        tmp_data;
  reg    [31:0]  tx_bd_num;
  reg    [((`MAX_BLK_SIZE * 32) - 1):0] burst_data;
  reg    [((`MAX_BLK_SIZE * 32) - 1):0] burst_tmp_data;
  integer        i;
  integer        i1;
  integer        i2;
  integer        i3;
  integer        fail;
  integer        test_num;
  reg    [31:0]  addr;
  reg    [31:0]  data;
  reg    [31:0]  data_max;
begin
// ACCESS TO MAC REGISTERS TEST
test_heading("ACCESS TO MAC REGISTERS TEST");
$display(" ");
$display("ACCESS TO MAC REGISTERS TEST");
fail = 0;

// reset MAC registers
hard_reset;
// reset MAC and MII LOGIC with soft reset
reset_mac;
reset_mii;


//////////////////////////////////////////////////////////////////////
////                                                              ////
////  test_access_to_mac_reg:                                     ////
////                                                              ////
////  0: Walking 1 with single cycles across MAC regs.            ////
////  1: Walking 1 with single cycles across MAC buffer descript. ////
////  2: Test max reg. values and reg. values after writing       ////
////     inverse reset values and hard reset of the MAC           ////
////  3: Test buffer desc. RAM preserving values after hard reset ////
////     of the MAC and resetting the logic                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
for (test_num=start_task; test_num <= end_task; test_num=test_num+1)
begin

  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Walking 1 with single cycles across MAC regs.             ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 0) // Walking 1 with single cycles across MAC regs.
    begin
      // TEST 'WALKING ONE' WITH SINGLE CYCLES ACROSS MAC REGISTERS ( VARIOUS BUS DELAYS )
      test_name   = "TEST 0: TEST 'WALKING ONE' WITH SINGLE CYCLES ACROSS MAC REGISTERS ( VARIOUS BUS DELAYS )";
      `TIME; $display("  TEST 0: TEST 'WALKING ONE' WITH SINGLE CYCLES ACROSS MAC REGISTERS ( VARIOUS BUS DELAYS )");
    
      data = 0;
      for (i = 0; i <= 4; i = i + 1) // for initial wait cycles on WB bus
        begin
          wbm_init_waits = i;
          wbm_subseq_waits = {$random} % 5; // it is not important for single accesses
          for (i_addr = 0; i_addr <= 32'h4C; i_addr = i_addr + 4) // register address
            begin
              addr = `ETH_BASE + i_addr;
              // set ranges of R/W bits
              case (addr)
                `ETH_MODER:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 16;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_INT: // READONLY - tested within INT test
                  begin
                    bit_start_1 = 32; // not used
                    bit_end_1   = 32; // not used
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_INT_MASK:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 6;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_IPGT:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 6;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_IPGR1:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 6;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_IPGR2:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 6;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_PACKETLEN:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 31;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_COLLCONF:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 5;
                    bit_start_2 = 16; 
                    bit_end_2   = 19; 
                  end
                `ETH_TX_BD_NUM: 
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 7;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_CTRLMODER:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 2;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_MIIMODER:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 9;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_MIICOMMAND: // "WRITEONLY" - tested within MIIM test - 3 LSBits are not written here!!!
                  begin
                    bit_start_1 = 32; // not used
                    bit_end_1   = 32; // not used
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_MIIADDRESS:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 4;
                    bit_start_2 = 8; 
                    bit_end_2   = 12;
                  end
                `ETH_MIITX_DATA:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 15;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_MIIRX_DATA: // READONLY - tested within MIIM test
                  begin
                    bit_start_1 = 32; // not used
                    bit_end_1   = 32; // not used
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_MIISTATUS: // READONLY - tested within MIIM test
                  begin
                    bit_start_1 = 32; // not used
                    bit_end_1   = 32; // not used
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_MAC_ADDR0:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 31;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                    end
                `ETH_MAC_ADDR1:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 15;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                `ETH_HASH_ADDR0:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 31;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
                default: // `ETH_HASH_ADDR1:
                  begin
                    bit_start_1 = 0;
                    bit_end_1   = 31;
                    bit_start_2 = 32; // not used
                    bit_end_2   = 32; // not used
                  end
              endcase
              
              for (i_data = 0; i_data <= 31; i_data = i_data + 1) // the position of walking one
                begin
                  data = 1'b1 << i_data;
                  if ( (addr == `ETH_MIICOMMAND) && (i_data <= 2) ) // DO NOT WRITE to 3 LSBits of MIICOMMAND !!!
                    ;
                  else
                    begin
                      wbm_write(addr, data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
                      wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
                      if ( ((i_data >= bit_start_1) && (i_data <= bit_end_1)) ||
                           ((i_data >= bit_start_2) && (i_data <= bit_end_2)) ) // data should be equal to tmp_data
                        begin
                          if (tmp_data !== data)
                          begin
                            fail = fail + 1;
                            test_fail("RW bit of the MAC register was not written or not read");
                            `TIME;
                            $display("wbm_init_waits %d, addr %h, data %h, tmp_data %h", 
                                      wbm_init_waits, addr, data, tmp_data);
                          end
                        end
                      else // data should not be equal to tmp_data
                        begin
                          if (tmp_data === data)
                            begin
                              fail = fail + 1;
                              test_fail("NON RW bit of the MAC register was written, but it shouldn't be");
                              `TIME;
                              $display("wbm_init_waits %d, addr %h, data %h, tmp_data %h",
                                        wbm_init_waits, addr, data, tmp_data);
                            end
                        end
                    end
                end
            end
        end
      
      if(fail == 0)
        test_ok;
      else
        fail = 0;    // Errors were reported previously
    end
        
        
        
  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Walking 1 with single cycles across MAC buffer descript.  ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 1) // Start Walking 1 with single cycles across MAC buffer descript.
  begin
    // TEST 'WALKING ONE' WITH SINGLE CYCLES ACROSS MAC BUFFER DESC. ( VARIOUS BUS DELAYS )
    test_name   = "TEST 1: TEST 'WALKING ONE' WITH SINGLE CYCLES ACROSS MAC BUFFER DESC. ( VARIOUS BUS DELAYS )";
    `TIME; $display("  TEST 1: TEST 'WALKING ONE' WITH SINGLE CYCLES ACROSS MAC BUFFER DESC. ( VARIOUS BUS DELAYS )");
        
    data = 0;
    // set TX and RX buffer descriptors
    tx_bd_num = 32'h40;
    wbm_write(`ETH_TX_BD_NUM, tx_bd_num, 4'hF, 1, 0, 0);
    for (i = 0; i <= 4; i = i + 1) // for initial wait cycles on WB bus
    begin
      wbm_init_waits = i;
      wbm_subseq_waits = {$random} % 5; // it is not important for single accesses
      for (i_addr = 32'h400; i_addr <= 32'h7FC; i_addr = i_addr + 4) // buffer descriptor address
      begin
        addr = `ETH_BASE + i_addr;
        if (i_addr < (32'h400 + (tx_bd_num << 3))) // TX buffer descriptors
        begin
          // set ranges of R/W bits
          case (addr[3])
            1'b0: // buffer control bits
            begin
              bit_start_1 = 0;
              bit_end_1   = 31; // 8;
              bit_start_2 = 11;
              bit_end_2   = 31;
            end
            default: // 1'b1: // buffer pointer
            begin
              bit_start_1 = 0;
              bit_end_1   = 31;
              bit_start_2 = 32; // not used
              bit_end_2   = 32; // not used
            end
          endcase
        end
        else // RX buffer descriptors
        begin
          // set ranges of R/W bits
          case (addr[3])
            1'b0: // buffer control bits
            begin
              bit_start_1 = 0;
              bit_end_1   = 31; // 7;
              bit_start_2 = 13;
              bit_end_2   = 31;
            end
            default: // 1'b1: // buffer pointer
            begin
              bit_start_1 = 0;
              bit_end_1   = 31;
              bit_start_2 = 32; // not used
              bit_end_2   = 32; // not used
            end
          endcase
        end
        
        for (i_data = 0; i_data <= 31; i_data = i_data + 1) // the position of walking one
        begin
          data = 1'b1 << i_data;
          if ( (addr[3] == 0) && (i_data == 15) ) // DO NOT WRITE to this bit !!!
            ;
          else
          begin
            wbm_write(addr, data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if ( ((i_data >= bit_start_1) && (i_data <= bit_end_1)) ||
                 ((i_data >= bit_start_2) && (i_data <= bit_end_2)) ) // data should be equal to tmp_data
            begin
              if (tmp_data !== data)
              begin
                fail = fail + 1;
                test_fail("RW bit of the MAC buffer descriptors was not written or not read");
                `TIME;
                $display("wbm_init_waits %d, addr %h, data %h, tmp_data %h", 
                          wbm_init_waits, addr, data, tmp_data);
              end
            end
            else // data should not be equal to tmp_data
            begin
              if (tmp_data === data)
              begin
                fail = fail + 1;
                test_fail("NON RW bit of the MAC buffer descriptors was written, but it shouldn't be");
                `TIME;
                $display("wbm_init_waits %d, addr %h, data %h, tmp_data %h",
                          wbm_init_waits, addr, data, tmp_data);
              end
            end
          end
        end
      end
      // INTERMEDIATE DISPLAYS
      case (i)
        0:       $display("    buffer descriptors tested with 0 bus delay");
        1:       $display("    buffer descriptors tested with 1 bus delay cycle");
        2:       $display("    buffer descriptors tested with 2 bus delay cycles");
        3:       $display("    buffer descriptors tested with 3 bus delay cycles");
        default: $display("    buffer descriptors tested with 4 bus delay cycles");
      endcase
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end
        
        
  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test max reg. values and reg. values after writing        ////
  ////  inverse reset values and hard reset of the MAC            ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 2) // Start this task
  begin
    // TEST MAX REG. VALUES AND REG. VALUES AFTER WRITING INVERSE RESET VALUES AND HARD RESET OF THE MAC
    test_name   = 
      "TEST 2: TEST MAX REG. VALUES AND REG. VALUES AFTER WRITING INVERSE RESET VALUES AND HARD RESET OF THE MAC";
    `TIME; $display(
      "  TEST 2: TEST MAX REG. VALUES AND REG. VALUES AFTER WRITING INVERSE RESET VALUES AND HARD RESET OF THE MAC");
        
    // reset MAC registers
    hard_reset;
    for (i = 0; i <= 4; i = i + 1) // 0, 2 - WRITE; 1, 3, 4 - READ
    begin
      for (i_addr = 0; i_addr <= 32'h4C; i_addr = i_addr + 4) // register address
      begin
        addr = `ETH_BASE + i_addr;
        // set ranges of R/W bits
        case (addr)
          `ETH_MODER:
          begin
            data = 32'h0000_A800;
            data_max = 32'h0001_FFFF;
          end
          `ETH_INT: // READONLY - tested within INT test
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_0000;
          end
          `ETH_INT_MASK:
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_007F;
          end
          `ETH_IPGT:
          begin
            data = 32'h0000_0012;
            data_max = 32'h0000_007F;
          end
          `ETH_IPGR1:
          begin
            data = 32'h0000_000C;
            data_max = 32'h0000_007F;
          end
          `ETH_IPGR2:
          begin
            data = 32'h0000_0012;
            data_max = 32'h0000_007F;
          end
          `ETH_PACKETLEN:
          begin
            data = 32'h0040_0600;
            data_max = 32'hFFFF_FFFF;
          end
          `ETH_COLLCONF:
          begin
            data = 32'h000F_003F;
            data_max = 32'h000F_003F;
          end
          `ETH_TX_BD_NUM: 
          begin
            data = 32'h0000_0040;
            data_max = 32'h0000_0080;
          end
          `ETH_CTRLMODER:
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_0007;
          end
          `ETH_MIIMODER:
          begin
            data = 32'h0000_0064;
            data_max = 32'h0000_03FF;
          end
          `ETH_MIICOMMAND: // "WRITEONLY" - tested within MIIM test - 3 LSBits are not written here!!!
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_0007;
          end
          `ETH_MIIADDRESS:
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_1F1F;
          end
          `ETH_MIITX_DATA:
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_FFFF;
          end
          `ETH_MIIRX_DATA: // READONLY - tested within MIIM test
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_0000;
          end
          `ETH_MIISTATUS: // READONLY - tested within MIIM test
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_0000;
          end
          `ETH_MAC_ADDR0:
          begin
            data = 32'h0000_0000;
            data_max = 32'hFFFF_FFFF;
          end
          `ETH_MAC_ADDR1:
          begin
            data = 32'h0000_0000;
            data_max = 32'h0000_FFFF;
          end
          `ETH_HASH_ADDR0:
          begin
            data = 32'h0000_0000;
            data_max = 32'hFFFF_FFFF;
          end
          default: // `ETH_HASH_ADDR1:
          begin
            data = 32'h0000_0000;
            data_max = 32'hFFFF_FFFF;
          end
        endcase
        
        wbm_init_waits = {$random} % 3;
        wbm_subseq_waits = {$random} % 5; // it is not important for single accesses
        if (i == 0)
          wbm_write(addr, ~data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        else if (i == 2)
          wbm_write(addr, 32'hFFFFFFFF, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        else if ((i == 1) || (i == 4))
        begin
          wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (tmp_data !== data)
          begin
            fail = fail + 1;
            test_fail("RESET value of the MAC register is not correct");
            `TIME;
            $display("  addr %h, data %h, tmp_data %h", addr, data, tmp_data);
          end
        end
        else // check maximum values
        begin
          wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (addr == `ETH_TX_BD_NUM) // previous data should remain in this register
          begin
            if (tmp_data !== data)
            begin
              fail = fail + 1;
              test_fail("Previous value of the TX_BD_NUM register did not remain");
              `TIME;
              $display("  addr %h, data_max %h, tmp_data %h", addr, data_max, tmp_data);
            end
            // try maximum (80)
            wbm_write(addr, data_max, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (tmp_data !== data_max)
            begin
              fail = fail + 1;
              test_fail("MAX value of the TX_BD_NUM register is not correct");
              `TIME;
              $display("  addr %h, data_max %h, tmp_data %h", addr, data_max, tmp_data);
            end
            // try one less than maximum (80)
            wbm_write(addr, (data_max - 1), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (tmp_data !== (data_max - 1))
            begin
              fail = fail + 1;
              test_fail("ONE less than MAX value of the TX_BD_NUM register is not correct");
              `TIME;
              $display("  addr %h, data_max %h, tmp_data %h", addr, data_max, tmp_data);
            end
            // try one more than maximum (80)
            wbm_write(addr, (data_max + 1), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (tmp_data !== (data_max - 1)) // previous data should remain in this register
            begin
              fail = fail + 1;
              test_fail("Previous value of the TX_BD_NUM register did not remain");
              `TIME;
              $display("  addr %h, data_max %h, tmp_data %h", addr, data_max, tmp_data);
            end
          end
          else
          begin
            if (tmp_data !== data_max)
            begin
              fail = fail + 1;
              test_fail("MAX value of the MAC register is not correct");
              `TIME;
              $display("  addr %h, data_max %h, tmp_data %h", addr, data_max, tmp_data);
            end
          end
        end
      end
      // reset MAC registers
      if ((i == 0) || (i == 3))
        hard_reset;
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test buffer desc. ram preserving values after hard reset  ////
  ////  of the mac and reseting the logic                         ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 3) // Start this task
  begin
    // TEST BUFFER DESC. RAM PRESERVING VALUES AFTER HARD RESET OF THE MAC AND RESETING THE LOGIC
    test_name   = "TEST 3: TEST BUFFER DESC. RAM PRESERVING VALUES AFTER HARD RESET OF THE MAC AND RESETING THE LOGIC";
    `TIME; 
    $display("  TEST 3: TEST BUFFER DESC. RAM PRESERVING VALUES AFTER HARD RESET OF THE MAC AND RESETING THE LOGIC");
        
    // reset MAC registers
    hard_reset;
    // reset LOGIC with soft reset
    reset_mac;
    reset_mii;
    for (i = 0; i <= 3; i = i + 1) // 0, 2 - WRITE; 1, 3 - READ
    begin
      for (i_addr = 32'h400; i_addr <= 32'h7FC; i_addr = i_addr + 4) // buffer descriptor address
      begin
        addr = `ETH_BASE + i_addr;
        
        wbm_init_waits = {$random} % 3;
        wbm_subseq_waits = {$random} % 5; // it is not important for single accesses
        if (i == 0)
        begin
          data = 32'hFFFFFFFF;
          wbm_write(addr, 32'hFFFFFFFF, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        end
        else if (i == 2)
        begin
          data = 32'h00000000;
          wbm_write(addr, 32'h00000000, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        end
        else
        begin
          wbm_read(addr, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (tmp_data !== data)
          begin
            fail = fail + 1;
            test_fail("PRESERVED value of the MAC buffer descriptors is not correct");
            `TIME;
            $display("  addr %h, data %h, tmp_data %h", addr, data, tmp_data);
          end
        end
      end
      if ((i == 0) || (i == 2))
      begin
        // reset MAC registers
        hard_reset;
        // reset LOGIC with soft reset
        reset_mac;
        reset_mii;
      end
    end
    if(fail == 0)
      test_ok;
    else
    fail = 0;
  end


  if (test_num == 4) // Start this task
  begin
        /*  // TEST 'WALKING ONE' WITH BURST CYCLES ACROSS MAC REGISTERS ( VARIOUS BUS DELAYS )
          test_name   = "TEST 4: TEST 'WALKING ONE' WITH BURST CYCLES ACROSS MAC REGISTERS ( VARIOUS BUS DELAYS )";
          `TIME; $display("  TEST 4: TEST 'WALKING ONE' WITH BURST CYCLES ACROSS MAC REGISTERS ( VARIOUS BUS DELAYS )");
        
          data = 0;
          burst_data = 0;
          burst_tmp_data = 0;
          i_length = 10; // two bursts for length 20
          for (i = 0; i <= 4; i = i + 1) // for initial wait cycles on WB bus
          begin
            for (i1 = 0; i1 <= 4; i1 = i1 + 1) // for initial wait cycles on WB bus
            begin
              wbm_init_waits = i;
              wbm_subseq_waits = i1; 
              #1;
              for (i_data = 0; i_data <= 31; i_data = i_data + 1) // the position of walking one
              begin
                data = 1'b1 << i_data;
                #1;
                for (i2 = 32'h4C; i2 >= 0; i2 = i2 - 4)
                begin
                  burst_data = burst_data << 32;
                  // DO NOT WRITE to 3 LSBits of MIICOMMAND !!!
                  if ( ((`ETH_BASE + i2) == `ETH_MIICOMMAND) && (i_data <= 2) ) 
                  begin
                    #1 burst_data[31:0] = 0;
                  end
                  else
                  begin
                    #1 burst_data[31:0] = data;
                  end
                end
                #1;
                // 2 burst writes
                addr = `ETH_BASE; // address of a first burst
                wbm_write(addr, burst_data[(32 * 10 - 1):0], 4'hF, i_length, wbm_init_waits, wbm_subseq_waits);
                burst_tmp_data = burst_data >> (32 * i_length);
                addr = addr + 32'h28; // address of a second burst
                wbm_write(addr, burst_tmp_data[(32 * 10 - 1):0], 4'hF, i_length, wbm_init_waits, wbm_subseq_waits);
                #1;
                // 2 burst reads
                addr = `ETH_BASE; // address of a first burst
                wbm_read(addr, burst_tmp_data[(32 * 10 - 1):0], 4'hF, i_length, 
                         wbm_init_waits, wbm_subseq_waits); // first burst
                burst_tmp_data = burst_tmp_data << (32 * i_length);
                addr = addr + 32'h28; // address of a second burst
                wbm_read(addr, burst_tmp_data[(32 * 10 - 1):0], 4'hF, i_length,
                         wbm_init_waits, wbm_subseq_waits); // second burst
                #1;
                for (i2 = 0; i2 <= 32'h4C; i2 = i2 + 4)
                begin
                  // set ranges of R/W bits
                  case (`ETH_BASE + i2)
                  `ETH_MODER:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 16;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_INT: // READONLY - tested within INT test
                    begin
                      bit_start_1 = 32; // not used
                      bit_end_1   = 32; // not used
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_INT_MASK:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 6;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_IPGT:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 6;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_IPGR1:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 6;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_IPGR2:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 6;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_PACKETLEN:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 31;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_COLLCONF:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 5;
                      bit_start_2 = 16; 
                      bit_end_2   = 19; 
                    end
                  `ETH_TX_BD_NUM: 
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 7;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_CTRLMODER:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 2;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MIIMODER:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 9;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MIICOMMAND: // "WRITEONLY" - tested within MIIM test - 3 LSBits are not written here!!!
                    begin
                      bit_start_1 = 32; // not used
                      bit_end_1   = 32; // not used
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MIIADDRESS:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 4;
                      bit_start_2 = 8; 
                      bit_end_2   = 12;
                    end
                  `ETH_MIITX_DATA:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 15;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MIIRX_DATA: // READONLY - tested within MIIM test
                    begin
                      bit_start_1 = 32; // not used
                      bit_end_1   = 32; // not used
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MIISTATUS: // READONLY - tested within MIIM test
                    begin
                      bit_start_1 = 32; // not used
                      bit_end_1   = 32; // not used
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MAC_ADDR0:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 31;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_MAC_ADDR1:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 15;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  `ETH_HASH_ADDR0:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 31;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  default: // `ETH_HASH_ADDR1:
                    begin
                      bit_start_1 = 0;
                      bit_end_1   = 31;
                      bit_start_2 = 32; // not used
                      bit_end_2   = 32; // not used
                    end
                  endcase
                  #1;
                  // 3 LSBits of MIICOMMAND are NOT written !!!
                  if ( ((`ETH_BASE + i2) == `ETH_MIICOMMAND) && (i_data <= 2) )
                  begin
                    if (burst_tmp_data[31:0] !== burst_data[31:0])
                    begin
                      fail = fail + 1;
                      test_fail("NON WR bit of the MAC MIICOMMAND register was wrong written or read");
                      `TIME;
                      $display("wbm_init_waits %d, wbm_subseq_waits %d, addr %h, data %h, tmp_data %h",
                                wbm_init_waits, wbm_subseq_waits, i2, burst_data[31:0], burst_tmp_data[31:0]);
                    end
                  end
                  else
                  begin
                    if ( ((i_data >= bit_start_1) && (i_data <= bit_end_1)) ||
                         ((i_data >= bit_start_2) && (i_data <= bit_end_2)) ) // data should be equal to tmp_data
                    begin
                      if (burst_tmp_data[31:0] !== burst_data[31:0])
                      begin
                        fail = fail + 1;
                        test_fail("RW bit of the MAC register was not written or not read");
                        `TIME;
                        $display("wbm_init_waits %d, wbm_subseq_waits %d, addr %h, data %h, tmp_data %h", 
                                  wbm_init_waits, wbm_subseq_waits, i2, burst_data[31:0], burst_tmp_data[31:0]);
                      end
                    end
                    else // data should not be equal to tmp_data
                    begin
                      if (burst_tmp_data[31:0] === burst_data[31:0])
                      begin
                        fail = fail + 1;
                        test_fail("NON RW bit of the MAC register was written, but it shouldn't be");
                        `TIME;
                        $display("wbm_init_waits %d, wbm_subseq_waits %d, addr %h, data %h, tmp_data %h", 
                                  wbm_init_waits, wbm_subseq_waits, i2, burst_data[31:0], burst_tmp_data[31:0]);
                      end
                    end
                  end
                  burst_tmp_data = burst_tmp_data >> 32;
                  burst_data = burst_data >> 32;
                end
              end
            end
          end
          if(fail == 0)
            test_ok;
          else
            fail = 0;*/
  end

end

end
endtask // test_access_to_mac_reg


task test_mii;
  input  [31:0]  start_task;
  input  [31:0]  end_task;
  integer        i;
  integer        i1;
  integer        i2;
  integer        i3;
  integer        cnt;
  integer        fail;
  integer        test_num;
  reg     [8:0]  clk_div; // only 8 bits are valid!
  reg     [4:0]  phy_addr;
  reg     [4:0]  reg_addr;
  reg     [15:0] phy_data;
  reg     [15:0] tmp_data;
begin
// MIIM MODULE TEST
test_heading("MIIM MODULE TEST");
$display(" ");
$display("MIIM MODULE TEST");
fail = 0;

// reset MAC registers
hard_reset;
// reset MAC and MII LOGIC with soft reset
reset_mac;
reset_mii;

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  test_mii:                                                   ////
////                                                              ////
////  0:  Test clock divider of mii management module with all    ////
////      possible frequences.                                    ////
////  1:  Test various readings from 'real' phy registers.        ////
////  2:  Test various writings to 'real' phy registers (control  ////
////      and non writable registers)                             ////
////  3:  Test reset phy through mii management module            ////
////  4:  Test 'walking one' across phy address (with and without ////
////      preamble)                                               ////
////  5:  Test 'walking one' across phy's register address (with  ////
////      and without preamble)                                   ////
////  6:  Test 'walking one' across phy's data (with and without  ////
////      preamble)                                               ////
////  7:  Test reading from phy with wrong phy address (host      ////
////      reading high 'z' data)                                  ////
////  8:  Test writing to phy with wrong phy address and reading  ////
////      from correct one                                        ////
////  9:  Test sliding stop scan command immediately after read   ////
////      request (with and without preamble)                     ////
//// 10:  Test sliding stop scan command immediately after write  ////
////      request (with and without preamble)                     ////
//// 11:  Test busy and nvalid status durations during write      ////
////      (with and without preamble)                             ////
//// 12:  Test busy and nvalid status durations during write      ////
////      (with and without preamble)                             ////
//// 13:  Test busy and nvalid status durations during scan (with ////
////      and without preamble)                                   ////
//// 14:  Test scan status from phy with detecting link-fail bit  ////
////      (with and without preamble)                             ////
//// 15:  Test scan status from phy with sliding link-fail bit    ////
////      (with and without preamble)                             ////
//// 16:  Test sliding stop scan command immediately after scan   ////
////      request (with and without preamble)                     ////
//// 17:  Test sliding stop scan command after 2. scan (with and  ////
////      without preamble)                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
for (test_num=start_task; test_num <= end_task; test_num=test_num+1)
begin
  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test clock divider of mii management module with all      ////
  ////  possible frequences.                                      ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 0) // Test clock divider of mii management module with all possible frequences.
  begin
    // TEST CLOCK DIVIDER OF MII MANAGEMENT MODULE WITH ALL POSSIBLE FREQUENCES
    test_name   = "TEST 0: TEST CLOCK DIVIDER OF MII MANAGEMENT MODULE WITH ALL POSSIBLE FREQUENCES";
    `TIME; $display("  TEST 0: TEST CLOCK DIVIDER OF MII MANAGEMENT MODULE WITH ALL POSSIBLE FREQUENCES");
  
    wait(Mdc_O); // wait for MII clock to be 1
    for(clk_div = 0; clk_div <= 255; clk_div = clk_div + 1)
    begin
      i1 = 0;
      i2 = 0;
      #Tp mii_set_clk_div(clk_div[7:0]);
      @(posedge Mdc_O);
      #Tp;
      fork
        begin
          @(posedge Mdc_O);
          #Tp;
          disable count_i1;
          disable count_i2;
        end
        begin: count_i1
          forever
          begin
            @(posedge wb_clk);
            i1 = i1 + 1;
            #Tp;
          end
        end
        begin: count_i2
          forever
          begin
            @(negedge wb_clk);
            i2 = i2 + 1;
            #Tp;
          end
        end
      join
      if((clk_div[7:0] == 0) || (clk_div[7:0] == 1) || (clk_div[7:0] == 2) || (clk_div[7:0] == 3))
      begin
        if((i1 == i2) && (i1 == 2))
        begin
        end
        else
        begin
          fail = fail + 1;
          test_fail("Clock divider of MII module did'nt divide frequency corectly (it should divid with 2)");
        end
      end
      else
      begin
        if((i1 == i2) && (i1 == {clk_div[7:1], 1'b0}))
        begin
        end
        else
        begin
          fail = fail + 1;
          test_fail("Clock divider of MII module did'nt divide frequency corectly");
        end
      end
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end
  
  
  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test various readings from 'real' phy registers.          ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 1) // Test various readings from 'real' phy registers.
  begin
    // TEST VARIOUS READINGS FROM 'REAL' PHY REGISTERS
    test_name   = "TEST 1: TEST VARIOUS READINGS FROM 'REAL' PHY REGISTERS";
    `TIME; $display("  TEST 1: TEST VARIOUS READINGS FROM 'REAL' PHY REGISTERS");
  
    // set the fastest possible MII
    clk_div = 0;
    mii_set_clk_div(clk_div[7:0]);
    // set address
    reg_addr = 5'h1F;
    phy_addr = 5'h1;
    while(reg_addr >= 5'h4)
    begin
      // read request
      #Tp mii_read_req(phy_addr, reg_addr);
      check_mii_busy; // wait for read to finish
      // read data
      #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      if (phy_data !== 16'hDEAD)
      begin
        test_fail("Wrong data was read from PHY from 'not used' address space");
        fail = fail + 1;
      end
      if (reg_addr == 5'h4) // go out of for loop
        reg_addr = 5'h3;
      else
        reg_addr = reg_addr - 5'h9;
    end
  
    // set address
    reg_addr = 5'h3;
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (phy_data !== {`PHY_ID2, `MAN_MODEL_NUM, `MAN_REVISION_NUM})
    begin
      test_fail("Wrong data was read from PHY from ID register 2");
      fail = fail + 1;
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test various writings to 'real' phy registers (control    ////
  ////  and non writable registers)                               ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 2) // 
  begin
    // TEST VARIOUS WRITINGS TO 'REAL' PHY REGISTERS ( CONTROL AND NON WRITABLE REGISTERS )
    test_name   = "TEST 2: TEST VARIOUS WRITINGS TO 'REAL' PHY REGISTERS ( CONTROL AND NON WRITABLE REGISTERS )";
    `TIME; $display("  TEST 2: TEST VARIOUS WRITINGS TO 'REAL' PHY REGISTERS ( CONTROL AND NON WRITABLE REGISTERS )");
  
    // negate data and try to write into unwritable register
    tmp_data = ~phy_data;
    // write request
    #Tp mii_write_req(phy_addr, reg_addr, tmp_data);
    check_mii_busy; // wait for write to finish
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (tmp_data !== phy_data)
    begin
      test_fail("Data was written into unwritable PHY register - ID register 2");
      fail = fail + 1;
    end
  
    // set address
    reg_addr = 5'h0; // control register
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // write request
    phy_data = 16'h7DFF; // bit 15 (RESET bit) and bit 9 are self clearing bits
    #Tp mii_write_req(phy_addr, reg_addr, phy_data);
    check_mii_busy; // wait for write to finish
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (phy_data !== 16'h7DFF)
    begin
      test_fail("Data was not correctly written into OR read from writable PHY register - control register");
      fail = fail + 1;
    end
    // write request
    #Tp mii_write_req(phy_addr, reg_addr, tmp_data);
    check_mii_busy; // wait for write to finish
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (phy_data !== tmp_data)
    begin
      test_fail("Data was not correctly written into OR read from writable PHY register - control register");
      fail = fail + 1;
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test reset phy through mii management module              ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 3) // 
  begin
    // TEST RESET PHY THROUGH MII MANAGEMENT MODULE
    test_name   = "TEST 3: TEST RESET PHY THROUGH MII MANAGEMENT MODULE";
    `TIME; $display("  TEST 3: TEST RESET PHY THROUGH MII MANAGEMENT MODULE");
  
    // set address
    reg_addr = 5'h0; // control register
    // write request
    phy_data = 16'h7DFF; // bit 15 (RESET bit) and bit 9 are self clearing bits
    #Tp mii_write_req(phy_addr, reg_addr, phy_data);
    check_mii_busy; // wait for write to finish
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (phy_data !== tmp_data)
    begin
      test_fail("Data was not correctly written into OR read from writable PHY register - control register");
      fail = fail + 1;
    end
    // set reset bit - selfclearing bit in PHY
    phy_data = phy_data | 16'h8000;
    // write request
    #Tp mii_write_req(phy_addr, reg_addr, phy_data);
    check_mii_busy; // wait for write to finish
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // check self clearing of reset bit
    if (tmp_data[15] !== 1'b0)
    begin
      test_fail("Reset bit should be self cleared - control register");
      fail = fail + 1;
    end
    // check reset value of control register
    if (tmp_data !== {2'h0, (`LED_CFG1 || `LED_CFG2), `LED_CFG1, 3'h0, `LED_CFG3, 8'h0})
    begin
      test_fail("PHY was not reset correctly AND/OR reset bit not self cleared");
      fail = fail + 1;
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test 'walking one' across phy address (with and without   ////
  ////  preamble)                                                 ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 4) // 
  begin
    // TEST 'WALKING ONE' ACROSS PHY ADDRESS ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 4: TEST 'WALKING ONE' ACROSS PHY ADDRESS ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 4: TEST 'WALKING ONE' ACROSS PHY ADDRESS ( WITH AND WITHOUT PREAMBLE )");
  
    // set PHY to test mode
    #Tp eth_phy.test_regs(1); // set test registers (wholy writable registers) and respond to all PHY addresses
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i); 
      #Tp eth_phy.clear_test_regs;
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}), 4'hF, 1, wbm_init_waits, 
                wbm_subseq_waits);
      // walk one across phy address
      for (phy_addr = 5'h1; phy_addr > 5'h0; phy_addr = phy_addr << 1)
      begin
        reg_addr = $random;
        tmp_data = $random;
        // write request
        #Tp mii_write_req(phy_addr, reg_addr, tmp_data);
        check_mii_busy; // wait for write to finish
        // read request
        #Tp mii_read_req(phy_addr, reg_addr);
        check_mii_busy; // wait for read to finish
        // read data
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        #Tp;
        if (phy_data !== tmp_data)
        begin
          if (i)
            test_fail("Data was not correctly written into OR read from test registers (without preamble)");
          else
            test_fail("Data was not correctly written into OR read from test registers (with preamble)");
          fail = fail + 1;
        end
        @(posedge wb_clk);
        #Tp;
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.test_regs(0);
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test 'walking one' across phy's register address (with    ////
  ////  and without preamble)                                     ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 5) // 
  begin
    // TEST 'WALKING ONE' ACROSS PHY'S REGISTER ADDRESS ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 5: TEST 'WALKING ONE' ACROSS PHY'S REGISTER ADDRESS ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 5: TEST 'WALKING ONE' ACROSS PHY'S REGISTER ADDRESS ( WITH AND WITHOUT PREAMBLE )");
  
    // set PHY to test mode
    #Tp eth_phy.test_regs(1); // set test registers (wholy writable registers) and respond to all PHY addresses
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i);
      #Tp eth_phy.clear_test_regs;
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}), 4'hF, 1, wbm_init_waits, 
                wbm_subseq_waits);
      // walk one across reg address
      for (reg_addr = 5'h1; reg_addr > 5'h0; reg_addr = reg_addr << 1)
      begin
        phy_addr = $random;
        tmp_data = $random;
        // write request
        #Tp mii_write_req(phy_addr, reg_addr, tmp_data);
        check_mii_busy; // wait for write to finish
        // read request
        #Tp mii_read_req(phy_addr, reg_addr);
        check_mii_busy; // wait for read to finish
        // read data
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        #Tp;
        if (phy_data !== tmp_data)
        begin
          if (i)
            test_fail("Data was not correctly written into OR read from test registers (without preamble)");
          else
            test_fail("Data was not correctly written into OR read from test registers (with preamble)");
          fail = fail + 1;
        end
        @(posedge wb_clk);
        #Tp;
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.test_regs(0);
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test 'walking one' across phy's data (with and without    ////
  ////  preamble)                                                 ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 6) // 
  begin
    // TEST 'WALKING ONE' ACROSS PHY'S DATA ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 6: TEST 'WALKING ONE' ACROSS PHY'S DATA ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 6: TEST 'WALKING ONE' ACROSS PHY'S DATA ( WITH AND WITHOUT PREAMBLE )");
  
    // set PHY to test mode
    #Tp eth_phy.test_regs(1); // set test registers (wholy writable registers) and respond to all PHY addresses
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i);
      #Tp eth_phy.clear_test_regs;
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}), 4'hF, 1, wbm_init_waits,
                wbm_subseq_waits);
      // walk one across data
      for (tmp_data = 16'h1; tmp_data > 16'h0; tmp_data = tmp_data << 1)
      begin
        phy_addr = $random;
        reg_addr = $random;
        // write request
        #Tp mii_write_req(phy_addr, reg_addr, tmp_data);
        check_mii_busy; // wait for write to finish
        // read request
        #Tp mii_read_req(phy_addr, reg_addr);
        check_mii_busy; // wait for read to finish
        // read data
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        #Tp;
        if (phy_data !== tmp_data)
        begin
          if (i)
            test_fail("Data was not correctly written into OR read from test registers (without preamble)");
          else
            test_fail("Data was not correctly written into OR read from test registers (with preamble)");
          fail = fail + 1;
        end
        @(posedge wb_clk);
        #Tp;
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.test_regs(0);
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test reading from phy with wrong phy address (host        ////
  ////  reading high 'z' data)                                    ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 7) // 
  begin
    // TEST READING FROM PHY WITH WRONG PHY ADDRESS ( HOST READING HIGH 'Z' DATA )
    test_name   = "TEST 7: TEST READING FROM PHY WITH WRONG PHY ADDRESS ( HOST READING HIGH 'Z' DATA )";
    `TIME; $display("  TEST 7: TEST READING FROM PHY WITH WRONG PHY ADDRESS ( HOST READING HIGH 'Z' DATA )");
  
    phy_addr = 5'h2; // wrong PHY address
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    $display("  => Two errors will be displayed from WB Bus Monitor, because correct HIGH Z data was read");
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (tmp_data !== 16'hzzzz)
    begin
      test_fail("Data was read from PHY register with wrong PHY address - control register");
      fail = fail + 1;
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test writing to phy with wrong phy address and reading    ////
  ////  from correct one                                          ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 8) // 
  begin
    // TEST WRITING TO PHY WITH WRONG PHY ADDRESS AND READING FROM CORRECT ONE
    test_name   = "TEST 8: TEST WRITING TO PHY WITH WRONG PHY ADDRESS AND READING FROM CORRECT ONE";
    `TIME; $display("  TEST 8: TEST WRITING TO PHY WITH WRONG PHY ADDRESS AND READING FROM CORRECT ONE");
  
    // set address
    reg_addr = 5'h0; // control register
    phy_addr = 5'h2; // wrong PHY address
    // write request
    phy_data = 16'h7DFF; // bit 15 (RESET bit) and bit 9 are self clearing bits
    #Tp mii_write_req(phy_addr, reg_addr, phy_data);
    check_mii_busy; // wait for write to finish
  
    phy_addr = 5'h1; // correct PHY address
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (phy_data === tmp_data)
    begin
      test_fail("Data was written into PHY register with wrong PHY address - control register");
      fail = fail + 1;
    end
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test sliding stop scan command immediately after read     ////
  ////  request (with and without preamble)                       ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 9) // 
  begin
    // TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER READ REQUEST ( WITH AND WITHOUT PREAMBLE )
    test_name = "TEST 9: TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER READ REQUEST ( WITH AND WITHOUT PREAMBLE )";
    `TIME; 
    $display("  TEST 9: TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER READ REQUEST ( WITH AND WITHOUT PREAMBLE )");
  
    for (i2 = 0; i2 <= 1; i2 = i2 + 1) // choose preamble or not
    begin
      #Tp eth_phy.preamble_suppresed(i2);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i2, 8'h0}), 4'hF, 1, wbm_init_waits, 
               wbm_subseq_waits);
      i = 0;
      cnt = 0;
      while (i < 80) // delay for sliding of writing a STOP SCAN command
      begin
        for (i3 = 0; i3 <= 1; i3 = i3 + 1) // choose read or write after read will be finished
        begin
          // set address
          reg_addr = 5'h0; // control register
          phy_addr = 5'h1; // correct PHY address
          cnt = 0;
          // read request
          #Tp mii_read_req(phy_addr, reg_addr);
          fork
            begin
              repeat(i) @(posedge Mdc_O);
              // write command 0x0 into MII command register
              // MII command written while read in progress
              wbm_write(`ETH_MIICOMMAND, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
              @(posedge wb_clk);
              #Tp check_mii_busy; // wait for read to finish
            end
            begin
              // wait for serial bus to become active
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
            end
          join
          // check transfer length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Read request did not proceed correctly, while SCAN STOP command was written");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Read request did not proceed correctly, while SCAN STOP command was written");
              fail = fail + 1;
            end
          end
          // check the BUSY signal to see if the bus is still IDLE
          for (i1 = 0; i1 < 8; i1 = i1 + 1)
            check_mii_busy; // wait for bus to become idle
    
          // try normal write or read after read was finished
          #Tp phy_data = {8'h7D, (i[7:0] + 1)};
          #Tp cnt = 0;
          if (i3 == 0) // write after read
          begin
            // write request
            #Tp mii_write_req(phy_addr, reg_addr, phy_data);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while(Mdio_IO !== 1'bz)
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          else // read after read
          begin
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          // check if transfer was a proper length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after read request");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after read request");
              fail = fail + 1;
            end
          end
        end
        #Tp;
        // set delay of writing the command
        if (i2) // without preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            18, 19, 20, 21, 22,
            23, 24, 25, 26, 27,
            28, 29, 30, 31, 32,
            33, 34, 35:         i = i + 1;
            36:                 i = 80;
            default:            i = 18;
          endcase
        end
        else // with preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            50, 51, 52, 53, 54, 
            55, 56, 57, 58, 59, 
            60, 61, 62, 63, 64, 
            65, 66, 67:         i = i + 1;
            68:                 i = 80;
            default:            i = 50;
          endcase
        end
        @(posedge wb_clk);
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test sliding stop scan command immediately after write    ////
  ////  request (with and without preamble)                       ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 10) // 
  begin
    // TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER WRITE REQUEST ( WITH AND WITHOUT PREAMBLE )
    test_name = "TEST 10: TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER WRITE REQUEST ( WITH AND WITHOUT PREAMBLE )";
    `TIME; 
    $display("  TEST 10: TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER WRITE REQUEST ( WITH AND WITHOUT PREAMBLE )");
  
    for (i2 = 0; i2 <= 1; i2 = i2 + 1) // choose preamble or not
    begin
      #Tp eth_phy.preamble_suppresed(i2);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i2, 8'h0}), 4'hF, 1, wbm_init_waits, 
                wbm_subseq_waits);
      i = 0;
      cnt = 0;
      while (i < 80) // delay for sliding of writing a STOP SCAN command
      begin
        for (i3 = 0; i3 <= 1; i3 = i3 + 1) // choose read or write after write will be finished
        begin
          // set address
          reg_addr = 5'h0; // control register
          phy_addr = 5'h1; // correct PHY address
          cnt = 0;
          // write request
          phy_data = {8'h75, (i[7:0] + 1)};
          #Tp mii_write_req(phy_addr, reg_addr, phy_data);
          fork
            begin
              repeat(i) @(posedge Mdc_O);
              // write command 0x0 into MII command register
              // MII command written while read in progress
              wbm_write(`ETH_MIICOMMAND, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
              @(posedge wb_clk);
              #Tp check_mii_busy; // wait for write to finish
            end
            begin
              // wait for serial bus to become active
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while(Mdio_IO !== 1'bz)
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
            end
          join
          // check transfer length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Write request did not proceed correctly, while SCAN STOP command was written");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Write request did not proceed correctly, while SCAN STOP command was written");
              fail = fail + 1;
            end
          end
          // check the BUSY signal to see if the bus is still IDLE
          for (i1 = 0; i1 < 8; i1 = i1 + 1)
            check_mii_busy; // wait for bus to become idle
    
          // try normal write or read after write was finished
          #Tp cnt = 0;
          if (i3 == 0) // write after write
          begin
            phy_data = {8'h7A, (i[7:0] + 1)};
            // write request
            #Tp mii_write_req(phy_addr, reg_addr, phy_data);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while(Mdio_IO !== 1'bz)
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data , 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          else // read after write
          begin
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data , 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          // check if transfer was a proper length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after write request");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after write request");
              fail = fail + 1;
            end
          end
        end
        #Tp;
        // set delay of writing the command
        if (i2) // without preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            18, 19, 20, 21, 22,
            23, 24, 25, 26, 27,
            28, 29, 30, 31, 32,
            33, 34, 35:         i = i + 1;
            36:                 i = 80;
            default:            i = 18;
          endcase
        end
        else // with preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            50, 51, 52, 53, 54, 
            55, 56, 57, 58, 59, 
            60, 61, 62, 63, 64, 
            65, 66, 67:         i = i + 1;
            68:                 i = 80;
            default:            i = 50;
          endcase
        end
        @(posedge wb_clk);
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test busy and nvalid status durations during write (with  ////
  ////  and without preamble)                                     ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 11) // 
  begin
    // TEST BUSY AND NVALID STATUS DURATIONS DURING WRITE ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 11: TEST BUSY AND NVALID STATUS DURATIONS DURING WRITE ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 11: TEST BUSY AND NVALID STATUS DURATIONS DURING WRITE ( WITH AND WITHOUT PREAMBLE )");
  
    reset_mii; // reset MII
    // set link up, if it wasn't due to previous tests, since there weren't PHY registers
    #Tp eth_phy.link_up_down(1);
    // set the MII
    clk_div = 64;
    mii_set_clk_div(clk_div[7:0]);
    // set address
    reg_addr = 5'h1; // status register
    phy_addr = 5'h1; // correct PHY address
  
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}) | (`ETH_MIIMODER_CLKDIV & clk_div), 
                4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      @(posedge Mdc_O);
      // write request
      #Tp mii_write_req(phy_addr, reg_addr, 16'h5A5A);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is not HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal was not set while MII IO signal is not HIGH Z anymore - 1. read");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during write");
          fail = fail + 1;
        end
      end
      else // Busy bit should already be set to '1', due to reads from MII status register
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set after write, due to reads from MII status register");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during write");
          fail = fail + 1;
        end
      end
  
      // wait for serial bus to become active
      wait(Mdio_IO !== 1'bz);
      // count transfer bits
      if (i)
      begin
        repeat(32) @(posedge Mdc_O);
      end
      else
      begin
        repeat(64) @(posedge Mdc_O);
      end
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO === 1'bz) // Mdio_IO should not be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal is not active anymore");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during write");
          fail = fail + 1;
        end
      end
      else // Busy bit should still be set to '1'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during write");
          fail = fail + 1;
        end
      end
  
      // wait for next negative clock edge
      @(negedge Mdc_O);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to early, Mdio_IO is not HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal was not set while MII IO signal is not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during write");
          fail = fail + 1;
        end
      end
      else // Busy bit should still be set to '1'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set after MII IO signal become HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during write");
          fail = fail + 1;
        end
      end
  
      // wait for Busy to become inactive
      i1 = 0;
      while (i1 <= 2)
      begin
        // wait for next positive clock edge
        @(posedge Mdc_O);
        // read data from MII status register - Busy and Nvalid bits
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
        // check MII IO signal and Busy and Nvalid bits
        if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
        begin
          test_fail("Testbench error - read was to early, Mdio_IO is not HIGH Z - set higher clock divider");
          if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
          begin
            test_fail("Busy signal was not set while MII IO signal is not HIGH Z");
            fail = fail + 1;
          end
          if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
          begin
            test_fail("Nvalid signal was set during write");
            fail = fail + 1;
          end
        end
        else // wait for Busy bit to be set to '0'
        begin
          if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
          begin
            i1 = 3; // end of Busy checking
          end
          else
          begin
            if (i1 == 2)
            begin
              test_fail("Busy signal should be cleared after 2 periods after MII IO signal become HIGH Z");
              fail = fail + 1;
            end
            #Tp i1 = i1 + 1;
          end
          if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
          begin
            test_fail("Nvalid signal was set after write");
            fail = fail + 1;
          end
        end
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test busy and nvalid status durations during write (with  ////
  ////  and without preamble)                                     ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 12) // 
  begin
    // TEST BUSY AND NVALID STATUS DURATIONS DURING READ ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 12: TEST BUSY AND NVALID STATUS DURATIONS DURING READ ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 12: TEST BUSY AND NVALID STATUS DURATIONS DURING READ ( WITH AND WITHOUT PREAMBLE )");
  
    reset_mii; // reset MII
    // set link up, if it wasn't due to previous tests, since there weren't PHY registers
    #Tp eth_phy.link_up_down(1); 
    // set the MII
    clk_div = 64;
    mii_set_clk_div(clk_div[7:0]);
    // set address
    reg_addr = 5'h1; // status register
    phy_addr = 5'h1; // correct PHY address
  
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}) | (`ETH_MIIMODER_CLKDIV & clk_div),
                4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      @(posedge Mdc_O);
      // read request
      #Tp mii_read_req(phy_addr, reg_addr);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is not HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal was not set while MII IO signal is not HIGH Z anymore - 1. read");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during read");
          fail = fail + 1;
        end
      end
      else // Busy bit should already be set to '1', due to reads from MII status register
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set after read, due to reads from MII status register");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during read");
          fail = fail + 1;
        end
      end
  
      // wait for serial bus to become active
      wait(Mdio_IO !== 1'bz);
      // count transfer bits
      if (i)
      begin
        repeat(31) @(posedge Mdc_O);
      end
      else
      begin
        repeat(63) @(posedge Mdc_O);
      end
      // wait for next negative clock edge
      @(negedge Mdc_O);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO === 1'bz) // Mdio_IO should not be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal is not active anymore");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during read");
          fail = fail + 1;
        end
      end
      else // Busy bit should still be set to '1'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during read");
          fail = fail + 1;
        end
      end
  
      // wait for next positive clock edge
      @(posedge Mdc_O);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to early, Mdio_IO is not HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal was not set while MII IO signal is not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during read");
          fail = fail + 1;
        end
      end
      else // Busy bit should still be set to '1'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set after MII IO signal become HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
        begin
          test_fail("Nvalid signal was set during read");
          fail = fail + 1;
        end
      end
  
      // wait for Busy to become inactive
      i1 = 0;
      while (i1 <= 2)
      begin
        // wait for next positive clock edge
        @(posedge Mdc_O);
        // read data from MII status register - Busy and Nvalid bits
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
        // check MII IO signal and Busy and Nvalid bits
        if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
        begin
          test_fail("Testbench error - read was to early, Mdio_IO is not HIGH Z - set higher clock divider");
          if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
          begin
            test_fail("Busy signal was not set while MII IO signal is not HIGH Z");
            fail = fail + 1;
          end
          if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
          begin
            test_fail("Nvalid signal was set during read");
            fail = fail + 1;
          end
        end
        else // wait for Busy bit to be set to '0'
        begin
          if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
          begin
            i1 = 3; // end of Busy checking
          end
          else
          begin
            if (i1 == 2)
            begin
              test_fail("Busy signal should be cleared after 2 periods after MII IO signal become HIGH Z");
              fail = fail + 1;
            end
            #Tp i1 = i1 + 1;
          end
          if (phy_data[`ETH_MIISTATUS_NVALID] !== 1'b0)
          begin
            test_fail("Nvalid signal was set after read");
            fail = fail + 1;
          end
        end
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test busy and nvalid status durations during scan (with   ////
  ////  and without preamble)                                     ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 13) // 
  begin
    // TEST BUSY AND NVALID STATUS DURATIONS DURING SCAN ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 13: TEST BUSY AND NVALID STATUS DURATIONS DURING SCAN ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 13: TEST BUSY AND NVALID STATUS DURATIONS DURING SCAN ( WITH AND WITHOUT PREAMBLE )");
  
    reset_mii; // reset MII
    // set link up, if it wasn't due to previous tests, since there weren't PHY registers
    #Tp eth_phy.link_up_down(1); 
    // set the MII
    clk_div = 64;
    mii_set_clk_div(clk_div[7:0]);
    // set address
    reg_addr = 5'h1; // status register
    phy_addr = 5'h1; // correct PHY address
  
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}) | (`ETH_MIIMODER_CLKDIV & clk_div),
                4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      @(posedge Mdc_O);
      // scan request
      #Tp mii_scan_req(phy_addr, reg_addr);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is not HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal was not set while MII IO signal is not HIGH Z anymore - 1. read");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
        begin
          test_fail("Nvalid signal was not set while MII IO signal is not HIGH Z anymore - 1. read");
          fail = fail + 1;
        end
      end
      else // Busy bit should already be set to '1', due to reads from MII status register
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set after scan, due to reads from MII status register");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
        begin
          test_fail("Nvalid signal should be set after scan, due to reads from MII status register");
          fail = fail + 1;
        end
      end
  
      // wait for serial bus to become active
      wait(Mdio_IO !== 1'bz);
      // count transfer bits
      if (i)
      begin
        repeat(21) @(posedge Mdc_O);
      end
      else
      begin
        repeat(53) @(posedge Mdc_O);
      end
      // stop scan
      #Tp mii_scan_finish; // finish scan operation
  
      // wait for next positive clock edge
      repeat(10) @(posedge Mdc_O);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO === 1'bz) // Mdio_IO should not be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal is not active anymore");
          fail = fail + 1;
        end
        // Nvalid signal can be cleared here - it is still Testbench error
      end
      else // Busy bit should still be set to '1', Nvalid bit should still be set to '1'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
        begin
          test_fail("Nvalid signal should be set while MII IO signal not HIGH Z");
          fail = fail + 1;
        end
      end
  
      // wait for next negative clock edge
      @(negedge Mdc_O);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO === 1'bz) // Mdio_IO should not be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to late, Mdio_IO is HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal is not active anymore");
          fail = fail + 1;
        end
        // Nvalid signal can be cleared here - it is still Testbench error
      end
      else // Busy bit should still be set to '1', Nvalid bit should still be set to '1'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set while MII IO signal not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
        begin
          test_fail("Nvalid signal should be set while MII IO signal not HIGH Z");
          fail = fail + 1;
        end
      end
  
      // wait for next negative clock edge
      @(posedge Mdc_O);
      // read data from MII status register - Busy and Nvalid bits
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
      // check MII IO signal and Busy and Nvalid bits
      if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
      begin
        test_fail("Testbench error - read was to early, Mdio_IO is not HIGH Z - set higher clock divider");
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal was not set while MII IO signal is not HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
        begin
          test_fail("Nvalid signal was not set while MII IO signal is not HIGH Z");
          fail = fail + 1;
        end
      end
      else // Busy bit should still be set to '1', Nvalid bit can be set to '0'
      begin
        if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
        begin
          test_fail("Busy signal should be set after MII IO signal become HIGH Z");
          fail = fail + 1;
        end
        if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
        begin
          i2 = 1; // check finished
        end
        else
        begin
          i2 = 0; // check must continue
        end
      end
  
      // wait for Busy to become inactive
      i1 = 0;
      while ((i1 <= 2) || (i2 == 0))
      begin
        // wait for next positive clock edge
        @(posedge Mdc_O);
        // read data from MII status register - Busy and Nvalid bits
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
        // check MII IO signal and Busy and Nvalid bits
        if (Mdio_IO !== 1'bz) // Mdio_IO should be HIGH Z here - testbench selfcheck
        begin
          test_fail("Testbench error - read was to early, Mdio_IO is not HIGH Z - set higher clock divider");
          if (i1 <= 2)
          begin
            if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
            begin
              test_fail("Busy signal was not set while MII IO signal is not HIGH Z");
              fail = fail + 1;
            end
          end
          if (i2 == 0)
          begin
            if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
            begin
              test_fail("Nvalid signal was not set while MII IO signal is not HIGH Z");
              fail = fail + 1;
            end
          end
        end
        else // wait for Busy bit to be set to '0'
        begin
          if (i1 <= 2)
          begin
            if (phy_data[`ETH_MIISTATUS_BUSY] === 1'b0)
            begin
              i1 = 3; // end of Busy checking
            end
            else
            begin
              if (i1 == 2)
              begin
                test_fail("Busy signal should be cleared after 2 periods after MII IO signal become HIGH Z");
                fail = fail + 1;
              end
              #Tp i1 = i1 + 1;
            end
          end
          if (i2 == 0)
          begin
            if (phy_data[`ETH_MIISTATUS_NVALID] === 1'b0)
            begin
              i2 = 1;
            end
            else
            begin
              test_fail("Nvalid signal should be cleared after MII IO signal become HIGH Z");
              fail = fail + 1;
            end
          end
        end
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test scan status from phy with detecting link-fail bit    ////
  ////  (with and without preamble)                               ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 14) // 
  begin
    // TEST SCAN STATUS FROM PHY WITH DETECTING LINK-FAIL BIT ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 14: TEST SCAN STATUS FROM PHY WITH DETECTING LINK-FAIL BIT ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 14: TEST SCAN STATUS FROM PHY WITH DETECTING LINK-FAIL BIT ( WITH AND WITHOUT PREAMBLE )");
  
    reset_mii; // reset MII
    // set link up, if it wasn't due to previous tests, since there weren't PHY registers
    #Tp eth_phy.link_up_down(1); 
    // set MII speed
    clk_div = 6;
    mii_set_clk_div(clk_div[7:0]);
    // set address
    reg_addr = 5'h1; // status register
    phy_addr = 5'h1; // correct PHY address
  
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data from PHY status register - remember LINK-UP status
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
    for (i = 0; i <= 1; i = i + 1)
    begin
      #Tp eth_phy.preamble_suppresed(i);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i, 8'h0}) | (`ETH_MIIMODER_CLKDIV & clk_div),
                4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      if (i)
      begin
        // change saved data when preamble is suppressed
        #Tp tmp_data = tmp_data | 16'h0040; // put bit 6 to ONE
      end
  
      // scan request
      #Tp mii_scan_req(phy_addr, reg_addr);
      check_mii_scan_valid; // wait for scan to make first data valid
     
      fork
      begin 
        repeat(2) @(posedge Mdc_O);
        // read data from PHY status register
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data !== tmp_data)
        begin
          test_fail("Data was not correctly scaned from status register");
          fail = fail + 1;
        end
        // read data from MII status register
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data[0] !== 1'b0)
        begin
          test_fail("Link FAIL bit was set in the MII status register");
          fail = fail + 1;
        end
      end
      begin
      // Completely check second scan
        #Tp cnt = 0;
        // wait for serial bus to become active - second scan
        wait(Mdio_IO !== 1'bz);
        // count transfer length
        while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i == 0)) || ((cnt == 15) && (i == 1)) )
        begin
          @(posedge Mdc_O);
          #Tp cnt = cnt + 1;
        end
        // check transfer length
        if (i) // without preamble
        begin
          if (cnt != 33) // at this value Mdio_IO is HIGH Z
          begin
            test_fail("Second scan request did not proceed correctly");
            fail = fail + 1;
          end
        end
        else // with preamble
        begin
          if (cnt != 65) // at this value Mdio_IO is HIGH Z
          begin
            test_fail("Second scan request did not proceed correctly");
            fail = fail + 1;
          end
        end
      end
      join
      // check third to fifth scans
      for (i3 = 0; i3 <= 2; i3 = i3 + 1)
      begin
        fork
        begin
          repeat(2) @(posedge Mdc_O);
          // read data from PHY status register
          #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (phy_data !== tmp_data)
          begin
            test_fail("Data was not correctly scaned from status register");
            fail = fail + 1;
          end
          // read data from MII status register
          #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (phy_data[0] !== 1'b0)
          begin
            test_fail("Link FAIL bit was set in the MII status register");
            fail = fail + 1;
          end
          if (i3 == 2) // after fourth scan read
          begin
            @(posedge Mdc_O);
            // change saved data
            #Tp tmp_data = tmp_data & 16'hFFFB; // put bit 3 to ZERO
            // set link down
            #Tp eth_phy.link_up_down(0);
          end
        end
        begin
        // Completely check scans
          #Tp cnt = 0;
          // wait for serial bus to become active - second scan
          wait(Mdio_IO !== 1'bz);
          // count transfer length
          while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i == 0)) || ((cnt == 15) && (i == 1)) )
          begin
            @(posedge Mdc_O);
            #Tp cnt = cnt + 1;
          end
          // check transfer length
          if (i) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Fifth scan request did not proceed correctly");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Fifth scan request did not proceed correctly");
              fail = fail + 1;
            end
          end
        end
        join
      end
  
      fork
      begin
        repeat(2) @(posedge Mdc_O);
        // read data from PHY status register
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data !== tmp_data)
        begin
          test_fail("Data was not correctly scaned from status register");
          fail = fail + 1;
        end
        // read data from MII status register
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data[0] === 1'b0)
        begin
          test_fail("Link FAIL bit was not set in the MII status register");
          fail = fail + 1;
        end
        // wait to see if data stayed latched
        repeat(4) @(posedge Mdc_O);
        // read data from PHY status register
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data !== tmp_data)
        begin
          test_fail("Data was not latched correctly in status register");
          fail = fail + 1;
        end
        // read data from MII status register
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data[0] === 1'b0)
        begin
          test_fail("Link FAIL bit was not set in the MII status register");
          fail = fail + 1;
        end
        // change saved data
        #Tp tmp_data = tmp_data | 16'h0004; // put bit 2 to ONE
        // set link up
        #Tp eth_phy.link_up_down(1);
      end
      begin
      // Wait for sixth scan
        // wait for serial bus to become active - sixth scan
        wait(Mdio_IO !== 1'bz);
        // wait for serial bus to become inactive - turn-around cycle in sixth scan
        wait(Mdio_IO === 1'bz);
        // wait for serial bus to become active - end of turn-around cycle in sixth scan
        wait(Mdio_IO !== 1'bz);
        // wait for serial bus to become inactive - end of sixth scan
        wait(Mdio_IO === 1'bz);
      end
      join
  
      @(posedge Mdc_O);
      // read data from PHY status register
      #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      if (phy_data !== tmp_data)
      begin
        test_fail("Data was not correctly scaned from status register");
        fail = fail + 1;
      end
      // read data from MII status register
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      if (phy_data[0] !== 1'b0)
      begin
        test_fail("Link FAIL bit was set in the MII status register");
        fail = fail + 1;
      end
      // wait to see if data stayed latched
      repeat(4) @(posedge Mdc_O);
      // read data from PHY status register
      #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      if (phy_data !== tmp_data)
      begin
        test_fail("Data was not correctly scaned from status register");
        fail = fail + 1;
      end
      // read data from MII status register
      #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      if (phy_data[0] !== 1'b0)
      begin
        test_fail("Link FAIL bit was set in the MII status register");
        fail = fail + 1;
      end
  
      // STOP SCAN
      #Tp mii_scan_finish; // finish scan operation
      #Tp check_mii_busy; // wait for scan to finish
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test scan status from phy with sliding link-fail bit      ////
  ////  (with and without preamble)                               ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 15) // 
  begin
    // TEST SCAN STATUS FROM PHY WITH SLIDING LINK-FAIL BIT ( WITH AND WITHOUT PREAMBLE )
    test_name   = "TEST 15: TEST SCAN STATUS FROM PHY WITH SLIDING LINK-FAIL BIT ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 15: TEST SCAN STATUS FROM PHY WITH SLIDING LINK-FAIL BIT ( WITH AND WITHOUT PREAMBLE )");
  
    // set address
    reg_addr = 5'h1; // status register
    phy_addr = 5'h1; // correct PHY address
  
    // read request
    #Tp mii_read_req(phy_addr, reg_addr);
    check_mii_busy; // wait for read to finish
    // read data from PHY status register - remember LINK-UP status
    #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  
    for (i2 = 0; i2 <= 1; i2 = i2 + 1) // choose preamble or not
    begin
      #Tp eth_phy.preamble_suppresed(i2);
      // MII mode register
      #Tp wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i2, 8'h0}), 4'hF, 1, wbm_init_waits, 
                    wbm_subseq_waits);
      if (i2)
      begin
        // change saved data when preamble is suppressed
        #Tp tmp_data = tmp_data | 16'h0040; // put bit 6 to ONE
      end
  
      i = 0;
      while (i < 80) // delay for sliding of LinkFail bit
      begin
        // first there are two scans
        #Tp cnt = 0;
        // scan request
        #Tp mii_scan_req(phy_addr, reg_addr);
        #Tp check_mii_scan_valid; // wait for scan to make first data valid
  
        // check second scan
        fork
        begin
          repeat(4) @(posedge Mdc_O);
          // read data from PHY status register
          #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (phy_data !== tmp_data)
          begin
            test_fail("Second data was not correctly scaned from status register");
            fail = fail + 1;
          end
          // read data from MII status register
          #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (phy_data[0] !== 1'b0)
          begin
            test_fail("Link FAIL bit was set in the MII status register");
            fail = fail + 1;
          end
        end
        begin
        // Completely check scan
          #Tp cnt = 0;
          // wait for serial bus to become active - second scan
          wait(Mdio_IO !== 1'bz);
          // count transfer length
          while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
          begin
            @(posedge Mdc_O);
            #Tp cnt = cnt + 1;
          end
          // check transfer length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Second scan request did not proceed correctly");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Second scan request did not proceed correctly");
              fail = fail + 1;
            end
          end
        end
        join
        // reset counter 
        #Tp cnt = 0;
        // SLIDING LINK DOWN and CHECK
        fork
          begin
          // set link down
            repeat(i) @(posedge Mdc_O);
            // set link down
            #Tp eth_phy.link_up_down(0);
          end
          begin
          // check data in MII registers after each scan in this fork statement
            if (i2) // without preamble
              wait (cnt == 32);
            else // with preamble
              wait (cnt == 64);
            repeat(3) @(posedge Mdc_O);
            // read data from PHY status register
            #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if ( ((i < 49) && !i2) || ((i < 17) && i2) )
            begin
              if (phy_data !== (tmp_data & 16'hFFFB)) // bit 3 is ZERO
              begin
                test_fail("Third data was not correctly scaned from status register");
                fail = fail + 1;
              end
            end
            else
            begin
              if (phy_data !== tmp_data)
              begin
                test_fail("Third data was not correctly scaned from status register");
                fail = fail + 1;
              end
            end
            // read data from MII status register
            #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if ( ((i < 49) && !i2) || ((i < 17) && i2) )
            begin
              if (phy_data[0] === 1'b0)
              begin
                test_fail("Link FAIL bit was not set in the MII status register");
                fail = fail + 1;
              end
            end
            else
            begin
              if (phy_data[0] !== 1'b0)
              begin
                test_fail("Link FAIL bit was set in the MII status register");
                fail = fail + 1;
              end
            end
          end
          begin
          // check length
            for (i3 = 0; i3 <= 1; i3 = i3 + 1) // two scans
            begin
              #Tp cnt = 0;
              // wait for serial bus to become active if there is more than one scan
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
              // check transfer length
              if (i2) // without preamble
              begin
                if (cnt != 33) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("3. or 4. scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              else // with preamble
              begin
                if (cnt != 65) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("3. or 4. scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
            end
          end
        join
        // reset counter
        #Tp cnt = 0;
        // check fifth scan and data from fourth scan
        fork
        begin
          repeat(2) @(posedge Mdc_O);
          // read data from PHY status register
          #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (phy_data !== (tmp_data & 16'hFFFB)) // bit 3 is ZERO
          begin
            test_fail("4. data was not correctly scaned from status register");
            fail = fail + 1;
          end
          // read data from MII status register
          #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          if (phy_data[0] === 1'b0)
          begin
            test_fail("Link FAIL bit was not set in the MII status register");
            fail = fail + 1;
          end
        end
        begin
        // Completely check intermediate scan
          #Tp cnt = 0;
          // wait for serial bus to become active - second scan
          wait(Mdio_IO !== 1'bz);
          // count transfer length
          while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
          begin
            @(posedge Mdc_O);
            #Tp cnt = cnt + 1;
          end
          // check transfer length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Fifth scan request did not proceed correctly");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("Fifth scan request did not proceed correctly");
              fail = fail + 1;
            end
          end
        end
        join
        // reset counter 
        #Tp cnt = 0;
        // SLIDING LINK UP and CHECK
        fork
          begin
          // set link up
            repeat(i) @(posedge Mdc_O);
            // set link up
            #Tp eth_phy.link_up_down(1);
          end
          begin
          // check data in MII registers after each scan in this fork statement
            repeat(2) @(posedge Mdc_O);
            if (i2) // without preamble
              wait (cnt == 32);
            else // with preamble
              wait (cnt == 64);
            repeat(3) @(posedge Mdc_O);
            // read data from PHY status register
            #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if ( ((i < 49) && !i2) || ((i < 17) && i2) )
            begin
              if (phy_data !== tmp_data) 
              begin
                test_fail("6. data was not correctly scaned from status register");
                fail = fail + 1;
              end
            end
            else
            begin
              if (phy_data !== (tmp_data & 16'hFFFB)) // bit 3 is ZERO
              begin
                test_fail("6. data was not correctly scaned from status register");
                fail = fail + 1;
              end
            end
            // read data from MII status register
            #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if ( ((i < 49) && !i2) || ((i < 17) && i2) )
            begin
              if (phy_data[0] !== 1'b0)
              begin
                test_fail("Link FAIL bit was set in the MII status register");
                fail = fail + 1;
              end
            end
            else
            begin
              if (phy_data[0] === 1'b0)
              begin
                test_fail("Link FAIL bit was not set in the MII status register");
                fail = fail + 1;
              end
            end
          end
          begin
          // check length
            for (i3 = 0; i3 <= 1; i3 = i3 + 1) // two scans
            begin
              #Tp cnt = 0;
              // wait for serial bus to become active if there is more than one scan
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
              // check transfer length
              if (i2) // without preamble
              begin
                if (cnt != 33) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("Scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              else // with preamble
              begin
                if (cnt != 65) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("Scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
            end
          end
        join
        // check last scan 
        repeat(4) @(posedge Mdc_O);
        // read data from PHY status register
        #Tp wbm_read(`ETH_MIIRX_DATA, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data !== tmp_data)
        begin
          test_fail("7. data was not correctly scaned from status register");
          fail = fail + 1;
        end
        // read data from MII status register
        #Tp wbm_read(`ETH_MIISTATUS, phy_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
        if (phy_data[0] !== 1'b0)
        begin
          test_fail("Link FAIL bit was set in the MII status register");
          fail = fail + 1;
        end
  
        #Tp mii_scan_finish; // finish scan operation
        #Tp check_mii_busy; // wait for scan to finish
        #Tp;
        // set delay of writing the command
        if (i2) // without preamble
        begin
          case(i)
            0,  1,  2,  3,  4:  i = i + 1;
            13, 14, 15, 16, 17,
            18, 19, 20, 21, 22,
            23, 24, 25, 26, 27,
            28, 29, 30, 31, 32,
            33, 34, 35:         i = i + 1;
            36:                 i = 80;
            default:            i = 13;
          endcase
        end
        else // with preamble
        begin
          case(i)
            0,  1,  2,  3,  4:  i = i + 1;
            45, 46, 47, 48, 49,
            50, 51, 52, 53, 54, 
            55, 56, 57, 58, 59, 
            60, 61, 62, 63, 64, 
            65, 66, 67:         i = i + 1;
            68:                 i = 80;
            default:            i = 45;
          endcase
        end
        @(posedge wb_clk);
        #Tp;
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test sliding stop scan command immediately after scan     ////
  ////  request (with and without preamble)                       ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 16) // 
  begin
    // TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER SCAN REQUEST ( WITH AND WITHOUT PREAMBLE )
    test_name = "TEST 16: TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER SCAN REQUEST ( WITH AND WITHOUT PREAMBLE )";
    `TIME; 
    $display("  TEST 16: TEST SLIDING STOP SCAN COMMAND IMMEDIATELY AFTER SCAN REQUEST ( WITH AND WITHOUT PREAMBLE )");
  
    for (i2 = 0; i2 <= 1; i2 = i2 + 1) // choose preamble or not
    begin
      #Tp eth_phy.preamble_suppresed(i2);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i2, 8'h0}), 4'hF, 1, wbm_init_waits, 
                wbm_subseq_waits);
      i = 0;
      cnt = 0;
      while (i < 80) // delay for sliding of writing a STOP SCAN command
      begin
        for (i3 = 0; i3 <= 1; i3 = i3 + 1) // choose read or write after scan will be finished
        begin
          // set address
          reg_addr = 5'h0; // control register
          phy_addr = 5'h1; // correct PHY address
          cnt = 0;
          // scan request
          #Tp mii_scan_req(phy_addr, reg_addr);
          fork
            begin
              repeat(i) @(posedge Mdc_O);
              // write command 0x0 into MII command register
              // MII command written while scan in progress
              wbm_write(`ETH_MIICOMMAND, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
              @(posedge wb_clk);
              #Tp check_mii_busy; // wait for scan to finish
              @(posedge wb_clk);
              disable check;
            end
            begin: check
              // wait for serial bus to become active
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
              // check transfer length
              if (i2) // without preamble
              begin
                if (cnt != 33) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              else // with preamble
              begin
                if (cnt != 65) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              cnt = 0;
              // wait for serial bus to become active if there is more than one scan
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
              // check transfer length
              if (i2) // without preamble
              begin
                if (cnt != 33) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              else // with preamble
              begin
                if (cnt != 65) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
            end
          join
          // check the BUSY signal to see if the bus is still IDLE
          for (i1 = 0; i1 < 8; i1 = i1 + 1)
            check_mii_busy; // wait for bus to become idle
    
          // try normal write or read after scan was finished
          phy_data = {8'h7D, (i[7:0] + 1)};
          cnt = 0;
          if (i3 == 0) // write after scan
          begin
            // write request
            #Tp mii_write_req(phy_addr, reg_addr, phy_data);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while(Mdio_IO !== 1'bz)
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          else // read after scan
          begin
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          // check if transfer was a proper length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after scan request");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after scan request");
              fail = fail + 1;
            end
          end
        end
        #Tp;
        // set delay of writing the command
        if (i2) // without preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            18, 19, 20, 21, 22,
            23, 24, 25, 26, 27,
            28, 29, 30, 31, 32,
            33, 34, 35:         i = i + 1;
            36:                 i = 80;
            default:            i = 18;
          endcase
        end
        else // with preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            50, 51, 52, 53, 54, 
            55, 56, 57, 58, 59, 
            60, 61, 62, 63, 64, 
            65, 66, 67:         i = i + 1;
            68:                 i = 80;
            default:            i = 50;
          endcase
        end
        @(posedge wb_clk);
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end


  ////////////////////////////////////////////////////////////////////
  ////                                                            ////
  ////  Test sliding stop scan command after 2. scan (with and    ////
  ////  without preamble)                                         ////
  ////                                                            ////
  ////////////////////////////////////////////////////////////////////
  if (test_num == 17) // 
  begin
    // TEST SLIDING STOP SCAN COMMAND AFTER 2. SCAN ( WITH AND WITHOUT PREAMBLE )
    test_name = "TEST 17: TEST SLIDING STOP SCAN COMMAND AFTER 2. SCAN ( WITH AND WITHOUT PREAMBLE )";
    `TIME; $display("  TEST 17: TEST SLIDING STOP SCAN COMMAND AFTER 2. SCAN ( WITH AND WITHOUT PREAMBLE )");
  
    for (i2 = 0; i2 <= 1; i2 = i2 + 1) // choose preamble or not
    begin
      #Tp eth_phy.preamble_suppresed(i2);
      // MII mode register
      wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_NOPRE & {23'h0, i2, 8'h0}), 4'hF, 1, wbm_init_waits, 
                wbm_subseq_waits);
  
      i = 0;
      cnt = 0;
      while (i < 80) // delay for sliding of writing a STOP SCAN command
      begin
        for (i3 = 0; i3 <= 1; i3 = i3 + 1) // choose read or write after scan will be finished
        begin
          // first there are two scans
          // set address
          reg_addr = 5'h0; // control register
          phy_addr = 5'h1; // correct PHY address
          cnt = 0;
          // scan request
          #Tp mii_scan_req(phy_addr, reg_addr);
          // wait and check first 2 scans
          begin
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            // check transfer length
            if (i2) // without preamble
            begin
              if (cnt != 33) // at this value Mdio_IO is HIGH Z
              begin
                test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                fail = fail + 1;
              end
            end
            else // with preamble
            begin
              if (cnt != 65) // at this value Mdio_IO is HIGH Z
              begin
                test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                fail = fail + 1;
              end
            end
            cnt = 0;
            // wait for serial bus to become active if there is more than one scan
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            // check transfer length
            if (i2) // without preamble
            begin
              if (cnt != 33) // at this value Mdio_IO is HIGH Z
              begin
                test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                fail = fail + 1;
              end
            end
            else // with preamble
            begin
              if (cnt != 65) // at this value Mdio_IO is HIGH Z
              begin
                test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                fail = fail + 1;
              end
            end
          end
  
          // reset counter 
          cnt = 0;
          fork
            begin
              repeat(i) @(posedge Mdc_O);
              // write command 0x0 into MII command register
              // MII command written while scan in progress
              wbm_write(`ETH_MIICOMMAND, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
              @(posedge wb_clk);
              #Tp check_mii_busy; // wait for scan to finish
              @(posedge wb_clk);
              disable check_3;
            end
            begin: check_3
              // wait for serial bus to become active
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
              // check transfer length
              if (i2) // without preamble
              begin
                if (cnt != 33) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              else // with preamble
              begin
                if (cnt != 65) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              cnt = 0;
              // wait for serial bus to become active if there is more than one scan
              wait(Mdio_IO !== 1'bz);
              // count transfer length
              while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
              begin
                @(posedge Mdc_O);
                #Tp cnt = cnt + 1;
              end
              // check transfer length
              if (i2) // without preamble
              begin
                if (cnt != 33) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
              else // with preamble
              begin
                if (cnt != 65) // at this value Mdio_IO is HIGH Z
                begin
                  test_fail("First scan request did not proceed correctly, while SCAN STOP was written");
                  fail = fail + 1;
                end
              end
            end
          join
          // check the BUSY signal to see if the bus is still IDLE
          for (i1 = 0; i1 < 8; i1 = i1 + 1)
            check_mii_busy; // wait for bus to become idle
    
          // try normal write or read after scan was finished
          phy_data = {8'h7D, (i[7:0] + 1)};
          cnt = 0;
          if (i3 == 0) // write after scan
          begin
            // write request
            #Tp mii_write_req(phy_addr, reg_addr, phy_data);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while(Mdio_IO !== 1'bz)
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          else // read after scan
          begin
            // read request
            #Tp mii_read_req(phy_addr, reg_addr);
            // wait for serial bus to become active
            wait(Mdio_IO !== 1'bz);
            // count transfer length
            while( (Mdio_IO !== 1'bz) || ((cnt == 47) && (i2 == 0)) || ((cnt == 15) && (i2 == 1)) )
            begin
              @(posedge Mdc_O);
              #Tp cnt = cnt + 1;
            end
            @(posedge Mdc_O);
            check_mii_busy; // wait for read to finish
            // read and check data
            #Tp wbm_read(`ETH_MIIRX_DATA, tmp_data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
            if (phy_data !== tmp_data)
            begin
              test_fail("Data was not correctly written into OR read from PHY register - control register");
              fail = fail + 1;
            end
          end
          // check if transfer was a proper length
          if (i2) // without preamble
          begin
            if (cnt != 33) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after scan request");
              fail = fail + 1;
            end
          end
          else // with preamble
          begin
            if (cnt != 65) // at this value Mdio_IO is HIGH Z
            begin
              test_fail("New request did not proceed correctly, after scan request");
              fail = fail + 1;
            end
          end
        end
        #Tp;
        // set delay of writing the command
        if (i2) // without preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            18, 19, 20, 21, 22,
            23, 24, 25, 26, 27,
            28, 29, 30, 31, 32,
            33, 34, 35:         i = i + 1;
            36:                 i = 80;
            default:            i = 18;
          endcase
        end
        else // with preamble
        begin
          case(i)
            0, 1:               i = i + 1;
            50, 51, 52, 53, 54, 
            55, 56, 57, 58, 59, 
            60, 61, 62, 63, 64, 
            65, 66, 67:         i = i + 1;
            68:                 i = 80;
            default:            i = 50;
          endcase
        end
        @(posedge wb_clk);
      end
    end
    // set PHY to normal mode
    #Tp eth_phy.preamble_suppresed(0);
    // MII mode register
    wbm_write(`ETH_MIIMODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if(fail == 0)
      test_ok;
    else
      fail = 0;
  end

end   //  for (test_num=start_task; test_num <= end_task; test_num=test_num+1)

end
endtask // test_mii


task test_mac_full_duplex_transmit;
  input  [31:0]  start_task;
  input  [31:0]  end_task;
  integer        bit_start_1;
  integer        bit_end_1;
  integer        bit_start_2;
  integer        bit_end_2;
  integer        num_of_reg;
  integer        i_addr;
  integer        i_data;
  integer        i_length;
  integer        tmp_data;
  reg    [31:0]  tx_bd_num;
  reg    [((`MAX_BLK_SIZE * 32) - 1):0] burst_data;
  reg    [((`MAX_BLK_SIZE * 32) - 1):0] burst_tmp_data;
  integer        i;
  integer        i1;
  integer        i2;
  integer        i3;
  integer        fail;
  integer        speed;
  reg    [31:0]  addr;
  reg    [31:0]  data;
  reg    [31:0]  tmp;
  reg    [ 7:0]  st_data;
  reg    [15:0]  max_tmp;
  reg    [15:0]  min_tmp;
begin
// MAC FULL DUPLEX TRANSMIT TEST
test_heading("MAC FULL DUPLEX TRANSMIT TEST");
$display(" ");
$display("MAC FULL DUPLEX TRANSMIT TEST");
fail = 0;

// reset MAC registers
hard_reset;
// reset MAC and MII LOGIC with soft reset
reset_mac;
reset_mii;
// set wb slave response
wb_slave.cycle_response(`ACK_RESPONSE, wbs_waits, wbs_retries);

  /*
  TASKS for set and control TX buffer descriptors (also send packet - set_tx_bd_ready):
  -------------------------------------------------------------------------------------
  set_tx_bd 
    (tx_bd_num_start[6:0], tx_bd_num_end[6:0], len[15:0], irq, pad, crc, txpnt[31:0]);
  set_tx_bd_wrap 
    (tx_bd_num_end[6:0]);
  set_tx_bd_ready 
    (tx_bd_num_start[6:0], tx_bd_num_end[6:0]);
  check_tx_bd 
    (tx_bd_num_start[6:0], tx_bd_status[31:0]);
  clear_tx_bd 
    (tx_bd_num_start[6:0], tx_bd_num_end[6:0]);

  TASKS for set and control RX buffer descriptors:
  ------------------------------------------------
  set_rx_bd 
    (rx_bd_num_strat[6:0], rx_bd_num_end[6:0], irq, rxpnt[31:0]);
  set_rx_bd_wrap 
    (rx_bd_num_end[6:0]);
  set_rx_bd_empty 
    (rx_bd_num_strat[6:0], rx_bd_num_end[6:0]);
  check_rx_bd 
    (rx_bd_num_end[6:0], rx_bd_status);
  clear_rx_bd 
    (rx_bd_num_strat[6:0], rx_bd_num_end[6:0]);

  TASKS for set and check TX packets:
  -----------------------------------
  set_tx_packet 
    (txpnt[31:0], len[15:0], eth_start_data[7:0]);
  check_tx_packet 
    (txpnt_wb[31:0], txpnt_phy[31:0], len[15:0], failure[31:0]);

  TASKS for set and check RX packets:
  -----------------------------------
  set_rx_packet 
    (rxpnt[31:0], len[15:0], plus_nibble, d_addr[47:0], s_addr[47:0], type_len[15:0], start_data[7:0]);
  check_rx_packet 
    (rxpnt_phy[31:0], rxpnt_wb[31:0], len[15:0], plus_nibble, successful_nibble, failure[31:0]);

  TASKS for append and check CRC to/of TX packet:
  -----------------------------------------------
  append_tx_crc 
    (txpnt_wb[31:0], len[15:0], negated_crc);
  check_tx_crc 
    (txpnt_phy[31:0], len[15:0], negated_crc, failure[31:0]); 

  TASK for append CRC to RX packet (CRC is checked together with check_rx_packet):
  --------------------------------------------------------------------------------
  append_rx_crc 
    (rxpnt_phy[31:0], len[15:0], plus_nibble, negated_crc);
  */


if ((start_task <= 0) && (end_task >= 0))
begin
  // TEST NO TRANSMIT WHEN ALL BUFFERS ARE RX ( 10Mbps )
  test_name   = "TEST NO TRANSMIT WHEN ALL BUFFERS ARE RX ( 10Mbps )";
  `TIME; $display("  TEST NO TRANSMIT WHEN ALL BUFFERS ARE RX ( 10Mbps )");

  // unmask interrupts
  wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
                           `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set all buffer descriptors to RX - must be set before TX enable
  wbm_write(`ETH_TX_BD_NUM, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // enable TX, set full-duplex mode, padding and CRC appending
  wbm_write(`ETH_MODER, `ETH_MODER_TXEN | `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN, 
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);

  // write to phy's control register for 10Mbps
  #Tp eth_phy.control_bit14_10 = 5'b00000; // bit 13 reset - speed 10
  #Tp eth_phy.control_bit8_0   = 9'h1_00;  // bit 6 reset  - (10/100), bit 8 set - FD
  speed = 10;

  i = 0;
  while (i < 128)
  begin
    for (i1 = 0; i1 <= i; i1 = i1 + 1)
    begin
      set_tx_packet((`MEMORY_BASE + (i1 * 200)), 100, 0);
      set_tx_bd(i1, i1, 100, 1'b1, 1'b1, 1'b1, (`MEMORY_BASE + (i1 * 200)));
    end
    set_tx_bd_wrap(i);
    fork
      begin
        set_tx_bd_ready(0, i);
        repeat(20) @(negedge mtx_clk);
        #1 disable check_tx_en10;
      end
      begin: check_tx_en10
        wait (MTxEn === 1'b1);
        test_fail("Tramsmit should not start at all");
        fail = fail + 1;
        `TIME; $display("*E Transmit of %d packets should not start at all - active MTxEn", i);
      end
    join
    for (i2 = 0; i2 < 20; i2 = i2 + 1)
    begin
      check_tx_bd(0, tmp);
      #1;
      if (tmp[15] === 1'b0)
      begin
        test_fail("Tramsmit should not start at all");
        fail = fail + 1;
        `TIME; $display("*E Transmit of %d packets should not start at all - ready is 0", i);
      end
      if (tmp[8:0] !== 0)
      begin
        test_fail("Tramsmit should not be finished since it should not start at all");
        fail = fail + 1;
        `TIME; $display("*E Transmit of should not be finished since it should not start at all");
      end
      @(posedge wb_clk);
    end
    wbm_read(`ETH_INT, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (tmp[6:0] !== 0)
    begin
      test_fail("Tramsmit should not get INT since it should not start at all");
      fail = fail + 1;
      `TIME; $display("*E Transmit of should not get INT since it should not start at all");
    end
    clear_tx_bd(0, i);
    if ((i < 5) || (i > 124))
      i = i + 1;
    else
      i = i + 120;
  end
  // disable TX
  wbm_write(`ETH_MODER, `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN,
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  if(fail == 0)
    test_ok;
  else
    fail = 0;
end


if ((start_task <= 1) && (end_task >= 1))
begin
  // TEST NO TRANSMIT WHEN ALL BUFFERS ARE RX ( 100Mbps )
  test_name   = "TEST NO TRANSMIT WHEN ALL BUFFERS ARE RX ( 100Mbps )";
  `TIME; $display("  TEST NO TRANSMIT WHEN ALL BUFFERS ARE RX ( 100Mbps )");

  // unmask interrupts
  wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
                           `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set all buffer descriptors to RX - must be set before TX enable
  wbm_write(`ETH_TX_BD_NUM, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // enable TX, set full-duplex mode, padding and CRC appending
  wbm_write(`ETH_MODER, `ETH_MODER_TXEN | `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN, 
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);

  // write to phy's control register for 100Mbps
  #Tp eth_phy.control_bit14_10 = 5'b01000; // bit 13 set - speed 100
  #Tp eth_phy.control_bit8_0   = 9'h1_00;  // bit 6 reset - (10/100), bit 8 set - FD
  speed = 100;

  i = 0;
  while (i < 128)
  begin
    for (i1 = 0; i1 <= i; i1 = i1 + 1)
    begin
      set_tx_packet((`MEMORY_BASE + (i1 * 200)), 100, 0);
      set_tx_bd(i1, i1, 100, 1'b1, 1'b1, 1'b1, (`MEMORY_BASE + (i1 * 200)));
    end
    set_tx_bd_wrap(i);
    fork
      begin
        set_tx_bd_ready(0, i);
        repeat(20) @(negedge mtx_clk);
        #1 disable check_tx_en100;
      end
      begin: check_tx_en100
        wait (MTxEn === 1'b1);
        test_fail("Tramsmit should not start at all");
        fail = fail + 1;
        `TIME; $display("*E Transmit of %d packets should not start at all - active MTxEn", i);
      end
    join
    for (i2 = 0; i2 < 20; i2 = i2 + 1)
    begin
      check_tx_bd(0, tmp);
      #1;
      if (tmp[15] === 1'b0)
      begin
        test_fail("Tramsmit should not start at all");
        fail = fail + 1;
        `TIME; $display("*E Transmit of %d packets should not start at all - ready is 0", i);
      end
      if (tmp[8:0] !== 0)
      begin
        test_fail("Tramsmit should not be finished since it should not start at all");
        fail = fail + 1;
        `TIME; $display("*E Transmit of should not be finished since it should not start at all");
      end
      @(posedge wb_clk);
    end
    wbm_read(`ETH_INT, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (tmp[6:0] !== 0)
    begin
      test_fail("Tramsmit should not get INT since it should not start at all");
      fail = fail + 1;
      `TIME; $display("*E Transmit of should not get INT since it should not start at all");
    end
    clear_tx_bd(0, i);
    if ((i < 5) || (i > 124))
      i = i + 1;
    else
      i = i + 120;
  end
  // disable TX
  wbm_write(`ETH_MODER, `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN,
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  if(fail == 0)
    test_ok;
  else
    fail = 0;
end


if ((start_task <= 2) && (end_task >= 2))
begin
  // TEST TRANSMIT PACKETS FROM MINFL TO MAXFL SIZES AT ONE TX BD ( 10Mbps )
  test_name = "TEST TRANSMIT PACKETS FROM MINFL TO MAXFL SIZES AT ONE TX BD ( 10Mbps )";
  `TIME; $display("  TEST TRANSMIT PACKETS FROM MINFL TO MAXFL SIZES AT ONE TX BD ( 10Mbps )");

  max_tmp = 0;
  min_tmp = 0;
//  // unmask interrupts
//  wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
//                           `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set one TX buffer descriptor - must be set before TX enable
  wbm_write(`ETH_TX_BD_NUM, 32'h1, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // enable TX, set full-duplex mode, padding and CRC appending
  wbm_write(`ETH_MODER, `ETH_MODER_TXEN | `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN,
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // prepare two packets of MAXFL length
  wbm_read(`ETH_PACKETLEN, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  max_tmp = tmp[15:0]; // 18 bytes consists of 6B dest addr, 6B source addr, 2B type/len, 4B CRC
  min_tmp = tmp[31:16];
  st_data = 8'h5A;
  set_tx_packet(`MEMORY_BASE, (max_tmp - 4), st_data); // length without CRC
  st_data = 8'h10;
  set_tx_packet((`MEMORY_BASE + max_tmp), (max_tmp - 4), st_data); // length without CRC
  // check WB INT signal
  if (wb_int !== 1'b0)
  begin
    test_fail("WB INT signal should not be set");
    fail = fail + 1;
  end

  // write to phy's control register for 10Mbps
  #Tp eth_phy.control_bit14_10 = 5'b00000; // bit 13 reset - speed 10
  #Tp eth_phy.control_bit8_0   = 9'h1_00;  // bit 6 reset  - (10/100), bit 8 set - FD
  speed = 10;

  for (i_length = (min_tmp - 4); i_length <= (max_tmp - 4); i_length = i_length + 1)
  begin
    // choose generating carrier sense and collision for first and last 64 lengths of frames
    case (i_length[1:0])
    2'h0: // Interrupt is generated
    begin
      // enable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b1, 1'b1, 1'b1, `MEMORY_BASE);
      // unmask interrupts
      wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
                               `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // not detect carrier sense in FD and no collision
      eth_phy.carrier_sense_tx_fd_detect(0);
      eth_phy.collision(0);
    end
    2'h1: // Interrupt is not generated
    begin
      // enable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b1, 1'b1, 1'b1, (`MEMORY_BASE + max_tmp));
      // mask interrupts
      wbm_write(`ETH_INT_MASK, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // detect carrier sense in FD and no collision
      eth_phy.carrier_sense_tx_fd_detect(1);
      eth_phy.collision(0);
    end
    2'h2: // Interrupt is not generated
    begin
      // disable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b0, 1'b1, 1'b1, `MEMORY_BASE);
      // unmask interrupts
      wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
                               `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // not detect carrier sense in FD and set collision
      eth_phy.carrier_sense_tx_fd_detect(0);
      eth_phy.collision(1);
    end
    default: // 2'h3: // Interrupt is not generated
    begin
      // disable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b0, 1'b1, 1'b1, (`MEMORY_BASE + max_tmp));
      // mask interrupts
      wbm_write(`ETH_INT_MASK, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // detect carrier sense in FD and set collision
      eth_phy.carrier_sense_tx_fd_detect(1);
      eth_phy.collision(1);
    end
    endcase
    eth_phy.set_tx_mem_addr(max_tmp);
    // set wrap bit
    set_tx_bd_wrap(0);
    set_tx_bd_ready(0, 0);
    #1 check_tx_bd(0, data);
    if (i_length < min_tmp) // just first four
    begin
      while (data[15] === 1)
      begin
        #1 check_tx_bd(0, data);
        @(posedge wb_clk);
      end
    end
    else if (i_length > (max_tmp - 8)) // just last four
    begin
      tmp = 0;
      wait (MTxEn === 1'b1); // start transmit
      while (tmp < (i_length - 20))
      begin
        #1 tmp = tmp + 1;
        @(posedge wb_clk);
      end
      #1 check_tx_bd(0, data);
      while (data[15] === 1)
      begin
        #1 check_tx_bd(0, data);
        @(posedge wb_clk);
      end
    end
    else
    begin
      wait (MTxEn === 1'b1); // start transmit
      wait (MTxEn === 1'b0); // end transmit
      repeat (2) @(posedge mtx_clk);
      repeat (3) @(posedge wb_clk);
    end
    // check length of a PACKET
    if (eth_phy.tx_len != (i_length + 4))
    begin
      test_fail("Wrong length of the packet out from MAC");
      fail = fail + 1;
    end
    // checking in the following if statement is performed only for first and last 64 lengths
    if ( ((i_length + 4) <= (min_tmp + 64)) || ((i_length + 4) > (max_tmp - 64)) )
    begin
      // check transmitted TX packet data
      if (i_length[0] == 0)
      begin
        check_tx_packet(`MEMORY_BASE, max_tmp, i_length, tmp);
      end
      else
      begin
        check_tx_packet((`MEMORY_BASE + max_tmp), max_tmp, i_length, tmp);
      end
      if (tmp > 0)
      begin
        test_fail("Wrong data of the transmitted packet");
        fail = fail + 1;
      end
      // check transmited TX packet CRC
      check_tx_crc(max_tmp, i_length, 1'b0, tmp); // length without CRC
      if (tmp > 0)
      begin
        test_fail("Wrong CRC of the transmitted packet");
        fail = fail + 1;
      end
    end
    // check WB INT signal
    if (i_length[1:0] == 2'h0)
    begin
      if (wb_int !== 1'b1)
      begin
        `TIME; $display("*E WB INT signal should be set");
        test_fail("WB INT signal should be set");
        fail = fail + 1;
      end
    end
    else
    begin
      if (wb_int !== 1'b0)
      begin
        `TIME; $display("*E WB INT signal should not be set");
        test_fail("WB INT signal should not be set");
        fail = fail + 1;
      end
    end
    // check TX buffer descriptor of a packet
    check_tx_bd(0, data);
    if (i_length[1] == 1'b0) // interrupt enabled
    begin
      if (data[15:0] !== 16'h7800)
      begin
        `TIME; $display("*E TX buffer descriptor status is not correct: %0h", data[15:0]);
        test_fail("TX buffer descriptor status is not correct");
        fail = fail + 1;
      end
    end
    else // interrupt not enabled
    begin
      if (data[15:0] !== 16'h3800)
      begin
        `TIME; $display("*E TX buffer descriptor status is not correct: %0h", data[15:0]);
        test_fail("TX buffer descriptor status is not correct");
        fail = fail + 1;
      end
    end
    // clear TX buffer descriptor
    clear_tx_bd(0, 0);
    // check interrupts
    wbm_read(`ETH_INT, data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (i_length[1:0] == 2'h0)
    begin
      if ((data & `ETH_INT_TXB) !== 1'b1)
      begin
        `TIME; $display("*E Interrupt Transmit Buffer was not set, interrupt reg: %0h", data);
        test_fail("Interrupt Transmit Buffer was not set");
        fail = fail + 1;
      end
      if ((data & (~`ETH_INT_TXB)) !== 0)
      begin
        `TIME; $display("*E Other interrupts (except Transmit Buffer) were set, interrupt reg: %0h", data);
        test_fail("Other interrupts (except Transmit Buffer) were set");
        fail = fail + 1;
      end
    end
    else
    begin
      if (data !== 0)
      begin
        `TIME; $display("*E Any of interrupts (except Transmit Buffer) was set, interrupt reg: %0h, len: %0h", data, i_length[1:0]);
        test_fail("Any of interrupts (except Transmit Buffer) was set");
        fail = fail + 1;
      end
    end
    // clear interrupts
    wbm_write(`ETH_INT, data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // check WB INT signal
    if (wb_int !== 1'b0)
    begin
      test_fail("WB INT signal should not be set");
      fail = fail + 1;
    end
    // INTERMEDIATE DISPLAYS
    if (i_length == min_tmp - 4)
      tmp_data = min_tmp;
    if (i_length == (max_tmp - 4))
    begin
      $display("    packets with lengths from %0d to %0d (MAXFL) are checked (also packet data and CRC)",
               tmp_data, (i_length + 4));
    end
    else if ( ((i_length + 4) !== 64) && (!((i_length + 4) % 64)) ) // display every 64 bytes, except for first byte
    begin
      if ( ((i_length + 4) <= (min_tmp + 64)) || ((i_length + 4) > (max_tmp - 64)) )
        $display("    packets with lengths from %0d to %0d are checked (also packet data and CRC)",
                 tmp_data, (i_length + 4));
      else
        $display("    packets with lengths from %0d to %0d are checked",
                 tmp_data, (i_length + 4));
      tmp_data = i_length + 4 + 1; // next starting length is for +1 longer
    end
  end
  // disable TX
  wbm_write(`ETH_MODER, `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN,
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  if(fail == 0)
    test_ok;
  else
    fail = 0;
end


if ((start_task <= 3) && (end_task >= 3))
begin
  // TEST TRANSMIT PACKETS FROM MINFL TO MAXFL SIZES AT ONE TX BD ( 100Mbps )
  test_name = "TEST TRANSMIT PACKETS FROM MINFL TO MAXFL SIZES AT ONE TX BD ( 100Mbps )";
  `TIME; $display("  TEST TRANSMIT PACKETS FROM MINFL TO MAXFL SIZES AT ONE TX BD ( 100Mbps )");

  max_tmp = 0;
  min_tmp = 0;
//  // unmask interrupts
//  wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
//                           `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set one TX buffer descriptor - must be set before TX enable
  wbm_write(`ETH_TX_BD_NUM, 32'h1, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // enable TX, set full-duplex mode, padding and CRC appending
  wbm_write(`ETH_MODER, `ETH_MODER_TXEN | `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN,
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // prepare two packets of MAXFL length
  wbm_read(`ETH_PACKETLEN, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  max_tmp = tmp[15:0]; // 18 bytes consists of 6B dest addr, 6B source addr, 2B type/len, 4B CRC
  min_tmp = tmp[31:16];
  st_data = 8'h5A;
  set_tx_packet(`MEMORY_BASE, (max_tmp - 4), st_data); // length without CRC
  st_data = 8'h10;
  set_tx_packet((`MEMORY_BASE + max_tmp), (max_tmp - 4), st_data); // length without CRC
  // check WB INT signal
  if (wb_int !== 1'b0)
  begin
    test_fail("WB INT signal should not be set");
    fail = fail + 1;
  end

  // write to phy's control register for 100Mbps
  #Tp eth_phy.control_bit14_10 = 5'b01000; // bit 13 set - speed 100
  #Tp eth_phy.control_bit8_0   = 9'h1_00;  // bit 6 reset - (10/100), bit 8 set - FD
  speed = 100;

  for (i_length = (min_tmp - 4); i_length <= (max_tmp - 4); i_length = i_length + 1)
  begin
    // choose generating carrier sense and collision
    case (i_length[1:0])
    2'h0: // Interrupt is generated
    begin
      // enable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b1, 1'b1, 1'b1, `MEMORY_BASE);
      // unmask interrupts
      wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
                               `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // not detect carrier sense in FD and no collision
      eth_phy.carrier_sense_tx_fd_detect(0);
      eth_phy.collision(0);
    end
    2'h1: // Interrupt is not generated
    begin
      // enable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b1, 1'b1, 1'b1, (`MEMORY_BASE + max_tmp));
      // mask interrupts
      wbm_write(`ETH_INT_MASK, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // detect carrier sense in FD and no collision
      eth_phy.carrier_sense_tx_fd_detect(1);
      eth_phy.collision(0);
    end
    2'h2: // Interrupt is not generated
    begin
      // disable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b0, 1'b1, 1'b1, `MEMORY_BASE);
      // unmask interrupts
      wbm_write(`ETH_INT_MASK, `ETH_INT_TXB | `ETH_INT_TXE | `ETH_INT_RXF | `ETH_INT_RXE | `ETH_INT_BUSY |
                               `ETH_INT_TXC | `ETH_INT_RXC, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // not detect carrier sense in FD and set collision
      eth_phy.carrier_sense_tx_fd_detect(0);
      eth_phy.collision(1);
    end
    default: // 2'h3: // Interrupt is not generated
    begin
      // disable interrupt generation
      set_tx_bd(0, 0, i_length, 1'b0, 1'b1, 1'b1, (`MEMORY_BASE + max_tmp));
      // mask interrupts
      wbm_write(`ETH_INT_MASK, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
      // detect carrier sense in FD and set collision
      eth_phy.carrier_sense_tx_fd_detect(1);
      eth_phy.collision(1);
    end
    endcase
    eth_phy.set_tx_mem_addr(max_tmp);
    // set wrap bit
    set_tx_bd_wrap(0);
    set_tx_bd_ready(0, 0);
    #1 check_tx_bd(0, data);
    if (i_length < min_tmp) // just first four
    begin
      while (data[15] === 1)
      begin
        #1 check_tx_bd(0, data);
        @(posedge wb_clk);
      end
    end
    else if (i_length > (max_tmp - 8)) // just last four
    begin
      tmp = 0;
      wait (MTxEn === 1'b1); // start transmit
      while (tmp < (i_length - 20))
      begin
        #1 tmp = tmp + 1;
        @(posedge wb_clk);
      end
      #1 check_tx_bd(0, data);
      while (data[15] === 1)
      begin
        #1 check_tx_bd(0, data);
        @(posedge wb_clk);
      end
    end
    else
    begin
      wait (MTxEn === 1'b1); // start transmit
      wait (MTxEn === 1'b0); // end transmit
      repeat (2) @(posedge mtx_clk);
      repeat (3) @(posedge wb_clk);
    end
    // check length of a PACKET
    if (eth_phy.tx_len != (i_length + 4))
    begin
      test_fail("Wrong length of the packet out from MAC");
      fail = fail + 1;
    end
    // checking in the following if statement is performed only for first and last 64 lengths
    if ( ((i_length + 4) <= (min_tmp + 64)) || ((i_length + 4) > (max_tmp - 64)) )
    begin
      // check transmitted TX packet data
      if (i_length[0] == 0)
      begin
        check_tx_packet(`MEMORY_BASE, max_tmp, i_length, tmp);
      end
      else
      begin
        check_tx_packet((`MEMORY_BASE + max_tmp), max_tmp, i_length, tmp);
      end
      if (tmp > 0)
      begin
        test_fail("Wrong data of the transmitted packet");
        fail = fail + 1;
      end
      // check transmited TX packet CRC
      check_tx_crc(max_tmp, i_length, 1'b0, tmp); // length without CRC
      if (tmp > 0)
      begin
        test_fail("Wrong CRC of the transmitted packet");
        fail = fail + 1;
      end
    end
    // check WB INT signal
    if (i_length[1:0] == 2'h0)
    begin
      if (wb_int !== 1'b1)
      begin
        `TIME; $display("*E WB INT signal should be set");
        test_fail("WB INT signal should be set");
        fail = fail + 1;
      end
    end
    else
    begin
      if (wb_int !== 1'b0)
      begin
        `TIME; $display("*E WB INT signal should not be set");
        test_fail("WB INT signal should not be set");
        fail = fail + 1;
      end
    end
    // check TX buffer descriptor of a packet
    check_tx_bd(0, data);
    if (i_length[1] == 1'b0) // interrupt enabled
    begin
      if (data[15:0] !== 16'h7800)
      begin
        `TIME; $display("*E TX buffer descriptor status is not correct: %0h", data[15:0]);
        test_fail("TX buffer descriptor status is not correct");
        fail = fail + 1;
      end
    end
    else // interrupt not enabled
    begin
      if (data[15:0] !== 16'h3800)
      begin
        `TIME; $display("*E TX buffer descriptor status is not correct: %0h", data[15:0]);
        test_fail("TX buffer descriptor status is not correct");
        fail = fail + 1;
      end
    end
    // clear TX buffer descriptor
    clear_tx_bd(0, 0);
    // check interrupts
    wbm_read(`ETH_INT, data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    if (i_length[1:0] == 2'h0)
    begin
      if ((data & `ETH_INT_TXB) !== 1'b1)
      begin
        `TIME; $display("*E Interrupt Transmit Buffer was not set, interrupt reg: %0h", data);
        test_fail("Interrupt Transmit Buffer was not set");
        fail = fail + 1;
      end
      if ((data & (~`ETH_INT_TXB)) !== 0)
      begin
        `TIME; $display("*E Other interrupts (except Transmit Buffer) were set, interrupt reg: %0h", data);
        test_fail("Other interrupts (except Transmit Buffer) were set");
        fail = fail + 1;
      end
    end
    else
    begin
      if (data !== 0)
      begin
        `TIME; $display("*E Any of interrupts (except Transmit Buffer) was set, interrupt reg: %0h", data);
        test_fail("Any of interrupts (except Transmit Buffer) was set");
        fail = fail + 1;
      end
    end
    // clear interrupts
    wbm_write(`ETH_INT, data, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // check WB INT signal
    if (wb_int !== 1'b0)
    begin
      test_fail("WB INT signal should not be set");
      fail = fail + 1;
    end
    // INTERMEDIATE DISPLAYS
    if (i_length == min_tmp - 4)
      tmp_data = min_tmp;
    if (i_length == (max_tmp - 4))
    begin
      $display("    packets with lengths from %0d to %0d (MAXFL) are checked (also packet data and CRC)",
               tmp_data, (i_length + 4));
    end
    else if ( ((i_length + 4) !== 64) && (!((i_length + 4) % 64)) ) // display every 64 bytes, except for first byte
    begin
      if ( ((i_length + 4) <= (min_tmp + 64)) || ((i_length + 4) > (max_tmp - 64)) )
        $display("    packets with lengths from %0d to %0d are checked (also packet data and CRC)",
                 tmp_data, (i_length + 4));
      else
        $display("    packets with lengths from %0d to %0d are checked",
                 tmp_data, (i_length + 4));
      tmp_data = i_length + 4 + 1; // next starting length is for +1 longer
    end
  end
  // disable TX
  wbm_write(`ETH_MODER, `ETH_MODER_FULLD | `ETH_MODER_PAD | `ETH_MODER_CRCEN,
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  if(fail == 0)
    test_ok;
  else
    fail = 0;
end



/*
          wbm_write(`ETH_MODER, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          wbm_read(`ETH_MODER, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    
          wbm_write(32'hd0000000, `ETH_MODER_RXEN  | `ETH_MODER_TXEN | `ETH_MODER_PRO | `ETH_MODER_CRCEN |
                    `ETH_MODER_PAD, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
          wbm_read(32'hd0000000, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);

          
          
    
          set_tx_bd(3);
          set_rx_bd(6);
    
          set_tx_packet(16'h34, 8'h1);
          set_tx_packet(16'h34, 8'h11);
          send_tx_packet;
          set_tx_packet(16'h34, 8'h21);
          set_tx_packet(16'h34, 8'h31);
          send_tx_packet;


          eth_phy.GetDataOnMRxD(100, `BROADCAST_XFR); // LengthRx bytes is comming on MRxD[3:0] signals
          repeat (100) @(posedge mrx_clk);   // Waiting for TxEthMac to finish transmit

          eth_phy.GetDataOnMRxD(70, `BROADCAST_XFR); // LengthRx bytes is comming on MRxD[3:0] signals
          repeat (10000) @(posedge wb_clk);   // Waiting for TxEthMac to finish transmit

          eth_phy.GetDataOnMRxD(70, `MULTICAST_XFR); // LengthRx bytes is comming on MRxD[3:0] signals
          repeat (10000) @(posedge wb_clk);   // Waiting for TxEthMac to finish transmit
*/


end
endtask // test_mac_full_duplex_transmit


//////////////////////////////////////////////////////////////
// WB Behavioral Models Basic tasks
//////////////////////////////////////////////////////////////

task wbm_write;
  input  [31:0] address_i;
  input  [((`MAX_BLK_SIZE * 32) - 1):0] data_i;
  input  [3:0]  sel_i;
  input  [31:0] size_i;
  input  [3:0]  init_waits_i;
  input  [3:0]  subseq_waits_i;

  reg `WRITE_STIM_TYPE write_data;
  reg `WB_TRANSFER_FLAGS flags;
  reg `WRITE_RETURN_TYPE write_status;
  integer i;
begin
  write_status = 0;

  flags                    = 0;
  flags`WB_TRANSFER_SIZE   = size_i;
  flags`INIT_WAITS         = init_waits_i;
  flags`SUBSEQ_WAITS       = subseq_waits_i;

  write_data               = 0;
  write_data`WRITE_DATA    = data_i[31:0];
  write_data`WRITE_ADDRESS = address_i;
  write_data`WRITE_SEL     = sel_i;

  for (i = 0; i < size_i; i = i + 1)
  begin
    wb_master.blk_write_data[i] = write_data;
    data_i                      = data_i >> 32;
    write_data`WRITE_DATA       = data_i[31:0];
    write_data`WRITE_ADDRESS    = write_data`WRITE_ADDRESS + 4;
  end

  wb_master.wb_block_write(flags, write_status);

  if (write_status`CYC_ACTUAL_TRANSFER !== size_i)
  begin
    `TIME;
    $display("*E WISHBONE Master was unable to complete the requested write operation to MAC!");
  end
end
endtask // wbm_write

task wbm_read;
  input  [31:0] address_i;
  output [((`MAX_BLK_SIZE * 32) - 1):0] data_o;
  input  [3:0]  sel_i;
  input  [31:0] size_i;
  input  [3:0]  init_waits_i;
  input  [3:0]  subseq_waits_i;

  reg `READ_RETURN_TYPE read_data;
  reg `WB_TRANSFER_FLAGS flags;
  reg `READ_RETURN_TYPE read_status;
  integer i;
begin
  read_status = 0;
  data_o      = 0;

  flags                  = 0;
  flags`WB_TRANSFER_SIZE = size_i;
  flags`INIT_WAITS       = init_waits_i;
  flags`SUBSEQ_WAITS     = subseq_waits_i;

  read_data              = 0;
  read_data`READ_ADDRESS = address_i;
  read_data`READ_SEL     = sel_i;

  for (i = 0; i < size_i; i = i + 1)
  begin
    wb_master.blk_read_data_in[i] = read_data;
    read_data`READ_ADDRESS        = read_data`READ_ADDRESS + 4;
  end

  wb_master.wb_block_read(flags, read_status);

  if (read_status`CYC_ACTUAL_TRANSFER !== size_i)
  begin
    `TIME;
    $display("*E WISHBONE Master was unable to complete the requested read operation from MAC!");
  end

  for (i = 0; i < size_i; i = i + 1)
  begin
    data_o       = data_o << 32;
    read_data    = wb_master.blk_read_data_out[(size_i - 1) - i]; // [31 - i];
    data_o[31:0] = read_data`READ_DATA;
  end
end
endtask // wbm_read


//////////////////////////////////////////////////////////////
// Ethernet Basic tasks
//////////////////////////////////////////////////////////////

task hard_reset; //  MAC registers
begin
  // reset MAC registers
  @(posedge wb_clk);
  #2 wb_rst = 1'b1;
  repeat(2) @(posedge wb_clk);
  #2 wb_rst = 1'b0;
end
endtask // hard_reset

task reset_mac; //  MAC module
  reg [31:0] tmp;
  reg [31:0] tmp_no_rst;
begin
  // read MODER register first
  wbm_read(`ETH_MODER, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set reset bit - write back to MODER register with RESET bit
  wbm_write(`ETH_MODER, (`ETH_MODER_RST | tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // clear reset bit - write back to MODER register without RESET bit
  tmp_no_rst = `ETH_MODER_RST;
  tmp_no_rst = ~tmp_no_rst;
  wbm_write(`ETH_MODER, (tmp_no_rst & tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
end
endtask // reset_mac

task set_tx_bd;
  input  [6:0]  tx_bd_num_start;
  input  [6:0]  tx_bd_num_end;
  input  [15:0] len;
  input         irq;
  input         pad;
  input         crc;
  input  [31:0] txpnt;

  integer       i;
  integer       bd_status_addr, bd_ptr_addr;
//  integer       buf_addr;
begin
  for(i = tx_bd_num_start; i <= tx_bd_num_end; i = i + 1) 
  begin
//    buf_addr = `TX_BUF_BASE + i * 32'h600;
    bd_status_addr = `TX_BD_BASE + i * 8;
    bd_ptr_addr = bd_status_addr + 4;
    // initialize BD - status
//    wbm_write(bd_status_addr, 32'h00005800, 4'hF, 1, wbm_init_waits, wbm_subseq_waits); // IRQ + PAD + CRC
    wbm_write(bd_status_addr, {len, 1'b0, irq, 1'b0, pad, crc, 11'h0}, 
              4'hF, 1, wbm_init_waits, wbm_subseq_waits); // IRQ + PAD + CRC
    // initialize BD - pointer
//    wbm_write(bd_ptr_addr, buf_addr, 4'hF, 1, wbm_init_waits, wbm_subseq_waits); // Initializing BD-pointer
    wbm_write(bd_ptr_addr, txpnt, 4'hF, 1, wbm_init_waits, wbm_subseq_waits); // Initializing BD-pointer
  end
end
endtask // set_tx_bd

task set_tx_bd_wrap;
  input  [6:0]  tx_bd_num_end;
  integer       bd_status_addr, tmp;
begin
  bd_status_addr = `TX_BD_BASE + tx_bd_num_end * 8;
  wbm_read(bd_status_addr, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set wrap bit to this BD - this BD should be last-one
  wbm_write(bd_status_addr, (`ETH_TX_BD_WRAP | tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
end
endtask // set_tx_bd_wrap

task set_tx_bd_ready;
  input  [6:0]  tx_nd_num_strat;
  input  [6:0]  tx_bd_num_end;
  integer       i;
  integer       bd_status_addr, tmp;
begin
  for(i = tx_nd_num_strat; i <= tx_bd_num_end; i = i + 1)
  begin
    bd_status_addr = `TX_BD_BASE + i * 8;
    wbm_read(bd_status_addr, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // set empty bit to this BD - this BD should be ready
    wbm_write(bd_status_addr, (`ETH_TX_BD_READY | tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  end
end
endtask // set_tx_bd_ready

task check_tx_bd;
  input  [6:0]  tx_bd_num_end;
  output [31:0] tx_bd_status;
  integer       bd_status_addr, tmp;
begin
  bd_status_addr = `TX_BD_BASE + tx_bd_num_end * 8;
  wbm_read(bd_status_addr, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  #1 tx_bd_status = tmp;
  #1;
end
endtask // check_tx_bd

task clear_tx_bd;
  input  [6:0]  tx_nd_num_strat;
  input  [6:0]  tx_bd_num_end;
  integer       i;
  integer       bd_status_addr, bd_ptr_addr;
begin
  for(i = tx_nd_num_strat; i <= tx_bd_num_end; i = i + 1)
  begin
    bd_status_addr = `TX_BD_BASE + i * 8;
    bd_ptr_addr = bd_status_addr + 4;
    // clear BD - status
    wbm_write(bd_status_addr, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // clear BD - pointer
    wbm_write(bd_ptr_addr, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  end
end
endtask // clear_tx_bd

task set_rx_bd;
  input  [6:0]  rx_bd_num_strat;
  input  [6:0]  rx_bd_num_end;
  input         irq;
  input  [31:0] rxpnt;
//  input  [6:0]  rxbd_num;
  integer       i;
  integer       bd_status_addr, bd_ptr_addr;
//  integer       buf_addr;
begin
  for(i = rx_bd_num_strat; i <= rx_bd_num_end; i = i + 1) 
  begin
//    buf_addr = `RX_BUF_BASE + i * 32'h600;
    bd_status_addr = `RX_BD_BASE + i * 8;
    bd_ptr_addr = bd_status_addr + 4; 
    
    // initialize BD - status
//    wbm_write(bd_status_addr, 32'h0000c000, 4'hF, 1, wbm_init_waits, wbm_subseq_waits); // IRQ + PAD + CRC
    wbm_write(bd_status_addr, {17'h0, irq, 14'h0}, 
              4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // initialize BD - pointer
//    wbm_write(bd_ptr_addr, buf_addr, 4'hF, 1, wbm_init_waits, wbm_subseq_waits); // Initializing BD-pointer
    wbm_write(bd_ptr_addr, rxpnt, 4'hF, 1, wbm_init_waits, wbm_subseq_waits); // Initializing BD-pointer
  end
end
endtask // set_rx_bd

task set_rx_bd_wrap;
  input  [6:0]  rx_bd_num_end;
  integer       bd_status_addr, tmp;
begin
  bd_status_addr = `RX_BD_BASE + rx_bd_num_end * 8;
  wbm_read(bd_status_addr, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set wrap bit to this BD - this BD should be last-one
  wbm_write(bd_status_addr, (`ETH_RX_BD_WRAP | tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
end
endtask // set_rx_bd_wrap

task set_rx_bd_empty;
  input  [6:0]  rx_bd_num_strat;
  input  [6:0]  rx_bd_num_end;
  integer       i;
  integer       bd_status_addr, tmp;
begin
  for(i = rx_bd_num_strat; i <= rx_bd_num_end; i = i + 1)
  begin
    bd_status_addr = `RX_BD_BASE + i * 8;
    wbm_read(bd_status_addr, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // set empty bit to this BD - this BD should be ready
    wbm_write(bd_status_addr, (`ETH_RX_BD_EMPTY | tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  end
end
endtask // set_rx_bd_empty

task check_rx_bd;
  input  [6:0]  rx_bd_num_end;
  output [31:0] rx_bd_status;
  integer       bd_status_addr, tmp;
begin
  bd_status_addr = `RX_BD_BASE + rx_bd_num_end * 8;
  wbm_read(bd_status_addr, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  #1 rx_bd_status = tmp;
  #1;
end
endtask // check_rx_bd

task clear_rx_bd;
  input  [6:0]  rx_bd_num_strat;
  input  [6:0]  rx_bd_num_end;
  integer       i;
  integer       bd_status_addr, bd_ptr_addr;
begin
  for(i = rx_bd_num_strat; i <= rx_bd_num_end; i = i + 1)
  begin
    bd_status_addr = `RX_BD_BASE + i * 8;
    bd_ptr_addr = bd_status_addr + 4;
    // clear BD - status
    wbm_write(bd_status_addr, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
    // clear BD - pointer
    wbm_write(bd_ptr_addr, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  end
end
endtask // clear_rx_bd

task set_tx_packet;
  input  [31:0] txpnt;
  input  [15:0] len;
  input  [7:0]  eth_start_data;
  integer       i, sd;
  integer       buffer;
  reg           delta_t;
begin
  buffer = txpnt;
  sd = eth_start_data;
  delta_t = 0;

  // First write might not be word allign.
  if(buffer[1:0] == 1)  
  begin
    wb_slave.wr_mem(buffer - 1, {8'h0, sd[7:0], sd[7:0] + 3'h1, sd[7:0] + 3'h2}, 4'h7);
    sd = sd + 3;
    i = 3;
  end
  else if(buffer[1:0] == 2)  
  begin
    wb_slave.wr_mem(buffer - 2, {16'h0, sd[7:0], sd[7:0] + 3'h1}, 4'h3);
    sd = sd + 2;
    i = 2;
  end      
  else if(buffer[1:0] == 3)
  begin
    wb_slave.wr_mem(buffer - 3, {24'h0, sd[7:0]}, 4'h1);
    sd = sd + 1;
    i = 1;
  end
  else
    i = 0;
  delta_t = !delta_t;

  for(i = i; i < (len - 4); i = i + 4) // Last 0-3 bytes are not written
  begin  
    wb_slave.wr_mem(buffer + i, {sd[7:0], sd[7:0] + 3'h1, sd[7:0] + 3'h2, sd[7:0] + 3'h3}, 4'hF);
    sd = sd + 4;
  end
  delta_t = !delta_t;
  
  // Last word
  if((len - i) == 3)
  begin
    wb_slave.wr_mem(buffer + i, {sd[7:0], sd[7:0] + 3'h1, sd[7:0] + 3'h2, 8'h0}, 4'hE);
  end
  else if((len - i) == 2)
  begin
    wb_slave.wr_mem(buffer + i, {sd[7:0], sd[7:0] + 3'h1, 16'h0}, 4'hC);
  end
  else if((len - i) == 1)
  begin
    wb_slave.wr_mem(buffer + i, {sd[7:0], 24'h0}, 4'h8);
  end
  else if((len - i) == 4)
  begin
    wb_slave.wr_mem(buffer + i, {sd[7:0], sd[7:0] + 3'h1, sd[7:0] + 3'h2, sd[7:0] + 3'h3}, 4'hF);
  end
  else
    $display("(%0t)(%m) ERROR", $time);
  delta_t = !delta_t;
end
endtask // set_tx_packet

task check_tx_packet;
  input  [31:0] txpnt_wb;  // source
  input  [31:0] txpnt_phy; // destination
  input  [15:0] len;
  output [31:0] failure;
  integer       i, data_wb, data_phy;
  reg    [31:0] addr_wb, addr_phy;
  reg    [31:0] failure;
  reg           delta_t;
begin
  addr_wb = txpnt_wb;
  addr_phy = txpnt_phy;
  delta_t = 0;
  failure = 0;

  // First write might not be word allign.
  if(addr_wb[1:0] == 1)
  begin
    wb_slave.rd_mem(addr_wb - 1, data_wb, 4'h7);
    data_phy[31:24] = 0;
    data_phy[23:16] = eth_phy.tx_mem[addr_phy[21:0]];
    data_phy[15: 8] = eth_phy.tx_mem[addr_phy[21:0] + 1];
    data_phy[ 7: 0] = eth_phy.tx_mem[addr_phy[21:0] + 2];
    i = 3;
    if (data_phy[23:0] !== data_wb[23:0])
    begin
      `TIME;
      $display("*E Wrong 1. word (3 bytes) of TX packet!");
      failure = 1;
    end
  end
  else if (addr_wb[1:0] == 2)
  begin
    wb_slave.rd_mem(addr_wb - 2, data_wb, 4'h3);
    data_phy[31:16] = 0;
    data_phy[15: 8] = eth_phy.tx_mem[addr_phy[21:0]];
    data_phy[ 7: 0] = eth_phy.tx_mem[addr_phy[21:0] + 1];
    i = 2;
    if (data_phy[15:0] !== data_wb[15:0])
    begin
      `TIME;
      $display("*E Wrong 1. word (2 bytes) of TX packet!");
      failure = 1;
    end
  end
  else if (addr_wb[1:0] == 3)
  begin
    wb_slave.rd_mem(addr_wb - 3, data_wb, 4'h1);
    data_phy[31: 8] = 0;
    data_phy[ 7: 0] = eth_phy.tx_mem[addr_phy[21:0]];
    i = 1;
    if (data_phy[7:0] !== data_wb[7:0])
    begin
      `TIME;
      $display("*E Wrong 1. word (1 byte) of TX packet!");
      failure = 1;
    end
  end
  else
    i = 0;
  delta_t = !delta_t;

  for(i = i; i < (len - 4); i = i + 4) // Last 0-3 bytes are not checked
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hF);
    data_phy[31:24] = eth_phy.tx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.tx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = eth_phy.tx_mem[addr_phy[21:0] + i + 2];
    data_phy[ 7: 0] = eth_phy.tx_mem[addr_phy[21:0] + i + 3];
    if (data_phy[31:0] !== data_wb[31:0])
    begin
      `TIME;
      $display("*E Wrong %d. word (4 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
  end
  delta_t = !delta_t;

  // Last word
  if((len - i) == 3)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hE);
    data_phy[31:24] = eth_phy.tx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.tx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = eth_phy.tx_mem[addr_phy[21:0] + i + 2];
    data_phy[ 7: 0] = 0;
    if (data_phy[31:8] !== data_wb[31:8])
    begin
      `TIME;
      $display("*E Wrong %d. word (3 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
  end
  else if((len - i) == 2)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hC);
    data_phy[31:24] = eth_phy.tx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.tx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = 0;
    data_phy[ 7: 0] = 0;
    if (data_phy[31:16] !== data_wb[31:16])
    begin
      `TIME;
      $display("*E Wrong %d. word (2 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
  end
  else if((len - i) == 1)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'h8);
    data_phy[31:24] = eth_phy.tx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = 0;
    data_phy[15: 8] = 0;
    data_phy[ 7: 0] = 0;
    if (data_phy[31:24] !== data_wb[31:24])
    begin
      `TIME;
      $display("*E Wrong %d. word (1 byte) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
  end
  else if((len - i) == 4)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hF);
    data_phy[31:24] = eth_phy.tx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.tx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = eth_phy.tx_mem[addr_phy[21:0] + i + 2];
    data_phy[ 7: 0] = eth_phy.tx_mem[addr_phy[21:0] + i + 3];
    if (data_phy[31:0] !== data_wb[31:0])
    begin
      `TIME;
      $display("*E Wrong %d. word (4 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
  end
  else
    $display("(%0t)(%m) ERROR", $time);
  delta_t = !delta_t;
end
endtask // check_tx_packet

task set_rx_packet;
  input  [31:0] rxpnt;
  input  [15:0] len;
  input         plus_dribble_nibble; // if length is longer for one nibble
  input  [47:0] eth_dest_addr;
  input  [47:0] eth_source_addr;
  input  [15:0] eth_type_len;
  input  [7:0]  eth_start_data;
  integer       i, sd;
  reg    [47:0] dest_addr;
  reg    [47:0] source_addr;
  reg    [15:0] type_len;
  reg    [21:0] buffer;
  reg           delta_t;
begin
  buffer = rxpnt[21:0];
  dest_addr = eth_dest_addr;
  source_addr = eth_source_addr;
  type_len = eth_type_len;
  sd = eth_start_data;
  delta_t = 0;
  for(i = 0; i < len; i = i + 1) 
  begin
    if (i < 6)
    begin
      eth_phy.rx_mem[buffer] = dest_addr[47:40];
      dest_addr = dest_addr << 8;
    end
    else if (i < 12)
    begin
      eth_phy.rx_mem[buffer] = source_addr[47:40];
      source_addr = source_addr << 8;
    end
    else if (i < 14)
    begin
      eth_phy.rx_mem[buffer] = type_len[15:8];
      type_len = type_len << 8;
    end
    else
    begin
      eth_phy.rx_mem[buffer] = sd[7:0];
      sd = sd + 1;
    end
    buffer = buffer + 1;
  end
  delta_t = !delta_t;
  if (plus_dribble_nibble)
    eth_phy.rx_mem[buffer] = {4'h0, 4'hD /*sd[3:0]*/};
  delta_t = !delta_t;
end
endtask // set_rx_packet

task check_rx_packet;
  input  [31:0] rxpnt_phy; // source
  input  [31:0] rxpnt_wb;  // destination
  input  [15:0] len;
  input         plus_dribble_nibble; // if length is longer for one nibble
  input         successful_dribble_nibble; // if additional nibble is stored into memory
  output [31:0] failure;
  integer       i, data_wb, data_phy;
  reg    [31:0] addr_wb, addr_phy;
  reg    [31:0] failure;
  reg    [21:0] buffer;
  reg           delta_t;
begin
  addr_phy = rxpnt_phy;
  addr_wb = rxpnt_wb;
  delta_t = 0;
  failure = 0;

  // First write might not be word allign.
  if(addr_wb[1:0] == 1)
  begin
    wb_slave.rd_mem(addr_wb - 1, data_wb, 4'h7);
    data_phy[31:24] = 0;
    data_phy[23:16] = eth_phy.rx_mem[addr_phy[21:0]];
    data_phy[15: 8] = eth_phy.rx_mem[addr_phy[21:0] + 1];
    data_phy[ 7: 0] = eth_phy.rx_mem[addr_phy[21:0] + 2];
    i = 3;
    if (data_phy[23:0] !== data_wb[23:0])
    begin
      `TIME;
      $display("*E Wrong 1. word (3 bytes) of TX packet!");
      failure = 1;
    end
  end
  else if (addr_wb[1:0] == 2)
  begin
    wb_slave.rd_mem(addr_wb - 2, data_wb, 4'h3);
    data_phy[31:16] = 0;
    data_phy[15: 8] = eth_phy.rx_mem[addr_phy[21:0]];
    data_phy[ 7: 0] = eth_phy.rx_mem[addr_phy[21:0] + 1];
    i = 2;
    if (data_phy[15:0] !== data_wb[15:0])
    begin
      `TIME;
      $display("*E Wrong 1. word (2 bytes) of TX packet!");
      failure = 1;
    end
  end
  else if (addr_wb[1:0] == 3)
  begin
    wb_slave.rd_mem(addr_wb - 3, data_wb, 4'h1);
    data_phy[31: 8] = 0;
    data_phy[ 7: 0] = eth_phy.rx_mem[addr_phy[21:0]];
    i = 1;
    if (data_phy[7:0] !== data_wb[7:0])
    begin
      `TIME;
      $display("*E Wrong 1. word (1 byte) of TX packet!");
      failure = 1;
    end
  end
  else
    i = 0;
  delta_t = !delta_t;

  for(i = i; i < (len - 4); i = i + 4) // Last 0-3 bytes are not checked
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hF);
    data_phy[31:24] = eth_phy.rx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.rx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = eth_phy.rx_mem[addr_phy[21:0] + i + 2];
    data_phy[ 7: 0] = eth_phy.rx_mem[addr_phy[21:0] + i + 3];
    if (data_phy[31:0] !== data_wb[31:0])
    begin
      `TIME;
      $display("*E Wrong %d. word (4 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
  end
  delta_t = !delta_t;

  // Last word
  if((len - i) == 3)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hF);
    data_phy[31:24] = eth_phy.rx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.rx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = eth_phy.rx_mem[addr_phy[21:0] + i + 2];
    if (plus_dribble_nibble)
      data_phy[ 7: 0] = eth_phy.rx_mem[addr_phy[21:0] + i + 3];
    else
      data_phy[ 7: 0] = 0;
    if (data_phy[31:8] !== data_wb[31:8])
    begin
      `TIME;
      $display("*E Wrong %d. word (3 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
    if (plus_dribble_nibble && successful_dribble_nibble)
    begin
      if (data_phy[3:0] !== data_wb[3:0])
      begin
        `TIME;
        $display("*E Wrong dribble nibble in %d. word (3 bytes) of TX packet!", ((i/4)+1));
        failure = failure + 1;
      end
    end
    else if (plus_dribble_nibble && !successful_dribble_nibble)
    begin
      if (data_phy[3:0] === data_wb[3:0])
      begin
        `TIME;
        $display("*E Wrong dribble nibble in %d. word (3 bytes) of TX packet!", ((i/4)+1));
        failure = failure + 1;
      end
    end
  end
  else if((len - i) == 2)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hE);
    data_phy[31:24] = eth_phy.rx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.rx_mem[addr_phy[21:0] + i + 1];
    if (plus_dribble_nibble)
      data_phy[15: 8] = eth_phy.rx_mem[addr_phy[21:0] + i + 2];
    else
      data_phy[15: 8] = 0;
    data_phy[ 7: 0] = 0;
    if (data_phy[31:16] !== data_wb[31:16])
    begin
      `TIME;
      $display("*E Wrong %d. word (2 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
    if (plus_dribble_nibble && successful_dribble_nibble)
    begin
      if (data_phy[11:8] !== data_wb[11:8])
      begin
        `TIME;
        $display("*E Wrong dribble nibble in %d. word (2 bytes) of TX packet!", ((i/4)+1));
        failure = failure + 1;
      end
    end
    else if (plus_dribble_nibble && !successful_dribble_nibble)
    begin
      if (data_phy[11:8] === data_wb[11:8])
      begin
        `TIME;
        $display("*E Wrong dribble nibble in %d. word (2 bytes) of TX packet!", ((i/4)+1));
        failure = failure + 1;
      end
    end
  end
  else if((len - i) == 1)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hC);
    data_phy[31:24] = eth_phy.rx_mem[addr_phy[21:0] + i];
    if (plus_dribble_nibble)
      data_phy[23:16] = eth_phy.rx_mem[addr_phy[21:0] + i + 1];
    else
      data_phy[23:16] = 0;
    data_phy[15: 8] = 0;
    data_phy[ 7: 0] = 0;
    if (data_phy[31:24] !== data_wb[31:24])
    begin
      `TIME;
      $display("*E Wrong %d. word (1 byte) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
    if (plus_dribble_nibble && successful_dribble_nibble)
    begin
      if (data_phy[19:16] !== data_wb[19:16])
      begin
        `TIME;
        $display("*E Wrong dribble nibble in %d. word (1 byte) of TX packet!", ((i/4)+1));
        failure = failure + 1;
      end
    end
    else if (plus_dribble_nibble && !successful_dribble_nibble)
    begin
      if (data_phy[19:16] === data_wb[19:16])
      begin
        `TIME;
        $display("*E Wrong dribble nibble in %d. word (1 byte) of TX packet!", ((i/4)+1));
        failure = failure + 1;
      end
    end
  end
  else if((len - i) == 4)
  begin
    wb_slave.rd_mem(addr_wb + i, data_wb, 4'hF);
    data_phy[31:24] = eth_phy.rx_mem[addr_phy[21:0] + i];
    data_phy[23:16] = eth_phy.rx_mem[addr_phy[21:0] + i + 1];
    data_phy[15: 8] = eth_phy.rx_mem[addr_phy[21:0] + i + 2];
    data_phy[ 7: 0] = eth_phy.rx_mem[addr_phy[21:0] + i + 3];
    if (data_phy[31:0] !== data_wb[31:0])
    begin
      `TIME;
      $display("*E Wrong %d. word (4 bytes) of TX packet!", ((i/4)+1));
      failure = failure + 1;
    end
    if (plus_dribble_nibble)
    begin
      wb_slave.rd_mem(addr_wb + i + 4, data_wb, 4'h8);
      data_phy[31:24] = eth_phy.rx_mem[addr_phy[21:0] + i + 4];
      if (successful_dribble_nibble)
      begin
        if (data_phy[27:24] !== data_wb[27:24])
        begin
          `TIME;
          $display("*E Wrong dribble nibble in %d. word (0 bytes) of TX packet!", ((i/4)+2));
          failure = failure + 1;
        end
      end
      else
      begin
        if (data_phy[27:24] === data_wb[27:24])
        begin
          `TIME;
          $display("*E Wrong dribble nibble in %d. word (0 bytes) of TX packet!", ((i/4)+2));
          failure = failure + 1;
        end
      end
    end
  end
  else
    $display("(%0t)(%m) ERROR", $time);
  delta_t = !delta_t;
end
endtask // check_rx_packet

//////////////////////////////////////////////////////////////
// Ethernet CRC Basic tasks
//////////////////////////////////////////////////////////////

task append_tx_crc;
  input  [31:0] txpnt_wb;  // source
  input  [15:0] len; // length in bytes without CRC
  input         negated_crc; // if appended CRC is correct or not
  reg    [31:0] crc;
  reg    [31:0] addr_wb;
  reg           delta_t;
begin
  addr_wb = txpnt_wb + len;
  delta_t = 0;
  // calculate CRC from prepared packet
  paralel_crc_mac(txpnt_wb, {16'h0, len}, 1'b0, crc);
  if (negated_crc)
    crc = ~crc;
  delta_t = !delta_t;

  // Write might not be word allign.
  if (addr_wb[1:0] == 1)
  begin
    wb_slave.wr_mem(addr_wb - 1, {8'h0, crc[7:0], crc[15:8], crc[23:16]}, 4'h7);
    wb_slave.wr_mem(addr_wb + 3, {crc[31:24], 24'h0}, 4'h8);
  end
  else if (addr_wb[1:0] == 2)
  begin
    wb_slave.wr_mem(addr_wb - 2, {16'h0, crc[7:0], crc[15:8]}, 4'h3);
    wb_slave.wr_mem(addr_wb + 2, {crc[23:16], crc[31:24], 16'h0}, 4'hC);
  end
  else if (addr_wb[1:0] == 3)
  begin
    wb_slave.wr_mem(addr_wb - 3, {24'h0, crc[7:0]}, 4'h1);
    wb_slave.wr_mem(addr_wb + 1, {crc[15:8], crc[23:16], crc[31:24], 8'h0}, 4'hE);
  end
  else
  begin
    wb_slave.wr_mem(addr_wb, {crc[7:0], crc[15:8], crc[23:16], crc[31:24]}, 4'hF);
  end
  delta_t = !delta_t;
end
endtask // append_tx_crc

task check_tx_crc; // used to check crc added to TX packets by MAC
  input  [31:0] txpnt_phy; // destination
  input  [15:0] len; // length in bytes without CRC
  input         negated_crc; // if appended CRC is correct or not
  output [31:0] failure;
  reg    [31:0] failure;
  reg    [31:0] crc_calc;
  reg    [31:0] crc;
  reg    [31:0] addr_phy;
  reg           delta_t;
begin
  addr_phy = txpnt_phy;
  failure = 0;
  // calculate CRC from sent packet
//  serial_crc_phy_tx(addr_phy, {16'h0, len}, 1'b0, crc_calc);
//#10;
  paralel_crc_phy_tx(addr_phy, {16'h0, len}, 1'b0, crc_calc);

  addr_phy = addr_phy + len;
  // Read CRC - BIG endian
  crc[31:24] = eth_phy.tx_mem[addr_phy[21:0]];
  crc[23:16] = eth_phy.tx_mem[addr_phy[21:0] + 1];
  crc[15: 8] = eth_phy.tx_mem[addr_phy[21:0] + 2];
  crc[ 7: 0] = eth_phy.tx_mem[addr_phy[21:0] + 3];

  delta_t = !delta_t;
  if (negated_crc)
  begin
    if ((~crc_calc) !== crc)
    begin
      `TIME;
      $display("*E Negated CRC was not successfuly transmitted!");
      failure = failure + 1;
    end
  end
  else
  begin
    if (crc_calc !== crc)
    begin
      `TIME;
      $display("*E Transmitted CRC was not correct!");
      failure = failure + 1;
    end
  end
  delta_t = !delta_t;
end
endtask // check_tx_crc

task append_rx_crc;
  input  [31:0] rxpnt_phy; // source
  input  [15:0] len; // length in bytes without CRC
  input         plus_dribble_nibble; // if length is longer for one nibble
  input         negated_crc; // if appended CRC is correct or not
  reg    [31:0] crc;
  reg    [7:0]  tmp;
  reg    [31:0] addr_phy;
  reg           delta_t;
begin
  addr_phy = rxpnt_phy + len;
  delta_t = 0;
  // calculate CRC from prepared packet
  paralel_crc_phy_rx(rxpnt_phy, {16'h0, len}, plus_dribble_nibble, crc);
  if (negated_crc)
    crc = ~crc;
  delta_t = !delta_t;

  if (plus_dribble_nibble)
  begin
    tmp = eth_phy.rx_mem[addr_phy];
    eth_phy.rx_mem[addr_phy]     = {crc[3:0], tmp[3:0]};
    eth_phy.rx_mem[addr_phy + 1] = {crc[11:8], crc[7:4]};
    eth_phy.rx_mem[addr_phy + 2] = {crc[19:16], crc[15:12]};
    eth_phy.rx_mem[addr_phy + 3] = {crc[27:24], crc[23:20]};
    eth_phy.rx_mem[addr_phy + 4] = {4'h0, crc[31:28]};
  end
  else
  begin
    eth_phy.rx_mem[addr_phy]     = crc[7:0];
    eth_phy.rx_mem[addr_phy + 1] = crc[15:8];
    eth_phy.rx_mem[addr_phy + 2] = crc[23:16];
    eth_phy.rx_mem[addr_phy + 3] = crc[31:24];
  end
end
endtask // append_rx_crc

// paralel CRC checking for PHY TX
task paralel_crc_phy_tx;
  input  [31:0] start_addr; // start address
  input  [31:0] len; // length of frame in Bytes without CRC length
  input         plus_dribble_nibble; // if length is longer for one nibble
  output [31:0] crc_out;
  reg    [21:0] addr_cnt; // only 22 address lines
  integer       word_cnt;
  integer       nibble_cnt;
  reg    [31:0] load_reg;
  reg           delta_t;
  reg    [31:0] crc_next;
  reg    [31:0] crc;
  reg           crc_error;
  reg     [3:0] data_in;
  integer       i;
begin
  #1 addr_cnt = start_addr[21:0];
  word_cnt = 24; // 27; // start of the frame - nibble granularity (MSbit first)
  crc = 32'hFFFF_FFFF; // INITIAL value
  delta_t = 0;
  // length must include 4 bytes of ZEROs, to generate CRC
  // get number of nibbles from Byte length (2^1 = 2)
  if (plus_dribble_nibble)
    nibble_cnt = ((len + 4) << 1) + 1'b1; // one nibble longer
  else
    nibble_cnt = ((len + 4) << 1);
  // because of MAGIC NUMBER nibbles are swapped [3:0] -> [0:3]
  load_reg[31:24] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[23:16] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[15: 8] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[ 7: 0] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  while (nibble_cnt > 0)
  begin
    // wait for delta time
    delta_t = !delta_t;
    // shift data in

    if(nibble_cnt <= 8) // for additional 8 nibbles shift ZEROs in!
      data_in[3:0] = 4'h0;
    else

      data_in[3:0] = {load_reg[word_cnt], load_reg[word_cnt+1], load_reg[word_cnt+2], load_reg[word_cnt+3]};
    crc_next[0]  = (data_in[0] ^ crc[28]);
    crc_next[1]  = (data_in[1] ^ data_in[0] ^ crc[28]    ^ crc[29]);
    crc_next[2]  = (data_in[2] ^ data_in[1] ^ data_in[0] ^ crc[28]  ^ crc[29] ^ crc[30]);
    crc_next[3]  = (data_in[3] ^ data_in[2] ^ data_in[1] ^ crc[29]  ^ crc[30] ^ crc[31]);
    crc_next[4]  = (data_in[3] ^ data_in[2] ^ data_in[0] ^ crc[28]  ^ crc[30] ^ crc[31]) ^ crc[0];
    crc_next[5]  = (data_in[3] ^ data_in[1] ^ data_in[0] ^ crc[28]  ^ crc[29] ^ crc[31]) ^ crc[1];
    crc_next[6]  = (data_in[2] ^ data_in[1] ^ crc[29]    ^ crc[30]) ^ crc[ 2];
    crc_next[7]  = (data_in[3] ^ data_in[2] ^ data_in[0] ^ crc[28]  ^ crc[30] ^ crc[31]) ^ crc[3];
    crc_next[8]  = (data_in[3] ^ data_in[1] ^ data_in[0] ^ crc[28]  ^ crc[29] ^ crc[31]) ^ crc[4];
    crc_next[9]  = (data_in[2] ^ data_in[1] ^ crc[29]    ^ crc[30]) ^ crc[5];
    crc_next[10] = (data_in[3] ^ data_in[2] ^ data_in[0] ^ crc[28]  ^ crc[30] ^ crc[31]) ^ crc[6];
    crc_next[11] = (data_in[3] ^ data_in[1] ^ data_in[0] ^ crc[28]  ^ crc[29] ^ crc[31]) ^ crc[7];
    crc_next[12] = (data_in[2] ^ data_in[1] ^ data_in[0] ^ crc[28]  ^ crc[29] ^ crc[30]) ^ crc[8];
    crc_next[13] = (data_in[3] ^ data_in[2] ^ data_in[1] ^ crc[29]  ^ crc[30] ^ crc[31]) ^ crc[9];
    crc_next[14] = (data_in[3] ^ data_in[2] ^ crc[30]    ^ crc[31]) ^ crc[10];
    crc_next[15] = (data_in[3] ^ crc[31])   ^ crc[11];
    crc_next[16] = (data_in[0] ^ crc[28])   ^ crc[12];
    crc_next[17] = (data_in[1] ^ crc[29])   ^ crc[13];
    crc_next[18] = (data_in[2] ^ crc[30])   ^ crc[14];
    crc_next[19] = (data_in[3] ^ crc[31])   ^ crc[15];
    crc_next[20] =  crc[16];
    crc_next[21] =  crc[17];
    crc_next[22] = (data_in[0] ^ crc[28])   ^ crc[18];
    crc_next[23] = (data_in[1] ^ data_in[0] ^ crc[29]    ^ crc[28]) ^ crc[19];
    crc_next[24] = (data_in[2] ^ data_in[1] ^ crc[30]    ^ crc[29]) ^ crc[20];
    crc_next[25] = (data_in[3] ^ data_in[2] ^ crc[31]    ^ crc[30]) ^ crc[21];
    crc_next[26] = (data_in[3] ^ data_in[0] ^ crc[31]    ^ crc[28]) ^ crc[22];
    crc_next[27] = (data_in[1] ^ crc[29])   ^ crc[23];
    crc_next[28] = (data_in[2] ^ crc[30])   ^ crc[24];
    crc_next[29] = (data_in[3] ^ crc[31])   ^ crc[25];
    crc_next[30] =  crc[26];
    crc_next[31] =  crc[27];

    crc = crc_next;
    crc_error = crc[31:0] != 32'hc704dd7b;  // CRC not equal to magic number
    case (nibble_cnt)
    9: crc_out = {!crc[24], !crc[25], !crc[26], !crc[27], !crc[28], !crc[29], !crc[30], !crc[31],
                  !crc[16], !crc[17], !crc[18], !crc[19], !crc[20], !crc[21], !crc[22], !crc[23],
                  !crc[ 8], !crc[ 9], !crc[10], !crc[11], !crc[12], !crc[13], !crc[14], !crc[15],
                  !crc[ 0], !crc[ 1], !crc[ 2], !crc[ 3], !crc[ 4], !crc[ 5], !crc[ 6], !crc[ 7]};
    default: crc_out = crc_out;
    endcase
    // wait for delta time
    delta_t = !delta_t;
    // increment address and load new data
    if ((word_cnt+3) == 7)//4)
    begin
      // because of MAGIC NUMBER nibbles are swapped [3:0] -> [0:3]
      load_reg[31:24] = eth_phy.tx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[23:16] = eth_phy.tx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[15: 8] = eth_phy.tx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[ 7: 0] = eth_phy.tx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
    end
    // set new load bit position
    if((word_cnt+3) == 31)
      word_cnt = 16;
    else if ((word_cnt+3) == 23)
      word_cnt = 8;
    else if ((word_cnt+3) == 15)
      word_cnt = 0;
    else if ((word_cnt+3) == 7)
      word_cnt = 24;
    else
      word_cnt = word_cnt + 4;// - 4;
    // decrement nibble counter
    nibble_cnt = nibble_cnt - 1;
    // wait for delta time
    delta_t = !delta_t;
  end // while
  #1;
end
endtask // paralel_crc_phy_tx

// paralel CRC calculating for PHY RX
task paralel_crc_phy_rx;
  input  [31:0] start_addr; // start address
  input  [31:0] len; // length of frame in Bytes without CRC length
  input         plus_dribble_nibble; // if length is longer for one nibble
  output [31:0] crc;
  reg    [21:0] addr_cnt; // only 22 address lines
  integer       word_cnt;
  integer       bit_cnt;
  reg    [31:0] load_reg;
  reg    [31:0] crc_shift_reg;
  reg    [31:0] crc_store_reg;
  reg           delta_t;
begin
  #1 addr_cnt = start_addr[21:0];
  word_cnt = 24; // start of the frame
  crc_shift_reg = 0;
  delta_t = 0;
  // length must include 4 bytes of ZEROs, to generate CRC
  // get number of bits from Byte length (2^3 = 8)
  if (plus_dribble_nibble)
    bit_cnt = ((len + 4) << 3) + 3'h4; // one nibble longer
  else
    bit_cnt = ((len + 4) << 3);
  load_reg[31:24] = eth_phy.rx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[23:16] = eth_phy.rx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[15:8]  = eth_phy.rx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[7:0]   = eth_phy.rx_mem[addr_cnt];

  while (bit_cnt > 0)
  begin
    // wait for delta time
    delta_t = !delta_t;
    // store previous data
    crc_store_reg = crc_shift_reg;
    // shift data in
    if(bit_cnt <= 32) // for additional 32 bits shift ZEROs in!
     crc_shift_reg[0] = 1'b0               ^ crc_store_reg[31];
    else
     crc_shift_reg[0] = load_reg[word_cnt] ^ crc_store_reg[31];
    crc_shift_reg[1]  = crc_store_reg[0]   ^ crc_store_reg[31];
    crc_shift_reg[2]  = crc_store_reg[1]   ^ crc_store_reg[31];
    crc_shift_reg[3]  = crc_store_reg[2];
    crc_shift_reg[4]  = crc_store_reg[3]   ^ crc_store_reg[31];
    crc_shift_reg[5]  = crc_store_reg[4]   ^ crc_store_reg[31];
    crc_shift_reg[6]  = crc_store_reg[5];
    crc_shift_reg[7]  = crc_store_reg[6]   ^ crc_store_reg[31];
    crc_shift_reg[8]  = crc_store_reg[7]   ^ crc_store_reg[31];
    crc_shift_reg[9]  = crc_store_reg[8];
    crc_shift_reg[10] = crc_store_reg[9]   ^ crc_store_reg[31];
    crc_shift_reg[11] = crc_store_reg[10]  ^ crc_store_reg[31];
    crc_shift_reg[12] = crc_store_reg[11]  ^ crc_store_reg[31];
    crc_shift_reg[13] = crc_store_reg[12];
    crc_shift_reg[14] = crc_store_reg[13];
    crc_shift_reg[15] = crc_store_reg[14];
    crc_shift_reg[16] = crc_store_reg[15]  ^ crc_store_reg[31];
    crc_shift_reg[17] = crc_store_reg[16];
    crc_shift_reg[18] = crc_store_reg[17];
    crc_shift_reg[19] = crc_store_reg[18];
    crc_shift_reg[20] = crc_store_reg[19];
    crc_shift_reg[21] = crc_store_reg[20];
    crc_shift_reg[22] = crc_store_reg[21]  ^ crc_store_reg[31];
    crc_shift_reg[23] = crc_store_reg[22]  ^ crc_store_reg[31];
    crc_shift_reg[24] = crc_store_reg[23];
    crc_shift_reg[25] = crc_store_reg[24];
    crc_shift_reg[26] = crc_store_reg[25]  ^ crc_store_reg[31];
    crc_shift_reg[27] = crc_store_reg[26];
    crc_shift_reg[28] = crc_store_reg[27];
    crc_shift_reg[29] = crc_store_reg[28];
    crc_shift_reg[30] = crc_store_reg[29];
    crc_shift_reg[31] = crc_store_reg[30];
    // wait for delta time
    delta_t = !delta_t;
    // increment address and load new data
    if (word_cnt == 7)
    begin
      addr_cnt = addr_cnt + 1;
      load_reg[31:24] = eth_phy.rx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[23:16] = eth_phy.rx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[15:8]  = eth_phy.rx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[7:0]   = eth_phy.rx_mem[addr_cnt];
    end
    // set new load bit position
    if(word_cnt == 31)
      word_cnt = 16;
    else if (word_cnt == 23)
      word_cnt = 8;
    else if (word_cnt == 15)
      word_cnt = 0;
    else if (word_cnt == 7)
      word_cnt = 24;
    else
      word_cnt = word_cnt + 1;
    // decrement bit counter
    bit_cnt = bit_cnt - 1;
    // wait for delta time
    delta_t = !delta_t;
  end // while

  // put CRC out
  crc = crc_shift_reg;
  #1;
end
endtask // paralel_crc_phy_rx

// paralel CRC checking for MAC
task paralel_crc_mac;
  input  [31:0] start_addr; // start address
  input  [31:0] len; // length of frame in Bytes without CRC length
  input         plus_dribble_nibble; // if length is longer for one nibble
  output [31:0] crc;
  reg    [19:0] addr_cnt; // only 20 address lines
  integer       word_cnt;
  integer       bit_cnt;
  reg    [31:0] load_reg;
  reg    [31:0] crc_shift_reg;
  reg    [31:0] crc_store_reg;
  reg           delta_t;
begin
  #1 addr_cnt = start_addr[19:0];
  // set starting point depending with which byte frame starts (e.g. if addr_cnt[1:0] == 0, then
  //   MSB of the packet must be written to the LSB of Big ENDIAN Word [31:24])
  if (addr_cnt[1:0] == 2'h1)
    word_cnt = 16; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)
  else if (addr_cnt[1:0] == 2'h2)
    word_cnt = 8; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)
  else if (addr_cnt[1:0] == 2'h3)
    word_cnt = 0; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)
  else 
    word_cnt = 24; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)

  crc_shift_reg = 0;
  delta_t = 0;
  // length must include 4 bytes of ZEROs, to generate CRC
  // get number of bits from Byte length (2^3 = 8)
  if (plus_dribble_nibble)
    bit_cnt = ((len + 4) << 3) + 3'h4; // one nibble longer
  else
    bit_cnt = ((len + 4) << 3);
  load_reg = wb_slave.wb_memory[{12'h0, addr_cnt}];

  while (bit_cnt > 0)
  begin
    // wait for delta time
    delta_t = !delta_t;
    // store previous data
    crc_store_reg = crc_shift_reg;
    // shift data in
    if(bit_cnt <= 32) // for additional 32 bits shift ZEROs in!
     crc_shift_reg[0] = 1'b0               ^ crc_store_reg[31];
    else
     crc_shift_reg[0] = load_reg[word_cnt] ^ crc_store_reg[31];
    crc_shift_reg[1]  = crc_store_reg[0]   ^ crc_store_reg[31];
    crc_shift_reg[2]  = crc_store_reg[1]   ^ crc_store_reg[31];
    crc_shift_reg[3]  = crc_store_reg[2];
    crc_shift_reg[4]  = crc_store_reg[3]   ^ crc_store_reg[31];
    crc_shift_reg[5]  = crc_store_reg[4]   ^ crc_store_reg[31];
    crc_shift_reg[6]  = crc_store_reg[5];
    crc_shift_reg[7]  = crc_store_reg[6]   ^ crc_store_reg[31];
    crc_shift_reg[8]  = crc_store_reg[7]   ^ crc_store_reg[31];
    crc_shift_reg[9]  = crc_store_reg[8];
    crc_shift_reg[10] = crc_store_reg[9]   ^ crc_store_reg[31];
    crc_shift_reg[11] = crc_store_reg[10]  ^ crc_store_reg[31];
    crc_shift_reg[12] = crc_store_reg[11]  ^ crc_store_reg[31];
    crc_shift_reg[13] = crc_store_reg[12];
    crc_shift_reg[14] = crc_store_reg[13];
    crc_shift_reg[15] = crc_store_reg[14];
    crc_shift_reg[16] = crc_store_reg[15]  ^ crc_store_reg[31];
    crc_shift_reg[17] = crc_store_reg[16];
    crc_shift_reg[18] = crc_store_reg[17];
    crc_shift_reg[19] = crc_store_reg[18];
    crc_shift_reg[20] = crc_store_reg[19];
    crc_shift_reg[21] = crc_store_reg[20];
    crc_shift_reg[22] = crc_store_reg[21]  ^ crc_store_reg[31];
    crc_shift_reg[23] = crc_store_reg[22]  ^ crc_store_reg[31];
    crc_shift_reg[24] = crc_store_reg[23];
    crc_shift_reg[25] = crc_store_reg[24];
    crc_shift_reg[26] = crc_store_reg[25]  ^ crc_store_reg[31];
    crc_shift_reg[27] = crc_store_reg[26];
    crc_shift_reg[28] = crc_store_reg[27];
    crc_shift_reg[29] = crc_store_reg[28];
    crc_shift_reg[30] = crc_store_reg[29];
    crc_shift_reg[31] = crc_store_reg[30];
    // wait for delta time
    delta_t = !delta_t;
    // increment address and load new data for Big ENDIAN Bytes (Litle ENDIAN bits)
    if (word_cnt == 7)
    begin
      addr_cnt = addr_cnt + 4;
      load_reg = wb_slave.wb_memory[{12'h0, addr_cnt}];
    end
    // set new load bit position for Big ENDIAN Bytes (Litle ENDIAN bits)
    if(word_cnt == 31)
      word_cnt = 16;
    else if (word_cnt == 23)
      word_cnt = 8;
    else if (word_cnt == 15)
      word_cnt = 0;
    else if (word_cnt == 7)
      word_cnt = 24;
    else
      word_cnt = word_cnt + 1;
    // decrement bit counter
    bit_cnt = bit_cnt - 1;
    // wait for delta time
    delta_t = !delta_t;
  end // while

  // put CRC out
  crc = crc_shift_reg;
  #1;
end
endtask // paralel_crc_mac

// serial CRC checking for PHY TX
task serial_crc_phy_tx;
  input  [31:0] start_addr; // start address
  input  [31:0] len; // length of frame in Bytes without CRC length
  input         plus_dribble_nibble; // if length is longer for one nibble
  output [31:0] crc;
  reg    [21:0] addr_cnt; // only 22 address lines
  integer       word_cnt;
  integer       bit_cnt;
  reg    [31:0] load_reg;
  reg    [31:0] crc_shift_reg;
  reg    [31:0] crc_store_reg;
  reg           delta_t;
begin
  #1 addr_cnt = start_addr[21:0];
  word_cnt = 24; // 27; // start of the frame - nibble granularity (MSbit first)
  crc_store_reg = 32'hFFFF_FFFF; // INITIAL value
  delta_t = 0;
  // length must include 4 bytes of ZEROs, to generate CRC
  // get number of bits from Byte length (2^3 = 8)
  if (plus_dribble_nibble)
    bit_cnt = ((len + 4) << 3) + 3'h4; // one nibble longer
  else
    bit_cnt = ((len + 4) << 3);
  // because of MAGIC NUMBER nibbles are swapped [3:0] -> [0:3]
  load_reg[31:24] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[23:16] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[15: 8] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[ 7: 0] = eth_phy.tx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
#1;
  while (bit_cnt > 0)
  begin
    // wait for delta time
    delta_t = !delta_t;
#1;
    // shift data in

    if(bit_cnt <= 32) // for additional 32 bits shift ZEROs in!
     crc_shift_reg[0] = 1'b0               ^ crc_store_reg[31];
    else

     crc_shift_reg[0] = load_reg[word_cnt] ^ crc_store_reg[31];
    crc_shift_reg[1]  = crc_store_reg[0]   ^ crc_store_reg[31];
    crc_shift_reg[2]  = crc_store_reg[1]   ^ crc_store_reg[31];
    crc_shift_reg[3]  = crc_store_reg[2];
    crc_shift_reg[4]  = crc_store_reg[3]   ^ crc_store_reg[31];
    crc_shift_reg[5]  = crc_store_reg[4]   ^ crc_store_reg[31];
    crc_shift_reg[6]  = crc_store_reg[5];
    crc_shift_reg[7]  = crc_store_reg[6]   ^ crc_store_reg[31];
    crc_shift_reg[8]  = crc_store_reg[7]   ^ crc_store_reg[31];
    crc_shift_reg[9]  = crc_store_reg[8];
    crc_shift_reg[10] = crc_store_reg[9]   ^ crc_store_reg[31];
    crc_shift_reg[11] = crc_store_reg[10]  ^ crc_store_reg[31];
    crc_shift_reg[12] = crc_store_reg[11]  ^ crc_store_reg[31];
    crc_shift_reg[13] = crc_store_reg[12];
    crc_shift_reg[14] = crc_store_reg[13];
    crc_shift_reg[15] = crc_store_reg[14];
    crc_shift_reg[16] = crc_store_reg[15]  ^ crc_store_reg[31];
    crc_shift_reg[17] = crc_store_reg[16];
    crc_shift_reg[18] = crc_store_reg[17];
    crc_shift_reg[19] = crc_store_reg[18];
    crc_shift_reg[20] = crc_store_reg[19];
    crc_shift_reg[21] = crc_store_reg[20];
    crc_shift_reg[22] = crc_store_reg[21]  ^ crc_store_reg[31];
    crc_shift_reg[23] = crc_store_reg[22]  ^ crc_store_reg[31];
    crc_shift_reg[24] = crc_store_reg[23];
    crc_shift_reg[25] = crc_store_reg[24];
    crc_shift_reg[26] = crc_store_reg[25]  ^ crc_store_reg[31];
    crc_shift_reg[27] = crc_store_reg[26];
    crc_shift_reg[28] = crc_store_reg[27];
    crc_shift_reg[29] = crc_store_reg[28];
    crc_shift_reg[30] = crc_store_reg[29];
    crc_shift_reg[31] = crc_store_reg[30];
    // wait for delta time
    delta_t = !delta_t;

    // store previous data
    crc_store_reg = crc_shift_reg;

    // put CRC out
    case (bit_cnt)
    33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 1:
    begin
      crc = crc_store_reg;
      crc = {!crc[24], !crc[25], !crc[26], !crc[27], !crc[28], !crc[29], !crc[30], !crc[31],
             !crc[16], !crc[17], !crc[18], !crc[19], !crc[20], !crc[21], !crc[22], !crc[23],
             !crc[ 8], !crc[ 9], !crc[10], !crc[11], !crc[12], !crc[13], !crc[14], !crc[15],
             !crc[ 0], !crc[ 1], !crc[ 2], !crc[ 3], !crc[ 4], !crc[ 5], !crc[ 6], !crc[ 7]};
    end
    default: crc = crc;
    endcase

    // increment address and load new data
#1;
    if (word_cnt == 7)//4)
    begin
      // because of MAGIC NUMBER nibbles are swapped [3:0] -> [0:3]
      load_reg[31:24] = eth_phy.tx_mem[addr_cnt];
//      load_reg[31:24] = {load_reg[28], load_reg[29], load_reg[30], load_reg[31], 
//                         load_reg[24], load_reg[25], load_reg[26], load_reg[27]};
      addr_cnt = addr_cnt + 1;
      load_reg[23:16] = eth_phy.tx_mem[addr_cnt];
//      load_reg[23:16] = {load_reg[20], load_reg[21], load_reg[22], load_reg[23], 
//                         load_reg[16], load_reg[17], load_reg[18], load_reg[19]};
      addr_cnt = addr_cnt + 1;
      load_reg[15: 8] = eth_phy.tx_mem[addr_cnt];
//      load_reg[15: 8] = {load_reg[12], load_reg[13], load_reg[14], load_reg[15], 
//                         load_reg[ 8], load_reg[ 9], load_reg[10], load_reg[11]};
      addr_cnt = addr_cnt + 1;
      load_reg[ 7: 0] = eth_phy.tx_mem[addr_cnt];
//      load_reg[ 7: 0] = {load_reg[ 4], load_reg[ 5], load_reg[ 6], load_reg[ 7], 
//                         load_reg[ 0], load_reg[ 1], load_reg[ 2], load_reg[ 3]};
      addr_cnt = addr_cnt + 1;
    end
#1;
    // set new load bit position
    if(word_cnt == 31)
      word_cnt = 16;
    else if (word_cnt == 23)
      word_cnt = 8;
    else if (word_cnt == 15)
      word_cnt = 0;
    else if (word_cnt == 7)
      word_cnt = 24;

//   if(word_cnt == 24)
//     word_cnt = 31;
//   else if (word_cnt == 28)
//     word_cnt = 19;
//   else if (word_cnt == 16)
//     word_cnt = 23;
//   else if (word_cnt == 20)
//     word_cnt = 11;
//   else if(word_cnt == 8)
//     word_cnt = 15;
//   else if (word_cnt == 12)
//     word_cnt = 3;
//   else if (word_cnt == 0)
//     word_cnt = 7;
//   else if (word_cnt == 4)
//     word_cnt = 27;
    else
      word_cnt = word_cnt + 1;// - 1;
#1;
    // decrement bit counter
    bit_cnt = bit_cnt - 1;
#1;
    // wait for delta time
    delta_t = !delta_t;
  end // while

  #1;
end
endtask // serial_crc_phy_tx

// serial CRC calculating for PHY RX
task serial_crc_phy_rx;
  input  [31:0] start_addr; // start address
  input  [31:0] len; // length of frame in Bytes without CRC length
  input         plus_dribble_nibble; // if length is longer for one nibble
  output [31:0] crc;
  reg    [21:0] addr_cnt; // only 22 address lines
  integer       word_cnt;
  integer       bit_cnt;
  reg    [31:0] load_reg;
  reg    [31:0] crc_shift_reg;
  reg    [31:0] crc_store_reg;
  reg           delta_t;
begin
  #1 addr_cnt = start_addr[21:0];
  word_cnt = 24; // start of the frame
  crc_shift_reg = 0;
  delta_t = 0;
  // length must include 4 bytes of ZEROs, to generate CRC
  // get number of bits from Byte length (2^3 = 8)
  if (plus_dribble_nibble)
    bit_cnt = ((len + 4) << 3) + 3'h4; // one nibble longer
  else
    bit_cnt = ((len + 4) << 3);
  load_reg[31:24] = eth_phy.rx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[23:16] = eth_phy.rx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[15:8]  = eth_phy.rx_mem[addr_cnt];
  addr_cnt = addr_cnt + 1;
  load_reg[7:0]   = eth_phy.rx_mem[addr_cnt];

  while (bit_cnt > 0)
  begin
    // wait for delta time
    delta_t = !delta_t;
    // store previous data
    crc_store_reg = crc_shift_reg;
    // shift data in
    if(bit_cnt <= 32) // for additional 32 bits shift ZEROs in!
     crc_shift_reg[0] = 1'b0               ^ crc_store_reg[31];
    else
     crc_shift_reg[0] = load_reg[word_cnt] ^ crc_store_reg[31];
    crc_shift_reg[1]  = crc_store_reg[0]   ^ crc_store_reg[31];
    crc_shift_reg[2]  = crc_store_reg[1]   ^ crc_store_reg[31];
    crc_shift_reg[3]  = crc_store_reg[2];
    crc_shift_reg[4]  = crc_store_reg[3]   ^ crc_store_reg[31];
    crc_shift_reg[5]  = crc_store_reg[4]   ^ crc_store_reg[31];
    crc_shift_reg[6]  = crc_store_reg[5];
    crc_shift_reg[7]  = crc_store_reg[6]   ^ crc_store_reg[31];
    crc_shift_reg[8]  = crc_store_reg[7]   ^ crc_store_reg[31];
    crc_shift_reg[9]  = crc_store_reg[8];
    crc_shift_reg[10] = crc_store_reg[9]   ^ crc_store_reg[31];
    crc_shift_reg[11] = crc_store_reg[10]  ^ crc_store_reg[31];
    crc_shift_reg[12] = crc_store_reg[11]  ^ crc_store_reg[31];
    crc_shift_reg[13] = crc_store_reg[12];
    crc_shift_reg[14] = crc_store_reg[13];
    crc_shift_reg[15] = crc_store_reg[14];
    crc_shift_reg[16] = crc_store_reg[15]  ^ crc_store_reg[31];
    crc_shift_reg[17] = crc_store_reg[16];
    crc_shift_reg[18] = crc_store_reg[17];
    crc_shift_reg[19] = crc_store_reg[18];
    crc_shift_reg[20] = crc_store_reg[19];
    crc_shift_reg[21] = crc_store_reg[20];
    crc_shift_reg[22] = crc_store_reg[21]  ^ crc_store_reg[31];
    crc_shift_reg[23] = crc_store_reg[22]  ^ crc_store_reg[31];
    crc_shift_reg[24] = crc_store_reg[23];
    crc_shift_reg[25] = crc_store_reg[24];
    crc_shift_reg[26] = crc_store_reg[25]  ^ crc_store_reg[31];
    crc_shift_reg[27] = crc_store_reg[26];
    crc_shift_reg[28] = crc_store_reg[27];
    crc_shift_reg[29] = crc_store_reg[28];
    crc_shift_reg[30] = crc_store_reg[29];
    crc_shift_reg[31] = crc_store_reg[30];
    // wait for delta time
    delta_t = !delta_t;
    // increment address and load new data
    if (word_cnt == 7)
    begin
      addr_cnt = addr_cnt + 1;
      load_reg[31:24] = eth_phy.rx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[23:16] = eth_phy.rx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[15:8]  = eth_phy.rx_mem[addr_cnt];
      addr_cnt = addr_cnt + 1;
      load_reg[7:0]   = eth_phy.rx_mem[addr_cnt];
    end
    // set new load bit position
    if(word_cnt == 31)
      word_cnt = 16;
    else if (word_cnt == 23)
      word_cnt = 8;
    else if (word_cnt == 15)
      word_cnt = 0;
    else if (word_cnt == 7)
      word_cnt = 24;
    else
      word_cnt = word_cnt + 1;
    // decrement bit counter
    bit_cnt = bit_cnt - 1;
    // wait for delta time
    delta_t = !delta_t;
  end // while

  // put CRC out
  crc = crc_shift_reg;
  #1;
end
endtask // serial_crc_phy_rx

// serial CRC checking for MAC
task serial_crc_mac;
  input  [31:0] start_addr; // start address
  input  [31:0] len; // length of frame in Bytes without CRC length
  input         plus_dribble_nibble; // if length is longer for one nibble
  output [31:0] crc;
  reg    [19:0] addr_cnt; // only 20 address lines
  integer       word_cnt;
  integer       bit_cnt;
  reg    [31:0] load_reg;
  reg    [31:0] crc_shift_reg;
  reg    [31:0] crc_store_reg;
  reg           delta_t;
begin
  #1 addr_cnt = start_addr[19:0];
  // set starting point depending with which byte frame starts (e.g. if addr_cnt[1:0] == 0, then
  //   MSB of the packet must be written to the LSB of Big ENDIAN Word [31:24])
  if (addr_cnt[1:0] == 2'h1)
    word_cnt = 16; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)
  else if (addr_cnt[1:0] == 2'h2)
    word_cnt = 8; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)
  else if (addr_cnt[1:0] == 2'h3)
    word_cnt = 0; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)
  else 
    word_cnt = 24; // start of the frame for Big ENDIAN Bytes (Litle ENDIAN bits)

  crc_shift_reg = 0;
  delta_t = 0;
  // length must include 4 bytes of ZEROs, to generate CRC
  // get number of bits from Byte length (2^3 = 8)
  if (plus_dribble_nibble)
    bit_cnt = ((len + 4) << 3) + 3'h4; // one nibble longer
  else
    bit_cnt = ((len + 4) << 3);
  load_reg = wb_slave.wb_memory[{12'h0, addr_cnt}];

  while (bit_cnt > 0)
  begin
    // wait for delta time
    delta_t = !delta_t;
    // store previous data
    crc_store_reg = crc_shift_reg;
    // shift data in
    if(bit_cnt <= 32) // for additional 32 bits shift ZEROs in!
     crc_shift_reg[0] = 1'b0               ^ crc_store_reg[31];
    else
     crc_shift_reg[0] = load_reg[word_cnt] ^ crc_store_reg[31];
    crc_shift_reg[1]  = crc_store_reg[0]   ^ crc_store_reg[31];
    crc_shift_reg[2]  = crc_store_reg[1]   ^ crc_store_reg[31];
    crc_shift_reg[3]  = crc_store_reg[2];
    crc_shift_reg[4]  = crc_store_reg[3]   ^ crc_store_reg[31];
    crc_shift_reg[5]  = crc_store_reg[4]   ^ crc_store_reg[31];
    crc_shift_reg[6]  = crc_store_reg[5];
    crc_shift_reg[7]  = crc_store_reg[6]   ^ crc_store_reg[31];
    crc_shift_reg[8]  = crc_store_reg[7]   ^ crc_store_reg[31];
    crc_shift_reg[9]  = crc_store_reg[8];
    crc_shift_reg[10] = crc_store_reg[9]   ^ crc_store_reg[31];
    crc_shift_reg[11] = crc_store_reg[10]  ^ crc_store_reg[31];
    crc_shift_reg[12] = crc_store_reg[11]  ^ crc_store_reg[31];
    crc_shift_reg[13] = crc_store_reg[12];
    crc_shift_reg[14] = crc_store_reg[13];
    crc_shift_reg[15] = crc_store_reg[14];
    crc_shift_reg[16] = crc_store_reg[15]  ^ crc_store_reg[31];
    crc_shift_reg[17] = crc_store_reg[16];
    crc_shift_reg[18] = crc_store_reg[17];
    crc_shift_reg[19] = crc_store_reg[18];
    crc_shift_reg[20] = crc_store_reg[19];
    crc_shift_reg[21] = crc_store_reg[20];
    crc_shift_reg[22] = crc_store_reg[21]  ^ crc_store_reg[31];
    crc_shift_reg[23] = crc_store_reg[22]  ^ crc_store_reg[31];
    crc_shift_reg[24] = crc_store_reg[23];
    crc_shift_reg[25] = crc_store_reg[24];
    crc_shift_reg[26] = crc_store_reg[25]  ^ crc_store_reg[31];
    crc_shift_reg[27] = crc_store_reg[26];
    crc_shift_reg[28] = crc_store_reg[27];
    crc_shift_reg[29] = crc_store_reg[28];
    crc_shift_reg[30] = crc_store_reg[29];
    crc_shift_reg[31] = crc_store_reg[30];
    // wait for delta time
    delta_t = !delta_t;
    // increment address and load new data for Big ENDIAN Bytes (Litle ENDIAN bits)
    if (word_cnt == 7)
    begin
      addr_cnt = addr_cnt + 4;
      load_reg = wb_slave.wb_memory[{12'h0, addr_cnt}];
    end
    // set new load bit position for Big ENDIAN Bytes (Litle ENDIAN bits)
    if(word_cnt == 31)
      word_cnt = 16;
    else if (word_cnt == 23)
      word_cnt = 8;
    else if (word_cnt == 15)
      word_cnt = 0;
    else if (word_cnt == 7)
      word_cnt = 24;
    else
      word_cnt = word_cnt + 1;
    // decrement bit counter
    bit_cnt = bit_cnt - 1;
    // wait for delta time
    delta_t = !delta_t;
  end // while

  // put CRC out
  crc = crc_shift_reg;
  #1;
end
endtask // serial_crc_mac

//////////////////////////////////////////////////////////////
// MIIM Basic tasks
//////////////////////////////////////////////////////////////

task reset_mii; //  MII module
  reg [31:0] tmp;
  reg [31:0] tmp_no_rst;
begin
  // read MII mode register first
  wbm_read(`ETH_MIIMODER, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // set reset bit - write back to MII mode register with RESET bit
  wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_RST | tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // clear reset bit - write back to MII mode register without RESET bit
  tmp_no_rst = `ETH_MIIMODER_RST;
  tmp_no_rst = ~tmp_no_rst;
  wbm_write(`ETH_MIIMODER, (tmp_no_rst & tmp), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
end
endtask // reset_mii

task mii_set_clk_div; // set clock divider for MII clock
  input [7:0]  clk_div;
begin
  // MII mode register
  wbm_write(`ETH_MIIMODER, (`ETH_MIIMODER_CLKDIV & clk_div), 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
end
endtask // mii_set_clk_div


task check_mii_busy; // MII - check if BUSY
  reg [31:0] tmp;
begin
  @(posedge wb_clk);                                                                  
  // MII read status register
  wbm_read(`ETH_MIISTATUS, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  while(tmp[`ETH_MIISTATUS_BUSY] !== 1'b0) //`ETH_MIISTATUS_BUSY
  begin
    @(posedge wb_clk);
    wbm_read(`ETH_MIISTATUS, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  end
end
endtask // check_mii_busy


task check_mii_scan_valid; // MII - check if SCAN data are valid
  reg [31:0] tmp;
begin
  @(posedge wb_clk);
  // MII read status register
  wbm_read(`ETH_MIISTATUS, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  while(tmp[`ETH_MIISTATUS_NVALID] !== 1'b0) //`ETH_MIISTATUS_NVALID
  begin
    @(posedge wb_clk);
    wbm_read(`ETH_MIISTATUS, tmp, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  end
end
endtask // check_mii_scan_valid


task mii_write_req; // requests write to MII
  input [4:0]  phy_addr;
  input [4:0]  reg_addr;
  input [15:0] data_in;
begin
  // MII address, PHY address = 1, command register address = 0
  wbm_write(`ETH_MIIADDRESS, (`ETH_MIIADDRESS_FIAD & phy_addr) | (`ETH_MIIADDRESS_RGAD & (reg_addr << 8)), 
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // MII TX data
  wbm_write(`ETH_MIITX_DATA, {16'h0000, data_in}, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // MII command
  wbm_write(`ETH_MIICOMMAND, `ETH_MIICOMMAND_WCTRLDATA, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  @(posedge wb_clk);                                                                  
end
endtask // mii_write_req


task mii_read_req; // requests read from MII
  input [4:0]  phy_addr;
  input [4:0]  reg_addr;
begin
  // MII address, PHY address = 1, command register address = 0
  wbm_write(`ETH_MIIADDRESS, (`ETH_MIIADDRESS_FIAD & phy_addr) | (`ETH_MIIADDRESS_RGAD & (reg_addr << 8)), 
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // MII command
  wbm_write(`ETH_MIICOMMAND, `ETH_MIICOMMAND_RSTAT, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  @(posedge wb_clk);
end
endtask // mii_read_req


task mii_scan_req; // requests scan from MII
  input [4:0]  phy_addr;
  input [4:0]  reg_addr;
begin
  // MII address, PHY address = 1, command register address = 0
  wbm_write(`ETH_MIIADDRESS, (`ETH_MIIADDRESS_FIAD & phy_addr) | (`ETH_MIIADDRESS_RGAD & (reg_addr << 8)), 
            4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  // MII command
  wbm_write(`ETH_MIICOMMAND, `ETH_MIICOMMAND_SCANSTAT, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  @(posedge wb_clk);
end
endtask // mii_scan_req


task mii_scan_finish; // finish scan from MII
begin
  // MII command
  wbm_write(`ETH_MIICOMMAND, 32'h0, 4'hF, 1, wbm_init_waits, wbm_subseq_waits);
  @(posedge wb_clk);
end
endtask // mii_scan_finish

//////////////////////////////////////////////////////////////
// Log files and memory tasks
//////////////////////////////////////////////////////////////

task clear_memories;
  reg    [22:0]  adr_i;
  reg            delta_t;
begin
  delta_t = 0;
  for (adr_i = 0; adr_i < 4194304; adr_i = adr_i + 1)
  begin
    eth_phy.rx_mem[adr_i[21:0]] = 0;
    eth_phy.tx_mem[adr_i[21:0]] = 0;
    wb_slave.wb_memory[adr_i[21:2]] = 0;
    delta_t = !delta_t;
  end
end
endtask // clear_memories

task test_note;
  input [799:0] test_note ;
  reg   [799:0] display_note ;
begin
  display_note = test_note;
  while ( display_note[799:792] == 0 )
    display_note = display_note << 8 ;
  $fdisplay( tb_log_file, " " ) ;
  $fdisplay( tb_log_file, "NOTE: %s", display_note ) ;
  $fdisplay( tb_log_file, " " ) ;
end
endtask // test_note

task test_heading;
  input [799:0] test_heading ;
  reg   [799:0] display_test ;
begin
  display_test = test_heading;
  while ( display_test[799:792] == 0 )
    display_test = display_test << 8 ;
  $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
  $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
  $fdisplay( tb_log_file, "  Heading: %s", display_test ) ;
  $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
  $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
  $fdisplay( tb_log_file, " " ) ;
end
endtask // test_heading


task test_fail ;
  input [7999:0] failure_reason ;
//  reg   [8007:0] display_failure ;
  reg   [7999:0] display_failure ;
  reg   [799:0] display_test ;
begin
  tests_failed = tests_failed + 1 ;

  display_failure = failure_reason; // {failure_reason, "!"} ;
  while ( display_failure[7999:7992] == 0 )
    display_failure = display_failure << 8 ;

  display_test = test_name ;
  while ( display_test[799:792] == 0 )
    display_test = display_test << 8 ;

  $fdisplay( tb_log_file, "    *************************************************************************************" ) ;
  $fdisplay( tb_log_file, "    At time: %t ", $time ) ;
  $fdisplay( tb_log_file, "    Test: %s", display_test ) ;
  $fdisplay( tb_log_file, "    *FAILED* because") ;
  $fdisplay( tb_log_file, "    %s", display_failure ) ;
  $fdisplay( tb_log_file, "    *************************************************************************************" ) ;
  $fdisplay( tb_log_file, " " ) ;

 `ifdef STOP_ON_FAILURE
    #20 $stop ;
 `endif
end
endtask // test_fail


task test_ok ;
  reg [799:0] display_test ;
begin
  tests_successfull = tests_successfull + 1 ;

  display_test = test_name ;
  while ( display_test[799:792] == 0 )
    display_test = display_test << 8 ;

  $fdisplay( tb_log_file, "    *************************************************************************************" ) ;
  $fdisplay( tb_log_file, "    At time: %t ", $time ) ;
  $fdisplay( tb_log_file, "    Test: %s", display_test ) ;
  $fdisplay( tb_log_file, "    reported *SUCCESSFULL*! ") ;
  $fdisplay( tb_log_file, "    *************************************************************************************" ) ;
  $fdisplay( tb_log_file, " " ) ;
end
endtask // test_ok


task test_summary;
begin
  $fdisplay(tb_log_file, "**************************** Ethernet MAC test summary **********************************") ;
  $fdisplay(tb_log_file, "Tests performed:   %d", tests_successfull + tests_failed) ;
  $fdisplay(tb_log_file, "Failed tests   :   %d", tests_failed) ;
  $fdisplay(tb_log_file, "Successfull tests: %d", tests_successfull) ;
  $fdisplay(tb_log_file, "**************************** Ethernet MAC test summary **********************************") ;
  $fclose(tb_log_file) ;
end
endtask // test_summary


endmodule
