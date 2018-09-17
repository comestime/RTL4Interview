/*
	The pipeline stage takes 4 chunks of data from the upstream logic
	and then assert vld to its downstream logic
	
	Using valid/ready procotol to transfer data

	Solution 1 is called "full register slice", that cuts the timing path b/w slave and mater
	Solution 2 is called "pass through", that does not add any latency b/w slave and master
	Solution 3 is called "forward register slice", that cust the timing path of valid but not ready

	Reference:
		https://www.southampton.ac.uk/~bim/notes/cad/reference/ZyboWorkshop/2015_2_zybo_labsolution/lab2/lab2.srcs/sources_1/ipshared/xilinx.com/axi_register_slice_v2_1/03a8e0ba/hdl/verilog/axi_register_slice_v2_1_axic_register_slice.v

*/

// Solution 1: using a 2-entry FIFO to break the timing path
module Rdy_Vld_Datapack_1 
	# ( parameter DWIDTH = 8)
(
	input						clk,
	input						rst_n,

	input [DWIDTH-1:0]			din,
	input 						vld_in,
	output						rdy_out,

	output logic [DWIDTH*4-1:0]	dout,
	output logic				vld_out,
	input						rdy_in,
);

	logic [1:0][3:0][DWIDTH-1:0]	mem;
	logic [1:0]						rd_ptr;
	logic [3:0]						wr_ptr;
	logic							empty, full;
	
	// FIFO full/empty logic
	assign empty = (rd_ptr == wr_ptr[3:2]);
	assign full = (rd_ptr[1] != wr_ptr[3]) & (rd_ptr[0] == wr_ptr[2]);

	// FIFO pointer logic
	always_ff@(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else if (vld_out & rdy_in)
			rd_ptr <= rd_ptr + 1'b1;

	always_ff@(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (vld_in & rdy_out)
			wr_ptr <= wr_ptr + 1'b1;

	// FIFO write logic
	always_ff@(posedge clk)
		if (vld_in & rdy_out)
			mem[wr_ptr[2]][wr_ptr[1:0]] <= din;

	// output assignment
	assign dout = {	mem[rd_ptr[0][3],
					mem[rd_ptr[0][2],
					mem[rd_ptr[0][1],
					mem[rd_ptr[0][0]};
	assign rdy_out = ~full;
	assign vld_out = ~empty;


endmodule


// Solution 2: using 3 intermediate data buffers
module Rdy_Vld_Datapack_2
	# ( parameter DWIDTH = 8)
(
	input						clk,
	input						rst_n,

	input [DWIDTH-1:0]			din,
	input 						vld_in,
	output						rdy_out,

	output logic [DWIDTH*4-1:0]	dout,
	output logic				vld_out,
	input						rdy_in,
);

	logic [2:0][DWIDTH-1:0]		buffer;
	logic [1:0]					wr_ptr;


	// output assignments
	assign dout = { buffer[2],
					buffer[1],
					buffer[0],
					din		 };
	assign vld_out = (wr_ptr == 2'b11) & vld_in;
	assign rdy_out = (wr_ptr != 2'b11) | rdy_in;

	// wr_ptr logic
	always_ff@(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (vld_in & rdy_out)
			wr_ptr <= wr_ptr + 1'b1;

	// data buffer logic
	genvar i;
	generate 
		for (i = 0; i < 3; i = i + 1) begin
			always_ff@(posedge clk)
				if ((wr_ptr == i) & vld_in & rdy_out)
					buffer[i] <= din;
		end
	endgenerate

endmodule


// Solution 3: using 4 intermediate data buffers and a valid bit
module Rdy_Vld_Datapack_3
	# ( parameter DWIDTH = 8)
(
	input						clk,
	input						rst_n,

	input [DWIDTH-1:0]			din,
	input 						vld_in,
	output						rdy_out,

	output logic [DWIDTH*4-1:0]	dout,
	output logic				vld_out,
	input						rdy_in,
);

	logic [3:0][DWIDTH-1:0]		buffer;
	logic [1:0]					wr_ptr;

	// output assignments
	assign dout = {	buffer[3],
					buffer[2],
					buffer[1],
					buffer[0]};
	assign rdy_out = ~vld_out | rdy_in;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			vld_out <= '0;
		else if ((wr_ptr == 2'b11) & vld_in & rdy_out)
			vld_out <= '1;
		else if (vld_out & rdy_in)
			vld_out <= '0;

	// wr_ptr logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (vld_in & rdy_out)
			wr_ptr <= wr_ptr + 1'b1;

	// data buffer logic
	always_ff @(posedge clk)
		if (vld_in & rdy_out)
			buffer[wr_ptr] <= din;

endmodule
