/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_workflow_test (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset
`ifdef USE_POWER_PINS
    inout wire        VPWR,     // Power supply
    inout wire        VGND      // Ground
`endif
);

  wire [6:0] addr = ui_in[6:0];
  wire [1:0] byte_index = addr[1:0];

  assign uio_oe  = 8'b0;  // All bidirectional IOs are inputs
  assign uio_out = 8'b0;

  wire WE = ui_in[7];
  wire WE0 = WE && (byte_index == 0);
  wire WE1 = WE && (byte_index == 1);
  wire WE2 = WE && (byte_index == 2);
  wire WE3 = WE && (byte_index == 3);

  wire [4:0] bit_index = {byte_index, 3'b000};
  wire [31:0] Di0 = {24'b0, uio_in} << bit_index;
  wire [31:0] Do0;
  reg [4:0] out_bit_index;
  assign uo_out = Do0[out_bit_index+:8];

  RAM32 ram1 (
`ifdef USE_POWER_PINS
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .CLK (clk),
      .EN0 (rst_n),
      .A0  (addr[6:2]),
      .WE0 ({WE3, WE2, WE1, WE0}),
      .Di0 (Di0),
      .Do0 (Do0)
  );

  always @(posedge clk) begin
    if (rst_n) begin
      out_bit_index <= bit_index;
    end else out_bit_index <= 0;
  end

// === SERV CPU Signals ===
wire        o_ibus_cyc;
wire [31:0] o_ibus_adr;
wire [31:0] i_ibus_rdt;
wire        i_ibus_ack;

wire        o_dbus_cyc;
wire [31:0] o_dbus_adr;
wire        o_dbus_we;
wire [31:0] o_dbus_dat;  // Changed from o_dbus_wdt to o_dbus_dat
wire  [3:0] o_dbus_sel;
wire [31:0] i_dbus_rdt;
wire        i_dbus_ack;

// Register file interface signals
wire        o_rf_rreq;
wire        o_rf_wreq;
wire        i_rf_ready;
wire [4:0]  o_wreg0;
wire [4:0]  o_wreg1;
wire        o_wen0;
wire        o_wen1;
wire        o_wdata0;
wire        o_wdata1;
wire [4:0]  o_rreg0;
wire [4:0]  o_rreg1;
wire        i_rdata0;
wire        i_rdata1;

// Extension interface signals
wire [2:0]  o_ext_funct3;
wire        i_ext_ready;
wire [31:0] i_ext_rd;
wire [31:0] o_ext_rs1;
wire [31:0] o_ext_rs2;
wire        o_mdu_valid;

// === Instantiate SERV CPU (just for size testing) ===
serv_top #(
    .RESET_PC(32'h0000_0000),
    .WITH_CSR(0),
    .PRE_REGISTER(1),
    .MDU(0)
) serv_cpu (
    .clk(clk),
    .i_rst(!rst_n),
    .i_timer_irq(1'b0),
    
    // Instruction bus
    .o_ibus_cyc(o_ibus_cyc),
    .o_ibus_adr(o_ibus_adr),
    .i_ibus_rdt(i_ibus_rdt),
    .i_ibus_ack(i_ibus_ack),
    
    // Data bus
    .o_dbus_cyc(o_dbus_cyc),
    .o_dbus_adr(o_dbus_adr),
    .o_dbus_we(o_dbus_we),
    .o_dbus_dat(o_dbus_dat),  // Corrected pin name
    .o_dbus_sel(o_dbus_sel),
    .i_dbus_rdt(i_dbus_rdt),
    .i_dbus_ack(i_dbus_ack),
    
    // Register file interface
    .o_rf_rreq(o_rf_rreq),
    .o_rf_wreq(o_rf_wreq),
    .i_rf_ready(i_rf_ready),
    .o_wreg0(o_wreg0),
    .o_wreg1(o_wreg1),
    .o_wen0(o_wen0),
    .o_wen1(o_wen1),
    .o_wdata0(o_wdata0),
    .o_wdata1(o_wdata1),
    .o_rreg0(o_rreg0),
    .o_rreg1(o_rreg1),
    .i_rdata0(i_rdata0),
    .i_rdata1(i_rdata1),
    
    // Extension interface
    .o_ext_funct3(o_ext_funct3),
    .i_ext_ready(i_ext_ready),
    .i_ext_rd(i_ext_rd),
    .o_ext_rs1(o_ext_rs1),
    .o_ext_rs2(o_ext_rs2),
    .o_mdu_valid(o_mdu_valid)
);

// Tie off SERV signals (not used in this test)
assign i_ibus_rdt = Do0;
assign i_dbus_rdt = Do0;
assign i_ibus_ack = o_ibus_cyc;
assign i_dbus_ack = o_dbus_cyc;

// Tie off register file interface
assign i_rf_ready = 1'b1;
assign i_rdata0 = 1'b0;
assign i_rdata1 = 1'b0;

// Tie off extension interface
assign i_ext_ready = 1'b1;
assign i_ext_rd = 32'h0;



endmodule
