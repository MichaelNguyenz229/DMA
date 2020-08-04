module dma_write_block
(
    input clk,
    input reset,

    //to AVMM master port
    output [31:0] wr_master_addr_o,
    output [10:0] wr_master_bcount_o,
    output [255:0] wr_master_data_o,

    //from AVMM master port
    input wr_master_wait_req_i,

    //from desc processsor
    input dma_wr_fifo_command_req_i,
    input [15:0] dma_wr_bytes_to_transfer_i,
    input [31:0] dma_wr_addr_i,
    input [7:0] dma_desc_id_i,
    input dma_owned_by_hw_i,

    //to desc processor
    output dma_wr_fifo_full_o,

    //to status update block
    output dma_status_fifo_wr_req_o,
    output [24:0] dma_status_fifo_data_o,

    //from status update block
    input dma_status_fifo_almost_full_i,

    //from dma data fifo
    input [255:0] dma_data,
    input dma_data_fifo_empty

);

//internal signals
wire [47:0] wr_fifo_data_in;
wire [47:0] wr_fifo_data_q;

wire wr_fifo_empty;

reg [2:0] current_state;
reg [2:0] next_state;

reg [47:0] wr_cmd_reg;

wire tc;
reg [10:0] transfer_count;
reg [10:0] bcount_reg;
wire [15:0] bytes_to_transfer;

reg [255:0] wr_master_data_reg;

reg [15:0] actual_bytes_transfered_reg;

reg [7:0] dma_desc_id_reg;
reg dma_owned_by_hw_reg;

wire rd_cmd_fifo_state;
wire ld_cmd_reg_state;
//wire check_xfr_state;
wire xfr_data_state;
wire update_status_state;

//write block fifo
scfifo	write_block_fifo (
				.clock (clk),
				.data (wr_fifo_data_in),
				.rdreq (rd_cmd_fifo_state),
				.sclr (reset),
				.wrreq (dma_wr_fifo_command_req_i),
				.almost_full (),
				.q (wr_fifo_data_q),
				.aclr (),
				.almost_empty (),
				.eccstatus (),
				.empty (wr_fifo_empty),
				.full (dma_wr_fifo_full_o),
				.usedw ());
	defparam
		write_block_fifo.add_ram_output_register = "OFF",
		write_block_fifo.almost_full_value = 24,
		write_block_fifo.intended_device_family = "Cyclone V",
		write_block_fifo.lpm_numwords = 32,
		write_block_fifo.lpm_showahead = "OFF",
		write_block_fifo.lpm_type = "scfifo",
		write_block_fifo.lpm_width = 48,
		write_block_fifo.lpm_widthu = 5,
		write_block_fifo.overflow_checking = "ON",
		write_block_fifo.underflow_checking = "ON",
		write_block_fifo.use_eab = "ON";

//
assign wr_fifo_data_in = {dma_wr_bytes_to_transfer_i, dma_wr_addr_i};

//write block state machine
localparam IDLE = 3'b00;
localparam RD_CMD_FIFO = 3'b001;
localparam LD_CMD_REG = 3'b010;
localparam CHECK_XFR = 3'b011;
localparam XFR_DATA = 3'b100;
localparam UPDATE_STATUS = 3'b101;

always @ (posedge clk)
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;

always @*
    case(current_state)
        IDLE:
            if(wr_fifo_empty)
                next_state <= IDLE;
            else
                next_state <= RD_CMD_FIFO;

        RD_CMD_FIFO:
            next_state <= LD_CMD_REG;

        LD_CMD_REG:
            next_state <= CHECK_XFR;

        CHECK_XFR:
            if(~dma_data_fifo_empty & ~tc & ~wr_master_wait_req_i)
                next_state <= XFR_DATA;
            else
                next_state <= CHECK_XFR;

        XFR_DATA:
            if(tc)
                next_state <= UPDATE_STATUS;
            else if(~dma_data_fifo_empty & ~tc & ~wr_master_wait_req_i)
                next_state <= XFR_DATA;
            else
                next_state <= CHECK_XFR;

        UPDATE_STATUS:
            next_state <= IDLE;

        default:
            next_state <= IDLE;

    endcase

//state machine assignment
assign rd_cmd_fifo_state = (current_state[2:0] == RD_CMD_FIFO);
assign ld_cmd_reg_state = (current_state[2:0] == LD_CMD_REG);
//assign check_xfr_state = (current_state[2:0] == CHECK_XFR);
assign xfr_data_state = (current_state[2:0] == XFR_DATA);
assign update_status_state = (current_state[2:0] == UPDATE_STATUS);

//latch cmd
always @ (posedge clk)
    if(ld_cmd_reg_state)
        wr_cmd_reg[47:0] <= wr_fifo_data_q[47:0];

assign bytes_to_transfer[15:0] = wr_cmd_reg[47:32];

//transfer counter
always @ (posedge clk)
    if(reset | ld_cmd_reg_state)
        transfer_count[10:0] <= bytes_to_transfer[15:5] + |(bytes_to_transfer[4:0]);
    else if(xfr_data_state)
        transfer_count[10:0] <= transfer_count[10:0] - 1'b1;
    else
        transfer_count[10:0] <= transfer_count[10:0];

assign tc = (transfer_count[10:0] == 11'h0);

//bcount
always @ (posedge clk)
    bcount_reg[10:0] <= bytes_to_transfer[15:5] + |(bytes_to_transfer[4:0]);

assign wr_master_bcount_o[10:0] = bcount_reg[10:0];
assign wr_master_addr_o[31:0] = wr_cmd_reg[31:0];

//write data
always @ (posedge clk)
    wr_master_data_reg[255:0] <= dma_data[255:0];

assign wr_master_data_o[255:0] = wr_master_data_reg[255:0];

//update status
assign dma_status_fifo_wr_req_o = update_status_state;

always @ (posedge clk)
    if(update_status_state)
        actual_bytes_transfered_reg[15:0] <= bytes_to_transfer[15:0];

always @ (posedge clk)
    if(update_status_state)
        dma_desc_id_reg[7:0] <= dma_desc_id_i[7:0];

always @ (posedge clk)
    if(update_status_state)
        dma_owned_by_hw_reg <= dma_owned_by_hw_i;

assign  dma_status_fifo_data_o[24:0] = {dma_owned_by_hw_reg, dma_desc_id_reg[7:0], actual_bytes_transfered_reg[15:0]};

endmodule
