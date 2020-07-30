module dma_desc_proc
(
    input clk,
    input reset,

    //from descriptor fetch
    input dma_desc_fifo_wr_i,
    input [264:0] dma_desc_fifo_wrdata_i,

    //to read block
    output dma_rd_fifo_command_rq_o,
    output dma_rd_bytes_to_transfer_o,
    output [31:0]dma_rd_addr_o,

    //from read block
    input dma_rd_fifo_full_i,

    //to write block
    output dma_wr_fifo_command_rq_o,
    output dma_wr_bytes_to_transfer_o,
    output [31:0]dma_wr_addr_o,

    //from write block
    input dma_wr_fifo_full_i
);

//Internal signals
reg [2:0] desc_current_state;
reg [2:0] desc_next_state;

wire dma_desc_fifo_almost_full;
reg [264:0] dma_desc_fifo_out;

wire desc_rd_fifo_state;
wire desc_latch_desc_state;
wire desc_rd_cmd_state;
wire desc_wr_cmd_state;

wire desc_fifo_empty;

reg [264:0] descriptor_register;

//Fifo instance 
scfifo	scfifo_component (
				.clock (clk),
				.data (dma_desc_fifo_wrdata_i),
				.rdreq (desc_rd_fifo_state),
				.sclr (reset),
				.wrreq (dma_desc_fifo_wr_i),
				.almost_full (dma_desc_fifo_almost_full),
				.q (dma_desc_fifo_out),
				.aclr (),
				.almost_empty (),
				.eccstatus (),
				.empty (),
				.full (),
				.usedw ());
	defparam
		scfifo_component.add_ram_output_register = "OFF",
		scfifo_component.almost_full_value = 24,
		scfifo_component.intended_device_family = "Cyclone V",
		scfifo_component.lpm_numwords = 32,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 265,
		scfifo_component.lpm_widthu = 5,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";

//state machine rd and wr command
localparam DESC_IDLE = 3'b000;
localparam DESC_RD_FIFO = 3'b001;
localparam DESC_LATCH_DESC = 3'b010;
localparam DESC_CMD = 3'b011;

always @ (posedge clk)
    if(reset)
         desc_current_state <= DESC_IDLE;
    else
         desc_current_state <=  desc_next_state;
    
always @*
    case(desc_current_state)
        DESC_IDLE:
            if(~desc_fifo_empty & ~dma_rd_fifo_full_i & ~dma_wr_fifo_full_i)
                desc_next_state <= DESC_RD_FIFO;
            else
                desc_next_state <= DESC_IDLE;

        DESC_RD_FIFO:
            desc_next_state <= DESC_LATCH_DESC;

        DESC_LATCH_DESC:
            desc_next_state <= DESC_CMD;

        DESC_CMD:
            desc_next_state <= DESC_IDLE;

        default:
            desc_next_state <= DESC_IDLE;
    endcase

assign desc_rd_fifo_state = (desc_current_state[2:0] == DESC_RD_FIFO);
assign desc_latch_desc_state = (desc_current_state[2:0] == DESC_LATCH_DESC);
assign desc_cmd_state = (desc_current_state[2:0] == DESC_CMD);

//latch descriptor from descriptor fifo
always @ (posedge clk)
    if(desc_latch_desc_state)
        descriptor_register[264:0] <= dma_desc_fifo_out[264:0];

assign dma_wr_fifo_command_rq_o = desc_cmd_state;
assign dma_rd_fifo_command_rq_o = desc_cmd_state;

assign dma_rd_bytes_to_transfer_o = descriptor_register[207:192];
assign dma_wr_bytes_to_transfer_o = descriptor_register[207:192];

assign dma_wr_addr_o = descriptor_register[95:62];
assign dma_rd_addr_o = descriptor_register[31:0];


endmodule


