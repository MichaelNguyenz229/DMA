module dma_read_block
(
    input clk,
    input reset,

    //to AVMM master port
    output [31:0] rd_master_addr_o,
    output [10:0] rd_master_bcount_o,

    //from AVMM master port
    input rd_master_wait_req_i,
    input rd_master_data_valid_i,
    input [255:0] rd_master_data_i,

    //from desc processor
    input dma_rd_fifo_command_req_i,
    input [15:0] dma_rd_bytes_to_transfer_i,
    input [31:0] dma_rd_addr_i,

    //to desc processor
    output dma_rd_fifo_full_o,

    //to dma data fifo
    output [255:0] dma_rd_data_o,
    output dma_rd_data_valid_o
);

//internal signals
wire [47:0] rd_fifo_data_in;
reg [47:0] rd_fifo_data_q;

wire rd_fifo_empty;

reg [1:0] current_state;
reg [1:0] next_state;

wire rd_fifo_state;
wire ld_reg_state;

reg [47:0] command_fifo_reg;

wire [15:0] bytes_to_transfer;

reg [10:0] bcount_reg;

reg[255:0] rd_master_data_reg;
reg rd_master_data_valid_reg;

//read fifo data
assign rd_fifo_data_in = {dma_rd_bytes_to_transfer_i, dma_rd_addr_i};

//read block fifo
scfifo	read_block_fifo (
				.clock (clk),
				.data (rd_fifo_data_in),
				.rdreq (rd_fifo_state),
				.sclr (reset),
				.wrreq (dma_rd_fifo_command_req_i),
				.almost_full (),
				.q (rd_fifo_data_q),
				.aclr (),
				.almost_empty (),
				.eccstatus (),
				.empty (rd_fifo_empty),
				.full (dma_rd_fifo_full_o),
				.usedw ());
	defparam
		read_block_fifo.add_ram_output_register = "OFF",
		read_block_fifo.almost_full_value = 24,
		read_block_fifo.intended_device_family = "Cyclone V",
		read_block_fifo.lpm_numwords = 32,
		read_block_fifo.lpm_showahead = "OFF",
		read_block_fifo.lpm_type = "scfifo",
		read_block_fifo.lpm_width = 48,
		read_block_fifo.lpm_widthu = 5,
		read_block_fifo.overflow_checking = "ON",
		read_block_fifo.underflow_checking = "ON",
		read_block_fifo.use_eab = "ON";

//read block state machine
localparam IDLE = 2'b00;
localparam RD_FIFO = 2'b01;
localparam LD_REG = 2'b10;
localparam SEND_RD = 2'b11;

always @(posedge clk)
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;

always @*
    case(current_state)
        IDLE:
            next_state <= RD_FIFO;

        RD_FIFO:
            next_state <= LD_REG;

        LD_REG:
            next_state <= SEND_RD;

        SEND_RD:
            if(~rd_master_wait_req_i)
                next_state <= IDLE;
            else
                next_state <= SEND_RD;
            
        default:
            next_state <= IDLE;
    endcase

//state machine assignment
assign rd_fifo_state = (current_state[1:0] == RD_FIFO);
assign ld_reg_state = (current_state[1:0] == LD_REG);

//signal to read from fifo? when does it output data q?

//latch reg
always @ (posedge clk)
    if(ld_reg_state)
        command_fifo_reg[47:0] <= rd_fifo_data_q;

//burst counter and source addr
assign bytes_to_transfer = command_fifo_reg[47:32];

always @ (posedge clk)
//if reset
    bcount_reg[10:0] <= bytes_to_transfer[15:5] + | bytes_to_transfer[4:0];

assign rd_master_bcount_o[10:0] = bcount_reg[10:0];
assign rd_master_addr_o[31:0] = command_fifo_reg[31:0];

//reg for dma data and rd data valid
always @ (posedge clk)
    rd_master_data_reg[255:0] <= rd_master_data_i[255:0];

always @ (posedge clk)
    rd_master_data_valid_reg <= rd_master_data_valid_i;

assign dma_rd_data_o[255:0] = rd_master_data_reg;
assign dma_rd_data_valid_o = rd_master_data_valid_reg;

//signal when rd fifo full?

endmodule
