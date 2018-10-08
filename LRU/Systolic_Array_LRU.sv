/*
	Design an LRU block using Systolic Array
	Implementation details see the the reference in this directory

*/

module Systolic_Array_LRU
	# (	parameter	NO_ENTRY = 8,					// must be power of 2
		parameter	IDX_WIDTH = $clog2(NO_ENTRY))
(
	input							clk,
	input							rst_n,
		
	input							acc_en,
	input [IDX_WIDTH-1:0]			acc_idx,

	output logic [IDX_WIDTH-1:0]	lru_idx	
);

	logic [NO_ENTRY/2-1:0][IDX_WIDTH-1:0]		idx_i, idx_o;
	logic [NO_ENTRY/2-1:0]						hit_i;
	logic [IDX_WIDTH-1:0]						mru_idx;

	// output assignment
	assign lru_idx = idx_o[0];

	// MRU idx logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			mru_idx <= '1;
		else if (acc_en)
			mru_idx <= acc_idx;

	// idx_i and hit_i for the first stage
	assign hit_i[0] = '0;
	assign idx_i[0] = acc_en ? acc_idx : mru_idx;
	
	// Systolic Array Nodes
	genvar i;
	generate
		for (i = 0; i < NO_ENTRY/2; i = i + 1) begin
			Systolic_Array_Node u_node
				# (.NO_ENTRY		(NO_ENTRY),
				   .INIT_IDX0		(i * 2))
			(
				.clk				(clk),
				.rst_n				(rst_n),
				.idx_prev_i			(idx_i[i]),
				.hit_prev_i			(hit_i[i]),
				.idx_next_i			(idx_o[i+1]),
				.idx_next_o			(idx_i[i+1]),
				.hit_next_o			(hit_i[i+1]),
				.idx_prev_o			(idx_o[i]),
				.idx0_cur			(),
				.idx1_cur			()
			);
		end
	endgenerate

endmodule


module Systolic_Array_Node
	# (	parameter NO_ENTRY = 8,
		parameter IDX_WIDTH = $clog2(NO_ENTRY),
		parameter INIT_IDX0 = 0,					// initial value of index 0
		parameter INIT_IDX1 = INIT_IDX0 + 1)		// initial value of index 1
(
	input							clk,
	input							rst_n,
	
	input [IDX_WIDTH-1:0]			idx_prev_i,		// incoming index from previous stage to compare with current stage; corresponding to "L" in Figure 3
	input							hit_prev_i,		// hit from previous stages to current stage; corresponding to "M" in Figure 3
	input [IDX_WIDTH-1:0]			idx_next_i,		// index 0 from next stage to update index 1 in current stage if hit in current stage

	output logic [IDX_WIDTH-1:0]	idx_next_o,		// outgoing index from current stage for next stage to compare
	output logic					hit_next_o,		// hit from current stage to next stage
	output logic [IDX_WIDTH-1:0]	idx_prev_o,		// index 0 from current stage for previous stage to update its index 1; corresponding to "index" in Figure 3

	output logic [IDX_WIDTH-1:0]	idx0_cur,		// index 0 from current stage; this is different than idx0_prev_o
	output logic [IDX_WIDTH-1:0]	idx1_cur		// index 1 from current stage; index 1 from the last stage would be most-recently used entry
);

	logic [IDX_WIDTH-1:0]	idx_prev_q;
	logic 					hit_prev_q;
	logic [IDX_WIDTH-1:0]	idx0_cur_next;
	logic [IDX_WIDTH-1:0]	idx1_cur_next;
	logic					hit_idx0, hit_idx1;

	// register input
	always_ff (posedge clk or negedge rst_n)
		if (~rst_n) begin
			idx_prev_q <= '1;						// during reset, 0 is LRU and 8 is MRU; using MRU to do initialization
			hit_prev_q <= '0;
		end else begin
			idx_prev_q <= idx_prev_i;
			hit_prev_q <= hit_prev_i;
		end

	// check hit condition in current stage
	assign hit_idx0 = hit_prev_q | (idx_prev_q == idx0_cur);
	assign hit_idx1 = hit_idx0   | (idx_prev_q == idx1_cur);

	// idx0/1_cur_next logic
	assign idx0_cur_next = hit_idx0 ? idx1_cur	 : idx0_cur;
	assign idx1_cur_next = hit_idx1 ? idx_next_i : idx1_cur;

	// idx0/1_cur logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			idx0_cur <= INIT_IDX0;
			idx1_cur <= INIT_IDX1;
		end else begin
			idx0_cur <= idx0_cur_next;
			idx1_cur <= idx1_cur_next;
		end

	// output assignment
	assign idx_next_o = idx_prev_q;
	assign hit_next_o = hit_idx1;
	assign idx_prev_o = idx0_cur_next;

endmodule
