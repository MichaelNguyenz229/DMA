module dma_desc_fetch
(
    input clk,
    input reset,

    input [31:0] csr_control_i,
    input [31:0] csr_first_pointer_i,

    output dma_desc_fetch_read_o,
    output [3:0] dma_desc_fetch_bcount_o,
    output [31:0] dma_desc_fetch_addr_o

    input dma_desc_fetch_waitrequest_i,
    input [31:0] dma_desc_fetch_rddata_i,
    input dma_desc_fetch_readdatavalid_i,

    output dma_desc_fifo_wr_o,
    output [255:0] dma_desc_fifo_wrdata_o,
    input dma_desc_fifo_full_i
);

//Internal signals
reg [2:0] current_state;
reg [2:0] next_state;

wire owned_by_hw;
wire park;
wire run;

//state machine
localparam IDLE = 4'b0000;
localparam LD_FIRST_PT = 3'b001;
localparam SEND_READ = 3'b010;
localparam WAIT_DATA = 3'b011;
localparam CHECK_DES = 3'b100;
localparam WAIT_RUN_CLR = 3'b101;

always @ (posedge clk)
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;

always @*
    case(current_state)
        IDLE:
            if(run)
                next_state <= LD_FIRST_PT;
            else
                next_state <= IDLE;

        LD_FIRST_PT:
            next_state <= SEND_READ;

        SEND_READ:
            if(dma_desc_fetch_waitrequest_i)
                next_state <= SEND_READ;
            else
                next_state <= WAIT_DATA;
        
        WAIT_DATA:
            if(dma_desc_fetch_bcount_o == 4'b1000)
                next_state <= CHECK_DES;
            else
                next_state <= WAIT_DATA;
        
        CHECK_DES:
            if(owned_by_hw == 1'b1)
                next_state <= SEND_READ;
            else if((owned_by_hw == 1'b0) & (park == 1'b1))
                next_state <= LD_FIRST_PT;
            else
                next_state <= WAIT_RUN_CLR;
        
        WAIT_RUN_CLR:
            if(run == 1'b0)
                next_state <= IDLE;
            else
                next_state <= WAIT_RUN_CLR;
        default:
            next_state <= IDLE;
    endcase





