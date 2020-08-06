module dma_status_update
(
    input clk,
    input reset,

    //status from write block
    input dma_status_fifo_wr_req_i,
    input [24:0]dma_status_fifo_data_i,

    //status to write block
    output dma_status_fifo_almost_full_o,

    //from csr
    input [31:0] csr_control_i,
    input [31:0] csr_status_i,
    input [31:0] csr_first_pointer_i,

    //to update csr status
    output [31:0] csr_status_update_data_o,
    output csr_status_update_req_o,
    input csr_status_update_ack_i,

    //to AVMM master (update descriptor)
    output dma_desc_update_wr_o,
    output [31:0] dma_desc_update_data_o,
    output [3:0] dma_desc_update_be_o,
    output reg [31:0] dma_desc_update_addr_o,
    input dma_desc_update_wait_req_i,

    //interupt output
    output dma_interupt_rq_o
);

//interal signals
reg [2:0] current_state;
reg [2:0] next_state;

wire rd_fifo_state;
wire ld_reg_state;
wire update_csr_status_state;
wire update_desc_state;
wire irq_state;

wire status_fifo_empty;

reg [24:0] status_fifo_data_q;
reg [24:0] status_fifo_data_reg;

wire ie_desc;
wire ie_chain;

wire last_desc;

wire status_clear;

wire [31:0] dma_desc_update_addr;

//status fifo
scfifo	status_fifo (
				.clock (clk),
				.data (dma_status_fifo_data_i),
				.rdreq (rd_fifo_state),
				.sclr (reset),
				.wrreq (dma_status_fifo_wr_req_i),
				.almost_full (dma_status_fifo_almost_full_o),
				.q (status_fifo_data_q),
				.aclr (),
				.almost_empty (),
				.eccstatus (),
				.empty (status_fifo_empty),
				.full (),
				.usedw ());
	defparam
		status_fifo.add_ram_output_register = "OFF",
		status_fifo.almost_full_value = 24,
		status_fifo.intended_device_family = "Cyclone V",
		status_fifo.lpm_numwords = 32,
		status_fifo.lpm_showahead = "OFF",
		status_fifo.lpm_type = "scfifo",
		status_fifo.lpm_width = 25,
		status_fifo.lpm_widthu = 5,
		status_fifo.overflow_checking = "ON",
		status_fifo.underflow_checking = "ON",
		status_fifo.use_eab = "ON";



//state machine wait status and updates
localparam IDLE = 3'b000;
localparam RD_FIFO = 3'b001;
localparam LD_REG = 3'b010;
localparam UPDATE_CSR_STATUS = 3'b011;
localparam UPDATE_DESC = 3'b100;
localparam IRQ = 3'b101;

always @(posedge clk)
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;

always @*
    case(current_state)

        IDLE:
            if(~status_fifo_empty)
                next_state <= RD_FIFO;
            else
                next_state <= IDLE;

        RD_FIFO:
            next_state <= LD_REG;

        LD_REG:
            next_state <= UPDATE_CSR_STATUS;

        UPDATE_CSR_STATUS:
            if(csr_status_update_ack_i)
                next_state <= UPDATE_DESC;
            else
                next_state <= UPDATE_CSR_STATUS;

        UPDATE_DESC:
            if(~dma_desc_update_wait_req_i & ~ie_chain & ~ie_desc)
                next_state <= IDLE;
            else if(~dma_desc_update_wait_req_i & (ie_chain | ie_desc))
                next_state <= IRQ;
            else
                next_state <= UPDATE_DESC;
                
        IRQ:
            if(status_clear)
                next_state <= IDLE;
            else
                next_state <= IRQ;

        default:
            next_state <= IDLE;

    endcase

//state assignment
assign rd_fifo_state = (current_state[2:0] == RD_FIFO);
assign ld_reg_state = (current_state[2:0] == LD_REG);
assign update_csr_status_state = (current_state[2:0] == UPDATE_CSR_STATUS);
assign update_desc_state = (current_state[2:0] == UPDATE_DESC);
assign irq_state = (current_state[2:0] == IRQ);

//IE assignment
assign last_desc = status_fifo_data_reg[24];
assign ie_desc = (csr_control_i[2] | csr_control_i[4]);
assign ie_chain = ((csr_control_i[3] & last_desc) | (csr_control_i[4] & last_desc));

//Status clear assignment
assign status_clear = ~csr_status_i[2] & ~csr_status_i[3];

//Latch status register
always @ (posedge clk)
    if(ld_reg_state)
        status_fifo_data_reg[24:0] <= status_fifo_data_q[24:0];

//csr status update interface
assign csr_status_update_req_o = update_csr_status_state;

//last desc
assign dma_owned_by_hw = status_fifo_data_reg[24]

assign csr_status_update_data_o[31:0] = {csr_status_i[31:4], dma_owned_by_hw, 1'b1, csr_status_i[1:0]};

//master write interface for descriptor update
assign dma_desc_update_wr_o = update_desc_state;
assign dma_desc_update_data_o[31:0] = {16'h0, status_fifo_data_reg[15:0]};
assign dma_desc_update_be_o[3:0] = 4'b1100;
assign dma_desc_update_addr[31:0] = csr_first_pointer_i + (status_fifo_data_reg[23:16] * 5'h1c);

//desc update addr register
always @ (posedge clk)
    if(reset)
        dma_desc_update_addr_o[31:0] <= 32'h0;
    else
        dma_desc_update_addr_o[31:0] <= dma_desc_update_addr[31:0];

//assign interupt 
assign dma_interupt_rq_o = irq_state;

endmodule