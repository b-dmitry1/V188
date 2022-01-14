module AdLibOperator(
	input wire clk,
	
	input wire [7:0] din,
	input wire wr_2n,
	input wire wr_4n,
	input wire wr_6n,
	input wire wr_8n,
	input wire wr_En,
	
	input wire play,
	
	output reg [3:0] harmonic,
	output reg [1:0] waveform,
	
	output reg [7:0] envelope
);

localparam
	S_IDLE		= 3'd0,
	S_ATTACK		= 3'd1,
	S_DECAY		= 3'd2,
	S_SUSTAIN	= 3'd3,
	S_RELEASE	= 3'd4;

reg [3:0] attack;
reg [3:0] decay;
reg [3:0] sustain;
reg [3:0] releas;
reg percussive;
reg [5:0] level;

reg [2:0] state;

reg [15:0] res;
wire [15:0] levelres;

reg [9:0] div;
reg div_overflow;

reg prev_play;
reg play_hit;

reg [21:0] attack_rate;
reg [21:0] decay_rate;
reg [21:0] release_rate;
reg [15:0] sustain_amp;
reg [18:0] steps;

wire [9:0] attack_delta = 10'd511;
wire [8:0] decay_delta = 9'd256;
wire [8:0] release_delta = 9'd256;

wire [16:0] res_attack = res + attack_delta;
wire [16:0] res_decay = res - decay_delta;

Mul8 levelmul(.dataa(res[15:8]), .datab({2'b00, level}), .result(levelres));

always @(posedge clk)
begin
	if (wr_2n) percussive <= ~din[5];
	if (wr_2n) harmonic <= ~|din[3:0] ? 4'd0 : din[3:0] - 4'd1;
	if (wr_4n) level <= ~din[5:0];
	if (wr_6n) attack <= din[7:4];
	if (wr_6n) decay <= din[3:0];
	if (wr_8n) sustain <= din[7:4];
	if (wr_8n) releas <= din[3:0];
	if (wr_En) waveform <= din[1:0];

	attack_rate <= 19'd292968 >> attack;
	decay_rate <= 22'd2343744 >> decay;
	release_rate <= 22'd2343744 >> releas;
	sustain_amp <= 16'hFFFF >> sustain;
	
	envelope <= levelres[13:6];
	
	div <= div + 1'd1;
	div_overflow <= &div;
	
	prev_play <= play;
	play_hit <= (~prev_play) && play;
	
	if (play_hit)
	begin
		state <= S_ATTACK;
		res <= 16'd0;
		steps <= 12'd0;
	end
	else
	begin
		case (state)
			S_IDLE:
			begin
				res <= 16'd0;
				steps <= 12'd0;
			end
			S_ATTACK:
			begin
				if (~play)
				begin
					state <= S_RELEASE;
				end
				else if (res_attack[16])
				begin
					res <= 16'hFFFF;
					steps <= 12'd0;
					state <= S_DECAY;
				end
				else
				begin
					if (steps >= attack_rate)
					begin
						res <= res + attack_delta;
						steps <= 12'd0;
					end
					else
						steps <= steps + 1'd1;
				end
			end
			S_DECAY:
			begin
				if ((res_decay <= sustain_amp) || (~play))
				begin
					res <= sustain_amp;
					state <= S_SUSTAIN;
				end
				else
				begin
					if (steps >= decay_rate)
					begin
						res <= res - decay_delta;
						steps <= 12'd0;
					end
					else
						steps <= steps + 1'd1;
				end
			end
			S_SUSTAIN:
			begin
				if (percussive || (~play))
					state <= S_RELEASE;
			end
			S_RELEASE:
			begin
				if (res <= release_delta)
				begin
					res <= 16'd0;
					state <= S_IDLE;
				end
				else
				begin
					if (steps >= release_rate)
					begin
						res <= res - release_delta;
						steps <= 12'd0;
					end
					else
						steps <= steps + 1'd1;
				end
					state <= S_IDLE;
			end
			default:
				state <= S_IDLE;
		endcase
	end
end

endmodule
