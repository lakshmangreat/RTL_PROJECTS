
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.09.2024 17:38:36
// Design Name: 
// Module Name: pdcch_top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "pdcch_header.svh"
`include "pdcch_controller.sv"
`include "pdcch_mainblock.sv"
`include "skid_buffer.sv"
 `include "fifo.sv"

module pdcch_top_module#(parameter
                         CONFIG_BIT_OUT_WIDTH=$bits(config_out_t),
                         CONFIG_BIT_WIDTH=$bits(config_input_t),
                         FIFO_DEPTH=1024,
                         DATA_OUT_WIDTH=8)
(
    input clk,
    input reset,
    
    input logic config_input_t_valid,
    output logic config_input_t_ready,
    input logic [(CONFIG_BIT_WIDTH-1):0] config_input_t_data,

    output logic top_out_valid,
    input logic top_out_ready,
    output logic [(CONFIG_BIT_OUT_WIDTH-1):0] top_out_data
);

    // Inputs to skid Buffer
    wire                             skidbuff1_controller_valid;
    wire [(CONFIG_BIT_WIDTH-1):0]     skidbuff1_controller_data;
    wire                              controller_skidbuff1_ready;
    
    // Instance of the 1st Skid Buffer module
  skid_buffer #(CONFIG_BIT_WIDTH) input_skid (
        .clk(clk),
        .reset(reset),
        .s_valid(config_input_t_valid),
        .s_data(config_input_t_data),
        .s_ready(config_input_t_ready),
        .m_valid(skidbuff1_controller_valid),
        .m_data(skidbuff1_controller_data),
        .m_ready(controller_skidbuff1_ready)
    );

    // Controller to Skid Buffer2 signals
    wire                      controller_skid2_valid;
    wire [(CONFIG_BIT_OUT_WIDTH-1):0]     controller_skid2_data;
    wire                            skid2_controller_ready;

    // Instance of the Controller module
    pdcch_controller #(
        
        CONFIG_BIT_OUT_WIDTH,
      CONFIG_BIT_WIDTH
    ) controller_inst (
        .clk(clk),
        .reset(reset),
        .s_cntlr_valid(skidbuff1_controller_valid),
        .s_cntlr_data(skidbuff1_controller_data),
        .s_cntlr_ready(controller_skidbuff1_ready),
        .m_cntlr_valid(controller_skid2_valid),
        .m_cntlr_data(controller_skid2_data),
        .m_cntlr_ready(skid2_controller_ready)
    );

    // 2nd Skid Buffer to Mainblock Signals
    wire                     skid2_mainblock_valid;
    wire  [(CONFIG_BIT_OUT_WIDTH-1):0]   skid2_mainblock_data;
    wire                     mainblock_skid2_ready;

    // Instance of the 2nd Skid Buffer module
    skid_buffer #(CONFIG_BIT_OUT_WIDTH) output_skid (
        .clk(clk),
        .reset(reset),
        .s_valid(controller_skid2_valid),
        .s_data(controller_skid2_data),
        .s_ready(skid2_controller_ready),
        .m_valid(skid2_mainblock_valid),
        .m_data(skid2_mainblock_data),
        .m_ready(mainblock_skid2_ready)
    );

    // FIFO signals
    wire     mainblock_fifo_valid;
    wire   [(CONFIG_BIT_OUT_WIDTH-1):0] mainblock_fifo_data;
    wire    mainblock_fifo_ready;

    // Instance of the main block module
    pdcch_mainblock #(CONFIG_BIT_OUT_WIDTH) mainblock_instansiation (
        .clk(clk),
        .reset(reset),
        .s_mainblock_valid(skid2_mainblock_valid),
        .s_mainblock_data(skid2_mainblock_data),
        .s_mainblock_ready(mainblock_skid2_ready),
        .m_mainblock_valid(mainblock_fifo_valid),
        .m_mainblock_data(mainblock_fifo_data),
        .m_mainblock_ready(mainblock_fifo_ready)
    );

    // FIFO instance
    wire fifo_wr_en = mainblock_fifo_valid; // FIFO write enable
    wire fifo_rd_en = top_out_ready;        // FIFO read enable

    fifo #(.DATA_WIDTH(CONFIG_BIT_OUT_WIDTH), .DEPTH(FIFO_DEPTH)) fifo_inst (
        .clk(clk),
        .reset(reset),
        .wr_en(fifo_wr_en),              // Connect FIFO write enable
        .rd_en(fifo_rd_en),              // Connect FIFO read enable
        .s_axis_data(mainblock_fifo_data),
        .s_axis_valid(mainblock_fifo_valid),
        .s_axis_ready(mainblock_fifo_ready),
        .m_axis_data(top_out_data),
        .m_axis_valid(top_out_valid),
        .m_axis_ready(top_out_ready),
        .full(),                          // Unconnected, can be connected if needed
        .empty()                          // Unconnected, can be connected if needed
    );

endmodule
