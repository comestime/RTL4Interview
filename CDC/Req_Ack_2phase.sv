/*
	Assuming sender block uses clk1, while receiving block uses clk2, and
	sender block and receiving block use 2-phase REQ/ACK protocol

	The sender block interacts with its upstream logic using valid/ready protocol
	The receiving block interacts with its downstream logic using valid/ready protocol
*/


module Req_Ack_2phase_Sender
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

	logic ack_q, ack_pulse;

	always_ff @(posedge clk1 or negedge rst1_n)
		if (~rst1_n)
			req <= '0;
		else if (valid & ready)
			req <= ~req;

	// ack from receiver to sender is a level signal
	// need to generate a pulse to acknowledge sender the transaction is complete
	always_ff @(posedge clk1 or negedge rst1_n)
		if (~rst1_n)
			ack_q <= '0;
		else
			ack_q <= ack;

	assign ack_pulse = ack ^ ack_q;
	
	always_ff @(posedge clk1 or negedge rst1_n)
		if (~rst1_n)
			ready <= '1;
		else if (valid & ready)
			ready <= '0;
		else if (ack_pulse)
			ready <= '1;

	// latch the data
	always_ff @(posedge clk1)
		if (valid & ready)
			dout <= din;
	
endmodule


module Req_Ack_2phase_Receiver
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

	logic req_q, req_pulse;

	always_ff @(posedge clk2 or negedge rst2_n)
		if (~rst2_n)
			ack <= '0;
		else if (valid & ready)
			ack <= ~ack;

	// req from sender to receiver is a level signal
	// need to generate a pulse to request receiver the new incoming transaction
	always_ff @(posedge clk2 or negedge rst2_n)
		if (~rst2_n)
			req_q <= '0;
		else
			req_q <= req;

	assign req_pulse = req ^ req_q;

	always_ff @(posedge clk2 or negedge rst2_n)
		if (~rst2_n)
			valid <= '0;
		else if (req_pulse)
			valid <= '1;
		else if (valid & ready)
			valid <= '0;

	// latch the data
	always_ff @(posedge clk2)
		if (valid & ready)
			dout <= din;
	
endmodule
