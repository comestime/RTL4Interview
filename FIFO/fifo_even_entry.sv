// Solution 1: the read/write pointer uses one extra bit to decide whether full or empty
module fifo_even_entry
	# ( parameter AWIDTH = 4,
		parameter DWIDTH = 4 )
(
	input					clk,
	input					rst_n,

	input					wen,
	input [DWIDTH-1:0]		din,
	output logic			full,

	input					ren,
	output [DWIDTH-1:0]		dout,
	output logic			empty

);

	localparam NUM_ENTRY = (1 << AWIDTH);

	logic [AWIDTH:0]		rd_ptr, wr_ptr, rd_ptr_next, wr_ptr_next;
	logic [NUM_ENTRY-1:0][DWIDTH-1:0] mem;

	// rd_ptr logic
	assign rd_ptr_next = rd_ptr + (ren & ~empty);
	
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else
			rd_ptr <= rd_ptr_next;

	// wr_ptr logic
	assign wr_ptr_next = wr_ptr + (wen & ~full);
	
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else
			wr_ptr <= wr_ptr_next;

	// full logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			full <= '0;
		else
			full <= (wr_ptr_next[AWIDTH] != rd_ptr_next[AWIDTH]) & 
					(wr_ptr_next[AWIDTH-1:0] == rd_ptr_next[AWIDTH-1:0]);

	// empty logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			empty <= '1;
		else
			empty <= (wr_ptr_next == rd_ptr_next);

	// memory logic
	always_ff @(posedge clk)
		if (wen & ~full)
			mem[wr_ptr[AWIDTH-1:0]] <= din;

	assign dout = mem[rd_ptr[AWIDTH-1:0]];


endmodule




// Solution 2: use FIFO count to decide full or empty condition
//			   this solution can be used when user wants to specify the full/empty threshold
module fifo_even_entry
	# ( parameter AWIDTH = 4,
		parameter DWIDTH = 4 )
(
	input						clk,
	input						rst_n,

	input						wen,
	input [DWIDTH-1:0]			din,
	output logic				full,

	input						ren,
	output [DWIDTH-1:0]			dout,
	output logic				empty,
	
	output logic [AWIDTH:0]		fifo_count

);

	localparam NUM_ENTRY = (1 << AWIDTH);

	logic [AWIDTH-1:0]		rd_ptr, wr_ptr;
	logic [AWIDTH:0]		fifo_count_next;
	logic [NUM_ENTRY-1:0][DWIDTH-1:0] mem;

	// rd_ptr logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else if (ren & ~empty)
			rd_ptr <= rd_ptr + 1'b1;

	// wr_ptr logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (wen & ~full)
			wr_ptr <= wr_ptr + 1'b1;

	// fifo_count logic
	assign fifo_count_next = fifo_count + (~full & wen) - (~empty & ren);

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			fifo_count <= '0;
		else
			fifo_count <= fifo_count_next;

	// full logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			full <= '0;
		else
			full <= (fifo_count_next == NUM_ENTRY);
			
	// empty logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			empty <= '1;
		else
			empty <= (fifo_coun_next == 0);

	// memory logic
	always_ff @(posedge clk)
		if (~full & wen)
			mem[wr_ptr] <= din;

	assign dout = mem[rd_ptr];


endmodule
