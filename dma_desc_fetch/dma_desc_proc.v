module dma_desc_proc
(
    input clk,
    input reset,

    //from descriptor fetch
    input dma_desc_fifo_wr_i,
    input [255:0] dma_desc_fifo_wrdata_i,

    //to read block
    output dma_rd_fifo_command_rq,
    output dma_rd_bytes_to_transfer_o,
    output [31:0]dma_rd_addr_o,

    //from read block
    input dma_rd_fifo_full_i,
    input dma_rd_done_status_i,

    //to write block
    output dma_wr_fifo_command_rq_o,
    output dma_wr_bytes_to_transfer_o,
    output [31:0]dma_wr_addr_o,

    //from write block
    input dma_wr_fifo_full_i,
    input dma_wr_done_status_i,

    //to csr
    output [31:0] csr_status_update_o,
    output [3:0] csr_status_update_be_o,
    output csr_status_update_rq_o,
    input csr_status_update_ack_i,

    //from csr
    input [31:0] csr_control_i,

    //to AVMM master update descriptor
    output dma_desc_update_wr_o,
    output [31:0] dma_desc_update_data_o,
    output [3:0] dma_desc_update_be_o,
    input dma_desc_update_wait_rq,

    //interupt output
    output dma_interupt_rq_o,
)

//Internal signals


//Fifo instance 
scfifo	scfifo_component (
				.clock (clk),
				.data (dma_desc_fifo_wrdata_i),
				.rdreq (rdreq),
				.sclr (reset),
				.wrreq (dma_desc_fifo_wr_i),
				.almost_full (dma_desc_fifo_almost_full),
				.q dma_desc_fifo_out),
				.aclr (),
				.almost_empty (),
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
		scfifo_component.lpm_width = 256,
		scfifo_component.lpm_widthu = 5,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";
