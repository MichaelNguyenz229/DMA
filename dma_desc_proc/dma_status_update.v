module dma_status_update
(
    input clk,
    input reset,

    //status from write block
    input [24:0]dma_wr_done_status_i,

    //from csr
    input [31:0] csr_control_i,

    //to update csr status
    output [31:0] csr_status_update_o,
    output [3:0] csr_status_update_be_o,
    output csr_status_update_rq_o,
    input csr_status_update_ack_i,

    //to AVMM master (update descriptor)
    output dma_desc_update_wr_o,
    output [31:0] dma_desc_update_data_o,
    output [3:0] dma_desc_update_be_o,
    input dma_desc_update_wait_rq,

    //interupt output
    output dma_interupt_rq_o,
)

//interal signals
reg [2:0] current_state;
reg [2:0] next_state;

wire idle_state;
wire rd_fifo_state;
wire ld_reg_state;
wire update_csr_state;
wire update_desc_state;
wire irq_state;

wire fifo_empty;

//status fifo
scfifo	status_fifo (
				.clock (clk),
				.data (dma_wr_done_status_i),
				.rdreq (rd_fifo_state),
				.sclr (reset),
				.wrreq (dma_desc_fifo_wr_i),
				.almost_full (dma_desc_fifo_almost_full),
				.q (dma_desc_fifo_out),
				.aclr (),
				.almost_empty (fifo_empty),
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
		scfifo_component.lpm_width = 25,
		scfifo_component.lpm_widthu = 5,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";



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
        if(~fifo_empty)

    RD_FIFO:

    LD_REG:

    UPDATE_CSR_STATUS:

    UPDATE_DESC:

    IRQ:

    default:

    endcase

//state assignment
assign idle_state = (current_state[2:0] == IDLE);
assign rd_fifo_state = (current_state[2:0] == RD_FIFO);
assign ld_reg_state = (current_state[2:0] == LD_REG);
assign update_csr_state_state = (current_state[2:0] == UPDATE_CSR_STATUS);
assign update_desc_state = (current_state[2:0] == UPDATE_DESC);
assign irq_state = (current_state[2:0] == IRQ);

endmodule