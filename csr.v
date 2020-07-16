module csr
(
    input csr_wr,
    input csr_rd,

    input [31:0] csr_addr,
    input [31:0] csr_wr_data,

    output csr_wait_rq,
    output [31:0] csr_rd_data
);

//state machine
typedef enum logic [2:0] {IDLE, WR_EN, WAIT_1, WAIT_2, RD_VALID} State;

State current_state, next_state;

//state machine logic
always @(posedge clk)
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;

always @*
    case(current_state)
        IDLE:
            if(csr_wr):
                next_state <= WR_EN;
            else if(csr_rd):
                next_state <= WAIT_1;
            else:
                next_state <= IDLE;
            
        WR_EN:
            next_state <= IDLE;

        WAIT1:
            next_state <= WAIT_2;

        WAIT2:
            next_state <= RD_VALID;

        RD_VALID:
            next_state <= IDLE;

        default:
            next_state <= IDLE;
    endcase



endmodule

