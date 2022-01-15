

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USB for keyboard and mouse
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [15:0] usb1_dout;
wire usb1_wrin;
reg usb1_wrout;
wire usb1_rdin;
reg usb1_rdout;
USB_LS usb_ls1(
	.clk(inclk),
	.reset_n(reset_n),
	.dm(usb1dm),
	.dp(usb1dp),
	.din(cpu_d),
	.dout(usb1_dout),
	.wrin(usb1_wrout),
	.wrout(usb1_wrin),
	.rdin(usb1_rdout),
	.rdout(usb1_rdin),
	.soft_reset(usb1_reset)
);

wire [15:0] usb2_dout;
wire usb2_wrin;
reg usb2_wrout;
wire usb2_rdin;
reg usb2_rdout;
USB_LS usb_ls2(
	.clk(inclk),
	.reset_n(reset_n),
	.dm(usb2dm),
	.dp(usb2dp),
	.din(cpu_d),
	.dout(usb2_dout),
	.wrin(usb2_wrout),
	.wrout(usb2_wrin),
	.rdin(usb2_rdout),
	.rdout(usb2_rdin),
	.soft_reset(usb2_reset)
);



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// USB
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg [20:0] hidtimer;

always @(posedge inclk)
begin
	hidtimer <= hidtimer == 21'd2000000 ? 21'd0 : hidtimer + 21'd1;

	if (io_write_strobe_low && (cpu_a[11:0] == 12'h0B4))
		usb1_wrout <= ~usb1_wrout;
	if (io_read_strobe && (cpu_a[11:0] == 12'h0B4))
		usb1_rdout <= ~usb1_rdout;

	if (io_write_strobe_low && (cpu_a[11:0] == 12'h0B6))
		usb2_wrout <= ~usb2_wrout;
	if (io_read_strobe && (cpu_a[11:0] == 12'h0B6))
		usb2_rdout <= ~usb2_rdout;
end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// HID keyboard and mouse
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//wire irq1;
wire [7:0] keyb_dout;
wire keyb_full;
FIFO8 keyb_fifo(
	.clk(inclk),
	.reset_n(reset_n),
	.din(cpu_a[11:0] == 12'h060 ? 8'hFA : cpu_d[7:0]),
	.dout(keyb_dout),
	.wr(io_write_strobe_low && ((cpu_a[11:0] == 12'h09E) || (cpu_a[11:0] == 12'h060))),
	.next(io_read_strobe && (cpu_a[11:0] == 12'h060)),
	.irq(keyb_full)
	//.irq(irq1)
	);

reg [7:0] keyb_char;

reg [7:0] keyb_ctrl;

reg [7:0] keyb_shift;

reg keyb_shift_mode;

reg irq1;

reg [9:0] next_irq1;

always @(posedge inclk)
begin
	keyb_shift <= {keyb_shift[6:0], io_read_strobe && (cpu_a[11:0] == 12'h060)};

	keyb_ctrl <=
		io_read_strobe && (cpu_a[11:0] == 12'h061) ? {keyb_ctrl[7:6], ~keyb_ctrl[5:4], keyb_ctrl[3:0]} :
		io_write_strobe_high && (cpu_a[11:1] == (12'h060 >> 1)) ? cpu_d[15:8] :
		keyb_ctrl;

	keyb_shift_mode <=
		io_write_strobe_high && (cpu_a[11:1] == (12'h067 >> 1)) && cpu_d[15] ? ~keyb_shift_mode :
		keyb_shift_mode;

	keyb_char <=
		io_read_strobe && (cpu_a[11:0] == 12'h060) ? keyb_dout :
		keyb_char;
	
	next_irq1 <=
		|next_irq1 ? next_irq1 - 16'd1 :
		keyb_full ? 16'hFFFF :
		next_irq1;

	irq1 <=
		(~reset_n) ? 1'b0 :
		io_read_strobe && (cpu_a[11:0] == 12'h060) ? 1'b0 :
		(~|next_irq1) && (keyb_full) ? 1'b1 :
		io_write_strobe_high && (cpu_a[11:1] == (12'h060 >> 1)) && cpu_d[15] ? 1'b0 :
		/*
		io_write_strobe_low && (cpu_a[11:0] == 12'h09E) ? 1'b1 :
		*/
		irq1;

	COM1 <=
		(io_write_strobe_low && (cpu_a[11:0] == 12'h3FC)) ? 48'h4D4D4D4D4D4D :
		(io_write_strobe_low && (cpu_a[11:0] == 12'h3F8)) ? {COM1[39:0], cpu_d[7:0]} :
		(io_read_strobe && (cpu_a[11:0] == 12'h3F8)) ? {COM1[7:0], COM1[47:8]} :
		COM1;
		
	COM1fill <=
		~start3 ? 6'b000000 :
		(io_write_strobe_low && (cpu_a[11:0] == 12'h3FC)) ? 6'b111111 :
		(io_write_strobe_low && (cpu_a[11:0] == 12'h3F8)) ? {COM1fill[4:0], 1'b1} :
		(io_read_strobe && (cpu_a[11:0] == 12'h3F8)) ? {1'b0, COM1fill[5:1]} :
		COM1fill;

	com1regs[15:8] <= (io_write_strobe_high && (cpu_a[11:0] == 12'h3F9)) ? cpu_d[15:8] : com1regs[15:8];
	com1regs[23:16] <= (io_write_strobe_low && (cpu_a[11:0] == 12'h3FA)) ? cpu_d[7:0] : com1regs[23:16];
	com1regs[31:24] <= (io_write_strobe_high && (cpu_a[11:0] == 12'h3FB)) ? cpu_d[15:8] : com1regs[31:24];
	com1regs[39:32] <= (io_write_strobe_low && (cpu_a[11:0] == 12'h3FC)) ? cpu_d[7:0] : com1regs[39:32];
	com1regs[47:40] <= (io_write_strobe_high && (cpu_a[11:0] == 12'h3FD)) ? cpu_d[15:8] : com1regs[47:40];
	com1regs[55:48] <= (io_write_strobe_low && (cpu_a[11:0] == 12'h3FE)) ? cpu_d[7:0] : com1regs[55:48];
	com1regs[63:56] <= (io_write_strobe_high && (cpu_a[11:0] == 12'h3FF)) ? cpu_d[15:8] : com1regs[63:56];
end
