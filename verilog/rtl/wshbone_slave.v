/*
    based off https://zipcpu.com/zipcpu/2017/05/29/simple-wishbone.html

    copyright Matt Venn 2020

    licensed under the GPL
*/
`default_nettype none
//we are assuming this is big endian
//RISCV should be written in little endian --> will have to check
module wshbone_slave #(
    parameter   [31:0]  BASE_ADDRESS    = 32'h03000000,        // base address
    parameter   [31:0]  KEY_0_ADDRESS   = BASE_ADDRESS,
    parameter   [31:0]  KEY_1_ADDRESS   = BASE_ADDRESS + 4,
    parameter   [31:0]  PLAIN_0_ADDRESS  = BASE_ADDRESS + 8,
    parameter   [31:0]  PLAIN_1_ADDRESS  = BASE_ADDRESS + 12,
    parameter   [31:0]  CMOS_OUT_0_ADDRESS  = BASE_ADDRESS + 16,
    parameter   [31:0]  CMOS_OUT_1_ADDRESS  = BASE_ADDRESS + 20,
    parameter   [31:0]  CONTROL_0_ADDRESS  = BASE_ADDRESS + 24//,
    //parameter   [31:0]  BUTTON_ADDRESS  = BASE_ADDRESS + 28,
    //parameter   [31:0]  BUTTON_ADDRESS  = BASE_ADDRESS + 32,
    ) 
    (
    input wire          clk,
    input wire          reset,

    // wb interface
    input wire          i_wb_cyc,       // wishbone transaction
    input wire          i_wb_stb,       // strobe - data valid and accepted as long as !o_wb_stall
    input wire          i_wb_we,        // write enable
    input wire  [31:0]  i_wb_addr,      // address
    input wire  [31:0]  i_wb_data,      // incoming data
    output reg          o_wb_ack,       // request is completed 
    output wire         o_wb_stall,     // cannot accept req
    output reg  [31:0]  o_wb_data//,      // output data

    );
    
    localparam DEPTH_LOG2 = 5;
    localparam ELEMENTS = 2**DEPTH_LOG2;
    localparam WIDTH = 32;

    reg [WIDTH-1:0] storage [ELEMENTS-1:0];
    
    
    assign o_wb_stall = 0;
    
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
        if(!reset && i_wb_stb && i_wb_cyc && i_wb_we && !o_wb_stall) begin
            case(i_wb_addr)
                KEY_0_ADDRESS: 
                    storage[i_wb_addr [DEPTH_LOG2-1:0]] <= i_wb_data;
                KEY_1_ADDRESS: 
                    storage[i_wb_addr [DEPTH_LOG2-1:0]] <= i_wb_data;
                PLAIN_0_ADDRESS: 
                    storage[i_wb_addr [DEPTH_LOG2-1:0]] <= i_wb_data;
                PLAIN_1_ADDRESS: 
                    storage[i_wb_addr [DEPTH_LOG2-1:0]] <= i_wb_data;
                CONTROL_0_ADDRESS: 
                    storage[i_wb_addr [DEPTH_LOG2-1:0]] <= i_wb_data;
            endcase
        end 
    end
    
    // reads
    always @(posedge clk) begin
        if(i_wb_stb && i_wb_cyc && !i_wb_we && !o_wb_stall)
            case(i_wb_addr)
                KEY_0_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                KEY_1_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                PLAIN_0_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                PLAIN_1_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                CMOS_OUT_0_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                CMOS_OUT_1_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                CONTROL_0_ADDRESS: 
                    o_wb_data <= storage[i_wb_addr [DEPTH_LOG2-1:0]];
                default:
                    o_wb_data <= 32'b0;
            endcase
    end
    
    // acks
    always @(posedge clk) begin
        if(reset)
            o_wb_ack <= 0;
        else
            // return ack immediately
            //$display("Addr %h, width %d, signal p1: %d", i_wb_addr, $clog2(WIDTH/8), ((i_wb_addr & (WIDTH/8 - 1)) == {32{1'b0}}));
            o_wb_ack <= (i_wb_stb && !o_wb_stall && ((i_wb_addr & (WIDTH/8 - 1)) == {$clog2(WIDTH/8){1'b0}}) && (i_wb_addr >= BASE_ADDRESS) && (i_wb_addr <= BASE_ADDRESS + 24));
    end

`ifdef FORMAL
	default clocking @(posedge clk); endclocking
	default disable iff (reset);

    cyc:    assume property (i_wb_cyc |=> i_wb_cyc && o_wb_ack);
	write:  cover property (##1 $rose(i_wb_stb) |-> ##[+] o_wb_data[3:0] == 4'b1010);
    read:   cover property (##1 $rose(i_wb_stb) |-> ##[+] leds[7:0] == 8'b11110000);
`endif
endmodule

