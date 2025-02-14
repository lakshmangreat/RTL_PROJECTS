
module pn_sequence_generator (
    input wire clk,
    input wire reset,
    input wire valid,
    input wire data_out_ready,
    input wire [2:0] data_in,
    output reg ready,
    output reg pn_seq_out, // Output for PN sequence bit
    output reg [2:0] data_out,
    output reg axi_tvalid
);
    // Parameters for state encoding
    parameter STATE_IDLE = 2'b00;
    parameter STATE_INPUT = 2'b01;
    parameter STATE_GENERATE = 2'b10;

    reg [2:0] lfsr;
    reg [2:0] counter;
    reg [1:0] state, next_state;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= STATE_IDLE;
            lfsr <= 3'b001;
            counter <= 3'b000;
            ready <= 1'b0;
            axi_tvalid <= 1'b0;
            pn_seq_out <= 1'b0;
            data_out <= 3'b000;
        end else begin
            state <= next_state;
        end
    end

    // Next State Logic
    always @(*) begin
        case (state)
            STATE_IDLE: begin
                ready = 1'b1;  // Ready when idle
                if (valid)
                    next_state = STATE_INPUT;
                else
                    next_state = STATE_IDLE;
            end

            STATE_INPUT: begin
                ready = 1'b0;  // Not ready during input processing
                if (!valid)
                    next_state = STATE_IDLE;
                else if (data_out_ready)
                    next_state = STATE_GENERATE;
                else
                    next_state = STATE_INPUT;
            end

            STATE_GENERATE: begin
                ready = 1'b0;  // Not ready during generation
              if (counter == 3'b110)  // Generate 7 bits (counter counts 0 to 6
                    next_state = STATE_IDLE;
                else
                    next_state = STATE_GENERATE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // Output and LFSR Logic
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            lfsr <= 3'b001;
            data_out <= 3'b000;
            ready <= 1'b0;
            axi_tvalid <= 1'b0;
            pn_seq_out <= 1'b0;  // Initialize pn_seq_out
            counter <= 3'b000;
        end else begin
            case (state)
                STATE_IDLE: begin
                    // Stay idle, ready to accept valid input
                    ready <= 1'b1;
                    axi_tvalid <= 1'b0;
                end

                STATE_INPUT: begin
                    if (valid && data_out_ready) begin
                        lfsr <= data_in;
                        counter <= 3'b000;  // Reset counter
                        ready <= 1'b0;      
                    end
                end

                STATE_GENERATE: begin
                    axi_tvalid <= 1'b1;  
                    data_out <= lfsr;
                    pn_seq_out <= lfsr[0];  // Output the LSB of LFSR
                    lfsr <= {lfsr[2] ^ lfsr[0], lfsr[2:1]};
                    counter <= counter + 1'b1;
                end
            endcase
        end
    end
endmodule
