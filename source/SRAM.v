module SRAM(
	input wire clk,

	output wire ready,
	
	input wire [23:0] cpu_addr,
	input wire [7:0] cpu_din,
	output reg [7:0] cpu_dout,
	input wire cpu_rdin,
	output reg cpu_rdout,
	input wire cpu_wrin,
	output reg cpu_wrout,

	input wire [23:0] gpu_addr,
	input wire [31:0] gpu_din,
	output reg [31:0] gpu_dout,
	input wire gpu_rdin,
	output reg gpu_rdout,
	input wire gpu_wrin,
	output reg gpu_wrout,
	
	input wire [23:0] video_addr,
	output reg [63:0] video_dout,

	output wire [17:0] a,
	inout wire [15:0] d,
	output wire cs_n,
	output wire we_n,
	output wire oe_n,
	output wire lb_n,
	output wire ub_n
);

parameter S_IDLE			 		= 1 << 0;
parameter S_READ_CPU_0   		= 1 << 1;
parameter S_READ_CPU_1   		= 1 << 2;
parameter S_READ_CPU_2   		= 1 << 3;
parameter S_WRITE_CPU   		= 1 << 4;
parameter S_READ_GPU_0   		= 1 << 5;
parameter S_READ_GPU_1   		= 1 << 6;
parameter S_READ_GPU_2   		= 1 << 7;
parameter S_WRITE_GPU_0			= 1 << 8;
parameter S_WRITE_GPU_1			= 1 << 9;
parameter S_READ_VIDEO_0  		= 1 << 10;
parameter S_READ_VIDEO_1  		= 1 << 11;
parameter S_READ_VIDEO_2  		= 1 << 12;
parameter S_READ_VIDEO_3  		= 1 << 13;
parameter S_READ_VIDEO_4  		= 1 << 14;

reg [14:0] state;

reg [18:3] cur_video_addr;

wire cs;
wire oe;
wire we;
assign cs = (state == S_READ_GPU_0) || (state == S_READ_GPU_1) ||
	(state == S_READ_VIDEO_0) || (state == S_READ_VIDEO_1) || (state == S_READ_VIDEO_2) || (state == S_READ_VIDEO_3) || (state == S_READ_CPU_0) || (state == S_READ_CPU_1) || (state == S_READ_CPU_2) ||
	(state == S_WRITE_CPU) || (state == S_WRITE_GPU_0) || (state == S_WRITE_GPU_1);
assign oe = (state == S_READ_GPU_0) || (state == S_READ_GPU_1) ||
	(state == S_READ_VIDEO_0) || (state == S_READ_VIDEO_1) || (state == S_READ_VIDEO_2) || (state == S_READ_VIDEO_3) || (state == S_READ_CPU_0) || (state == S_READ_CPU_1) || (state == S_READ_CPU_2);
assign we = (state == S_WRITE_CPU) || (state == S_WRITE_GPU_0) || (state == S_WRITE_GPU_1);

assign ready = ~((cpu_rdin ^ cpu_rdout) | (cpu_wrin ^ cpu_wrout));


assign d =
	state == S_WRITE_GPU_0 ? gpu_din[15:0] :
	state == S_WRITE_GPU_1 ? gpu_din[31:16] :
	state == S_WRITE_CPU ? {cpu_din, cpu_din} :
	16'hZZZZ;

assign a =
	(state == S_READ_GPU_0) || (state == S_READ_GPU_1) || (state == S_WRITE_GPU_0) || (state == S_WRITE_GPU_1) ?
		{gpu_addr[18:2], (state == S_READ_GPU_1) || (state == S_WRITE_GPU_1)} : 
	(state == S_READ_VIDEO_0) || (state == S_READ_VIDEO_1) || (state == S_READ_VIDEO_2) || (state == S_READ_VIDEO_3) ?
		{video_addr[18:3], (state == S_READ_VIDEO_2) || (state == S_READ_VIDEO_3), (state == S_READ_VIDEO_1) || (state == S_READ_VIDEO_3)} :
	cpu_addr[18:1];

assign oe_n = ~oe;
assign we_n = ~we;
assign cs_n = ~cs;

assign lb_n = state == S_WRITE_CPU ? cpu_addr[0] : 1'b0;
assign ub_n = state == S_WRITE_CPU ? ~cpu_addr[0] : 1'b0;

reg video_needs_data;

always @(negedge clk)
begin
	video_needs_data <= video_addr[18:3] != cur_video_addr;
end

always @(posedge clk)
begin
	cur_video_addr <= state == S_READ_VIDEO_1 ? video_addr[18:3] : cur_video_addr;

	cpu_dout <= state == S_READ_CPU_1 ? cpu_addr[0] ? d[15:8] : d[7:0] : cpu_dout;
	
	gpu_dout[15:0] <= state == S_READ_GPU_1 ? d : gpu_dout[15:0];
	gpu_dout[31:16] <= state == S_READ_GPU_2 ? d : gpu_dout[31:16];

	video_dout[15:0] <= state == S_READ_VIDEO_1 ? d : video_dout[15:0];
	video_dout[31:16] <= state == S_READ_VIDEO_2 ? d : video_dout[31:16];
	video_dout[47:32] <= state == S_READ_VIDEO_3 ? d : video_dout[47:32];
	video_dout[63:48] <= state == S_READ_VIDEO_4 ? d : video_dout[63:48];
	
	cpu_rdout <= state == S_READ_CPU_2 ? ~cpu_rdout : cpu_rdout;
	cpu_wrout <= state == S_WRITE_CPU ? ~cpu_wrout : cpu_wrout;

	gpu_rdout <= state == S_READ_GPU_2 ? ~gpu_rdout : gpu_rdout;
	gpu_wrout <= state == S_WRITE_GPU_1 ? ~gpu_wrout : gpu_wrout;
end

reg delay;

always @(posedge clk)
begin
	delay <= (cpu_wrin ^ cpu_wrout) || (cpu_rdin ^ cpu_rdout);
	case (state)
		S_IDLE:
			if (video_needs_data)
				state <= S_READ_VIDEO_0;
			else if (gpu_wrin ^ gpu_wrout)
				state <= S_WRITE_GPU_0;
			else if (gpu_rdin ^ gpu_rdout)
				state <= S_READ_GPU_0;
			else if ((cpu_wrin ^ cpu_wrout) && delay)
				state <= S_WRITE_CPU;
			else if ((cpu_rdin ^ cpu_rdout) && delay)
				state <= S_READ_CPU_0;
		S_READ_CPU_0:
			state <= S_READ_CPU_1;
		S_READ_CPU_1:
			state <= S_READ_CPU_2;
		S_READ_CPU_2:
			state <= S_IDLE;
		S_WRITE_CPU:
			state <= S_IDLE;
		S_READ_GPU_0:
			state <= S_READ_GPU_1;
		S_READ_GPU_1:
			state <= S_READ_GPU_2;
		S_READ_GPU_2:
			state <= S_IDLE;
		S_WRITE_GPU_0:
			state <= S_WRITE_GPU_1;
		S_WRITE_GPU_1:
			state <= S_IDLE;
		S_READ_VIDEO_0:
			state <= S_READ_VIDEO_1;
		S_READ_VIDEO_1:
			state <= S_READ_VIDEO_2;
		S_READ_VIDEO_2:
			state <= S_READ_VIDEO_3;
		S_READ_VIDEO_3:
			state <= S_READ_VIDEO_4;
		S_READ_VIDEO_4:
			state <= S_IDLE;
		default:
			state <= S_IDLE;
	endcase
end

endmodule
