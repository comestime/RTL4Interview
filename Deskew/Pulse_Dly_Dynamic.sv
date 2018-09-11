/*
	pulse delay logic, the input sel decides how many cycles the input pulse should be delayed
	assuming maximum clock cycles to be delayed is 3
	input sel can be dynamic
*/

module Pulse_Dly_Dynamic (
	input 				clk,
	input				rst_n,
	input				din,
	output				dout,

	input [1:0]			sel
);

	logic din_q1, din_q2, din_q3;
	logic [1:0] sel_q1, sel_q2, sel_q3;

	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n)
			{din_q1, din_q2, din_q3} <= '0;
			{sel_q1, sel_q2, sel_q3} <= '0;
		else
			{din_q1, din_q2, din_q3} <= {din, din_q1, din_q2};
			{sel_q1, sel_q2, sel_q3} <= {sel, sel_q1, sel_q2};
	end

	// output assignments
	// adding unique0 to make sure it must be a parallel case, otherwise the pulse will overlap
	always_comb begin
		unique0 case (1'b1)
			(sel 	== 2'b00):		dout = din;
			(sel_q1 == 2'b01):		dout = din_q1;
			(sel_q2 == 2'b10):		dout = din_q2;
			(sel_q3 == 2'b11):		dout = din_q3;
			default:				dout = din;
		endcase
	end
	
endmodule
