// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module wb_port_test #( //maybe we can give it its own name 
    parameter   [31:0]  BASE_ADDRESS    = 32'h03000000,        // base address
    parameter   [31:0]  KEY_0_ADDRESS   = BASE_ADDRESS,
    parameter   [31:0]  KEY_1_ADDRESS   = BASE_ADDRESS + 4,
    parameter   [31:0]  PLAIN_0_ADDRESS  = BASE_ADDRESS + 8,
    parameter   [31:0]  PLAIN_1_ADDRESS  = BASE_ADDRESS + 12,
    parameter   [31:0]  CMOS_OUT_0_ADDRESS  = BASE_ADDRESS + 16,
    parameter   [31:0]  CMOS_OUT_1_ADDRESS  = BASE_ADDRESS + 20,
    parameter   [31:0]  CONTROL_0_ADDRESS  = BASE_ADDRESS + 24
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [15:0] io_in,
    output [15:0] io_out,
    output [15:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [15:0] io_in;
    wire [15:0] io_out;
    wire [15:0] io_oeb;

    wire [15:0] rdata; 
    wire [15:0] wdata;
    wire [15:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wdata = wbs_dat_i[15:0];

    // IO
    assign io_out = count;
    assign io_oeb = {(15){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    //assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [63:32] are for controlling the count register  
    //assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;
    
    localparam DEPTH_LOG2 = 5;
    localparam ELEMENTS = 2**DEPTH_LOG2;
    localparam WIDTH = 32;
    
    reg [WIDTH-1:0] storage [ELEMENTS-1:0];
 ////////////////////////////////////////////////////////////////////////////////////////////////   
        
    //assign o_wb_stall = 0; //dont seem to see this used in user_project_wrapper.v and example
    
    // writes
    genvar i ;
    generate
    for (i=0; i<ELEMENTS; i=i+1) begin
        always @(posedge clk) begin
            if(reset) begin
                storage[i] <= {WIDTH{1'b0}}; 
        	end   
        end
    end
    endgenerate
    
    
    always @(posedge clk) begin
        if(!reset && valid) begin // && !o_wb_stall) begin
            case(wbs_adr_i)
                KEY_0_ADDRESS, KEY_1_ADDRESS, 
                PLAIN_0_ADDRESS, PLAIN_1_ADDRESS, 
                CONTROL_0_ADDRESS: begin
                    if (wstrb[0]) storage[wbs_adr_i[DEPTH_LOG2-1:0]][7:0] <= wbs_dat_i[7:0];
                    if (wstrb[1]) storage[wbs_adr_i[DEPTH_LOG2-1:0]][15:8] <= wbs_dat_i[15:8];
                    if (wstrb[2]) storage[wbs_adr_i[DEPTH_LOG2-1:0]][23:16] <= wbs_dat_i[23:16];
                    if (wstrb[3]) storage[wbs_adr_i[DEPTH_LOG2-1:0]][31:24] <= wbs_dat_i[31:24];
                end
            endcase
        end 
    end
    
    // reads
    always @(posedge clk) begin
        if(valid && !i_wb_we) // && !o_wb_stall)
            case(wbs_adr_i)
                KEY_0_ADDRESS, KEY_1_ADDRESS,
                PLAIN_0_ADDRESS, PLAIN_1_ADDRESS,
                CMOS_OUT_0_ADDRESS, CMOS_OUT_1_ADDRESS, 
                CONTROL_0_ADDRESS:
                    wbs_dat_o <= storage[wbs_adr_i [DEPTH_LOG2-1:0]];
                default:
                    wbs_dat_o <= 32'b0;
            endcase
    end
    
    // acks
    always @(posedge clk) begin
        if(reset)
            wbs_ack_o <= 0;
        else
            // return ack immediately
            //$display("Addr %h, width %d, signal p1: %d", i_wb_addr, $clog2(WIDTH/8), ((i_wb_addr & (WIDTH/8 - 1)) == {32{1'b0}}));
            wbs_ack_o <= (valid && !wbs_ack_o && /*!o_wb_stall &&*/ ((wbs_adr_i & (WIDTH/8 - 1)) == {$clog2(WIDTH/8){1'b0}}) && (wbs_adr_i >= BASE_ADDRESS) && (wbs_adr_i <= BASE_ADDRESS + 24));
    end
    
endmodule
`default_nettype wire
