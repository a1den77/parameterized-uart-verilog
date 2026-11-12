module uart_tx #(
    parameter DATA_BITS = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 tick,      // 16x baud tick
    input  wire                 tx_start,
    input  wire [DATA_BITS-1:0] tx_data,
    output reg                  tx,
    output reg                  tx_busy,
    output reg                  tx_done
);

    localparam [1:0] IDLE  = 2'b00,
                     START = 2'b01,
                     DATA  = 2'b10,
                     STOP  = 2'b11;

    reg [1:0]           state, next_state;
    reg [3:0]           tick_cnt, tick_cnt_next;
    reg [2:0]           bit_idx, bit_idx_next;
    reg [DATA_BITS-1:0] shift_reg, shift_reg_next;

    // Sequential state & register update
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

    // Combinational next-state & output logic
    always @(*) begin
        next_state     = state;
        tick_cnt_next  = tick_cnt;
        bit_idx_next   = bit_idx;
        shift_reg_next = shift_reg;
        tx             = 1'b1;
        tx_busy        = 1'b1;
        tx_done        = 1'b0;

        case (state)
            IDLE: begin
                tx      = 1'b1;
                tx_busy = 1'b0;
                if (tx_start) begin
                    next_state     = START;
                    tick_cnt_next  = 4'd0;
                    shift_reg_next = tx_data;
                end
            end

            START: begin
                tx = 1'b0; // Start bit
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        next_state    = DATA;
                        tick_cnt_next = 4'd0;
                        bit_idx_next  = 3'd0;
                    end else begin
                        tick_cnt_next = tick_cnt + 1'b1;
                    end
                end
            end

            DATA: begin
                tx = shift_reg[0]; // Transmit LSB first
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        tick_cnt_next  = 4'd0;
                        shift_reg_next = shift_reg >> 1;
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
                tx = 1'b1; // Stop bit
                if (tick) begin
                    if (tick_cnt == 4'd15) begin
                        next_state = IDLE;
                        tx_done    = 1'b1;
                    end else begin
                        tick_cnt_next = tick_cnt + 1'b1;
                    end
                end
            end
        endcase
    end

endmodule