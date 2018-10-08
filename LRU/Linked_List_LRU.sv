/*

	Design an LRU block using linked list mechanism. Head node is the MRU entry, while tail node is the LRU entry.
	Each entry of the linked list consist of 2 counters, which is the previous node index and next node index;
	Each entry also keeps 2 bits indicating whether this node is the head or the tail.
	Total storage = n entries x 2 x log(n) + 2 x log(n) ~= O(nlog(n))

*/

module Linked_List_LRU 
	#( parameter	NO_ENTRY = 8,
	   parameter	IDX_WIDTH = $clog2(NO_ENTRY) )
(
	input							clk,
	input							rst_n,
	
	input							acc_en,		// indicating a valid access
	input [IDX_WIDTH-1:0]			acc_idx,	// the index to entry being accessed

	output logic [IDX_WIDTH-1:0]	lru_idx

);

	logic [NO_ENTRY-1:0][IDX_WIDTH-1]		prev_idx;
	logic [NO_ENTRY-1:0][IDX_WIDTH-1]		next_idx;
	logic [IDX_WIDTH-1:0]					head_idx;
	logic [IDX_WIDTH-1:0]					tail_idx;
	logic									acc_head, acc_tail, acc_middle;

	assign acc_head = acc_en & (acc_idx == head_idx);
	assign acc_tail = acc_en & (acc_idx == tail_idx);
	assign acc_middle = acc_en & !acc_head & !acc_tail;

	// head_idx logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			head_idx <= '0;
		else if (acc_en)
			head_idx <= acc_idx;

	// tail_idx logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			tail_idx <= '1;
		else if (acc_tail)
			tail_idx <= prev_idx[tail_idx];

	// prev_idx logic
	always_ff @(posedge clk or negedge rst_n)
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			if (~rst_n)
				prev_idx[i] <= (i - 1);
			else if (acc_en & (head_idx == i))					// update head node's previous node
				prev_idx[i] <= acc_idx;
			else if (acc_middle & (next_idx[acc_idx] == i))		// update accessed node's next node's previous pointer
				prev_idx[i] <= prev_idx[acc_idx];
	
	// next_idx logic
	always_ff @(posedge clk or negedge rst_n)
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			if (~rst_n)
				next_idx[i] <= (i + 1);			
			else if (acc_en & (acc_idx == i))					// update accessed node's next node
				next_idx[i] <= head_idx;
			else if (acc_middle & (prev_idx[acc_idx] == i))		// update accessed node's previous node's next pointer
				next_idx[i] <= next_idx[acc_idx];

	// lru_idx assignment
	assign lru_idx = tail_idx;


endmodule
