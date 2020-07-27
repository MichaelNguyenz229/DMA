module dma_desc_fetch
(
    input clk,
    input reset,

    //From CSR
    input [31:0] csr_control_i,
    input [31:0] csr_first_pointer_i,

    //To AVMM master to descriptor memory
    output dma_desc_fetch_read_o, 
    output [3:0] dma_desc_fetch_bcount_o,
    output [31:0] dma_desc_fetch_addr_o,

    //From AVMM descriptor slave to master
    input dma_desc_fetch_waitrequest_i,
    input [31:0] dma_desc_fetch_rddata_i,
    input dma_desc_fetch_readdatavalid_i,

    //To descriptor fifo
    output dma_desc_fifo_wr_o,
    output [255:0] dma_desc_fifo_wrdata_o,

    //From descriptor fifo
    input dma_desc_fifo_full_i
);

//Internal signals
reg [2:0] current_state;
reg [2:0] next_state;

wire owned_by_hw;
wire park;
wire run;
reg [3:0] desc_burst_counter;

wire ld_first_ptr_state;
wire send_read_state;
wire wait_data_state;
wire check_desc_state;
wire wait_run_clr_state;

reg [31:0] desc_reg [0:7];

reg [31:0] desc_addr_register;

//state machine
localparam IDLE = 3'b000;
localparam LD_FIRST_PTR = 3'b001;
localparam SEND_READ = 3'b010;
localparam WAIT_DATA = 3'b011;
localparam CHECK_DESC = 3'b100;
localparam WAIT_RUN_CLR = 3'b101;
localparam FIFO_WAIT = 3'b110;

always @ (posedge clk)
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;

always @*
    case(current_state)
        IDLE:
            if(run)
                next_state <= LD_FIRST_PTR;
            else
                next_state <= IDLE;

        LD_FIRST_PTR:
            if(~dma_desc_fifo_full_i)
                next_state <= SEND_READ
            else
                next_state <= LD_FIRST_PTR;

        SEND_READ:
            if(dma_desc_fetch_waitrequest_i)
                next_state <= SEND_READ;
            else
                next_state <= WAIT_DATA;
        
        WAIT_DATA:
            if(desc_burst_counter == 4'b1000)
                next_state <= CHECK_DESC;
            else
                next_state <= WAIT_DATA;
        
        CHECK_DESC:
            if(dma_desc_fifo_full_i)
                next_state <= FIFO_WAIT;
            else if(owned_by_hw == 1'b1)
                next_state <= SEND_READ;
            else if((~owned_by_hw) & (park))
                next_state <= LD_FIRST_PTR;
            else
                next_state <= WAIT_RUN_CLR;
                
        FIFO_WAIT:
            if(~dma_desc_fifo_full_i & owned_by_hw)
                next_state <= SEND_READ;
            else if(~dma_desc_fifo_full_i & ~owned_by_hw & park)
                next_state <= LD_FIRST_PTR;
            else if (~dma_desc_fifo_full_i & ~owned_by_hw & ~park)
                next_state <= WAIT_RUN_CLR;
            else
                next_state <= FIFO_WAIT;
        
        WAIT_RUN_CLR:
            if(run == 1'b0)
                next_state <= IDLE;
            else
                next_state <= WAIT_RUN_CLR;
        default:
            next_state <= IDLE;
    endcase

//State machine signal assignemnt
assign ld_first_ptr_state = (current_state[2:0] == LD_FIRST_PTR);
assign send_read_state = (current_state[2:0] == SEND_READ);
assign wait_data_state = (current_state[2:0] == WAIT_DATA);
assign check_desc_state = (current_state[2:0] == CHECK_DESC);
assign wait_run_clr_state = (current_state[2:0] == WAIT_RUN_CLR);

//Burst counter
always @ (posedge clk)
    if(reset | send_read_state)
        desc_burst_counter <= 4'h0;
    else if(dma_desc_fetch_readdatavalid_i)
        desc_burst_counter <= desc_burst_counter + 1'b1;

//Descriptor collection
for(int i = 0; i < 8; i++)
    begin
       always @ (posedge clk)
        if(reset)
            desc_reg[i][31:0] <= 32'h0;
        else if(desc_burst_counter == i & dma_desc_fetch_readdatavalid_i)
            desc_reg[i][31:0] <= dma_desc_fetch_rddata_i[31:0]; 
    end

assign owned_by_hw = desc_reg[31][7]
assign park = csr_control_i[17]
assign run = csr_control_i[5]

//Address register
always @ (posedge clk)
    if(reset)
        desc_addr_register <= 32'h0;
    else if(ld_first_ptr_state)
        desc_addr_register <= csr_first_pointer_i;
    else if(check_desc_state)
        desc_addr_register <= desc_reg[4];

assign dma_desc_fetch_addr_o = desc_addr_register;
assign dma_desc_fetch_read_o = send_read_state;
assign dma_desc_fetch_bcount_o = 4'h8;

assign dma_desc_fifo_wr_o = check_desc_state;
assign dma_desc_fifo_wrdata_o = {desc_reg[7], desc_reg[6], desc_reg[5], desc_reg[4],
desc_reg[3], desc_reg[2], desc_reg[1], desc_reg[0]};

