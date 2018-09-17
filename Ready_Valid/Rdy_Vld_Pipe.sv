/*
	Pipe stage: takes rdy_in and produces vld_out
	
	Solution 1 is called "forward register slice", that cuts the timing path of valid but not ready
	Solution 2 is called "reverse register slice", that cuts the timing path of ready but not valid
	Solution 3 is called "pass through", which has not register between ready and valid (not shown here)
	Solution 4 is called "full register slice", that cuts the timing path of both valid and ready (essentially a FIFO, not shown here)

	Reference:
		https://www.southampton.ac.uk/~bim/notes/cad/reference/ZyboWorkshop/2015_2_zybo_labsolution/lab2/lab2.srcs/sources_1/ipshared/xilinx.com/axi_register_slice_v2_1/03a8e0ba/hdl/verilog/axi_register_slice_v2_1_axic_register_slice.v
*/

// Solution 1
module Rdy_Vld_Pipe
#( parameter DWIDTH = 32)
(
	input						clk,
	input						rst_n,

	input						vld_in,
	input [DWIDTH-1:0]			din,
	output logic				rdy_out,

	output logic				vld_out,
	output logic [DWIDTH-1:0]	dout,
	input						rdy_in
);

	assign rdy_out = ~vld_out | rdy_in;
	
	always_ff @(posedge clk)
		if (vld_in & rdy_out)
			dout <= din;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			vld_out <= '0;
		else if (vld_in & rdy_out)
			// always set vld_out when new transaction coming in
			vld_out <= '1;
		else if (vld_out & rdy_in)
			// clear vld_out when no new transaction coming in and downstream logic sinks the data
			vld_out <= '0;

endmodule


// Solution 2
module Rdy_Vld_Pipe
#( parameter DWIDTH = 32)
(
	input						clk,
	input						rst_n,

	input						vld_in,
	input [DWIDTH-1:0]			din,
	output logic				rdy_out,

	output logic				vld_out,
	output logic [DWIDTH-1:0]	dout,
	input						rdy_in
);

	logic has_vld_storage, has_vld_storage_next;
	logic [DWIDTH-1:0] data_buf;

	// data buffer
	always_ff @(posedge clk)
		if (vld_in & rdy_out)
			data_buf <= din;

	// data output assignment
	assign dout = has_vld_storage ? data_buf : din;

	// vld_out assignment
	assign vld_out = vld_in | has_vld_storage;

	// rdy_out assignment
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rdy_out <= '0;
		else
			rdy_out <= rdy_in | ~has_vld_storage;

	// has_vld_storage logic
	always_comb begin
		if (vld_in & rdy_out & ~rdy_in)
			has_vld_storage_next = '1;
		else if (has_vld_storage & rdy_in & (~vld_in | ~rdy_out)
			has_vld_storage_next = '0;
		else
			has_vld_storage_next = has_vld_storage;
	end

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			has_vld_storage <= '0;
		else
			has_vld_storage <= has_vld_storage_next;

endmodule
