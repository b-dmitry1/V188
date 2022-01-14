module AdLib(
	input wire clk,
	input wire reset_n,
	
	input wire [11:0] port,
	input wire [7:0] iodin,
	output wire [7:0] iodout,
	input wire iowr,
	input wire iordin,
	output reg iordout,
	output wire ready,
	
	output reg [7:0] music
);

assign ready = iordin == iordout;

reg [5:0] iodelay;
always @(posedge clk)
begin
	if (|iodelay)
	begin
		iodelay <= iodelay + 1'd1;
		if (&iodelay)
			iordout <= iordin;
	end
	else if (iordin ^ iordout)
	begin
		if (port[11:4] == 8'h38)
			iodelay <= 1'd1;
		else
			iordout <= iordin;
	end
end

assign iodout = {timer1[8] | timer2[8], timer1[8], timer2[8], 5'h0};

reg [8:0] timer1;
reg [8:0] timer2;

reg timer1_start;
reg timer2_start;

reg timer1_mask;
reg timer2_mask;

reg [13:0] timer_div;

reg [7:0] index;

reg distortion;
reg rhythm;

wire regwr = iowr && (port == 12'h389);

reg [19:0] result;

wire [15:0] ch0res;
AdLibChannel #(0, 0) ch0(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch0res)
);

wire [15:0] ch1res;
AdLibChannel #(1, 1) ch1(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch1res)
);

wire [15:0] ch2res;
AdLibChannel #(2, 2) ch2(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch2res)
);

wire [15:0] ch3res;
AdLibChannel #(3, 8) ch3(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch3res)
);

wire [15:0] ch4res;
AdLibChannel #(4, 9) ch4(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch4res)
);

wire [15:0] ch5res;
AdLibChannel #(5, 10) ch5(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch5res)
);

wire [15:0] ch6res;
AdLibChannel #(6, 16) ch6(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch6res)
);

wire [15:0] ch7res;
AdLibChannel #(7, 17) ch7(
	.clk(clk),
	.a(index),
	.din(iodin),
	.regwr(regwr),
	.distortion(distortion),
	.result(ch7res)
);



// Микшер
always @(posedge clk)
begin
	if (rhythm)
		result <= ch0res + ch1res + ch2res + ch3res + ch4res + ch5res;
	else
		result <= ch0res + ch1res + ch2res + ch3res + ch4res + ch5res + ch6res + ch7res;
	
	music <= result[18:11];
end


// Регистры
always @(posedge clk)
begin
	index <= iowr && (port == 12'h388) ? iodin : index;
	
	distortion <= regwr && (index == 8'h01) ? iodin[5] : distortion;
	rhythm <= regwr && (index == 8'hBD) ? iodin[5] : rhythm;
end


// Таймеры
always @(posedge clk)
begin
	timer_div <= timer_div + 14'd1;
	
	timer1 <=
		iowr && (port == 12'h389) && (index == 8'h04) && iodin[7] ? 9'd0 :
		iowr && (port == 12'h389) && (index == 8'h02) ? {1'b0, iodin} :
		timer1_start && (&timer_div[11:0]) && (~timer1[8]) ? timer1 + 9'd1 :
		timer1;

	timer1_start <=
		iowr && (port == 12'h389) && (index == 8'h04) && iodin[6] ? 1'b1 :
		timer1_start && timer1[8] ? 1'b0 :
		timer1_start;
	
	timer1_mask <=
		iowr && (port == 12'h389) && (index == 8'h04) ? iodin[6] :
		timer1_mask;

	timer2 <=
		iowr && (port == 12'h389) && (index == 8'h04) && iodin[7] ? 9'd0 :
		iowr && (port == 12'h389) && (index == 8'h03) ? {1'b0, iodin} :
		timer2_start && (&timer_div[13:0]) && (~timer2[8]) ? timer2 + 9'd1 :
		timer2;

	timer2_start <=
		iowr && (port == 12'h389) && (index == 8'h04) && iodin[5] ? 1'b1 :
		timer2_start && timer2[8] ? 1'b0 :
		timer2_start;
	
	timer2_mask <=
		iowr && (port == 12'h389) && (index == 8'h04) ? iodin[5] :
		timer2_mask;
end


endmodule
