IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

RTL_SRCS = rtl/baud_gen.v rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v
TB_SRC   = tb/uart_tb.v
OUT      = uart_sim.vvp
VCD      = uart_sim.vcd

.PHONY: all sim wave clean

all: sim

sim:
	$(IVERILOG) -g2012 -o $(OUT) $(RTL_SRCS) $(TB_SRC)
	$(VVP) $(OUT)

wave: sim
	$(GTKWAVE) $(VCD) &

clean:
	rm -f $(OUT) $(VCD)