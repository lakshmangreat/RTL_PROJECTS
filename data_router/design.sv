
module data_router#(parameter DATA_WIDTH=64, CONFIG_BIT_WIDTH=$bits(config_param))(
  input clk,
  input reset,
  
  input [CONFIG_BIT_WIDTH-1:0] s_axi_config_data,
  input s_axi_config_valid,
  output reg s_axi_config_ready,
  
  input [DATA_WIDTH-1:0] s_axi_data,
  input s_axi_valid,
  output reg s_axi_ready,
  
  output reg [DATA_WIDTH-1:0] out_axi_data_1,
  output reg out_axi_valid_1,
  input out_axi_ready_1,
  
  output reg [DATA_WIDTH-1:0] out_axi_data_2,
  output reg out_axi_valid_2,
  input out_axi_ready_2,
  
  output reg [DATA_WIDTH-1:0] out_axi_data_3,
  output reg out_axi_valid_3,
  input out_axi_ready_3
);

typedef struct packed {
  logic [4:0] symbol_1;
  logic [4:0] prb_1;
  logic [4:0] symbol_2;
  logic [4:0] prb_2;
  logic [4:0] symbol_3;
  logic [4:0] prb_3;
} config_param;

reg [10:0] stream_count_1, stream_count_2, stream_count_3;
reg [10:0] count_1, count_2, count_3;

config_param config_1;

reg [DATA_WIDTH-1:0] fifo[0:1023];
  reg [$clog2(1024)-1:0] write_ptr, read_ptr;

enum bit[3:0] {
  IDLE,
  CONFIG_READ,
  CONFIG_CALC,
  DATA_READ_1,
  DATA_READ_2,
  DATA_READ_3,
  DATA_WRITE_1,
  DATA_WRITE_2,
  DATA_WRITE_3
} state, next_state;

always @(posedge clk) begin
  if (reset) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end

always @(*) begin
  case (state)
    IDLE: next_state = CONFIG_READ;
    CONFIG_READ: begin
      if (s_axi_config_valid && s_axi_config_ready) begin
        next_state = CONFIG_CALC;
      end else begin
        next_state = CONFIG_READ;
      end
    end
    CONFIG_CALC: next_state = DATA_READ_1;
    DATA_READ_1: begin
      if (s_axi_valid && s_axi_ready && count_1 == stream_count_1 - 1) begin
        next_state = DATA_READ_2;
      end else begin
        next_state = DATA_READ_1;
      end
    end
    DATA_READ_2: begin
      if (s_axi_valid && s_axi_ready && count_2 == stream_count_2 - 1) begin
        next_state = DATA_READ_3;
      end else begin
        next_state = DATA_READ_2;
      end
    end
    DATA_READ_3: begin
      if (s_axi_valid && s_axi_ready && count_3 == stream_count_3 - 1) begin
        next_state = DATA_WRITE_1;
      end else begin
        next_state = DATA_READ_3;
      end
    end
    DATA_WRITE_1: begin
      if (out_axi_ready_1 && count_1 == 0) begin
        next_state = DATA_WRITE_2;
      end else begin
        next_state = DATA_WRITE_1;
      end
    end
    DATA_WRITE_2: begin
      if (out_axi_ready_2 && count_2 == 0) begin
        next_state = DATA_WRITE_3;
      end else begin
        next_state = DATA_WRITE_2;
      end
    end
    DATA_WRITE_3: begin
      if (out_axi_ready_3 && count_3 == 0) begin
        next_state = CONFIG_READ;
      end else begin
        next_state = DATA_WRITE_3;
      end
    end
    default: next_state = IDLE;
  endcase
end

always @(posedge clk) begin
  if (reset) begin
    {config_1, out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
    {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
    {stream_count_1, stream_count_2, stream_count_3} <= 0;
    {count_1, count_2, count_3} <= 0;
    {write_ptr, read_ptr} <= 0;
  end else begin
    case (state)
      IDLE: begin
        {config_1, out_axi_data_1, out_axi_data_2, out_axi_data_3, 
         out_axi_valid_1, out_axi_valid_2, out_axi_valid_3, 
         stream_count_1, stream_count_2, stream_count_3, 
         count_1, count_2, count_3} <= 0;
      end
      CONFIG_READ: begin
        if (s_axi_config_valid && s_axi_config_ready) begin
          config_1 <= s_axi_config_data;
          {out_axi_data_1, out_axi_data_2, out_axi_data_3, 
           out_axi_valid_1, out_axi_valid_2, out_axi_valid_3, 
           count_1, count_2, count_3} <= 0;
        end else begin
          config_1 <= config_1;
          {out_axi_data_1, out_axi_data_2, out_axi_data_3, 
           out_axi_valid_1, out_axi_valid_2, out_axi_valid_3, 
           count_1, count_2, count_3} <= 0;
        end
      end
      CONFIG_CALC: begin
        stream_count_1 <= (config_1.symbol_1 * config_1.prb_1) * 12;
        stream_count_2 <= (config_1.symbol_2 * config_1.prb_2) * 12;
        stream_count_3 <= (config_1.symbol_3 * config_1.prb_3) * 12;
        {out_axi_data_1, out_axi_data_2, out_axi_data_3, 
         out_axi_valid_1, out_axi_valid_2, out_axi_valid_3, 
         count_1, count_2, count_3} <= 0;
      end
      DATA_READ_1: begin
        if (s_axi_valid && s_axi_ready && count_1 < stream_count_1) begin
          {out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
          {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
          {count_2, count_3} <= 0;
          count_1 <= count_1 + 1;
          fifo[write_ptr] <= s_axi_data;
          write_ptr <= write_ptr + 1;
        end else begin
          {out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
          {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
          {count_1, count_2, count_3} <= {count_1, count_2, count_3};
          fifo[write_ptr] <= fifo[write_ptr];
        end
      end
      DATA_READ_2: begin
        if (s_axi_valid && s_axi_ready && count_2 < stream_count_2) begin
          {out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
          {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
          count_2 <= count_2 + 1;
          fifo[write_ptr] <= s_axi_data;
          write_ptr <= write_ptr + 1;
        end else begin
          {out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
          {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
          count_2 <= count_2 + 1;
          fifo[write_ptr] <= fifo[write_ptr];
        end
      end
      DATA_READ_3: begin
        if (s_axi_valid && s_axi_ready && count_3 < stream_count_3) begin
          {out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
          {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
          count_3 <= count_3 + 1;
          fifo[write_ptr] <= s_axi_data;
          write_ptr <= write_ptr + 1;
        end else begin
          {out_axi_data_1, out_axi_data_2, out_axi_data_3} <= 0;
          {out_axi_valid_1, out_axi_valid_2, out_axi_valid_3} <= 0;
          {count_1, count_2, count_3} <= {count_1, count_2, count_3};
          fifo[write_ptr] <= fifo[write_ptr];
        end
      end
      DATA_WRITE_1: begin
        if (out_axi_ready_1 && read_ptr < write_ptr) begin
          out_axi_data_1 <= fifo[read_ptr];
          out_axi_valid_1 <= 1;
          read_ptr <= read_ptr + 1;
          count_1 <= count_1 - 1;
        end else begin
          out_axi_data_1 <= 0;
          out_axi_valid_1 <= 0;
          count_1 <= count_1;
        end
      end
      DATA_WRITE_2: begin
        if (out_axi_ready_2 && read_ptr < write_ptr) begin
          out_axi_data_2 <= fifo[read_ptr];
          out_axi_valid_2 <= 1;
          read_ptr <= read_ptr + 1;
          count_2 <= count_2 - 1;
        end else begin
          out_axi_data_2 <= 0;
          out_axi_valid_2 <= 0;
          count_2 <= count_2;
        end
      end
      DATA_WRITE_3: begin
        if (out_axi_ready_3 && read_ptr < write_ptr) begin
          out_axi_data_3 <= fifo[read_ptr];
          out_axi_valid_3 <= 1;
          read_ptr <= read_ptr + 1;
          count_3 <= count_3 - 1;
        end else begin
          out_axi_data_3 <= 0;
          out_axi_valid_3 <= 0;
          count_3 <= count_3;
        end
      end
    endcase
  end
end

always @(*) begin
  s_axi_config_ready = (state == CONFIG_READ) && !reset;
  s_axi_ready = (state == DATA_READ_1 || state == DATA_READ_2 || state == DATA_READ_3) && !reset;
end

endmodule
