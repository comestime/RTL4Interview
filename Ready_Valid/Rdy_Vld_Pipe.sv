/*
	Pipe stage 0: reg0 (takes vld_in and produces rdy_out)
	Pipe stage 1: reg1 (takes rdy_in and produces vld_out)
	
	This solution is called "forward register slice", that cuts the timing path of valid but not ready
*/

module Rdy_Vld_Pipe
#( parameter DWIDTH = 32)
(
	input						clk,
	input						rst_n,

	input						vld_in,
	input [DWIDTH-1:0]			din,
	output logic				rdy_out,

	output logic				vld_out,
	output logic [DWIDTH-1:0]	dout,
	input						rdy_in
);

	logic [DWIDTH-1:0]			reg0, reg1;
	logic 						reg0_vld, reg1_vld;
	logic						reg0_rdy, reg1_vld;

	// rdy logic for each stage
	assign reg0_rdy = ~reg0_vld | reg1_rdy;
	assign reg1_rdy = ~reg1_vld | rdy_in;

	// vld logic for each stage
	always_ff@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			reg0_vld <= '0;
		end else if (vld_in & reg0_rdy) begin
			reg0_vld <= '1;
		end else if (reg0_vld & reg1_rdy) begin
			reg0_vld <= '0;
		end
	end

	always_ff@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			reg1_vld <= '0;
		end else if (reg0_vld & reg1_rdy) begin
			reg1_vld <= '1;
		end else if (reg1_vld & rdy_in) begin
			reg1_vld <= '0;
		end
	end

	// reg0 and reg1 assignment
	always_ff@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			reg0 <= '0;
		end else if (vld_in & reg0_rdy) begin
			reg0 <= din;
		end
	end

	always_ff@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			reg1 <= '0;
		end else if (reg0_vld & reg1_rdy) begin
			reg1 <= reg0;
		end
	end

	// output assignment
	assign dout = reg1;
	assign vld_out = reg1_vld;
	assign rdy_out = reg0_rdy;


endmodule
