module USB_LS(
	input wire clk,
	input wire reset_n,
	
	inout reg dm,
	inout reg dp,
	
	output reg [15:0] dout,
	input wire [15:0] din,
	input wire wrin,
	output reg wrout,
	input wire rdin,
	output reg rdout,
	
	input wire soft_reset
);

localparam
	S_NODEVICE			= 1 << 0,
	S_RESET				= 1 << 1,
	S_START				= 1 << 2,
	S_IDLE				= 1 << 3,
	S_EOP				= 1 << 4,
	S_SEND				= 1 << 5,
	S_WAIT				= 1 << 6,
	S_RECEIVE			= 1 << 7;

reg [2:0] div1;
reg [2:0] div2;

reg [7:0] state;
reg [7:0] next;

reg [5:0] div40;
reg clk1_5;

reg [15:0] counter;
reg [3:0] recv_timeout;

reg [3:0] bitn;

reg [15:0] send_buf;

reg [15:0] recv_buf;

reg tx;
reg tx_next;

reg rx;

reg dm_next;
reg dp_next;

reg txe_next;

reg dm_out;
reg dp_out;

reg sync;

reg [2:0] ones;

reg [11:0] rw_timeout;

reg [19:0] start_timeout;

reg [15:0] reset_counter;

reg [19:0] nodevice_timeout;

reg prev_1_5;

always @(posedge clk or negedge reset_n)
begin
	if (~reset_n)
	begin
		state <= S_NODEVICE;
		counter <= 16'd0;
		bitn <= 4'd0;
		tx <= 1'b0;
		rx <= 1'b0;
		send_buf <= 16'd0;
		recv_buf <= 16'd0;
		wrout <= 1'b0;
		rdout <= 1'b0;
		dm <= 1'bZ;
		dp <= 1'bZ;
		dout <= 16'd0;
		rw_timeout <= 12'd0;
		start_timeout <= 20'd0;
		reset_counter <= 16'd0;
		div1 <= 3'd0;
		div2 <= 3'd0;
		sync <= 1'b0;
		clk1_5 <= 1'b0;
		prev_1_5 <= 1'b0;
	end
	else
	begin
		prev_1_5 <= clk1_5;
	
		div1 <=
			div1 == 3'd3 ? (div2 == 3'd5 ? div1 + 3'd1 : 3'd0) :
			div1 == 3'd4 ? 3'd0 :
			div1 + 3'd1;

		div2 <= div1 == 3'd3 ? div2 == 3'd5 ? 3'd0 : div2 + 3'd1 : div2;
		
		if (div1 == 3'd3)
		begin
			sync <= dp;

			if (state == S_WAIT)
			begin
				div40 <=
					div40 == 6'd3 ? 6'd0 :
					div40 + 6'b1;
				clk1_5 <=
					div40 == 6'd3;
			end
			else
			begin
				div40 <=
					(state == S_RECEIVE) && (sync ^ dp) ? 6'd3 :
					div40 == 6'd7 ? 6'd0 :
					div40 + 6'b1;
				clk1_5 <=
					(state == S_RECEIVE) && (sync ^ dp) ? 1'b0 :
					div40 == 6'd7;
			end
		end
	
		if ((~prev_1_5) && (clk1_5))
		begin
			state <=
				soft_reset ? S_NODEVICE :
				next;

			rw_timeout <=
				(rdin ^ rdout) || (wrin ^ wrout) ? rw_timeout + 12'd1 :
				12'd0;

			counter <=
				(state != S_RESET) && (&counter[10:9]) ? 16'd0 :
				counter + 16'd1;

			recv_timeout <=
				(state == S_RECEIVE) && (rx == dm) ? recv_timeout + 4'd1 :
				4'd0;

			bitn <=
				ones == 3'd6 ? bitn :
				(state == S_EOP) && (bitn == 4'd3) ? 4'd15 :
				(state == S_IDLE) ? 4'd0 :
				(state == S_WAIT) ? 4'd0 :
				bitn + 4'd1;

			send_buf <=
				state == S_WAIT ? din :
				bitn == 4'd15 ? din :
				{1'b0, send_buf[15:1]};
			
			tx <= tx_next;

			wrout <=
				&rw_timeout ? wrin :
				(state == S_SEND) && (bitn == 4'd15) && (wrout ^ wrin) ? ~wrout :
				(state == S_EOP) && (bitn == 4'd15) && (wrout ^ wrin) ? ~wrout :
				(state == S_WAIT) && (wrout ^ wrin) ? ~wrout :
				// (state == S_NODEVICE) || (state == S_START) ? wrin :
				wrout;

			dout <=
				state == S_START ? 16'hF080 :
				state == S_NODEVICE ? 16'h1E80 :
				bitn == 4'd15 ? recv_buf :
				dout;

			rx <= dm;
			
			recv_buf <=
				ones == 3'd6 ? recv_buf :
				state == S_RECEIVE ? {rx == dm, recv_buf[15:1]} :
				16'd0;

			rdout <=
				&rw_timeout ? rdin :
				(state == S_WAIT) || (state == S_EOP) || (state == S_SEND) ? rdout :
				state == S_RECEIVE ? ((bitn == 4'd15) && (ones != 3'd6) && (rdin ^ rdout) ? ~rdout : rdout) :
				// rdin ^ rdout ? ~rdout :
				rdout;

			ones <=
				ones == 3'd6 ? 3'd0 :
				(state == S_RECEIVE) && (rx == dm) ? ones + 3'd1 :
				3'd0;

			start_timeout <=
				state == S_START ? start_timeout + 20'd1 :
				20'd0;
				
			reset_counter <=
				state == S_RESET ? reset_counter + 16'd1 :
				16'd0;

			nodevice_timeout <=
				state == S_NODEVICE ? nodevice_timeout + 20'd1 :
				20'd0;

			dm <= txe_next ? dm_next : 1'bZ;
			dp <= txe_next ? dp_next : 1'bZ;
		end
	end
end

always @*
begin
	tx_next <=
		1'b0;
		
	txe_next <=
		(state == S_RESET) || (state == S_EOP) || (state == S_SEND);
		
	dm_next <=
		state == S_EOP ? |bitn[2:1] :
		state == S_SEND ? (send_buf[0] ? ~tx : tx) :
		1'b0;
		
	dp_next <=
		state == S_SEND ? (send_buf[0] ? tx : ~tx) :
		1'b0;

	next <= S_IDLE;

	case (state)
		S_NODEVICE:
		begin
			if (nodevice_timeout[19])
				next <= S_RESET;
			else if (dm)
				next <= S_RESET;
			else
				next <= S_NODEVICE;
		end
		S_RESET:
		begin
			if (reset_counter[15])
				next <= S_START;
			else
				next <= S_RESET;
		end
		S_START:
		begin
			if (start_timeout[19])
				next <= S_RESET;
			else if (dm)
				next <= S_IDLE;
			else
				next <= S_START;
		end
		S_IDLE:
		begin
			if ((&counter[10:9]) && (dm))
				next <= S_EOP;
			else
				next <= S_IDLE;
		end
		S_EOP:
		begin
			if (bitn == 4'd15)
			begin
				if (wrin ^ wrout)
					next <= S_SEND;
				else
					next <= S_WAIT;
			end
			else
				next <= S_EOP;
		end
		S_SEND:
		begin
			tx_next <= send_buf[0] ? tx : ~tx;
			if ((bitn == 4'd15) && (wrin == wrout))
				next <= S_EOP;
			else
				next <= S_SEND;
		end
		S_WAIT:
		begin
			if (wrin ^ wrout)
				next <= S_SEND;
			else if (dp)
				next <= S_RECEIVE;
			else if (&counter[10:9])
				next <= S_IDLE;
			else
				next <= S_WAIT;
		end
		S_RECEIVE:
		begin
			if ((~dm) && (~dp))
				next <= S_WAIT;
			else if (&recv_timeout)
				next <= S_RESET;
			else
				next <= S_RECEIVE;
		end
		default:
			next <= S_NODEVICE;
	endcase
end

endmodule
