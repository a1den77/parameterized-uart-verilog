module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200,
    parameter DATA_BITS = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    // Transmitter interface
    input  wire                 tx_start,
    input  wire [DATA_BITS-1:0] tx_data,
    output wire                 tx,
    output wire                 tx_busy,
    output wire                 tx_done,
    // Receiver interface
    input  wire                 rx,
    output wire [DATA_BITS-1:0] rx_data,
    output wire                 rx_done,
    output wire                 frame_err
);

    wire tick;

    baud_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_gen (
        .clk  (clk),
        .rst_n(rst_n),
        .tick (tick)
    );

    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) u_uart_tx (
        .clk     (clk),
        .rst_n   (rst_n),
        .tick    (tick),
        .tx_start(tx_start),
        .tx_data (tx_data),
        .tx      (tx),
        .tx_busy (tx_busy),
        .tx_done (tx_done)
    );

    uart_rx #(
        .DATA_BITS(DATA_BITS)
    ) u_uart_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick     (tick),
        .rx       (rx),
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .frame_err(frame_err)
    );

endmodule