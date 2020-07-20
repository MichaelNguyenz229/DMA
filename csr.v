module csr
(
    input clk,
    input reset,

    input csr_wr_i,
    input csr_rd_i,

    input [3:0] csr_addr_i,
    input [31:0] csr_wr_data_i,

    input [1:0] csr_be_i,

    output csr_wait_rq_o,
    output [31:0] csr_rd_data_o
);

//internal signals
csr_reg_hit [2:0];

//state machine
typedef enum logic [2:0] {IDLE, WR_EN, WAIT_READ_1, WAIT_READ_2, RD_VALID} State;

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
                next_state <= WAIT_READ_1;
            else:
                next_state <= IDLE;
            
        WR_EN:
            next_state <= IDLE;

        WAIT1:
            next_state <= WAIT_READ_2;

        WAIT2:
            next_state <= RD_VALID;

        RD_VALID:
            next_state <= IDLE;

        default:
            next_state <= IDLE;
    endcase

    //decoder
    always @*
    begin
        case(csr_addr_i)
            4'h0: csr_reg_hit = 001;
            4'h4: csr_reg_hit = 010;
            4'h8: csr_reg_hit = 100;
            default: csr_reg_hit = 000;
    end

    //reg file
    



endmodule

