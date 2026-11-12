`timescale 1ns/1ps

module uart_tb;

    localparam CLK_FREQ  = 50_000_000;
    localparam BAUD_RATE = 115_200;
    localparam CLK_PERIOD = 20; // 50 MHz -> 20 ns

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_serial;
    wire       tx_busy;
    wire       tx_done;
    wire [7:0] rx_data;
    wire       rx_done;
    wire       frame_err;

    integer error_count = 0;

    // Instantiate DUT in loopback mode (tx_serial wired to rx)
    uart_top #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(8)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (tx_serial),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done),
        .rx       (tx_serial), // Loopback connection
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .frame_err(frame_err)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Task to transmit a byte and verify received byte
    task send_and_check(input [7:0] test_byte);
        begin
            @(posedge clk);
            tx_data  <= test_byte;
            tx_start <= 1'b1;
            @(posedge clk);
            tx_start <= 1'b0;

            // Wait for receiver to assert rx_done
            @(posedge rx_done);
            #1; // Small delay for signal stability

            if (frame_err) begin
                $display("[FAIL] Frame error detected for byte 0x%02h at time %0t", test_byte, $time);
                error_count = error_count + 1;
            end else if (rx_data !== test_byte) begin
                $display("[FAIL] Mismatch! Sent: 0x%02h, Received: 0x%02h at time %0t", test_byte, rx_data, $time);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] Sent: 0x%02h == Received: 0x%02h", test_byte, rx_data);
            end

            // Wait for transmitter to finish completely before next byte
            wait (!tx_busy);
            repeat (10) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("uart_sim.vcd");
        $dumpvars(0, uart_tb);

        // Reset sequence
        rst_n    = 0;
        tx_start = 0;
        tx_data  = 8'h00;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        // Run test vectors
        send_and_check(8'hA5); // Alternating bits
        send_and_check(8'h5A); // Inverse alternating bits
        send_and_check(8'h00); // All zeros
        send_and_check(8'hFF); // All ones
        send_and_check(8'hFE); // Edge case byte

        // Final Summary
        $display("----------------------------------------");
        if (error_count == 0)
            $display("ALL TESTS PASSED SUCCESSFULLY!");
        else
            $display("TESTS FAILED WITH %0d ERRORS.", error_count);
        $display("----------------------------------------");

        $finish;
    end

endmodule