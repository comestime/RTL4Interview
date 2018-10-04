/*
	Build a FIFO from a 1-port RAM. Since read and write can happen in the same cycle, thus we need 2 banks of 1-port RAM to sustain the bandwidth
	Bank 0 takes care of access for even address, while Bank 1 takes care of access for odd address
	The problem is, if both read and write happen to the same bank, then a conflict happens. To resolve this issue, we always make read having higher priority than write, and store the write to a delay_buffer; in the next clock cycle, the delayed write can be posted to the RAM.

	Reference: https://patents.google.com/patent/US7181563B2/en

	Solution 1: build a FIFO using 2 1-port RAMs; however, in this solution, there's 1-cycle read data latency. The not empty indication from the FIFO should match the read data latency

*/


// Solution 1
module FIFO_1Port_RAM #(
	parameter	DWIDTH = 32,
	parameter	AWIDTH = 4 )
(
	input						clk,
	input						rst_n,

	input [DWIDTH-1:0]			din,
	input						wen,
	output logic				full,

	output logic [DWIDTH-1:0]	dout,
	input						ren,
	output logic				emtpy
	
);

	localparam full_threshold = 1 << AWIDTH;

	logic [AWIDTH:0]			fifo_count, fifo_count_next;
	logic [AWIDTH-1:0]			wr_ptr, rd_ptr;

	logic 						dly_wr_vld;
	logic [AWIDTH-1:0]			dly_wr_addr;
	logic [DWIDTH-1:0]			dly_wr_data;

	logic						ram_ren0, ram_wen0, ram_dly_wr0;
	logic						ram_ren1, ram_wen1, ram_dly_wr1;
	logic						ram_oe0, ram_oe1;
	logic						ram_we0, ram_we1;
	logic [AWIDTH-2:0]			ram_addr0, ram_addr1;
	logic [DWIDTH-1:0]			ram_din0, ram_din1;
	logic [DWIDTH-1:0]			ram_dout0, ram_dout1;
	logic						ram_rd_idx;

	// delayed write logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			dly_wr_vld <= '0;
		else if (ren & ~empty & wen & ~full & (wr_ptr[0] == rd_ptr[0]))
			dly_wr_vld <= '1;
		else
			dly_wr_vld <= '0;

	always_ff @(posedge clk)
		if (ren & ~empty & wen & ~full & (wr_ptr[0] == rd_ptr[0]))
			dly_wr_data <= din;
			dly_wr_addr <= wr_ptr;

	// RAM control logic
	assign ram_ren0 = (ren & ~empty & ~rd_ptr[0]);
	assign ram_ren1 = (ren & ~empty & rd_ptr[0]);
	assign ram_wen0 = (wen & ~full & ~wr_ptr[0]);
	assign ram_wen1 = (wen & ~full & wr_ptr[0]);
	assign ram_dly_wr0 = (dly_wr_vld & ~dly_wr_addr[0]);
	assign ram_dly_wr1 = (dly_wr_vld & dly_wr_addr[0]);

	assign ram_oe0 = ram_dly_wr0 | ram_wen0 | ram_ren0;
	assign ram_oe1 = ram_dly_wr1 | ram_wen1 | ram_ren1;

	assign ram_we0 = !ram_ren0;
	assign ram_we1 = !ram_ren1;

	assign ram_addr0 = ram_ren0			?	rd_ptr[AWIDTH-1:1]		:
					   ram_wen0			?	wr_ptr[AWIDTH-1:1]		:
											dly_wr_addr[AWIDTH-1:1]	;
	assign ram_addr1 = ram_ren1			?	rd_ptr[AWIDTH-1:1]		:
					   ram_wen1			?	wr_ptr[AWIDTH-1:1]		:
											dly_wr_addr[AWIDTH-1:1]	;

	assign ram_din0 = ram_wen0 ? din : dly_wr_data;
	assign ram_din1 = ram_wen1 ? din : dly_wr_data;

	// dout assignment
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			ram_rd_idx <= '0;
		else if (ram_ren0)
			ram_rd_idx <= '0;
		else if (ram_ren1)
			ram_rd_idx <= '1;

	assign dout = ram_rd_idx ? ram_dout1 : ram_dout0;

	// FIFO pointer logic
	assign fifo_count_next = fifo_count + (wen & ~full) - (ren & ~empty);

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			fifo_count <= '0;
		else
			fifo_count <= fifo_count_next;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			empty <= '1;
		else
			empty <= (fifo_count_next == '0);

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			full <= '0;
		else
			full <= (fifo_count_next == full_threshold);
	
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (wen & ~full)
			wr_ptr <= wr_ptr + 1'b1;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else if (ren & ~empty)
			rd_ptr <= rd_ptr + 1'b1;

	// 1-port RAM instantiation
	ram_1p	u_ram0 (
		.clk		(clk),
		.din		(ram_din0),
		.dout		(ram_dout0),
		.oe			(ram_oe0),
		.we			(ram_we0),
		.addr		(ram_addr0)
	);
	
	ram_1p	u_ram1 (
		.clk		(clk),
		.din		(ram_din1),
		.dout		(ram_dout1),
		.oe			(ram_oe1),
		.we			(ram_we1),
		.addr		(ram_addr1)
	);
	
endmodule
