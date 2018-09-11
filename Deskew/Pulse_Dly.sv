/*
	pulse delay logic, the input sel decides how many cycles the input pulse should be delayed
	assuming input sel is static, and maximum clock cycles to be delayed is 3
*/

module Pulse_Dly (
	input 				clk,
	input				rst_n,
	input				din,
	output				dout,

	input [1:0]			sel
);

	logic din_q1, din_q2, din_q3;

	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n)
			{din_q1, din_q2, din_q3} <= '0;
		else
			{din_q1, din_q2, din_q3} <= {din, din_q1, din_q2};
	end

	// output assignments
	always_comb begin
		case (sel)
			2'b00:		dout = din;
			2'b01:		dout = din_q1;
			2'b10:		dout = din_q2;
			2'b11:		dout = din_q3;
			default:	dout = din;
		endcase
	end
	
endmodule
