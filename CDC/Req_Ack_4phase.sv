/*
	Assuming sender block uses clk1, while receiving block uses clk2, and
	sender block and receiving block use 4-phase REQ/ACK protocol

	The sender block interacts with its upstream logic using valid/ready protocol
	The receiving block interacts with its downstream logic using valid/ready protocol
*/


module Req_Ack_4phase_Sender
	# ( parameter DWIDTH = 8)
(
	input						clk1,
	input						rst1_n,		// assuming this reset is synchronized

	input						valid,
	output logic				ready,
	input [DWIDTH-1:0]			din,

	output logic				req,
	input						ack,		// assuming this signal is synchronized from clk2 to clk1
	output logic [DWIDTH-1:0]	dout
);

	always_ff @(posedge clk1 or negedge rst1_n)
		if (~rst1_n)
			req <= '0;
		else if (valid & ready)
			req <= '1;
		else if (req & ack)
			req <= '0;
	
	always_ff @(posedge clk1 or negedge rst1_n)
		if (~rst1_n)
			ready <= '1;
		else if (valid & ready)		// this condition needs to be put first, in case multiple data to be sent
			ready <= '0;
		else if (~req & ~ack)
			ready <= '1;

	always_ff @(posedge clk)
		if (valid & ready)
			dout <= din;
	
endmodule


module Req_Ack_4phase_Receiver
	# ( parameter DWIDTH = 8)
(
	input						clk2,
	input						rst2_n,		// assuming this reset is synchronized

	input						ready,
	output logic				valid,
	input [DWIDTH-1:0]			din,

	output logic				ack,
	input						req,		// assuming this signal is synchronized from clk1 to clk2
	output logic [DWIDTH-1:0]	dout
);

	always_ff @(posedge clk2 or negedge rst2_n)
		if (~rst1_n)
			valid <= '0;
		else if (valid & ready)		// this condition needs to be put first, in case multiple data to be sent
			valid <= '0;
		else if (req & ~ack)
			valid <= '1;
	
	always_ff @(posedge clk2 or negedge rst2_n)
		if (~rst1_n)
			ack <= '0;
		else if (valid & ready)
			ack <= '1;
		else if (~req & ack)
			ack <= '0;

	assign dout == din;
	
endmodule
