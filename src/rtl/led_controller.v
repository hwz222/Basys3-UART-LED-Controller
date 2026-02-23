module led_controller (
    input  wire        clk,
    input  wire        rst,
    
    // FIFO Interface
    input  wire        empty,
    input  wire  [7:0] dout,
    output reg         rd_en,
    
    // LED Output
    output reg  [15:0] led
);

    reg [1:0] state;
    
    localparam IDLE = 2'd0;
    localparam WAIT_DATA = 2'd1;
    localparam PROCESS_DATA = 2'd2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_en <= 1'b0;
            led   <= 16'd0;
            state <= IDLE;
        end else begin
            rd_en <= 1'b0;
            case (state)
                IDLE: begin
                    if (~empty) begin
                        rd_en <= 1'b1;
                        state <= WAIT_DATA;
                    end
                end
                
                WAIT_DATA: begin
                    // Wait 1 cycle for FIFO data to propagate to dout
                    state <= PROCESS_DATA;
                end
                
                PROCESS_DATA: begin
                    if (dout >= 8'h41 && dout <= 8'h50) begin
                        // 'A' ~ 'P' -> 0x41 ~ 0x50
                        led <= 16'd1 << (dout - 8'h41);
                    end else begin
                        // Other characters
                        led <= {8'h00, dout};
                    end
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
