/*
	The data is stored in memory in following pattern
		Addr x   |	D0
		Addr x+1 |	D1
		Addr x+2 |	next_ptr = y
			...
		Addr y	 |	D2
		Addr y+1 |	D3
		Addr y+2 |	next_ptr = z
			...
		Addr z	 |	D4
			...

	The read latency of the memory is 3 cycles

	At the beginning, given Addr x, and a start indication, the expected output will be like this:

		cycle a: {D1, D0}
		cycle b: {D3, D2}
		cycle c: {D5, D4}
			...

	Assuming the linked list is endless, don't need to consider out of bound issue
*/

module Rd_Linked_List 
	#( parameter AWIDTH = 8,
	   parameter DWIDTH = 8)
(
	input						clk,
	input						rst_n,
	
	input [AWIDTH-1:0]			address,
	input 						start,
		
	output logic				vld,
	output logic [DWIDTH*2 - 1]	dout
);

	localparam IDLE		= 2'b00;
	localparam RD_PTR	= 2'b01;
	localparam RD_D0	= 2'b10;
	localparam RD_D1	= 2'b11;

	logic [1:0] state, next_state;
	// when normal is 0, the data output from mem is garbage
	logic 		normal;
	// data buffer for D0
	logic [DWIDTH-1:0]	buffer;
	// address buffer
	logic [AWIDTH-1:0]	addr_buffer;
	// memory interface
	logic 				ren;
	logic [AWIDTH-1:0]	addr;
	logic [DWIDTH-1:0]	mem_dout;

	// D0 buffer
	always_ff @(posedge clk) begin
		if (normal & (state == RD_PTR)) 
			buffer <= mem_dout;
	end

	// address buffer
	always_ff @(posedge clk) begin
		if (state == RD_D1)
			addr_buffer <= mem_dout;
		else if (start & (state == IDLE))
			addr_buffer <= address;
	end

	// output assignment
	assign dout = {mem_dout, buffer};
	assign vld = normal & (state == RD_D0);

	// normal logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n)
			normal <= '0;
		else if (state == RD_D1)
			normal <= '1;
	end
	
	// FSM
	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n)
			state <= IDLE;
		else
			state <= next_state;
	end

	always_comb begin
		next_state = state;
		case (state)
			IDLE:	if (start)	next_state = RD_PTR;
			RD_PTR:				next_state = RD_D0;
			RD_D0:				next_state = RD_D1;
			RD_D1:				next_state = RD_PTR;
		endcase
	end

	// memory control logic
	assign ren = (start == 1'b1) | (state != IDLE);

	always_comb begin
		addr = '0;
		case (state)
			IDLE:		addr = address + 2'd2;
			RD_PTR:		addr = addr_buffer;
			RD_D0:		addr = addr_buffer + 2'd1;
			RD_D1:		addr = mem_dout + 2'd2;
		endcase
	end

	// memory instantiation
	mem u_mem (
		.clk			(clk),
		.ren			(ren),
		.addr			(addr),
		.mem_dout		(mem_dout)
	);


endmodule
