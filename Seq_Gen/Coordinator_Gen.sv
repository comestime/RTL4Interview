/*

	A (height x width) frame consists of (height x width) pixels. Each pixel can be referenced by a 2-dimensional coordinator (x, y).

	For example, a (4 x 5) frame looks like this:
	
	-------------------------------------------> width (y)
	|	(0, 0)	(0, 1)	(0, 2)	(0, 3)	(0, 4)
	|	(1, 0)	(1, 1)	(1, 2)	(1, 3)	(1, 4)
	|	(2, 0)	(2, 1)	(2, 2)	(2, 3)	(2, 4)
	|	(3, 0)	(3, 1)	(3, 2)	(3, 3)	(3, 4)
	|
	height (x)
	
	The desired sequence looks like this:

	(0, 0) -> (0, 1) -> (1, 0) -> (0, 2) -> (1, 1) -> (0, 3) -> (1, 2) -> (0, 4) -> (1, 3) -> (1, 4) ->
	(2, 0) -> (2, 1) -> (3, 0) -> (2, 2) -> (3, 1) -> (2, 3) -> (3, 2) -> (2, 4) -> (3, 3) -> (3, 4)

	Given height is always an even number >= 2, and width is always >= 2, design a sequence generator following the rule defined above
	The sequence generator takes start, height, width as inputs, x and y as outputs

*/


module Coordinator_Gen
	#( parameter X_WIDTH = 4,
	   parameter Y_WIDTH = 4)
(
	input						clk,
	input						rst_n,

	input 						start,
	input [X_WIDTH:0]			height,
	input [Y_WIDTH:0]			width,

	output logic [X_WIDTH-1:0]	x,
	output logic [Y_WIDTH-1:0]	y

);

	localparam S0 = 0;
	localparam S1 = 1;
	localparam S2 = 2;
	localparam S3 = 3;
	localparam S4 = 4;
	localparam S5 = 5;

	logic [5:0]	state, next_state;	// 1-hot encoding

	// FSM logic
	always_ff @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			state[0] <= '1;
			state[5:1] <= '0;
		end else
			state <= next_state;

	always_comb begin
		next_state = '0;
		case (1'b1)
			state[S0]:
				if (start)
					next_state[S1] = '1;
				else
					next_state = state;
			state[S1]:
				next_state[S2] = '1;
			state[S2]:
				if (y == (width - 1))
					next_state[S4] = '1;
				else
					next_state[S3] = '1;
			state[S3]:
				next_state[S2] = '1;
			state[S4]:
				if (x == (height - 1))
					next_state[S0] = '1;
				else
					next_state[S5] = '1;
			state[S5]:
				next_state[S1] = '1;
			default:
				next_state = state;
		endcase
	end

	// output generation: coordinate sequence
	always_ff @(posedge clk or negedge rst_n)
		unique if (~rst_n)
			x <= '0;
		else if (next_state[S5] | next_state[S2])
			x <= x + 1;
		else if (next_state[S3])
			x <= x - 1;
		else if (next_state[S0])
			x <= '0;

	always_ff @(posedge clk or negedge rst_n)
		unique if (~rst_n)
			y <= '0;
		else if (next_state[S1] | next_state[S4])
			y <= y + 1;
		else if (next_state[S3])
			y <= y + 2;
		else if (next_state[S2])
			y <= y - 1;
		else if (next_state[S5] | next_state[S0])
			y <= '0;

endmodule

