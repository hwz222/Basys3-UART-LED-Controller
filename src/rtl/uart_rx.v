module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid
);

    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    parameter OVERSAMPLE = 16;
    parameter TICK_MAX = CLK_FREQ / (BAUD_RATE * OVERSAMPLE) - 1; // 53

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state, next_state;
    reg [5:0] tick_cnt;
    reg       tick;
    reg [3:0] os_cnt; // 0 to 15
    reg [2:0] bit_cnt; // 0 to 7
    reg [7:0] shift_reg;
    reg       rx_sync_0, rx_sync_1;

    // Double-flop synchronizer for RX
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;
        end
    end

    // Tick Generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt <= 6'd0;
            tick     <= 1'b0;
        end else begin
            if (tick_cnt == TICK_MAX) begin
                tick_cnt <= 6'd0;
                tick     <= 1'b1;
            end else begin
                tick_cnt <= tick_cnt + 6'd1;
                tick     <= 1'b0;
            end
        end
    end

    // State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            os_cnt    <= 4'd0;
            bit_cnt   <= 3'd0;
            shift_reg <= 8'd0;
            rx_data   <= 8'd0;
            rx_valid  <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            if (tick) begin
                case (state)
                    IDLE: begin
                        os_cnt <= 4'd0;
                        bit_cnt <= 3'd0;
                        if (~rx_sync_1) begin
                            state <= START;
                        end
                    end

                    START: begin
                        if (os_cnt == 4'd7) begin
                            if (~rx_sync_1) begin
                                os_cnt <= 4'd0;
                                state  <= DATA;
                            end else begin
                                state <= IDLE;
                            end
                        end else begin
                            os_cnt <= os_cnt + 4'd1;
                        end
                    end

                    DATA: begin
                        if (os_cnt == 4'd15) begin
                            os_cnt    <= 4'd0;
                            shift_reg <= {rx_sync_1, shift_reg[7:1]};
                            if (bit_cnt == 3'd7) begin
                                state <= STOP;
                            end else begin
                                bit_cnt <= bit_cnt + 3'd1;
                            end
                        end else begin
                            os_cnt <= os_cnt + 4'd1;
                        end
                    end

                    STOP: begin
                        if (os_cnt == 4'd15) begin
                            state <= IDLE;
                            if (rx_sync_1) begin
                                rx_data  <= shift_reg;
                                rx_valid <= 1'b1;
                            end
                        end else begin
                            os_cnt <= os_cnt + 4'd1;
                        end
                    end
                endcase
            end
        end
    end

endmodule
