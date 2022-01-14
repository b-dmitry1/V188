module MyDiv(
	input wire clk,
	
	input wire [31:0] denom,
	input wire [15:0] num,
	output reg [15:0] q,
	output reg [15:0] r,
	
	input wire signed_div,
	
	input wire run_in,
	output reg run_out
);

initial
begin
  run_out <= 1'b0;
  v <= 32'd0;
  bm <= 32'd0;
  phase <= 5'd0;
  q <= 16'd0;
  r <= 16'd0;
end

reg [31:0] v;
reg [15:0] m;
reg [4:0] phase;
reg [15:0] res;
reg [31:0] bm;

wire sign = denom[31] ^ num[15];
wire [31:0] pos_denom = (signed_div && denom[31]) ? 32'd0 - denom : denom;
wire [15:0] pos_num = (signed_div && num[15]) ? 16'd0 - num : num;

always @(posedge clk)
begin
	if (run_in ^ run_out)
	begin
		q <= (signed_div && sign) ? 16'd0 - res[15:0] : res[15:0];
		r <= (signed_div && sign) ? 16'd0 - v[15:0] : v[15:0];
		if (phase == 5'd16)
		begin
			run_out <= ~run_out;
		end
		else
		begin
			if (v >= bm)
			begin
				res <= res | m;
				v <= v - bm;
			end
			bm <= {1'b0, bm[31:1]};
			m <= {1'b0, m[15:1]};
		end
		phase <= phase + 5'd1;
		
		$display("%d / %d", v, bm);
	end
	else
	begin
		v <= pos_denom;
		res <= 16'd0;
		m <= 16'd32768;
		bm <= {1'b0, pos_num, 15'd0};
		phase <= 5'd0;
	end
end

endmodule
