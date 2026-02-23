module top (
    input  wire        clk_100m,
    input  wire        uart_rx,
    output wire [15:0] led
);

    wire clk;
    wire locked;
    wire rst = ~locked; // Reset active when IP is not locked

    // Clock wizard IP from Vivado (100MHz in -> 100MHz out)
    clk_wiz_0 u_clk_wiz (
        .clk_out1 (clk),
        .reset    (1'b0),     // Not using external reset for PLL
        .locked   (locked),
        .clk_in1  (clk_100m)
    );

    wire [7:0] rx_data;
    wire       rx_valid;

    // UART RX module
    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115200),
        .OVERSAMPLE(16)
    ) u_uart_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (uart_rx),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    wire       rd_en;
    wire [7:0] dout;
    wire       full;
    wire       empty;

    // FIFO Generator IP from Vivado (8 bits width / 64 depth)
    fifo_generator_0 u_fifo (
        .clk   (clk),
        .srst  (rst),
        .din   (rx_data),
        .wr_en (rx_valid),
        .rd_en (rd_en),
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );
    
    // LED Controller module
    led_controller u_led_ctrl (
        .clk   (clk),
        .rst   (rst),
        .empty (empty),
        .dout  (dout),
        .rd_en (rd_en),
        .led   (led)
    );

endmodule
