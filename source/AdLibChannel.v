module AdLibChannel #(parameter N, OPN)
(
	input wire clk,
	
	input wire [7:0] a,
	input wire [7:0] din,
	input wire regwr,
	
	input wire distortion,
	
	output reg [15:0] result
);

wire wr_2n = regwr && ({a[7:5], 1'b0} == 4'h2);
wire wr_4n = regwr && ({a[7:5], 1'b0} == 4'h4);
wire wr_6n = regwr && ({a[7:5], 1'b0} == 4'h6);
wire wr_8n = regwr && ({a[7:5], 1'b0} == 4'h8);
wire wr_An = regwr && (a[7:4] == 4'hA);
wire wr_Bn = regwr && (a[7:4] == 4'hB);
wire wr_Cn = regwr && (a[7:4] == 4'hC);
wire wr_En = regwr && ({a[7:5], 1'b0} == 4'hE);

reg algorythm;

wire op1waveneg;
wire [3:0] op1wave;
wire op2waveneg;
wire [3:0] op2wave;
wire oscplay;
AdLibOsc osc(
	.clk(clk),
	.din(din),
	.wr_An(wr_An && (a[3:0] == N)),
	.wr_Bn(wr_Bn && (a[3:0] == N)),
	
	.harmonic1(op1harmonic),
	.harmonic2(op2harmonic),
	
	.waveform1(op1waveform),
	.waveform2(op2waveform),

	.neg1(op1waveneg),
	.value1(op1wave),
	.neg2(op2waveneg),
	.value2(op2wave),
	.play(oscplay)
);

wire [7:0] op1envelope;
wire [3:0] op1harmonic;
wire [1:0] op1waveform;
AdLibOperator op1(
	.clk(clk),
	.din(din),
	.wr_2n(wr_2n && (a[4:0] == OPN)),
	.wr_4n(wr_4n && (a[4:0] == OPN)),
	.wr_6n(wr_6n && (a[4:0] == OPN)),
	.wr_8n(wr_8n && (a[4:0] == OPN)),
	.wr_En(wr_En && (a[4:0] == OPN)),
	
	.play(oscplay),
	.harmonic(op1harmonic),
	.waveform(op1waveform),
	
	.envelope(op1envelope)
);

wire [7:0] op2envelope;
wire [3:0] op2harmonic;
wire [1:0] op2waveform;
AdLibOperator op2(
	.clk(clk),
	.din(din),
	.wr_2n(wr_2n && (a[4:0] == (OPN + 3))),
	.wr_4n(wr_4n && (a[4:0] == (OPN + 3))),
	.wr_6n(wr_6n && (a[4:0] == (OPN + 3))),
	.wr_8n(wr_8n && (a[4:0] == (OPN + 3))),
	.wr_En(wr_En && (a[4:0] == (OPN + 3))),
	
	.play(oscplay),
	.harmonic(op2harmonic),
	.waveform(op2waveform),
	
	.envelope(op2envelope)
);

wire [15:0] scaled1;
Mul8 op1mul(.dataa({op1wave, 2'b00}), .datab(op1envelope), .result(scaled1));

wire [15:0] scaled2;
Mul8 op2mul(.dataa(algorythm ? {op2wave, 2'b00} : {op2wave, 2'b00} + scaled1[13:8]), .datab(op2envelope), .result(scaled2));

reg [13:0] sc1pos;
reg [13:0] sc1neg;
reg [14:0] sc2pos;
reg [14:0] sc2neg;

always @(posedge clk)
begin
	if (wr_Cn && (a[3:0] == N)) algorythm <= din[0];

	if (algorythm)
	begin
		// op1 + op2
		sc1pos <= op1waveneg ? 14'd0 : scaled1[13:0];
		sc1neg <= op1waveneg ? scaled1[13:0] : 14'd0;
		sc2pos <= op2waveneg ? 15'd0 : scaled2[14:0];
		sc2neg <= op2waveneg ? scaled2[14:0] : 15'd0;
	end
	else
	begin
		// op1 модулирует op2
		sc1pos <= 14'd0;
		sc1neg <= 14'd0;
		sc2pos <= op1waveneg ^ op2waveneg ? 15'd0 : scaled2[14:0];
		sc2neg <= op1waveneg ^ op2waveneg ? scaled2[14:0] : 15'd0;
	end

	result <= 16'd32768 + sc1pos - sc1neg + sc2pos - sc2neg;
end

endmodule
