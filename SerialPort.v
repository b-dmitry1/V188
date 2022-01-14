module SerialPort(
	input wire clk,
	
	input wire [7:0] din,
	output reg [7:0] dout,
	input wire wrin,
	output reg wrout,
	output reg rdout,
	
	output wire txd,
	input wire rxd
);


// Передающая часть
reg [8:0] div;

reg [9:0] shift;

assign txd = |shift ? shift[0] : 1'b1;

always @(posedge clk)
begin
	div <= div == 9'd434 ? 9'd0 : div + 9'd1;
	
	if (~|div)
	begin
		if (~|shift)
		begin
			if (wrin ^ wrout)
			begin
				shift <= {1'b1, din, 1'b0};
				wrout <= ~wrout;
			end
		end
		else
			shift <= {1'b0, shift[9:1]};
	end
end

// Принимающая часть

reg [8:0] rdiv;
reg [8:0] rpreset;

reg [3:0] malfunction_counter;
reg malfunction;

reg [9:0] rshift;

always @(posedge clk)
begin
	rdiv <= rdiv + 9'd1;
	
	rpreset <= |rshift[9:1] ? 9'd434 : 9'd108;
	
	malfunction <= &malfunction_counter;
	
	if (rdiv >= rpreset)
	begin
		malfunction_counter <= rxd ? 4'd0 : &malfunction_counter ? malfunction_counter : malfunction_counter + 4'd1;
		rdiv <= 9'd0;
		if (rshift == 10'd0)
		begin
			if ((~rxd) && (~malfunction))
				rshift <= 10'd1;
		end
		else
		begin
			rshift <= {rshift[8:0], 1'b0};
			if (|rshift[8:1])
				dout <= {rxd, dout[7:1]};
			if (rshift[9])
				rdout <= ~rdout;
		end
	end
end

endmodule
