module DMA8(
	input wire clk,
	input wire reset_n,
	
	input wire [11:0] port,
	input wire [7:0] iodin,
	input wire iowrin,
	output reg iowrout,
	
	output reg [23:0] dma1_addr,
	input wire [7:0] dma1_din,
	input wire dma1_rdin,
	output reg dma1_rdout,
	
	output wire [7:0] dma1_dout,
	input wire dma1_wrin,
	output reg dma1_wrout,
	
	output reg irq7
);

localparam
	S_IDLE				= 3'd0,
	S_READ				= 3'd1,
	S_WRITE				= 3'd2;

assign dma1_dout = dma1_din;

reg [15:0] dma1_base;
reg [15:0] dma1_base_count;

reg [15:0] dma1_count;

reg data_ff;

reg dma1_run;

reg [2:0] dma1_state;

always @(posedge clk)
begin
	iowrout <= iowrin;

	// Регистр адреса и старшие разряды
	dma1_base[7:0] <= (iowrin ^ iowrout) && (port == 12'h02) && (~data_ff) ? iodin : dma1_base[7:0];
	dma1_base[15:8] <= (iowrin ^ iowrout) && (port == 12'h02) && (data_ff) ? iodin : dma1_base[15:8];
	dma1_addr[23:16] <= (iowrin ^ iowrout) && (port == 12'h83) ? iodin : dma1_addr[23:16];

	// Регистр количества
	dma1_base_count[7:0] <= (iowrin ^ iowrout) && (port == 12'h03) && (~data_ff) ? iodin : dma1_base_count[7:0];
	dma1_base_count[15:8] <= (iowrin ^ iowrout) && (port == 12'h03) && (data_ff) ? iodin : dma1_base_count[15:8];

	// Триггер данных, сбрасывается при записи в порт 0Ch и переключается при записи в порты адреса и количества
	data_ff <=
		(iowrin ^ iowrout) && (port == 12'h0C) ? 1'b0 :
		(iowrin ^ iowrout) && (port == 12'h02) ? ~data_ff :
		(iowrin ^ iowrout) && (port == 12'h03) ? ~data_ff :
		data_ff;
	
	case (dma1_state)
		S_IDLE:
		begin
			// При поступлении команды запуска начать чтение
			if ((iowrin ^ iowrout) && (port == 12'h0A) && (iodin[2:0] == 3'd1))
			begin
				dma1_state <= S_READ;
				dma1_addr[15:0] <= dma1_base;
				dma1_count <= dma1_base_count;
				dma1_rdout <= ~dma1_rdout;
			end
		end
		S_READ:
		begin
			// Как только чтение будет закончено, отправить данные устройству
			if (dma1_rdin == dma1_rdout)
			begin
				dma1_state <= S_WRITE;
				dma1_addr <= dma1_addr + 16'd1;
				dma1_count <= dma1_count - 16'd1;
				dma1_wrout <= ~dma1_wrout;
			end
		end
		S_WRITE:
		begin
			// Как только запись будет закончена, начать новый цикл или перейти в ожидание
			if (dma1_wrin == dma1_wrout)
			begin
				if (&dma1_count)
				begin
					dma1_state <= S_IDLE;
					irq7 <= ~irq7;
				end
				else
				begin
					dma1_state <= S_READ;
					dma1_rdout <= ~dma1_rdout;
				end
			end
		end
	endcase
	
end

endmodule
