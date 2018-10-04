/*
	Design a LRU using counter mechanism.
	
	There is one to one mapping between the counters and cache lines
	This is used to record LRU information and the cache linesin a set. 
	The values in the register indicate the order in which the cache lines within a set have been accessed.
	A register with a larger value means that corresponding cache line is more recently accessed than the line whose register has a lesser value. 
	The smallest value, Zero in the register indicates the corresponding cache line is least recently accessed line
	And the highest value, N-1 indicates the corresponding cache line is most recently accessed line.
	The value of the register, which is called active register whose cache line being accessed is compared with the value of other registers.
	The registers whose value is greater than active register are decremented and the active register is set to highest
value N-1.

	Total storage = n entries X log(n) counters ~= O(nlog(n))
*/

module Counter_LRU
	# (	parameter NO_ENTRY = 8,
		parameter IDX_WIDTH = $clog2(NO_ENTRY))
(
	input							clk,
	input							rst_n,
	
	input							acc_en,
	input [IDX_WIDTH-1:0]			acc_idx,

	output logic [IDX_WIDTH-1:0]	lru_idx
);

	logic [NO_ENTRY-1:0][IDX_WIDTH-1:0]		counter;
	logic [NO_ENTRY-1:0]					allzero_cnt;

	// counter update logic
	always_ff @(posedge clk or negedge rst_n)
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			if (~rst)
				counter[i] <= i;
			else if (acc_en)
				if (acc_idx == i)						// update the counter[acc_idx] to be (N-1)
					counter[i] <= (NO_ENTRY - 1);
				else if (counter[i] > counter[acc_idx])	// decrement counter[i] if its value is larger than counter[acc_idx]
					counter[i] <= counter[i] - 1'b1;
	
	// lru_idx assignment
	always_comb
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			allzero_cnt[i] = ~|counter[i];

	always_comb
		lru_idx = '0;
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			lru_idx |= ({IDX_WIDTH{allzero_cnt[i]}} & i);

endmodule
