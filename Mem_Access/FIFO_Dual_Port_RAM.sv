/*

	Build a FIFO from a dual port RAM

	------------------------------------------------------------------
	| fifo_count	|	REN	|	WEN	|	fifo_count_next	|	dout <=	 |
	------------------------------------------------------------------
	|				|	0	|	0	|		0			|			 |
	|	0			|	0	|	1	|		1			|		din	 |
	|				|	1	|	0	|		illegal		|			 |
	|				|	1	|	1	|		illegal		|			 |
	------------------------------------------------------------------
	|				|	0	|	0	|		1			|			 |
	|	1			|	0	|	1	|		2			|			 |
	|				|	1	|	0	|		0			|			 |
	|				|	1	|	1	|		1			|		din	 |
	------------------------------------------------------------------
	|				|	0	|	0	|		2			|			 |
	|	2			|	0	|	1	|		3			|			 |
	|				|	1	|	0	|		1			|		din_q|
	|				|	1	|	1	|		2			|		din_q|
	------------------------------------------------------------------
	|				|	0	|	0	|		fifo_count	|			 |
	|	> 2			|	0	|	1	|		fifo_count+1|			 |
	|				|	1	|	0	|		fifo_count-1|		ram_o|
	|				|	1	|	1	|		fifo_count	|		ram_o|
	------------------------------------------------------------------

*/

module FIFO_2Port_RAM
	#( parameter DWIDTH = 32,
	   parameter AWIDTH = 4 )
(
	input							clk,
	input							rst_n,
	
	input [DWIDTH-1:0]				din,
	input							wen,
	output logic					full,

	input							ren,
	output logic [DWIDTH-1:0]		dout,
	output logic					empty
);
	
	localparam full_threshold = 1 << AWIDTH;

	logic [DWIDTH-1:0]				din_q;		// input buffer
	logic [AWIDTH-1:0]				rd_ptr;		// used to index RAM
	logic [AWIDTH-1:0]				wr_ptr;		// used to index RAM
	logic [DWIDTH-1:0]				ram_o;		// data read from RAM
	logic [AWIDTH:0]				fifo_count, fifo_count_next;

	// fifo_count logic
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

	// rd_ptr logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= 1;		// initial rd_ptr value is one entry ahead
		else if (ren & ~empty)
			rd_ptr <= rd_ptr + 1;

	// wr_ptr logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (wen & ~full)
			wr_ptr <= wr_ptr + 1;

	// din_q logic
	always_ff @(posedge clk)
		if (wen & ~full)
			din_q <= din;

	// dout logic
	always_ff @(posedge clk)
		unique if ((fifo_count == 0) & wen)
			dout <= din;
		else if ((fifo_count == 1) & ren)
			dout <= din;
		else if ((fifo_count == 2) & ren)
			dout <= din_q;
		else if ((fifo_count > 2) & ren)
			dout <= ram_o;

	// RAM block instantiation
	ram u_ram (
		.clk			(clk),
		.ren			('1),
		.raddr			(rd_ptr),
		.dout			(ram_o),
		.wen			(wen),
		.waddr			(wr_ptr),
		.din			(din),	
	);

endmodule
