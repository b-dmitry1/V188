module Main(
	input wire clk,
	input wire reset_n,
	
	output wire led,
	
	// VGA
	output wire hsync,
	output wire vsync,
	
	output wire [3:0] red,
	output wire [3:0] green,
	output wire [3:0] blue,
	
	// HDMI
	output wire hdmi_rp,
	output wire hdmi_rm,
	output wire hdmi_gp,
	output wire hdmi_gm,
	output wire hdmi_bp,
	output wire hdmi_bm,
	output wire hdmi_cp,
	output wire hdmi_cm,
	
	// Audio
	output wire [1:0] audio_left,
	output wire [1:0] audio_right,
	
	// SDRAM
	output wire [12:0] sdram_a,
	output wire [1:0] sdram_ba,
	inout wire [15:0] sdram_d,
	output wire [1:0] sdram_dqm_n,
	output wire sdram_ras_n,
	output wire sdram_cas_n,
	output wire sdram_we_n,
	output wire sdram_cs_n,
	output wire sdram_sclk,
	output wire sdram_scke,
	
	// SRAM
	output wire [17:0] ram_a,
	inout wire [15:0] ram_d,
	output wire ram_cs_n,
	output wire ram_we_n,
	output wire ram_oe_n,
	output wire ram_lb_n,
	output wire ram_ub_n,
	
	// HC595 / leds
	output reg clk595,
	output wire dat595,
	output reg lat595,
	
	// SD-card
	output wire sd_cs_n,
	output wire sd_mosi,
	input wire sd_miso,
	output wire sd_sck,
	
	// USB
	inout wire dm1,
	inout wire dp1,
	inout wire dm2,
	inout wire dp2,
	
	// RS232
	input wire ch_txd,
	output wire ch_rxd
);

wire clk2;

reg [5:0] probe_div;
reg probe_clk;

always @(posedge clk60)
begin
	probe_div <= probe_div == 6'd39 ? 6'd0 : probe_div + 6'd1;
	
	probe_clk <= ~|probe_div;
end

wire probe_txd;
Probe probe(
	.clk(probe_clk),
	.inputs({dm2, dp2, dm1, dp1}),
	.txd(probe_txd)
	);


assign ch_rxd = com1txd;

assign com1rxd = ch_txd;

localparam
	S_IDLE = 3'd0,
	S_MREAD = 3'd1,
	S_MWRITE = 3'd2,
	S_IOREAD = 3'd3,
	S_IOWRITE = 3'd4,
	S_IOREAD2 = 3'd5;

reg [2:0] state;

reg [27:0] div;

assign led = com1txd;

reg [7:0] keyb_ctrl;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DMA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [23:0] dma1_addr;
wire [7:0] dma1_din;
wire dma1_rdin;
wire dma1_rdout;
wire [7:0] dma1_dout;
wire dma1_wrin;
wire dma1_wrout;
wire irq7;
DMA8 dma1(
	.clk(clk),
	.reset_n(reset_n),
	.port(port),
	.iodin(ciodout),
	.iowrin(ciowrout),
	
	.dma1_addr(dma1_addr),
	.dma1_din(dma1_din),
	.dma1_rdin(dma1_rdin),
	.dma1_rdout(dma1_rdout),
	
	.dma1_dout(dma1_dout),
	.dma1_wrin(dma1_wrin),
	.dma1_wrout(dma1_wrout),
	
	.irq7(irq7)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Fake AdLib
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [7:0] adlib_iodout;
wire adlib_ready;
wire [7:0] music;
AdLib adlib(
	.clk(clk),
	.reset_n(reset_n),
	
	.port(port),
	.iodin(ciodout),
	.iodout(adlib_iodout),
	.iowr(iowr),
	.ready(adlib_ready),
	
	.music(music)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SoundBlaster
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign audio_left = 2'b00;//pwm_left ? 2'b11 : 2'b00;
assign audio_right = {2{keyb_ctrl[1] && ((~keyb_ctrl[0]) | t2out) && (&speaker_pwm)}};

reg [1:0] speaker_pwm;

always @(posedge clk)
	speaker_pwm <= speaker_pwm + 1'd1;

wire [7:0] sb_iodout;
wire pwm_left;
SoundBlaster sb(
	.clk(clk),
	.reset_n(reset_n),
	
	.port(port),
	.iodin(ciodout),
	.iodout(sb_iodout),
	.iowrin(ciowrout),
	.iordin(ciordout),
	
	.dma_din(dma1_dout),
	.dma_rdin(dma1_wrout),
	.dma_rdout(dma1_wrin),
	
	.adlib_in(music),
	
	.pwm_left(pwm_left)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PLL
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire clk250;
wire clk_sdram;
wire clk_sram;
PLL1 pll1(.inclk0(clk), .c0(clk_sdram), .c1(clk250), .c2(clk_sram), .c3(clk2));

wire clk60;
PLL2 pll2(.inclk0(clk), .c0(clk60));

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// HC595
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg [7:0] data595;
reg [16:0] state595;
reg [7:0] shift595;

assign dat595 = shift595[7];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SDRAM
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [7:0] cpu_dout_sdram;
reg [7:0] cpu_din_sdram;
wire cpu_rdin_sdram;
reg  cpu_rdout_sdram;
wire cpu_wrin_sdram;
reg cpu_wrout_sdram;
wire sdram_cpu_addr_hit;

SDRAM sdram(.clk(clk), .clk1(clk_sdram), .reset_n(reset_n),
	.cpu_addr(ca), .cpu_din(cdout), .cpu_dout(cpu_dout_sdram), .cpu_addr_hit(sdram_cpu_addr_hit),
	.cpu_rdin(cpu_rdout_sdram), .cpu_rdout(cpu_rdin_sdram), .cpu_wrin(cpu_wrout_sdram), .cpu_wrout(cpu_wrin_sdram),

	.dma_addr(dma1_addr),
	.dma_dout(dma1_din),
	.dma_rdin(dma1_rdout),
	.dma_rdout(dma1_rdin),

	/*
	.video_addr(video_addr[23:3]), .video_dout(video_din),
	
	.gpu_addr(gpu_addr),
	.gpu_din(gpu_din),
	.gpu_dout(gpu_dout),
	.gpu_rdin(gpu_rdin),
	.gpu_rdout(gpu_rdout),
	.gpu_wrin(gpu_wrin),
	.gpu_wrout(gpu_wrout),
	*/
	
	.a(sdram_a), .ba(sdram_ba), .d(sdram_d), .ras_n(sdram_ras_n), .cas_n(sdram_cas_n), .we_n(sdram_we_n), .cs_n(sdram_cs_n),
	.sclk(sdram_sclk), .scke(sdram_scke), .dqm(sdram_dqm_n));

	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SRAM
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [7:0] cpu_dout_sram;
reg [7:0] cpu_din_sram;
wire cpu_rdin_sram;
reg  cpu_rdout_sram;
wire cpu_wrin_sram;
reg cpu_wrout_sram;

wire [23:0] gpu_addr;
wire [31:0] gpu_din;
wire [31:0] gpu_dout;
wire gpu_rdin;
wire gpu_rdout;
wire gpu_wrin;
wire gpu_wrout;

SRAM sram(.clk(clk_sram),
	.cpu_addr(ca), .cpu_din(cdout), .cpu_dout(cpu_dout_sram),
	.cpu_rdin(cpu_rdout_sram), .cpu_rdout(cpu_rdin_sram), .cpu_wrin(cpu_wrout_sram), .cpu_wrout(cpu_wrin_sram),
	.gpu_addr(gpu_addr), .gpu_din(gpu_din), .gpu_dout(gpu_dout),
	.gpu_rdin(gpu_rdin), .gpu_rdout(gpu_rdout), .gpu_wrin(gpu_wrin), .gpu_wrout(gpu_wrout),
	.video_addr(video_addr), .video_dout(video_din),
	.a(ram_a), .d(ram_d), .we_n(ram_we_n), .cs_n(ram_cs_n), .oe_n(ram_oe_n),
	.lb_n(ram_lb_n), .ub_n(ram_ub_n));

	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VGA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [23:0] video_addr;
wire [63:0] video_din;
wire [7:0] video_red;
wire [7:0] video_green;
wire [7:0] video_blue;
assign red = video_red[7:4];
assign green = video_green[7:4];
assign blue = video_blue[7:4];
wire [7:0] vga_iodout;
wire [7:0] vga_dout;
wire vga_ready;
wire vga_planar;
VGA vga(.clk(clk), .clk250(clk250), .reset_n(reset_n), .ready(vga_ready),
	.a(ca), .din(cdout), .dout(vga_dout), .mrdin(cmrdout), .mwrin(cmwrout),
	.port(port), .iodin(ciodout), .iowrin(ciowrin), .iodout(vga_iodout), .iordin(ciordin),
	.hsync(hsync), .vsync(vsync),
	.red(video_red), .green(video_green), .blue(video_blue),
	.video_addr(video_addr), .video_din(video_din),
	
	.gpu_addr(gpu_addr),
	.gpu_din(gpu_dout),
	.gpu_dout(gpu_din),
	.gpu_rdin(gpu_rdout),
	.gpu_rdout(gpu_rdin),
	.gpu_wrin(gpu_wrout),
	.gpu_wrout(gpu_wrin),
	
	.planar(vga_planar)
	
	// ,.hdmi_rp(hdmi_rp), .hdmi_rm(hdmi_rm), .hdmi_gp(hdmi_gp), .hdmi_gm(hdmi_gm), .hdmi_bp(hdmi_bp), .hdmi_bm(hdmi_bm), .hdmi_cp(hdmi_cp), .hdmi_cm(hdmi_cm)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PIT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire irq0;
wire t1out, t2out;
wire [7:0] pit_iodout;
PIT pit(
	.clk(clk),
	.reset_n(reset_n),
	
	.port(port),
	.iodin(ciodout),
	.iodout(pit_iodout),
	.iord(iord),
	.iowr(iowr),
	
	.irq0(irq0),
	.t1out(t1out),
	.t2out(t2out)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CPU
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire vram_access = ca[19:17] == 3'b101;
wire [19:0] ca;
wire [7:0] cdin = &ca[19:16] ? bios_out : vram_access ? vga_planar ? vga_dout : cpu_dout_sram : cpu_dout_sdram;
wire [7:0] cdout;
wire cmrdout;
wire cmwrout;
reg cmrdin;
reg cmwrin;

wire [7:0] ciodin = 
	port == 12'h060 ? usb1cout :
	port == 12'h061 ? {keyb_ctrl[7:6], t2out, t1out, keyb_ctrl[3:0]} :
	port == 12'h3DA ? {4'h0, div[20], 2'b00, div[13]} :
	port == 12'h064 ? {6'h00, irq1, 1'b0} :
	port[11:5] == 7'b0011110 ? vga_iodout :
	port[11:3] == 9'b001111111 ? com1_dout :
/*
	port == 12'h060 ? com1dout :
	port == 12'h061 ? {2'b0, t2out, t1out, keyb_ctrl[3:0]} :
	//port[11:4] == 8'h38 ? adlib_iodout :
	//port[11:4] == 8'h22 ? sb_iodout :
*/
	port == 12'h0B2 ? spi_out :
	port[11:4] == 8'h04 ? pit_iodout :
	8'hFF;

wire [7:0] ciodout;
wire ciordin1;
wire ciowrin1;
reg ciordin; always @(posedge clk) ciordin <= ciordin1;
reg ciowrin; always @(posedge clk) ciowrin <= ciowrin1;
reg ciordout;
reg ciowrout;
wire [7:0] cirqout;
wire [7:0] cirqin = {irq7, 2'b00, irq4, 2'b00, irq1, irq0};
wire [7:0] mcout;
wire [11:0] port;
wire ready =
	(cpu_rdin_sdram == cpu_rdout_sdram) && (cpu_wrin_sdram == cpu_wrout_sdram) &&
	(cpu_rdin_sram == cpu_rdout_sram) && (cpu_wrin_sram == cpu_wrout_sram) &&
	(vga_ready) &&
	(state == S_IDLE);
V188 cpu(
	.clk(clk2),
	.reset_n(reset_n),
	.a(ca),
	.dout(cdout),
	.din(cdin),
	.mrdout(cmrdout),
	.mwrout(cmwrout),
	.ready(ready),
	.port(port),
	.iodout(ciodout),
	.iodin(ciodin),
	.iordout(ciordin1),
	.iordin(ciordout),
	.iowrout(ciowrin1),
	.iowrin(ciowrout),
	.irqout(cirqout),
	.irqin(cirqin),
	.mcout(mcout)
);

wire iord = ciordin ^ iordout;
reg iordout;
wire iowr = ciowrin ^ iowrout;
reg iowrout;

always @(posedge clk)
begin
	iordout <= ciordin;
	iowrout <= ciowrin;
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BIOS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [7:0] bios_out;
BIOS bios(
	.clock(clk),
	.address(ca[12:0]),
	.q(bios_out)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SERIAL PORT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire com1txd;
reg com1wrout;
wire com1wrin;
wire com1rxd;
wire com1rdin;
wire [7:0] com1dout;
SerialPort com1(
	.clk(clk),
	.din(cdout),
	.dout(com1dout),
	.wrin(com1wrout),
	.wrout(com1wrin),
	.rdout(com1rdin),
	.txd(com1txd),
	.rxd(com1rxd)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPI
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [7:0] spi_out;
wire spi_ready;
SPI spi(
	.clk(clk2),
	.ioaddr(port),
	.din(ciodout),
	.dout(spi_out),
	.iowr(iows),
	.ready(spi_ready),
	.cs_n(sd_cs_n),
	.miso(sd_miso),
	.mosi(sd_mosi),
	.sck(sd_sck)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PIT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USB 1
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [7:0] usb1cout;
wire [7:0] usb1mcout;
wire usb1mwrc;
reg usb1mwrcout;

wire irq1;
USB usb1(
	.clk(clk),
	.clk60(clk60),
	.reset_n(reset_n),
	
	.dout1(usb1cout),
	
	.irq(irq1),
	.irqin(cirqout[1]),
	
	.dout2(usb1mcout),
	.wr2(usb1mwrc),
	.wr2in(usb1mwrcout),
	
	.keyb_latch(keyb_ctrl[7]),
	
	.mouse(1'b1),
	
	.dp(dp1),
	.dm(dm1)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USB mouse - COM1
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

reg [7:0] com1_dout;

always @*
begin
	case (port[2:0])
		3'd0: com1_dout <= COM1[47:40];
		3'd1: com1_dout <= com1regs[15:8];
		3'd2: com1_dout <= com1regs[23:16];
		3'd3: com1_dout <= com1regs[31:24];
		3'd4: com1_dout <= com1regs[39:32];
		3'd5: com1_dout <= {com1regs[47:41], 1'b1};
		3'd6: com1_dout <= com1regs[55:48];
		default: com1_dout <= com1regs[63:56];
	endcase
end

reg [47:0] COM1;
reg [5:0] COM1fill;

reg [63:0] com1regs;

reg irq4;


always @(posedge clk2)
begin
	COM1 <=
		((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FC)) ? 48'h4D4D4D4D4D4D :
		(usb1mwrc ^ usb1mwrcout) ? {COM1[39:0], usb1mcout[7:0]} :
		((state == S_IOREAD) && (port[11:0] == 12'h3F8)) ? {COM1[7:0], COM1[47:8]} :
		COM1;
		
	COM1fill <=
		((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FC)) ? 6'b111111 :
		(usb1mwrc ^ usb1mwrcout) ? {COM1fill[4:0], 1'b1} :
		((state == S_IOREAD) && (port[11:0] == 12'h3F8)) ? {1'b0, COM1fill[5:1]} :
		COM1fill;

	if (|COM1fill)
		irq4 <= ~cirqout[4];
	else
		irq4 <= cirqout[4];
	
	usb1mwrcout <= usb1mwrc;
	
	com1regs[15:8] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3F9)) ? ciodout : com1regs[15:8];
	com1regs[23:16] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FA)) ? ciodout : com1regs[23:16];
	com1regs[31:24] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FB)) ? ciodout : com1regs[31:24];
	com1regs[39:32] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FC)) ? ciodout : com1regs[39:32];
	com1regs[47:40] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FD)) ? ciodout : com1regs[47:40];
	com1regs[55:48] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FE)) ? ciodout : com1regs[55:48];
	com1regs[63:56] <= ((ciowrout ^ ciowrin) && (port[11:0] == 12'h3FF)) ? ciodout : com1regs[63:56];
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MAIN
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

reg last_iow;
wire iows = {last_iow, ciowrin ^ ciowrout} == 2'b01;
wire [1:0] ior = {ior[0], ciordin ^ ciordout};
wire iors = ior == 2'b01;

always @(posedge clk2)
begin
	div <= div + 28'd1;

	last_iow <= ciowrin ^ ciowrout;
	
	case (state)
		S_IDLE:
		begin
			if (cmrdout ^ cmrdin)
			begin
				if (vram_access)
				begin
					if (~vga_planar)
						cpu_rdout_sram <= ~cpu_rdout_sram;
				end
				else if (~sdram_cpu_addr_hit)
					cpu_rdout_sdram <= ~cpu_rdout_sdram;
				state <= S_MREAD;
			end
			if (cmwrout ^ cmwrin)
			begin
				if (vram_access)
				begin
					if (~vga_planar)
						cpu_wrout_sram <= ~cpu_wrout_sram;
				end
				else
					cpu_wrout_sdram <= ~cpu_wrout_sdram;
				state <= S_MWRITE;
			end
			if (ciordout ^ ciordin)
			begin
				state <= S_IOREAD;
			end
			if (ciowrout ^ ciowrin)
			begin
				if (port == 12'hBC)
					com1wrout <= ~com1wrout;
				if (port == 12'h61)
					keyb_ctrl <= ciodout;
	
				state <= S_IOWRITE;
			end
		end
		S_MREAD:
		begin
			if ((cpu_rdout_sdram == cpu_rdin_sdram) && (cpu_rdout_sram == cpu_rdin_sram) && (vga_ready))
			begin
				cmrdin <= ~cmrdin;
				state <= S_IDLE;
			end
		end
		S_MWRITE:
		begin
			if ((cpu_wrout_sdram == cpu_wrin_sdram) && (cpu_wrout_sram == cpu_wrin_sram) && (vga_ready))
			begin
				cmwrin <= ~cmwrin;
				state <= S_IDLE;
			end
		end
		S_IOREAD:
			if (vga_ready)
				state <= S_IOREAD2;
		S_IOREAD2:
			if (vga_ready && adlib_ready)
			begin
				ciordout <= ~ciordout;
				state <= S_IDLE;
			end
		S_IOWRITE:
			if ((com1wrout == com1wrin) && (spi_ready))
			begin
				ciowrout <= ~ciowrout;
				state <= S_IDLE;
			end
		default:
			state <= S_IDLE;
	endcase

	data595 <= ~{dm1, dp1, dm2, dp2, gpu_rdin, 1'b0, com1rxd};//~mcout;//{ca[7:0]/*cpu_rdin_sdram, cpu_rdout_sdram, cpu_wrin_sdram, cpu_wrout_sdram*/};
	
	state595 <= |state595 ? {state595[15:0], 1'b0} : 17'd1;
	
	clk595 <= (state595[1] | state595[3] | state595[5] | state595[7] | state595[9] | state595[11] | state595[13] | state595[15]);
	lat595 <= state595[16];

	shift595 <= ~|state595 ? data595 : clk595 ? {shift595[6:0], shift595[7]} : shift595;
end

endmodule
