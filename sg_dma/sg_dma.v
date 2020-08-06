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
    output reg [31:0] dma_desc_update_addr_o,
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
    input wr_master_wait_req_i,
);

//dma_csr instance

//dma_desc_fetch instance

//dma_desc_proc instance

//dma_status_update instance

//dma_read_block instance

//dma_write_block instance