module baud_gen #(
    parameter CLK_FREQ  = 50_000_000, // 50 MHz system clock
    parameter BAUD_RATE = 115_200     // Standard baud rate
)(
    input  wire clk,
    input  wire rst_n,
    output wire tick                  // 16x oversampling pulse
);

    localparam integer DIVISOR = CLK_FREQ / (BAUD_RATE * 16);
    localparam integer WIDTH   = $clog2(DIVISOR);

    reg [WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (count == DIVISOR - 1) begin
            count <= 0;
        end else begin
            count <= count + 1'b1;
        end
    end

    assign tick = (count == DIVISOR - 1);

endmodule