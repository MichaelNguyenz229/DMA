module csr
(
    input clk,
    input reset,

    input csr_wr_i,
    input csr_rd_i,

    input [3:0] csr_addr_i,
    input [31:0] csr_wr_data_i,

    input [3:0] csr_be_i,

    output csr_wait_rq_o,
    output [31:0] csr_rd_data_o
);

//internal signals
reg csr_reg_hit [2:0];

reg csr_wr_en_reg [2:0];

reg csr_control_reg [31:0];
reg csr_status_reg [31:0];
reg csr_descriptor_pointer_reg [31:0];

reg rd_data_mux [31:0];

//state machine
typedef enum logic [2:0] {IDLE, WR_EN, WAIT_READ_1, RD_VALID} State;

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
            next_state <= RD_VALID;

        RD_VALID:
            next_state <= IDLE;

        default:
            next_state <= IDLE;
    endcase

    //state machine output assignment
    assign wr_en_state = (current_state[2:0] == WR_EN);
    assign rd_valid_state = (current_state[2:0] == RD_VALID);
    assign csr_ready = (wr_en_state | rd_valid_state);
    assign csr_wait_rq_o = ~csr_ready

    //decoder
    always @*
    begin
        case(csr_addr_i)
            4'h0: csr_reg_hit[2:0] <= 3'b001;
            4'h4: csr_reg_hit[2:0] <= 3'b010;
            4'h8: csr_reg_hit[2:0] <= 3'b100;
            default: csr_reg_hit[2:0] <= 3'b000;
    end

    always @ (posedge clk)
        if(reset)
            csr_wr_en_reg[2:0] <= 3'h0;
        else
            csr_wr_en_reg[2:0] <= csr_reg_hit[2:0]


    //REG FILE SECTION

    //Control Register
    always @ (posedge clk)
        if(reset)
            csr_control_reg[7:0] <= 8'h0; 
        else if(csr_wr_en_reg[0] & csr_be_i[0] & wr_en_state)
            csr_control_reg[7:0] <= csr_wr_data_i[7:0];

    always @ (posedge clk)
        if(reset)
            csr_control_reg[15:8] <= 8'h0; 
        else if(csr_wr_en_reg[0] & csr_be_i[1] & wr_en_state)
            csr_control_reg[15:8] <= csr_wr_data_i[15:8];

    always @ (posedge clk)
        if(reset)
            csr_control_reg[23:16] <= 8'h0; 
        else if(csr_wr_en_reg[0] & csr_be_i[2] & wr_en_state)
            csr_control_reg[23:16] <= csr_wr_data_i[23:16];

    always @ (posedge clk)
        if(reset)
            csr_control_reg[31:24] <= 8'h0; 
        else if(csr_wr_en_reg[0] & csr_be_i[3] & wr_en_state)
            csr_control_reg[31:24] <= csr_wr_data_i[31:24];
    
    //Status Register
    always @ (posedge clk)
        if(reset)
            csr_status_reg[7:0] <= 8'h0; 
        else if(csr_wr_en_reg[1] & csr_be_i[0] & wr_en_state)
            csr_status_reg[7:0] <= csr_wr_data_i[7:0];

    always @ (posedge clk)
        if(reset)
            csr_status_reg[15:8] <= 8'h0; 
        else if(csr_wr_en_reg[1] & csr_be_i[1] & wr_en_state)
            csr_status_reg[15:8] <= csr_wr_data_i[15:8];

    always @ (posedge clk)
        if(reset)
            csr_status_reg[23:16] <= 8'h0; 
        else if(csr_wr_en_reg[1] & csr_be_i[2] & wr_en_state)
            csr_status_reg[23:16] <= csr_wr_data_i[23:16];

    always @ (posedge clk)
        if(reset)
            csr_status_reg[31:24] <= 8'h0; 
        else if(csr_wr_en_reg[1] & csr_be_i[3] & wr_en_state)
            csr_status_reg[31:24] <= csr_wr_data_i[31:24];

    //Next Descriptor Pointer Register
    always @ (posedge clk)
        if(reset)
            csr_descriptor_pointer_reg[7:0] <= 8'h0; 
        else if(csr_wr_en_reg[2] & csr_be_i[0] & wr_en_state)
            csr_descriptor_pointer_reg[7:0] <= csr_wr_data_i[7:0];

    always @ (posedge clk)
        if(reset)
            csr_descriptor_pointer_reg[15:8] <= 8'h0; 
        else if(csr_wr_en_reg[2] & csr_be_i[1] & wr_en_state)
            csr_descriptor_pointer_reg[15:8] <= csr_wr_data_i[15:8];

    always @ (posedge clk)
        if(reset)
            csr_descriptor_pointer_reg[23:16] <= 8'h0; 
        else if(csr_wr_en_reg[2] & csr_be_i[2] & wr_en_state)
            csr_descriptor_pointer_reg[23:16] <= csr_wr_data_i[23:16];

    always @ (posedge clk)
        if(reset)
            csr_descriptor_pointer_reg[31:24] <= 8'h0; 
        else if(csr_wr_en_reg[2] & csr_be_i[3] & wr_en_state)
            csr_descriptor_pointer_reg[31:24] <= csr_wr_data_i[31:24];

    //csr read mux
    always @* 
        begin
            case(csr_wr_en_reg[2:0])
                3'b001: rd_data_mux[31:0] <= csr_control_reg[31:0];
                3'b010: rd_data_mux[31:0] <= csr_status_reg[31:0];
                3'b100: rd_data_mux[31:0] <= csr_descriptor_pointer_reg[31:0];
                default: rd_data_mux[31:0] <= 32'h0;
        end
    always @ (posedge clk)
        if(reset)
            csr_rd_data_o[31:0] <= 32'h0;
        else
            csr_rd_data_o[31:0] <= rd_data_mux[31:0];

endmodule

