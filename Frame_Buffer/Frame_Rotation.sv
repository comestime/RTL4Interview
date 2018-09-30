/*
	Design a module that can rotate the frame by 90 degree clock-wise
	
		The input frame is 16 x 16 pixels, and each pixel is 1B; same as the output frame
		Next cycle following start_i, each clock the input data_i will provide one row of the frame (16 x 8 = 128b)
		The output data_o shall provide one row of the rotated frame (16 x 8 = 128b) each clock cycle following start_o

*/

// Solution 1: base solution, allow one frame to be rotated every 32 cycles
module Frame_Rotation
(
	input				clk,
	input				rst_n,

	input [127:0]		data_i,
	input				start_i,

	output logic [127:0]data_o,
	output logic		start_o
);

	logic [3:0]				counter;		// serve as both rd_ptr and wr_ptr
	logic					vld_i;			// similar to WEN
	logic					vld_o;			// similar to REN
	logic [15:0][7:0]		row_i, row_o;
	logic [15:0][15:0][7:0]	buffer;			// frame buffer

	// convert the data_i to row format
	always_comb
		for (int i = 0; i < 16; i = i + 1)
			row_i[i] = data_i[8 * i + 7 : 8 * i];

	// convert the row format for data_o
	always_comb
		for (int i = 0; i < 16; i = i + 1)
			data_o[8 * i + 7 : 8 * i] = row_o[i];

	// vld_i logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			vld_i <= '0;
		else if (start_i)
			vld_i <= '1;
		else if (counter == '0)
			vld_i <= '0;

	// vld_o logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			vld_o <= '0;
		else if (start_o)
			vld_o <= '1;
		else if (counter == 4'hF)
			vld_o <= '0;

	// counter logic, decrementing during WEN, incrementing during REN
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			counter <= '0;
		else if (start_i)
			counter <= 4'hF;
		else if (start_o)
			counter <= '0;
		else if (vld_i)
			counter <= counter - 1'b1;
		else if (vld_o)
			counter <= counter + 1'b1;

	// frame buffer logic
	always_ff @(posedge clk)
		if (vld_i)
			for (int i = 0; i < 16; i = i + 1)
				buffer[i][counter] <= row_i[i];

	// row_o logic
	assign row_o = buffer[counter];

	// start_o assignment
	assign start_o = vld_i & (counter == '0);

endmodule


// Solution 2: allow one frame to be rotated every 16 cycles
module Frame_Rotation
(
	input				clk,
	input				rst_n,

	input [127:0]		data_i,
	input				start_i,

	output logic [127:0]data_o,
	output logic		start_o
);

	logic [3:0]					wr_ptr, rd_ptr;	// serve as pointers for frame buffer entry
	logic						vld_i;			// similar to WEN
	logic						vld_o;			// similar to REN
	logic						buf_in_use;		// which frame buffer entry is being written
	logic [15:0][7:0]			row_i, row_o;
	logic [1:0][15:0][15:0][7:0]buffer;			// ping-pong frame buffer

	// convert the data_i to row format
	always_comb
		for (int i = 0; i < 16; i = i + 1)
			row_i[i] = data_i[8 * i + 7 : 8 * i];

	// convert the row format for data_o
	always_comb
		for (int i = 0; i < 16; i = i + 1)
			data_o[8 * i + 7 : 8 * i] = row_o[i];

	// row_o assignment
	assign row_o = buffer[~buf_in_use][rd_ptr];
	
	// start_o assignment
	assign start_o = vld_i & (wr_ptr == '0);

	// frame buffer write logic
	always_ff @(posedge clk)
		if (vld_i)
			for (int i = 0; i < 16; i = i + 1)
				buffer[buf_in_use][i][wr_ptr] <= row_i[i];

	// vld_i or WEN logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			vld_i <= '0;
		else if (start_i)
			vld_i <= '1;
		else if (wr_ptr == '0)
			vld_i <= '0;

	// vld_o or REN logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			vld_o <= '0;
		else if (start_o)
			vld_o <= '1;
		else if (rd_ptr == 4'hF)
			vld_o <= '0;

	// buf_in_use logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			buf_in_use <= '0;
		else if (start_o)
			buf_in_use <= ~buf_in_use;

	// wr_ptr logic; decrementing during WEN
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			wr_ptr <= '0;
		else if (start_i)
			wr_ptr <= 4'hF;
		else if (vld_i)
			wr_ptr <= wr_ptr - 1'b1;

	// rd_ptr logic; incrementing during REN
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n)
			rd_ptr <= '0;
		else if (start_o)
			rd_ptr <= '0;
		else if (vld_o)
			rd_ptr <= rd_ptr + 1'b1;

endmodule

