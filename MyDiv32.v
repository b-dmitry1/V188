module MyDiv32(
	input wire clk,
	
	input wire [63:0] denom,
	input wire [31:0] num,
	output reg [31:0] q,
	output reg [31:0] r,
	
	input wire signed_div,
	
	input wire run_in,
	output reg run_out
);

initial
begin
  run_out <= 1'b0;
  v <= 64'd0;
  bm <= 64'd0;
  phase <= 6'd0;
  q <= 32'd0;
  r <= 32'd0;
end

reg [63:0] v;
reg [31:0] m;
reg [5:0] phase;
reg [31:0] res;
reg [63:0] bm;

wire sign = denom[63] ^ num[31];
wire [63:0] pos_denom = (signed_div && denom[63]) ? 64'd0 - denom : denom;
wire [31:0] pos_num = (signed_div && num[31]) ? 32'd0 - num : num;

always @(posedge clk)
begin
	if (run_in ^ run_out)
	begin
		q <= (signed_div && sign) ? 32'd0 - res[31:0] : res[31:0];
		r <= (signed_div && sign) ? 32'd0 - v[31:0] : v[31:0];
		if (phase == 6'd32)
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
			bm <= {1'b0, bm[63:1]};
			m <= {1'b0, m[31:1]};
		end
		phase <= phase + 6'd1;
		
		$display("%d / %d", v, bm);
	end
	else
	begin
		v <= pos_denom;
		res <= 32'd0;
		m <= 32'd2147483648;
		bm <= {1'b0, pos_num, 31'd0};
		phase <= 6'd0;
	end
end

endmodule
