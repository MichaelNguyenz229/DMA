module sg_dma
(
    input clk,
    input reset,

    //From master to csr slave (csr module)
    input csr_wr_i,
    input csr_rd_i,
    input [3:0] csr_addr_i,
    input [31:0] csr_wr_data_i,
    input [3:0] csr_be_i,
    output csr_wait_rq_o,
    output csr_rd_data_o,

    //From AVMM descriptor slave to master (fetch module)
    input dma_desc_fetch_waitrequest_i,
    input [31:0] dma_desc_fetch_rddata_i,
    input dma_desc_fetch_readdatavalid_i,

    //To AVMM master to descriptor memory (fetch module)
    output dma_desc_fetch_read_o, 
    output [3:0] dma_desc_fetch_bcount_o,
    output [31:0] dma_desc_fetch_addr_o,

    //to AVMM master (update descriptor) (status update module)
    output dma_desc_update_wr_o,
    output [31:0] dma_desc_update_data_o,
    output [3:0] dma_desc_update_be_o,
    output [31:0] dma_desc_update_addr_o,
    input dma_desc_update_wait_req_i,

    //interupt output (status update module)
    output dma_interupt_rq_o,

    //to AVMM master port (read module)
    output [31:0] rd_master_addr_o,
    output [10:0] rd_master_bcount_o,

    //from AVMM master port (read module)
    input rd_master_wait_req_i,
    input rd_master_data_valid_i,
    input [255:0] rd_master_data_i,

    //to AVMM master port (write module)
    output [31:0] wr_master_addr_o,
    output [10:0] wr_master_bcount_o,
    output [255:0] wr_master_data_o,

    //from AVMM master port (write module)
    input wr_master_wait_req_i
);

/////////////////////////////////////////
//internal signals
////////////////////////////////////////
wire [31:0] csr_control_data;
wire [31:0] csr_status_data;
wire [31:0] csr_next_pointer_data;

wire [31:0] csr_status_update_data;
wire csr_status_update_req;
wire csr_status_update_ack;

wire dma_desc_fifo_wr;
wire [264:0] dma_desc_fifo_wrdata;
wire dma_desc_fifo_full;

wire dma_rd_fifo_command_req;
wire [15:0] dma_rd_bytes_to_transfer;
wire [31:0] dma_rd_addr;
wire dma_rd_fifo_full;

wire dma_wr_fifo_command_req;
wire [15:0] dma_wr_bytes_to_transfer;
wire [31:0] dma_wr_addr;
wire [7:0] dma_desc_id;
wire dma_owned_by_hw;
wire dma_wr_fifo_full;

wire dma_status_fifo_wr_req;
wire [24:0] dma_status_fifo_data;
wire dma_status_fifo_almost_full;

wire [255:0] dma_rd_data;
wire dma_rd_data_valid;

wire [255:0] dma_data;
wire dma_data_fifo_empty;
wire dma_data_fifo_rd_req;

//dma_csr instance
dma_csr dma_csr_instance
(
    .clk (clk),
    .reset (reset),

    .csr_wr_i (csr_wr_i),
    .csr_rd_i (csr_rd_i),
    .csr_addr_i (csr_addr_i),
    .csr_wr_data_i (csr_wr_data_i),
    .csr_be_i (csr_be_i),

    .csr_wait_rq_o (csr_wait_rq_o),
    .csr_rd_data_o (csr_rd_data_o),

    //to status update
    .csr_control_o (csr_control_data),
    .csr_status_o (csr_status_data),
    .csr_next_pointer_o (csr_next_pointer_data),

    //csr status update
    .csr_status_update_data_i (csr_status_update_data),
    .csr_status_update_req_i (csr_status_update_req),
    .csr_status_update_ack_o (csr_status_update_ack)
);

//dma_desc_fetch instance
dma_desc_fetch dma_desc_fetch_instance
(
    .clk (clk),
    .reset (reset),

    //From CSR
    .csr_control_i (csr_control_data),
    .csr_first_pointer_i (csr_next_pointer_data),

    //To AVMM master to descriptor memory
    .dma_desc_fetch_read_o (dma_desc_fetch_read_o), 
    .dma_desc_fetch_bcount_o (dma_desc_fetch_bcount_o),
    .dma_desc_fetch_addr_o (dma_desc_fetch_addr_o),

    //From AVMM descriptor slave to master
    .dma_desc_fetch_waitrequest_i (dma_desc_fetch_waitrequest_i),
    .dma_desc_fetch_rddata_i (dma_desc_fetch_rddata_i),
    .dma_desc_fetch_readdatavalid_i (dma_desc_fetch_readdatavalid_i),

    //To descriptor fifo
    .dma_desc_fifo_wr_o (dma_desc_fifo_wr),
    .dma_desc_fifo_wrdata_o (dma_desc_fifo_wrdata),

    //From descriptor fifo
    .dma_desc_fifo_full_i (dma_desc_fifo_full)
);

//dma_desc_proc instance
dma_desc_proc dma_desc_proc_instance
(
    .clk (clk),
    .reset (reset),

    //from descriptor fetch
    .dma_desc_fifo_wr_i (dma_desc_fifo_wr),
    .dma_desc_fifo_wrdata_i (dma_desc_fifo_wrdata),

    //to descriptor fetch
    .dma_desc_fifo_full (dma_desc_fifo_full),

    //to read block
    .dma_rd_fifo_command_rq_o (dma_rd_fifo_command_req),
    .dma_rd_bytes_to_transfer_o (dma_rd_bytes_to_transfer),
    .dma_rd_addr_o (dma_rd_addr),

    //from read block
    .dma_rd_fifo_full_i (dma_rd_fifo_full),

    //to write block
    .dma_wr_fifo_command_rq_o (dma_wr_fifo_command_req),
    .dma_wr_bytes_to_transfer_o (dma_wr_bytes_to_transfer),
    .dma_wr_addr_o (dma_wr_addr),
    .dma_desc_id_o (dma_desc_id),
    .dma_owned_by_hw_o (dma_owned_by_hw),

    //from write block
    .dma_wr_fifo_full_i (dma_wr_fifo_full)
);

//dma_status_update instance
dma_status_update dma_status_update_instance
(   
    .clk (clk),
    .reset (reset),

    //status from write block
    .dma_status_fifo_wr_req_i (dma_status_fifo_wr_req),
    .dma_status_fifo_data_i (dma_status_fifo_data),

    //status to write block
    .dma_status_fifo_almost_full_o (dma_status_fifo_almost_full),

    //from csr
    .csr_control_i (csr_control_data),
    .csr_status_i (csr_status_data),
    .csr_first_pointer_i (csr_next_pointer_data),

    //to update csr status
    .csr_status_update_data_o (csr_status_update_data),
    .csr_status_update_req_o (csr_status_update_req),
    .csr_status_update_ack_i (csr_status_update_ack),

    //to AVMM master (update descriptor)
    .dma_desc_update_wr_o (dma_desc_update_wr_o),
    .dma_desc_update_data_o (dma_desc_update_data_o),
    .dma_desc_update_be_o (dma_desc_update_be_o),
    .dma_desc_update_addr_o (dma_desc_update_addr_o),
    .dma_desc_update_wait_req_i (dma_desc_update_wait_req_i),

    //interupt output
    .dma_interupt_rq_o (dma_interupt_rq_o)
);

//dma_read_block instance
dma_read_block dma_read_block_instance
(
    .clk (clk),
    .reset (reset),

    //to AVMM master port
    .rd_master_addr_o (rd_master_addr_o),
    .rd_master_bcount_o (rd_master_bcount_o),

    //from AVMM master port
    .rd_master_wait_req_i (rd_master_wait_req_i),
    .rd_master_data_valid_i (rd_master_data_valid_i),
    .rd_master_data_i (rd_master_data_i),

    //from desc processor
    .dma_rd_fifo_command_req_i (dma_rd_fifo_command_req),
    .dma_rd_bytes_to_transfer_i (dma_rd_bytes_to_transfer),
    .dma_rd_addr_i (dma_rd_addr),

    //to desc processor
    .dma_rd_fifo_full_o (dma_rd_fifo_full),

    //to dma data fifo
    .dma_rd_data_o (dma_rd_data),
    .dma_rd_data_valid_o (dma_rd_data_valid)
);

//dma_write_block instance
dma_write_block dma_write_block_instance
(
    .clk (clk),
    .reset (reset),

    //to AVMM master port
    .wr_master_addr_o (wr_master_addr_o),
    .wr_master_bcount_o (wr_master_bcount_o),
    .wr_master_data_o (wr_master_data_o),

    //from AVMM master port
    .wr_master_wait_req_i (wr_master_wait_req_i),

    //from desc processsor
    .dma_wr_fifo_command_req_i (dma_wr_fifo_command_req),
    .dma_wr_bytes_to_transfer_i (dma_wr_bytes_to_transfer),
    .dma_wr_addr_i (dma_wr_addr),
    .dma_desc_id_i (dma_desc_id),
    .dma_owned_by_hw_i (dma_owned_by_hw),

    //to desc processor
    .dma_wr_fifo_full_o (dma_wr_fifo_full),

    //to status update block
    .dma_status_fifo_wr_req_o (dma_status_fifo_wr_req),
    .dma_status_fifo_data_o (dma_status_fifo_data),

    //from status update block
    .dma_status_fifo_almost_full_i (dma_status_fifo_almost_full),

    //from dma data fifo
    .dma_data_i (dma_data),
    .dma_data_fifo_empty_i (dma_data_fifo_empty),

    //to dma data fifo
    .dma_data_fifo_rd_req_o (dma_data_fifo_rd_req)
);

dma_data_fifo dma_data_fifo_instance
(
    .clk (clk),
    .reset (reset),

    //read block interface
    .dma_rd_data_i (dma_rd_data),
    .dma_rd_data_valid_i (dma_rd_data_valid),

    //write block interface
    .dma_data_o (dma_data),
    .dma_data_fifo_empty_o (dma_data_fifo_empty),
    .dma_data_fifo_rd_req_i (dma_data_fifo_rd_req)
);

endmodule