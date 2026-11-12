module uart_rx #(
    parameter DATA_BITS = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 tick,      // 16x baud tick
    input  wire                 rx,
    output wire [DATA_BITS-1:0] rx_data,
    output reg                  rx_done,
    output reg                  frame_err
);

    localparam [1:0] IDLE  = 2'b00,
                     START = 2'b01,
                     DATA  = 2'b10,
                     STOP  = 2'b11;

    reg [1:0]           state, next_state;
    reg [3:0]           tick_cnt, tick_cnt_next;
    reg [2:0]           bit_idx, bit_idx_next;
    reg [DATA_BITS-1:0] shift_reg, shift_reg_next;

    // 2-FF Synchronizer to prevent metastability on asynchronous rx pin
    reg rx_sync1, rx_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tick_cnt  <= 4'd0;
            bit_idx   <= 3'd0;
            shift_reg <= {DATA_BITS{1'b0}};
        end else begin
            state     <= next_state;
            tick_cnt  <= tick_cnt_next;
            bit_idx   <= bit_idx_next;
            shift_reg <= shift_reg_next;
        end
    end

    always @(*) begin
        next_state     = state;
        tick_cnt_next  = tick_cnt;
        bit_idx_next   = bit_idx;
        shift_reg_next = shift_reg;
        rx_done        = 1'b0;
        frame_err      = 1'b0;

        case (state)
            IDLE: begin
                if (rx_sync2 == 1'b0) begin // Falling edge detected
                    next_state    = START;
                    tick_cnt_next = 4'd0;
                end
            end

            START: begin
                if (tick) begin
                    if (tick_cnt == 4'd7) begin // Sample middle of start bit
                        if (rx_sync2 == 1'b0) begin
                            next_state    = DATA;
                            tick_cnt_next = 4'd0;
                            bit_idx_next  = 3'd0;
                        end else begin
                            next_state = IDLE; // False start / noise glitch
                        end
                    end else begin
                        tick_cnt_next = tick_cnt + 1'b1;
                    end
                end
            end

            DATA: begin
                if (tick) begin
                    if (tick_cnt == 4'd15) begin // Sample middle of each data bit
                        tick_cnt_next  = 4'd0;
                        shift_reg_next = {rx_sync2, shift_reg[DATA_BITS-1:1]};
                        if (bit_idx == DATA_BITS - 1) begin
                            next_state = STOP;
                        end else begin
                            bit_idx_next = bit_idx + 1'b1;
                        end
                    end else begin
                        tick_cnt_next = tick_cnt + 1'b1;
                    end
                end
            end

            STOP: begin
                if (tick) begin
                    if (tick_cnt == 4'd15) begin // Sample middle of stop bit
                        next_state = IDLE;
                        if (rx_sync2 == 1'b1)
                            rx_done = 1'b1;
                        else
                            frame_err = 1'b1; // Stop bit was not high
                    end else begin
                        tick_cnt_next = tick_cnt + 1'b1;
                    end
                end
            end
        endcase
    end

    assign rx_data = shift_reg;

endmodule