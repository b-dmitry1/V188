module SPI(
	input wire clk,
	
	input wire [11:0] ioaddr,
	input wire [7:0] din,
	output wire [7:0] dout,
	input wire iord,
	input wire iowr,
	
	output wire ready,
	
	output wire cs_n,
	input wire miso,
	output wire mosi,
	output wire sck
);

reg cs;

reg [7:0] div;
reg [7:0] preset;

reg [7:0] sin;
reg [7:0] sout;
reg [3:0] bits;

reg [15:0] shift;

assign cs_n = ~cs;
assign sck = shift[1] | shift[3] | shift[5] | shift[7] | shift[9] | shift[11] | shift[13] | shift[15];
assign mosi = sout[7];

assign dout = sin;

assign ready = ~|shift;

always @(posedge clk)
begin
	if (iowr && (ioaddr[11:0] == 12'h0B0))	// 0xB0
		cs <= din[0];
	
	if (iowr && (ioaddr[11:0] == 12'h0B1))	// 0xB1
		preset <= din;
	
	if (iowr && (ioaddr[11:0] == 12'h0B2))	// 0xB2
	begin
		sout <= din;
		shift <= 16'd1;
		div <= 8'd0;
	end
	
	if (|shift)
	begin
		if (div == preset)
		begin
			div <= 8'd0;
			
			shift <= {shift[14:0], 1'b0};
			
			if (sck)
			begin
				sin <= {sin[6:0], miso};
				sout <= {sout[6:0], 1'b0};
			end
		end
		else
			div <= div + 8'd1;
	end
end

endmodule
