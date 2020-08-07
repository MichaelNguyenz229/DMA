module dma_data_fifo
(
    input clk,
    input reset,

    //read block interface
    input [255:0] dma_rd_data_i,
    input dma_rd_data_valid_i,

    //write block interface
    output [255:0] dma_data_o,
    output dma_data_fifo_empty_o,
    input dma_data_fifo_rd_req_i
);

//internal signals

//data fifo instance
scfifo	data_fifo (
				.clock (clk),
				.data (dma_rd_data_i),
				.rdreq (dma_data_fifo_rd_req_i),
				.sclr (reset),
				.wrreq (dma_rd_data_valid_i),
				.almost_full (),
				.q (dma_data_o),
				.aclr (1'b0),
				.almost_empty (),
				.eccstatus (),
				.empty (dma_data_fifo_empty_o),
				.full (),
				.usedw ());
	defparam
		data_fifo.add_ram_output_register = "OFF",
		data_fifo.almost_full_value = 24,
		data_fifo.intended_device_family = "Cyclone V",
		data_fifo.lpm_numwords = 256,
		data_fifo.lpm_showahead = "OFF",
		data_fifo.lpm_type = "scfifo",
		data_fifo.lpm_width = 256,
		data_fifo.lpm_widthu = 8,
		data_fifo.overflow_checking = "ON",
		data_fifo.underflow_checking = "ON",
		data_fifo.use_eab = "ON";

endmodule