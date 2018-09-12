module fifo_async_even_entry
	# (	parameter AWIDTH = 4,
		parameter DWIDHT = 4 )
(
	// rd_clk domain
	input						rd_clk,
	input						rd_rst_n,

	output logic [DWIDTH-1:0]	dout,
	input						ren,
	output logic				empty,

	// wr_clk domain
	input						wr_clk,
	input						wr_rst_n,

	input [DWIDTH-1:0]			din,
	input						wen,
	output logic				full			

);
	
	// rd_clk domain
	logic [AWIDTH:0]			rd_ptr_gray, rd_ptr_bin, rd_ptr_gray_next, rd_ptr_bin_next;
	logic [AWIDTH:0]			wr_ptr_sync0, wr_ptr_sync1;
	// wr_clk domain
	logic [AWIDTH:0]			wr_ptr_gray, wr_ptr_bin, wr_ptr_gray_next, wr_ptr_bin_next;
	logic [AWIDTH:0]			rd_ptr_sync0, rd_ptr_sync1;

	localparam NUM_EMTRY = (1 << AWIDTH);
	logic [NUM_ENTRY-1:0][DWIDTH-1:0] mem;

	// sync wr_ptr to rd_clk domain
	// use double synchronizer scheme
	always_ff @(posedge rd_clk or negedge rd_rst_n)
		if (~rd_rst_n)
			{wr_ptr_sync0, wr_ptr_sync1} <= '0;
		else
			{wr_ptr_sync0, wr_ptr_sync1} <= {wr_ptr_gray, wr_ptr_sync0};

	// empty logic
	always_ff @(posedge rd_clk or negedge rd_rst_n)
		if (~rd_rst_n)
			empty <= '1;
		else
			empty <= (rd_ptr_gray_next == wr_ptr_sync1);

	// rd_ptr logic
	assign rd_ptr_bin_next = rd_ptr_bin + (~empty & ren);
	assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

	always_ff @(posedge clk or negedge rd_rst_n)
		if (~rd_rst_n)
			{rd_ptr_gray, rd_ptr_bin} <= '0;
		else
			{rd_ptr_gray, rd_ptr_bin} <= {rd_ptr_gray_next, rd_ptr_bin_next};

	// sync rd_ptr to wr_clk domain
	// use double synchronizer scheme
	always_ff @(posedge clk or negedge wr_rst_n)
		if (~wr_rst_n)
			{rd_ptr_sync0, rd_ptr_sync1} <= '0;
		else
			{rd_ptr_sync0, rd_ptr_sync1} <= {rd_ptr_gray, rd_ptr_sync0};

	// full logic
	always_ff @(posedge clk or negedge wr_rst_n)
		if (~wr_rst_n)
			full <= '0;
		else
			full <= (wr_ptr_gray_next[AWIDTH:0] == {~rd_ptr_gray_sync1[AWIDTH:AWIDTH-1],
													 rd_ptr_gray_sync1[AWIDTH-2:0]});

	// wr_ptr logic
	assign wr_ptr_bin_next = wr_ptr_bin + (~full & wen);
	assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

	always_ff @(posedge clk or negedge wr_rst_n)
		if (~wr_rst_n)
			{wr_ptr_gray, wr_ptr_bin} <= '0;
		else
			{wr_ptr_gray, wr_ptr_bin} <= {wr_ptr_gray_next, wr_ptr_bin_next};

	// memory logic
	always_ff @(posedge wr_clk)
		if (~full & wen)
			mem[wr_ptr_bin[AWIDTH-1:0]] <= din;

	assign dout = mem[rd_ptr_bin[AWIDTH-1:0]];


endmodule
