module USBrx(
	input wire clk60,
	
	input wire fullspeed,

	output reg [7:0] dout,
	input wire rdin,
	output reg rdout,

	input wire transmitting,
	
	output reg [7:0] d,
	
	output wire led,
	
	output reg done,
	
	input wire dm,
	input wire dp
);

// assign led = state != S_SYNC;
assign led = done;

reg dm1;
reg dp1;
reg dm2;
always @(posedge clk60)
begin
	dm1 <= dm;
	dp1 <= dp;
	dm2 <= dm1;
end

initial
begin
	dout = 8'h00;
	rdout = 1'b0;
	numbits = 3'd0;
	ones = 3'd0;
	rdm = 1'b0;
	clk = 1'b0;
	d = 8'h00;
end

reg [5:0] div;
reg [5:0] prescaler;
reg clk;

reg rdm;
reg [2:0] numbits;
reg [2:0] ones;

reg [9:0] timeout;

localparam
	S_IDLE		= 2'b00,
	S_SYNC		= 2'b01,
	S_RECEIVE	= 2'b10,
	S_TRANSMIT	= 2'b11;

reg [1:0] state;

reg save;

always @(posedge clk60)
begin
	prescaler <= fullspeed ? 6'd4 : 6'd39;

	clk = div == prescaler[5:1];

	done <= state == S_IDLE;
	
	case (state)
		S_IDLE:
		begin
			// Ожидание сигнала чтения от процессора
			div <= 6'd0;
			timeout <= 10'd0;
			numbits <= 3'd0;
			rdm <= ~fullspeed;
			save <= 1'b0;
			ones <= 3'd0;
			if (transmitting)
				state <= S_TRANSMIT;
			else
			if (rdin != rdout)
				state <= S_SYNC;
		end
		S_TRANSMIT:
		begin
			if (({dm1, dp1} == {~fullspeed, fullspeed}) && (!transmitting))
				state <= S_IDLE;
		end
		S_SYNC:
		begin
			// Ожидание первого бита, отмены или таймаута приема
			timeout <= timeout + 1'd1;
			if (timeout[9])
			begin
				dout <= 8'hFF;
				rdout <= rdin;
				state <= S_IDLE;
			end
			if ({dm1, dp1} == {fullspeed, ~fullspeed})
				state <= S_RECEIVE;
		end
		S_RECEIVE:
		begin
			div <= (dm1 ^ dm2) ? 6'd2 : (div == prescaler) ? 6'd0 : div + 1'd1;

			if (clk)
			begin
				if (rdm == dm1)
				begin
					ones <= ones + 3'd1;
					d <= {1'b1, d[7:1]};
					numbits <= numbits + 1'd1;
					if (ones == 3'd7)
					begin
						dout <= 8'h11;
						rdout <= rdin;
						state <= S_IDLE;
					end
				end
				else
				begin
					ones <= 3'd0;
					if (ones != 3'd6)
					begin
						d <= {1'b0, d[7:1]};
						numbits <= numbits + 1'd1;
					end
				end
				if (numbits == 3'd7)
					save <= 1'b1;
				rdm <= dm1;
			end
			if (save)
			begin
				rdout <= rdin;
				dout <= d;
				save <= 1'b0;
			end
		end
		default:
			state <= S_IDLE;
	endcase
end

endmodule
