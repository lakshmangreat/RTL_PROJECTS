typedef struct packed{
  logic [4:0] symbol_1;
    logic [4:0] prb_1;
  logic [4:0] symbol_2;
    logic [4:0] prb_2;
  logic [4:0] symbol_3;
    logic [4:0] prb_3;
} config_param_1;

module data_router_tb();

  parameter DATA_WIDTH = 64, CONFIG_BIT_WIDTH = $bits(config_param_1);
  logic clk;
  logic reset;
  
  logic [CONFIG_BIT_WIDTH-1:0] s_axi_config_data;
  logic s_axi_config_valid;
  logic s_axi_config_ready;
  
  logic [DATA_WIDTH-1:0] s_axi_data;
  logic s_axi_valid;
  logic s_axi_ready;
  
  logic [DATA_WIDTH-1:0] out_axi_data_1;
  logic out_axi_valid_1;
  logic out_axi_ready_1;
  
  logic [DATA_WIDTH-1:0] out_axi_data_2;
  logic out_axi_valid_2;
  logic out_axi_ready_2;
  
  logic [DATA_WIDTH-1:0] out_axi_data_3;
  logic out_axi_valid_3;
  logic out_axi_ready_3;
  
  localparam string config_file = "config1.csv";
  localparam string data_file = "input_data1.csv";
  
  config_param_1 param;
  
  data_router#(DATA_WIDTH, CONFIG_BIT_WIDTH) dut(
    clk,
    reset,
    s_axi_config_data,
    s_axi_config_valid,
    s_axi_config_ready,
    s_axi_data,
    s_axi_valid,
    s_axi_ready,
    out_axi_data_1,
    out_axi_valid_1,
    out_axi_ready_1,
    out_axi_data_2,
    out_axi_valid_2,
    out_axi_ready_2,
    out_axi_data_3,
    out_axi_valid_3,
    out_axi_ready_3
  );
  
  always #5 clk = ~clk;
  
  initial begin
    clk = 0;
    reset = 1;
    out_axi_ready_1 = 1;
    out_axi_ready_2 = 1;
    out_axi_ready_3 = 1;
    reset_task;
    fork
      read_csv(config_file, 1);
      read_data(data_file, 1);
    join
    out_axi_ready_1 = 1;
    out_axi_ready_2 = 1;
    out_axi_ready_3 = 1;
    repeat(2) @(posedge clk);
    $finish;
  end
  
  task automatic reset_task;
    begin
      @(posedge clk);
      reset <= ~reset;
    end
  endtask
  
  task read_csv;
    input string filename;
    input int throttle;
    begin
      int fp, wait_n;
      logic [4:0] symb_1, prbb_1, symb_2, prbb_2, symb_3, prbb_3;
      fp = $fopen(filename, "r");
      
      if(fp == 0) begin
        $display("Error in opening file");
      end
      
      while($fscanf(fp, "%d %d %d %d %d %d", symb_1, prbb_1, symb_2, prbb_2, symb_3, prbb_3) == 6) begin
        $display("---------------------------------");
        $display("Read values: sym_1=%b, prb_1=%b, sym_2=%b, prb_2=%b, sym_3=%b, prb_3=%b", symb_1, prbb_1, symb_2, prbb_2, symb_3, prbb_3);
        $display("---------------------------------");
        param.symbol_1 = symb_1;
        param.prb_1 = prbb_1;
        param.symbol_2 = symb_2;
        param.prb_2 = prbb_2;
        param.symbol_3 = symb_3;
        param.prb_3 = prbb_3;
        s_axi_config_data <= param;
        s_axi_config_valid <= 1;
        @(posedge clk);
        while(!s_axi_config_ready)
          @(posedge clk);
        s_axi_config_valid <= 0;
        wait_n = $urandom % throttle;
        repeat(wait_n) begin
          @(posedge clk);
        end
      end
      $display("%0t wait = %0d", $time, wait_n);
      $fclose(fp);
    end
  endtask
    
  task automatic read_data;
    input string filename;
    input int throttle;
    begin
      int fp1, wait_n;
      logic [DATA_WIDTH-1:0] data;
      fp1 = $fopen(filename, "r");
      
      if(fp1 == 0) begin
        $display("Error in Reading file");
      end
      
      while($fscanf(fp1, "%h", data) == 1) begin
        $display("---------------------------------");
        $display("Read values: data=%h", data);
        $display("---------------------------------");
        s_axi_data <= data;
        s_axi_valid <= 1;
        @(posedge clk);
        while(!s_axi_ready)
          @(posedge clk);
        s_axi_valid <= 0;
        wait_n = $urandom % throttle;
        $display("%0d", wait_n);
        repeat(wait_n) begin
          @(posedge clk);
        end
      end
      $fclose(fp1);
    end
  endtask
    
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
  initial begin
    $monitor("stream_count_1=%0d, stream_count_2=%0d, stream_count_3=%0d", dut.stream_count_1, dut.stream_count_2, dut.stream_count_3);
  end

  initial begin
    #1000;  // Adjust the time value to increase simulation time
    $finish;
  end

endmodule
