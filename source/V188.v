module V188(
	input wire clk,
	input wire reset_n,
	
	output wire [19:0] a,
	output wire [7:0] dout,
	input wire [7:0] din,
	output reg mrdout,
	output reg mwrout,
	
	input wire ready,
	
	output reg [11:0] port,
	output wire [7:0] iodout,
	input wire [7:0] iodin,
	output reg iordout,
	input wire iordin,
	output reg iowrout,
	input wire iowrin,
	
	output reg [7:0] irqout,
	input wire [7:0] irqin,
	
	output wire [7:0] mcout
);

assign mcout = opcode;//mc[7:0];

localparam
	S_EXECUTE = 1 << 0,
	S_FETCH = 1 << 1,
	S_FETCHMODRM = 1 << 2,
	S_DECODEMODRM = 1 << 3,
	S_OPCODE = 1 << 4,
	S_MODRM = 1 << 5,
	S_MODRM_DECODE = 1 << 6,
	S_MODRM_D8 = 1 << 7,
	S_MODRM_D16 = 1 << 8,
	S_MODRM_D16_HIGH = 1 << 9,
	S_DECODE = 1 << 10,
	S_DIV = 1 << 11,
	S_READ_HIGH = 1 << 12,
	S_READ = 1 << 13,
	S_WRITE_HIGH = 1 << 14,
	S_WRITE = 1 << 15,
	S_FETCH_D8 = 1 << 16,
	S_FETCH_D16 = 1 << 17,
	S_PUSH = 1 << 20,
	S_PUSH_HIGH = 1 << 21,
	S_POP = 1 << 22,
	S_POP_HIGH = 1 << 23,
	S_READ_IO = 1 << 24,
	S_WRITE_IO = 1 << 25,
	S_READ_IO2 = 1 << 26,
	S_WRITE_IO2 = 1 << 27,
	S_HLT = 1 << 28;

localparam
	F_C = 0,
	F_P = 2,
	F_A = 4,
	F_Z = 6,
	F_S = 7,
	F_T = 8,
	F_I = 9,
	F_D = 10,
	F_O = 11;


assign a =
	((state == S_READ_HIGH) || (state == S_WRITE_HIGH)) ? {seg, 4'h0} + ofshigh :
	((state == S_READ) || (state == S_WRITE)) ? {seg, 4'h0} + ofs :
	((state == S_PUSH) || (state == S_PUSH_HIGH) || (state == S_POP) || (state == S_POP_HIGH)) ? {ss, 4'h0} + sp :
	{cs, 4'h0} + ip;

assign dout =
	(state == S_WRITE_HIGH) || (state == S_PUSH) ? stack[63:56] : stack[55:48];

assign iodout = stack[55:48];

reg [15:0] ax; reg [15:0] cx; reg [15:0] dx; reg [15:0] bx;
reg [15:0] sp; reg [15:0] bp; reg [15:0] si; reg [15:0] di;
reg [15:0] es; reg [15:0] cs; reg [15:0] ss; reg [15:0] ds;
reg [15:0] fs; reg [15:0] gs; reg [15:0] flags; reg [15:0] ip;

reg [28:0] state;

reg [7:0] opcode;
reg [7:0] modrm;
reg [15:0] seg;
reg [15:0] sseg;
reg [15:0] saveseg;
reg [15:0] ofs;
wire [15:0] ofshigh = ofs + 16'd1;
reg [7:0] low;

reg repz;
reg repnz;

reg [3:0] aluop;

reg [5:0] aluflags;

reg [63:0] stack;

reg irqs_enabled;

reg [11:0] mip;
wire [17:0] mout;
reg [17:0] mc;
reg [15:0] imm;
MICROCODE mcode(
	.clock(clk),
	.address_a(mip),
	.q_a(mout));

//////////////////////////////////////////////////////////////////////////////////
// MOD R/M REG
//////////////////////////////////////////////////////////////////////////////////
reg [7:0] mod_greg8;
always @*
begin
	case (modrm[5:3])
		3'd0: mod_greg8 <= ax[7:0];
		3'd1: mod_greg8 <= cx[7:0];
		3'd2: mod_greg8 <= dx[7:0];
		3'd3: mod_greg8 <= bx[7:0];
		3'd4: mod_greg8 <= ax[15:8];
		3'd5: mod_greg8 <= cx[15:8];
		3'd6: mod_greg8 <= dx[15:8];
		3'd7: mod_greg8 <= bx[15:8];
	endcase
end

reg [15:0] mod_greg16;
always @*
begin
	case (modrm[5:3])
		3'd0: mod_greg16 <= ax;
		3'd1: mod_greg16 <= cx;
		3'd2: mod_greg16 <= dx;
		3'd3: mod_greg16 <= bx;
		3'd4: mod_greg16 <= sp;
		3'd5: mod_greg16 <= bp;
		3'd6: mod_greg16 <= si;
		3'd7: mod_greg16 <= di;
	endcase
end

reg [7:0] mod_ereg8;
always @*
begin
	case (modrm[2:0])
		3'd0: mod_ereg8 <= ax[7:0];
		3'd1: mod_ereg8 <= cx[7:0];
		3'd2: mod_ereg8 <= dx[7:0];
		3'd3: mod_ereg8 <= bx[7:0];
		3'd4: mod_ereg8 <= ax[15:8];
		3'd5: mod_ereg8 <= cx[15:8];
		3'd6: mod_ereg8 <= dx[15:8];
		3'd7: mod_ereg8 <= bx[15:8];
	endcase
end

reg [15:0] mod_ereg16;
always @*
begin
	case (modrm[2:0])
		3'd0: mod_ereg16 <= ax;
		3'd1: mod_ereg16 <= cx;
		3'd2: mod_ereg16 <= dx;
		3'd3: mod_ereg16 <= bx;
		3'd4: mod_ereg16 <= sp;
		3'd5: mod_ereg16 <= bp;
		3'd6: mod_ereg16 <= si;
		3'd7: mod_ereg16 <= di;
	endcase
end

reg [15:0] mod_sreg;
always @*
begin
	case (modrm[4:3])
		2'd0: mod_sreg <= es;
		2'd1: mod_sreg <= cs;
		2'd2: mod_sreg <= ss;
		2'd3: mod_sreg <= ds;
	endcase
end

reg [15:0] mc_reg8;
always @*
begin
	case (mout[2:0])
		3'd0: mc_reg8 <= {8'h00, ax[7:0]};
		3'd1: mc_reg8 <= {8'h00, cx[7:0]};
		3'd2: mc_reg8 <= {8'h00, dx[7:0]};
		3'd3: mc_reg8 <= {8'h00, bx[7:0]};
		3'd4: mc_reg8 <= {8'h00, ax[15:8]};
		3'd5: mc_reg8 <= {8'h00, cx[15:8]};
		3'd6: mc_reg8 <= {8'h00, dx[15:8]};
		3'd7: mc_reg8 <= {8'h00, bx[15:8]};
	endcase
end

reg [15:0] mc_reg16;
always @*
begin
	case (mout[3:0])
		4'd0: mc_reg16 <= ax;
		4'd1: mc_reg16 <= cx;
		4'd2: mc_reg16 <= dx;
		4'd3: mc_reg16 <= bx;
		4'd4: mc_reg16 <= sp;
		4'd5: mc_reg16 <= bp;
		4'd6: mc_reg16 <= si;
		4'd7: mc_reg16 <= di;
		4'd8: mc_reg16 <= es;
		4'd9: mc_reg16 <= cs;
		4'd10: mc_reg16 <= ss;
		4'd11: mc_reg16 <= ds;
		4'd12: mc_reg16 <= fs;
		4'd13: mc_reg16 <= gs;
		4'd14: mc_reg16 <= flags;
		4'd15: mc_reg16 <= ip;
	endcase
end

//////////////////////////////////////////////////////////////////////////////////
// ALU8
//////////////////////////////////////////////////////////////////////////////////
reg [8:0] alu8res;
reg alu8s;
reg alu8z;
reg alu8p;
wire alu8c = alu8res[8];
reg alu8a;
reg alu8o;
wire [7:0] alu8a1 = stack[55:48];
wire [7:0] alu8a2 = stack[7:0];

always @*
begin
	case (aluop)
		4'h0: begin alu8res = alu8a1 + alu8a2; alu8o = (alu8res[7] ^ alu8a1[7]) & (alu8res[7] ^ alu8a2[7]); end // add
		4'h2: begin alu8res = alu8a1 - alu8a2; alu8o = (alu8res[7] ^ alu8a1[7]) & (alu8a1[7] ^ alu8a2[7]); end // sub
		4'h4: begin alu8res = {1'b0, alu8a1 & alu8a2}; alu8o = 1'b0; end // and
		4'h5: begin alu8res = {1'b0, alu8a1 | alu8a2}; alu8o = 1'b0; end // or
		4'h6: begin alu8res = {1'b0, alu8a1 ^ alu8a2}; alu8o = 1'b0; end // xor
		4'h7: begin alu8res = {alu8a1, 1'b0}; alu8o = alu8a1[7] ^ alu8a1[6]; end // shl
		4'h8: begin alu8res = {alu8a1[0], 1'b0, alu8a1[7:1]}; alu8o = alu8a1[7]; end // shr
		4'h9: begin alu8res = {alu8a1[0], alu8a1[7], alu8a1[7:1]}; alu8o = 1'b0; end // sar
		4'hA: begin alu8res = {alu8a1, alu8a1[7]}; alu8o = alu8a1[7] ^ alu8a1[6]; end // rol
		4'hB: begin alu8res = {alu8a1[0], alu8a1[0], alu8a1[7:1]}; alu8o = alu8res[7] ^ alu8res[6]; end // ror
		4'hC: begin alu8res = {alu8a1, flags[F_C]}; alu8o = alu8a1[7] ^ alu8a1[6]; end // rcl
		4'hD: begin alu8res = {alu8a1[0], flags[F_C], alu8a1[7:1]}; alu8o = alu8res[7] ^ alu8res[6]; end // rcr
		default: begin alu8res = 9'h00; alu8o = 1'b0; end
	endcase
	alu8z = ~|alu8res[7:0];
	alu8s = alu8res[7];
	alu8p = ~^alu8res[7:0];
	alu8a = alu8res[4] ^ alu8a1[4] ^ alu8a2[4];
end

//////////////////////////////////////////////////////////////////////////////////
// ALU16
//////////////////////////////////////////////////////////////////////////////////
reg [16:0] alu16res;
reg alu16s;
reg alu16z;
reg alu16p;
wire alu16c = alu16res[16];
reg alu16a;
reg alu16o;
wire [15:0] alu16a1 = stack[63:48];
wire [15:0] alu16a2 = stack[15:0];

always @*
begin
	case (aluop)
		4'h0: begin alu16res = alu16a1 + alu16a2; alu16o = (alu16res[15] ^ alu16a1[15]) & (alu16res[15] ^ alu16a2[15]); end // add
		4'h2: begin alu16res = alu16a1 - alu16a2; alu16o = (alu16res[15] ^ alu16a1[15]) & (alu16a1[15] ^ alu16a2[15]); end // sub
		4'h4: begin alu16res = {1'b0, alu16a1 & alu16a2}; alu16o = 1'b0; end // and
		4'h5: begin alu16res = {1'b0, alu16a1 | alu16a2}; alu16o = 1'b0; end // or
		4'h6: begin alu16res = {1'b0, alu16a1 ^ alu16a2}; alu16o = 1'b0; end // xor
		4'h7: begin alu16res = {alu16a1, 1'b0}; alu16o = alu16a1[15] ^ alu16a1[14]; end // shl
		4'h8: begin alu16res = {alu16a1[0], 1'b0, alu16a1[15:1]}; alu16o = alu16a1[15]; end // shr
		4'h9: begin alu16res = {alu16a1[0], alu16a1[15], alu16a1[15:1]}; alu16o = 1'b0; end // sar
		4'hA: begin alu16res = {alu16a1, alu16a1[15]}; alu16o = alu16a1[15] ^ alu16a1[14]; end // rol
		4'hB: begin alu16res = {alu16a1[0], alu16a1[0], alu16a1[15:1]}; alu16o = alu16res[15] ^ alu16res[14]; end // ror
		4'hC: begin alu16res = {alu16a1, flags[F_C]}; alu16o = alu16a1[15] ^ alu16a1[14]; end // rcl
		4'hD: begin alu16res = {alu16a1[0], flags[F_C], alu16a1[15:1]}; alu16o = alu16res[15] ^ alu16res[14]; end // rcr
		default: begin alu16res = 17'h00; alu16o = 1'b0; end
	endcase
	alu16z = ~|alu16res[15:0];
	alu16s = alu16res[15];
	alu16p = ~^alu16res[7:0];
	alu16a = alu16res[4] ^ alu16a1[4] ^ alu16a2[4];
end

wire [31:0] mulresult;
Mul1 mul(
	.clock(clk),
	.dataa(stack[15:0]),
	.datab(stack[31:16]),
	.result(mulresult)
);

wire [31:0] imulresult;
SignedMul imul(
	.clock(clk),
	.dataa(stack[15:0]),
	.datab(stack[31:16]),
	.result(imulresult)
);

reg div_run_out;
wire div_run_in;
wire [15:0] div_q;
wire [15:0] div_r;
MyDiv div(
	.clk(clk),
	.denom(stack[31:0]),
	.num(stack[47:32]),
	.q(div_q),
	.r(div_r),
	.run_in(div_run_out),
	.run_out(div_run_in),
	.signed_div(mc[7])
);

//////////////////////////////////////////////////////////////////////////////////
// CPU
//////////////////////////////////////////////////////////////////////////////////
always @(negedge clk or negedge reset_n)
begin
	if (~reset_n)
	begin
		mip <= 12'd0;
		mc <= 18'd0;
		state <= S_EXECUTE;
	end
	else
	begin
		case (state)
			S_EXECUTE:
			begin
				state <= S_FETCH;
				casex (mc)
					18'b00_xxxx_0000_xxxx_0000: // reset
					begin
						cs <= 16'hFFFF;
						ip <= 16'h0000;
						flags <= 16'hF002;
						mrdout <= ~mrdout;
						state <= S_OPCODE;
					end

					18'b00_xxxx_0000_xxxx_0111: // dup
						stack[15:0] <= stack[31:16];

					18'b00_xxxx_0000_xxxx_0101: // jmptable
						mip <= mip + modrm[5:3];
					
					18'b00_xxxx_0001_xxxx_0000: // setofs
						ofs <= stack[63:48];
					18'b00_xxxx_0001_xxxx_0001: // getofs
						stack[15:0] <= ofs;
					18'b00_xxxx_0001_xxxx_0010: // setseg, overrideseg
					begin
						if (mc[4])
							sseg <= stack[63:48];
						seg <= stack[63:48];
					end
					18'b00_xxxx_0001_xxxx_0110: // imul, idiv
					begin
						if (mc[4])
							stack[31:0] <= mulresult;
						if (mc[5])
						begin
							if (stack[47:32] != 16'd0)
							begin
								div_run_out <= ~div_run_out;
								state <= S_DIV;
							end
							else
								mip <= 12'd256;
						end
						if (mc[6])
							stack[31:0] <= imulresult;
						if (mc[7])
						begin
							if (stack[47:32] != 16'd0)
							begin
								div_run_out <= ~div_run_out;
								state <= S_DIV;
							end
							else
								mip <= 12'd256;
						end
					end
					
					
					18'b00_xxxx_0010_xxxx_0010: // storee8
					begin
						if (modrm[7:6] != 2'b11)
						begin
							mwrout <= ~mwrout;
							state <= S_WRITE;
						end
						else
						begin
							case (modrm[2:0])
								3'b000: ax[7:0] <= stack[55:48];
								3'b001: cx[7:0] <= stack[55:48];
								3'b010: dx[7:0] <= stack[55:48];
								3'b011: bx[7:0] <= stack[55:48];
								3'b100: ax[15:8] <= stack[55:48];
								3'b101: cx[15:8] <= stack[55:48];
								3'b110: dx[15:8] <= stack[55:48];
								3'b111: bx[15:8] <= stack[55:48];
							endcase
						end
					end
					18'b00_xxxx_0010_xxxx_0011: // storee16
					begin
						if (&modrm[7:6])
						begin
							case (modrm[2:0])
								3'b000: ax <= stack[63:48];
								3'b001: cx <= stack[63:48];
								3'b010: dx <= stack[63:48];
								3'b011: bx <= stack[63:48];
								3'b100: sp <= stack[63:48];
								3'b101: bp <= stack[63:48];
								3'b110: si <= stack[63:48];
								3'b111: di <= stack[63:48];
							endcase
						end
						else
						begin
							mwrout <= ~mwrout;
							state <= S_WRITE;
						end
					end
					
					
					
					18'b00_xxxx_0010_xxxx_1000: // loadsreg
						stack[15:0] <= mod_sreg;
					18'b00_xxxx_0010_xxxx_1001: // storesreg
						case (modrm[4:3])
							2'd0: es <= stack[63:48];
							2'd1: cs <= stack[63:48];
							2'd2: ss <= stack[63:48];
							2'd3: ds <= stack[63:48];
						endcase
					
					18'b00_xxxx_0100_xxxx_xxxx: // alu8
					begin
						stack[15:0] <= {8'h00, alu8res[7:0]};
						aluflags <= {alu8o, alu8s, alu8z, alu8a, alu8p, alu8c};
					end
					18'b00_xxxx_0101_xxxx_xxxx: // alu16
					begin
						stack[15:0] <= {alu16res[15:0]};
						aluflags <= {alu16o, alu16s, alu16z, alu16a, alu16p, alu16c};
					end

					
					
					
					18'b01_xx10_xxxx_xxxx_xxxx: // testflags
						stack[15:0] <= flags & mc[11:0];
					
					18'b10_0100_xxxx_xxxx_xxxx: // jrep
						if (repz | repnz)
							mip <= mc[11:0];
					18'b10_0101_xxxx_xxxx_xxxx: // jrepz
						if (repz)
							mip <= mc[11:0];
					18'b10_0110_xxxx_xxxx_xxxx: // jrepnz
						if (repnz)
							mip <= mc[11:0];
					
				endcase
			end
			S_FETCH:
			begin
				casex (mout[17:14])
					4'b0x01,
					4'b1011:
						stack <= {stack[15:0], stack[63:16]};
					4'b0x10,
					4'b11xx:
						stack <= {stack[47:0], stack[63:48]};
					4'b0011:
						stack[31:0] <= {stack[15:0], stack[31:16]};
				endcase
				
				casex (mout[17:0])
					18'b10_0000_xxxx_xxxx_xxxx: // jmp
						mip <= mout[11:0];

						
					18'b10_1101_xxxx_xxxx_xxxx: // jnz
						if (|stack[15:0])
							mip <= mout[11:0];
						else
							mip <= mip + 12'd1;
							
					18'b10_1110_xxxx_xxxx_xxxx: // jz
						if (~|stack[15:0])
							mip <= mout[11:0];
						else
							mip <= mip + 12'd1;

					18'b00_xxxx_0000_xxxx_0001: // end
					begin
						if (irqs_enabled && flags[F_I] && (irqin[0] ^ irqout[0]))
						begin
							mip <= 12'd264;
						end
						else
						if (irqs_enabled && flags[F_I] && (irqin[1] ^ irqout[1]))
						begin
							mip <= 12'd265;
						end
						else
						if (irqs_enabled && flags[F_I] && (irqin[4] ^ irqout[4]))
						begin
							mip <= 12'd268;
						end
						else
						if (irqs_enabled && flags[F_I] && (irqin[7] ^ irqout[7]))
						begin
							mip <= 12'd271;
						end
						else
							mip <= mip + 12'd1;
					end
					
					default:
						mip <= mip + 12'd1;
				endcase

				casex (mout[17:0])
					18'b10_0000_xxxx_xxxx_xxxx: // jmp
						;
					
					18'b10_1101_xxxx_xxxx_xxxx: // jnz
						;
					18'b10_1110_xxxx_xxxx_xxxx: // jz
						;

					18'b00_xxxx_0010_xxxx_0100: // loadg8
						stack[15:0] <= {8'h00, mod_greg8};
					18'b00_xxxx_0010_xxxx_0101: // loadg16
						stack[15:0] <= mod_greg16;
					
					
					18'b00_xxxx_0010_xxxx_0110: // storeg8
						case (modrm[5:3])
							3'd0: ax[7:0] <= stack[7:0];
							3'd1: cx[7:0] <= stack[7:0];
							3'd2: dx[7:0] <= stack[7:0];
							3'd3: bx[7:0] <= stack[7:0];
							3'd4: ax[15:8] <= stack[7:0];
							3'd5: cx[15:8] <= stack[7:0];
							3'd6: dx[15:8] <= stack[7:0];
							3'd7: bx[15:8] <= stack[7:0];
						endcase
					18'b00_xxxx_0010_xxxx_0111: // storeg16
						case (modrm[5:3])
							3'd0: ax <= stack[15:0];
							3'd1: cx <= stack[15:0];
							3'd2: dx <= stack[15:0];
							3'd3: bx <= stack[15:0];
							3'd4: sp <= stack[15:0];
							3'd5: bp <= stack[15:0];
							3'd6: si <= stack[15:0];
							3'd7: di <= stack[15:0];
						endcase


					18'b00_xxxx_0001_xxxx_0011: // getseg
						stack[15:0] <= seg;
					18'b00_xxxx_0001_xxxx_0100: // saveseg / and set es:di
					begin
						saveseg <= seg;
						if (mout[4])
						begin
							seg <= es;
							ofs <= di;
						end
					end
					18'b00_xxxx_0001_xxxx_0101: // restseg
						seg <= saveseg;
										
					18'b00_xxxx_0001_xxxx_1000: // read8
					begin
						mrdout <= ~mrdout;
						state <= S_READ;
					end
					18'b00_xxxx_0001_xxxx_1001: // read16
					begin
						mrdout <= ~mrdout;
						state <= S_READ;
					end
					18'b00_xxxx_0001_xxxx_1010: // write8
					begin
						mwrout <= ~mwrout;
						state <= S_WRITE;
					end
					18'b00_xxxx_0001_xxxx_1011: // write16
					begin
						mwrout <= ~mwrout;
						state <= S_WRITE;
					end
					18'b00_xxxx_0001_xxxx_1100: // readio8
					begin
						iordout <= ~iordout;
						state <= S_READ_IO;
					end
					18'b00_xxxx_0001_xxxx_1110: // writeio8
					begin
						iowrout <= ~iowrout;
						state <= S_WRITE_IO;
					end
					
					18'b00_xxxx_0010_xxxx_0000: // loade8
						if (&modrm[7:6])
							stack[15:0] <= {8'h00, mod_ereg8};
						else
						begin
							mrdout <= ~mrdout;
							state <= S_READ;
						end
					18'b00_xxxx_0010_xxxx_0001: // loade16
						if (&modrm[7:6])
							stack[15:0] <= mod_ereg16;
						else
						begin
							mrdout <= ~mrdout;
							state <= S_READ;
						end

					18'b00_xxxx_0000_xxxx_1011: // nop, stackleft, stackright, swap, setrep
					begin
						if (mout[4])
							repz <= 1'b1;
						if (mout[5])
							repnz <= 1'b1;
						if (mout[6])
							state <= S_HLT;
					end
					18'b00_xxxx_0000_xxxx_1100: // push
					begin
						sp <= sp - 16'd1;
						mwrout <= ~mwrout;
						state <= S_PUSH;
					end
					18'b00_xxxx_0000_xxxx_1101: // pop
					begin
						mrdout <= ~mrdout;
						state <= S_POP;
					end
					18'b00_xxxx_0000_xxxx_1110: // adv_si, adv_di
					begin
						if (mout[4])
							si <= flags[F_D] ? si - 16'd1 : si + 16'd1;
						if (mout[5])
							di <= flags[F_D] ? di - 16'd1 : di + 16'd1;
					end

					18'b00_xxxx_0000_xxxx_0110: // setioport
						port <= stack[11:0];
					
					18'b00_xxxx_0000_xxxx_1000: // fetch8
					begin
						mrdout <= ~mrdout;
						state <= S_FETCH_D8;
					end
					18'b00_xxxx_0000_xxxx_1001: // fetch16
					begin
						mrdout <= ~mrdout;
						state <= S_FETCH_D8;
					end
					
					18'b00_xxxx_0000_xxxx_1010: // dec_cx
						cx <= cx - 16'd1;

					18'b00_xxxx_0000_xxxx_0010: // end prefix
					begin
						state <= S_OPCODE;
						mrdout <= ~mrdout;
					end
					
					18'b00_xxxx_0000_xxxx_0001: // end
					begin
						repnz <= 1'b0;
						repz <= 1'b0;
						seg <= ds;
						sseg <= ss;

						if (irqs_enabled && flags[F_I] && (irqin[0] ^ irqout[0]))
						begin
							irqs_enabled <= 1'b0;
							irqout[0] <= ~irqout[0];
						end
						else
						if (irqs_enabled && flags[F_I] && (irqin[1] ^ irqout[1]))
						begin
							irqs_enabled <= 1'b0;
							irqout[1] <= ~irqout[1];
						end
						else
						if (irqs_enabled && flags[F_I] && (irqin[4] ^ irqout[4]))
						begin
							irqs_enabled <= 1'b0;
							irqout[4] <= ~irqout[4];
						end
						else
						if (irqs_enabled && flags[F_I] && (irqin[7] ^ irqout[7]))
						begin
							irqs_enabled <= 1'b0;
							irqout[7] <= ~irqout[7];
						end
						else
						begin
							state <= S_OPCODE;
							mrdout <= ~mrdout;
						end
					end
											
					18'b01_xx00_xxxx_xxxx_xxxx: // addflags
						flags <= flags | mout[11:0];
					18'b01_xx01_xxxx_xxxx_xxxx: // removeflags
						flags <= flags & ~mout[11:0];

					18'b00_xxxx_0000_xxxx_0011: // modrm
					begin
						state <= S_MODRM;
						mrdout <= ~mrdout;
					end
					
					18'b00_xxxx_0000_xxxx_0100: // signext
						stack[15:8] <= {8{stack[7]}};

					18'b00_xxxx_0000_xxxx_1111: // addip
						ip <= ip + stack[15:0];

					18'b11_xxxx_xxxx_xxxx_xxxx: // loadimm
					begin
						stack[15:0] <= mout[15:0];
						//mip <= mip + 12'd1;
					end
						
					18'b01_xx11_xxxx_xxxx_xxxx: // setaluflags
					begin
						flags[F_C] <= mout[F_C] ? aluflags[0] : flags[F_C];
						flags[F_P] <= mout[F_P] ? aluflags[1] : flags[F_P];
						flags[F_A] <= mout[F_A] ? aluflags[2] : flags[F_A];
						flags[F_Z] <= mout[F_Z] ? aluflags[3] : flags[F_Z];
						flags[F_S] <= mout[F_S] ? aluflags[4] : flags[F_S];
						flags[F_O] <= mout[F_O] ? aluflags[5] : flags[F_O];
						//mip <= mip + 12'd1;
					end

					18'b00_xxxx_1000_xxxx_xxxx: // loadreg8
					begin
						stack[15:0] <= mc_reg8;
						//mip <= mip + 12'd1;
					end
					
					
					18'b00_xxxx_1001_xxxx_xxxx: // loadreg16
					begin
						stack[15:0] <= mc_reg16;
						//mip <= mip + 12'd1;
					end
						
						
					18'b00_xxxx_1010_xxxx_0000: // storereg8
						ax[7:0] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0001:
						cx[7:0] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0010:
						dx[7:0] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0011:
						bx[7:0] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0100:
						ax[15:8] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0101:
						cx[15:8] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0110:
						dx[15:8] <= stack[7:0];
					18'b00_xxxx_1010_xxxx_0111:
						bx[15:8] <= stack[7:0];
						
					
					18'b00_xxxx_1011_xxxx_0000: // storereg16
						ax <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0001:
						cx <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0010:
						dx <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0011:
						bx <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0100:
						sp <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0101:
						bp <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0110:
						si <= stack[15:0];
					18'b00_xxxx_1011_xxxx_0111:
						di <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1000:
						es <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1001:
						cs <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1010:
						ss <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1011:
						ds <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1100:
						fs <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1101:
						gs <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1110:
						flags <= stack[15:0];
					18'b00_xxxx_1011_xxxx_1111:
						ip <= stack[15:0];

					default:
					begin
						state <= S_EXECUTE;
						//mip <= mip + 12'd1;
					end
				endcase
				
				mc <= mout;
				aluop <= mout[3:0];
			end
			S_OPCODE:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					opcode <= din;
					fs <= din;
					mip <= {4'h0, din};
					state <= S_FETCH;
				end
			end
			S_MODRM:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					modrm <= din;
					state <= S_MODRM_DECODE;
				end
			end
			S_MODRM_DECODE:
			begin
				state <= S_FETCH;
				case (modrm[2:0])
					3'd0:
						ofs <= bx + si;
					3'd1:
						ofs <= bx + di;
					3'd2:
					begin
						ofs <= bp + si;
						seg <= sseg;
					end
					3'd3:
					begin
						ofs <= bp + di;
						seg <= sseg;
					end
					3'd4:
						ofs <= si;
					3'd5:
						ofs <= di;
					3'd6:
					begin
						if (|modrm[7:6])
						begin
							ofs <= bp;
							seg <= sseg;
						end
						else
							ofs <= 16'd0;
					end
					3'd7:
						ofs <= bx;
				endcase
				case (modrm[7:6])
					2'b00:
						if (modrm[2:0] == 3'd6)
						begin
							mrdout <= ~mrdout;
							state <= S_MODRM_D16;
						end
					2'b01:
					begin
						mrdout <= ~mrdout;
						state <= S_MODRM_D8;
					end
					2'b10:
					begin
						mrdout <= ~mrdout;
						state <= S_MODRM_D16;
					end
				endcase
			end
			S_MODRM_D8:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					ofs <= ofs + {{8{din[7]}}, din};
					state <= S_FETCH;
				end
			end
			S_MODRM_D16:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					low <= din;
					mrdout <= ~mrdout;
					state <= S_MODRM_D16_HIGH;
				end
			end
			S_MODRM_D16_HIGH:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					ofs <= ofs + {din, low};
					state <= S_FETCH;
				end
			end
			S_FETCH_D8:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					stack[7:0] <= din;
					stack[15:8] <= mc[4] & din[7] ? 8'hFF : 8'h00;
					if (mc[0])
					begin
						mrdout <= ~mrdout;
						state <= S_FETCH_D16;
					end
					else
						state <= S_FETCH;
				end
			end
			S_FETCH_D16:
			begin
				if (ready)
				begin
					ip <= ip + 16'd1;
					stack[15:8] <= din;
					state <= S_FETCH;
				end
			end
			S_READ:
			begin
				if (ready)
				begin
					stack[15:0] <= {8'h00, din};
					if (mc[0])
					begin
						mrdout <= ~mrdout;
						state <= S_READ_HIGH;
					end
					else
						state <= S_FETCH;
				end
			end
			S_READ_HIGH:
			begin
				if (ready)
				begin
					stack[15:8] <= din;
					state <= S_FETCH;
				end
			end
			S_WRITE:
			begin
				if (ready)
				begin
					if (mc[0])
					begin
						mwrout <= ~mwrout;
						state <= S_WRITE_HIGH;
					end
					else
						state <= S_FETCH;
				end
			end
			S_WRITE_HIGH:
			begin
				if (ready)
					state <= S_FETCH;
			end
			S_PUSH:
			begin
				if (ready)
				begin
					sp <= sp - 16'd1;
					mwrout <= ~mwrout;
					state <= S_PUSH_HIGH;
				end
			end
			S_PUSH_HIGH:
			begin
				if (ready)
					state <= S_FETCH;
			end
			S_POP:
			begin
				if (ready)
				begin
					stack[7:0] <= din;
					sp <= sp + 16'd1;
					mrdout <= ~mrdout;
					state <= S_POP_HIGH;
				end
			end
			S_POP_HIGH:
			begin
				if (ready)
				begin
					stack[15:8] <= din;
					sp <= sp + 16'd1;
					state <= S_FETCH;
				end
			end
			S_READ_IO:
				state <= S_READ_IO2;
			S_READ_IO2:
			begin
				if (iordout == iordin)
				begin
					stack[15:0] <= {8'h00, iodin};
					state <= S_FETCH;
				end
			end
			S_WRITE_IO:
			begin
				if ((port == 12'h20) && (iodout == 8'h20))
					irqs_enabled <= 1'b1;
				state <= S_WRITE_IO2;
			end
			S_WRITE_IO2:
				if (iowrout == iowrin)
					state <= S_FETCH;
			S_DIV:
				if (div_run_in == div_run_out)
				begin
					stack[31:0] <= {div_r, div_q};
					state <= S_FETCH;
				end
			S_HLT:
				if (irqs_enabled && flags[F_I] && ((irqin ^ irqout) & 8'b10000011))
					state <= S_FETCH;
		endcase
	end
end

reg [3:0] divphase;

endmodule
