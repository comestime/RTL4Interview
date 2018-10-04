/*
	Design a pseudo LRU block for an 8-way set associative cache. This is similar to a binary tree:

					h0
				/		\
			   h1		h2		
			/	 \	   /   \
		  h3	 h4	  h5   h6
		/  \	/ \  /  \  / \
	   0   1   2  3 4   5 6   7

*/

module Pseudo_LRU (
	input					clk,
	input					rst_n,
	
	input					acc_en,		// access indication
	input [2:0]				acc_idx,	// index to accessed entry

	output logic [2:0]		lru_idx		// index to LRU entry
);

	// tree node
	logic h0, h1, h2, h3, h4, h5, h6;

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h0 <= '0;
		else if (acc_en)
			h0 <= ~h0;					// always flip h0 if there's an access

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h1 <= '0;
		else if (acc_en & ~acc_idx[2])
			h1 <= ~h1;					// flip h1 if acc_idx == 0/1/2/3

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h2 <= '0;
		else if (acc_en & acc_idx[2])
			h2 <= ~h2;					// flip h2 if acc_idx == 4/5/6/7

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h3 <= '0;
		else if (acc_en & (acc_idx[2:1] == 2'b00))
			h3 <= ~h3;					// flip h3 if acc_idx == 0/1

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h4 <= '0;
		else if (acc_en & (acc_idx[2:1] == 2'b01))
			h4 <= ~h4;					// flip h4 if acc_idx == 2/3

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h5 <= '0;
		else if (acc_en & (acc_idx[2:1] == 2'b10))
			h5 <= ~h5;					// flip h5 if acc_idx == 4/5

	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			h6 <= '0;
		else if (acc_en & (acc_idx[2:1] == 2'b11))
			h6 <= ~h6;					// flip h6 if acc_idx == 6/7

	// lru_idx assignment
	assign lru_idx[2] = h0;
	assign lru_idx[1] = ~h0 & h1 | h0 & h2;
	assign lru_idx[0] = (~h0 & ~h1 & ~h3) | (~h0 & h1 & ~h4) | (h0 & ~h2 & ~h5) | (~h0 & h2 & ~h6);


endmodule
