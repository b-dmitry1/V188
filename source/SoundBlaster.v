module SoundBlaster(
	input wire clk,
	input wire reset_n,
	
	input wire [11:0] port,
	input wire [7:0] iodin,
	output reg [7:0] iodout,
	input wire iowrin,
	output reg iowrout,
	input wire iordin,
	output reg iordout,
	
	input wire [7:0] dma_din,
	input wire dma_rdin,
	output reg dma_rdout,
	
	input wire [7:0] adlib_in,
	
	output reg [7:0] output_left,
	
	output reg pwm_left
);

reg data;
reg [7:0] index;

reg [7:0] div;

reg [7:0] timeconst;

reg [5:0] div50;

reg [9:0] pwm;

always @(posedge clk or negedge reset_n)
begin
	if (~reset_n)
	begin
		data <= 1'b0;
		output_left <= 8'd0;
	end
	else
	begin
		pwm <= pwm + 1'd1;
	
		pwm_left <= (output_left + {adlib_in, 1'b0}) < pwm;
	
		iordout <= iordin;
		iowrout <= iowrin;
	
		iodout <=
			port == 12'h22C ? 8'h00 :
			8'hAA;
	
		data <=
			(port == 12'h22C) && (iordin ^ iordout) ? 1'd0 :
			(port == 12'h22C) && (iowrin ^ iowrout) ? ~data :
			data;

		index <=
			(port == 12'h22C) && (iowrin ^ iowrout) && (~data) ? iodin[7:0] :
			index;
		
		timeconst <=
			(port == 12'h22C) && (iowrin ^ iowrout) && data && (index == 8'h40) ? iodin[7:0] :
			timeconst;
			
		div <=
			div50 == 6'd49 ?
			(&div ? timeconst : div + 8'd1) :
			div;
		
		dma_rdout <=
			(&div) && (div50 == 6'd49) && (dma_rdin ^ dma_rdout) ? ~dma_rdout :
			dma_rdout;
		
		output_left <=
			(&div) && (div50 == 6'd49) && (dma_rdin ^ dma_rdout) ? dma_din :
			output_left;
		
		div50 <= div50 == 6'd49 ? 6'd22 : div50 + 6'd1;
	end
end

endmodule
