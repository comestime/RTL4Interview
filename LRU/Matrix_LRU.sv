/*
	Design an LRU block using square matirx mechanism.

	The Square-Matrix implementation follows a simple logging scheme wherein, 
	it sets the row of accessed line to one and after this sets the column of the accessed line to zero.
	The number of ones in each row is an indication of the order of the accesses cache lines within the set.
	A line with more number of 1’s is more recently accessed than the one that has less number of 1’s.

	On a cache miss, LRU is detected by checking the row for which all the storage elements are zero

	The total storage = n entries X n entries ~= O(n^2)

*/

module Matrix_LRU
	# (	parameter	NO_ENTRY = 8,
		parameter	IDX_WIDTH = $clog2(NO_ENTRY))
(
	input							clk,
	input							rst_n,

	input							acc_en,
	input [IDX_WIDTH-1:0]			acc_idx,

	output logic [IDX_WIDTH-1:0]	lru_idx
);

	logic [NO_ENTRY-1:0][NO_ENTRY-1:0]	array;
	logic [NO_ENTRY-1:0]				allzero_rows;

	// array update logic
	always_ff @(posedge clk or negedge rst_n)
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			for (int j = 0; j < NO_ENTRY; j = j + 1)
				if (~rst_n)
					if (i < j) 	array[i][j] <= '1;
					else		array[i][j] <= '0;
				else if (acc_en & (acc_idx == j))		// clear has higher priority than set when i == j
					array[i][j] <= '0;
				else if (acc_en & (acc_idx == i))
					array[i][j] <= '1;

	// lru_idx assignment
	always_comb
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			allzero_rows[i] = ~|array[i];

	always_comb
		lru_idx = '0;
		for (int i = 0; i < NO_ENTRY; i = i + 1)
			lru_idx |= ({IDX_WIDTH{allzero_rows[i]}} & i);


endmodule
