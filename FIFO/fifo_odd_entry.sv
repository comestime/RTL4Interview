// Solution 1: rd_ptr and wr_ptr use one extra bit to decide full/empty condition
//			   assuming num_entry = 13
module fifo_odd_entry
	# (	parameter DWIDTH = 4)
(
	input						clk,
	input						rst_n,

	input						ren,
	output logic				emtpy,
	output logic [DWIDTH-1:0]	dout,

	input						wen,
	output logic				full,
	input [DWIDTH-1:0]			din
);

	logic [4:0]	rd_ptr, wr_ptr;
	logic [4:0]	rd_ptr_next, wr_ptr_next;
	logic [4:0]	rd_ptr_temp, wr_ptr_temp;

	logic [12:0][DWIDTH-1:0]	mem;

	// rd_ptr logic
	assign rd_ptr_temp = rd_ptr + (ren & ~empty);
	// since num_emtry is non power of 2, so needs some special handling for pointer roll over
	assign rd_ptr_next = (rd_ptr_temp == {1'b0, 4'd13}) ? {1'b1, 4'd0}  :
						 (rd_ptr_temp == {1'b1, 4'd13}) ? {1'b0, 4'd0}	:
						  rd_ptr_temp									;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else
			rd_ptr <= rd_ptr_next;

	// wr_ptr logic
	assign wr_ptr_temp = wr_ptr + (wen & ~full);
	// since num_emtry is non power of 2, so needs some special handling for pointer roll over
	assign wr_ptr_next = (wr_ptr_temp == {1'b0, 4'd13}) ? {1'b1, 4'd0}  :
						 (wr_ptr_temp == {1'b1, 4'd13}) ? {1'b0, 4'd0}	:
						  wr_ptr_temp									;

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
			full <= (rd_ptr_next[4] != wr_ptr_next[4]) &
					(rd_ptr_next[3:0] == wr_ptr_next[3:0]);

	// empty logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			empty <= '1;
		else
			empty <= (rd_ptr_next == wr_ptr_next);

	// memory logic
	always_ff @(posedge clk)
		if (~full & wen)
			mem[wr_ptr[3:0]] <= din;

	assign dout = mem[rd_ptr[3:0]];

endmodule



// Solution 2: use fifo_count to decide full/empty condition
//			   assuming num_entry = 13
module fifo_odd_entry
	# (	parameter DWIDTH = 4)
(
	input						clk,
	input						rst_n,

	input						ren,
	output logic				emtpy,
	output logic [DWIDTH-1:0]	dout,

	input						wen,
	output logic				full,
	input [DWIDTH-1:0]			din,

	output logic [3:0]			fifo_count
);

	logic [3:0]	rd_ptr, wr_ptr;
	logic [3:0]	rd_ptr_next, wr_ptr_next;
	logic [3:0]	rd_ptr_temp, wr_ptr_temp;

	logic [3:0]	fifo_count_next;

	logic [12:0][DWIDTH-1:0]	mem;

	// rd_ptr logic
	assign rd_ptr_temp = rd_ptr + (ren & ~empty);
	// since num_emtry is non power of 2, so needs some special handling for pointer roll over
	assign rd_ptr_next = (rd_ptr_temp == 4'd13) ? '0  :
						  rd_ptr_temp				  ;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else
			rd_ptr <= rd_ptr_next;

	// wr_ptr logic
	assign wr_ptr_temp = wr_ptr + (wen & ~full);
	// since num_emtry is non power of 2, so needs some special handling for pointer roll over
	assign wr_ptr_next = (wr_ptr_temp == 4'd13) ? '0  :
						  wr_ptr_temp				  ;

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
			full <= (fifo_count_next[3:0] == 4'd13);

	// fifo_count logic
	assign fifo_count_next = fifo_count + (wen & ~full) - (ren & ~empty);
	
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			fifo_count <= '0;
		else
			fifo_count <= fifo_count_next;

	// empty logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			empty <= '1;
		else
			empty <= (fifo_count_next == '0);

	// memory logic
	always_ff @(posedge clk)
		if (~full & wen)
			mem[wr_ptr] <= din;

	assign dout = mem[rd_ptr];

endmodule
