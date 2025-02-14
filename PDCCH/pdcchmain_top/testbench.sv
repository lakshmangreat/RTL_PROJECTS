
typedef struct packed {
   logic [8:0] BWPsize;
    logic [11:0] BWPstart;
   
    logic [1:0] copeset;
    logic [6:0] slotnumber;
    logic [15:0] Nid;
    logic [3:0] startsymbol;
    logic [1:0] startsymbolindex;
    logic [12:0] dmrsoffset;
    logic [44:0] freqbitmap;
  logic  coreset_type;
} config_input_t_1;

typedef struct packed {
    logic [30:0] Cinit;
    logic [15:0] pnseqlength;
    logic [12:0] dmrsoffset;
    logic [44:0] freqbitmap;   
} config_out_t_1;

module NewTopModule_tb;

  parameter DATA_WIDTH = 64;
  parameter DATA_OUT_WIDTH = 8;
  parameter DEPTH = 1024;
   parameter FIFO_DEPTH = 1024;
    parameter datawidth_1 = 5;
  parameter  datawidth_2 = 64;
  parameter PTR_SIZE = $clog2(DEPTH);
  parameter CONFIG_BIT_WIDTH = $bits(config_input_t_1);
  parameter CONFIG_BIT_OUT_WIDTH = $bits(config_out_t_1);
 

  
  // Clock and Reset
  logic clk;
  logic reset;
  
  // Signals for NewTopModule
  logic [DATA_WIDTH-1:0] s_axis_maintop_data;
//   logic s_axis_maintop_valid;
//   logic s_axis_maintop_ready; // Corrected name
  logic [datawidth_1-1:0] pio; // Ensure the width matches the input

  logic [DATA_OUT_WIDTH-1:0] m_axis_maintop_outdata;
  logic m_axis_maintop_valid;
  logic m_axis_maintop_ready;
  
  // Instantiate the NewTopModule
  NewTopModule #(DATA_WIDTH, DATA_OUT_WIDTH,DEPTH,FIFO_DEPTH,datawidth_1,datawidth_2, PTR_SIZE, CONFIG_BIT_WIDTH, CONFIG_BIT_OUT_WIDTH) uut (
    .clk(clk),
    .reset(reset),
    .s_axis_maintop_data(s_axis_maintop_data),
    
    .pio(pio),
    .m_axis_maintop_outdata(m_axis_maintop_outdata),
    .m_axis_maintop_valid(m_axis_maintop_valid),
    .m_axis_maintop_ready(m_axis_maintop_ready)
  );
  
  // File path for input data
  localparam string datafile = "input_data.txt";  // Input data file
  
  // Clock generation
  always #5 clk = ~clk;
  
  // Testbench main process
  initial begin
    // Initialize signals
    clk = 0;
    reset = 1;
    s_axis_maintop_data = 0;
//     s_axis_maintop_valid = 0;
    m_axis_maintop_ready = 0;
    pio =0; // Set pio to a proper initial value
    
    // Apply reset
    reset_task;
    
    // Start data generation and read input from file
    fork
      data_gen(datafile, 6);         // Input data generator from file
      data_ready_task(300);          // Control m_axis_maintop_ready
    join
    
    // Wait for a while before finishing the simulation
    #1000; // Adjust as needed to allow for processing
    $finish;
  end
  
  // Reset task
  task automatic reset_task;
    begin
      repeat (2) @(posedge clk);
      reset <= 0; 
    end
  endtask
  
  // Task to generate input data by reading from a file
  task automatic data_gen(input string filename, input int throttle);
    begin
      int fp, wait_n;
      logic [DATA_WIDTH-1:0] file_data;
      fp = $fopen(filename, "r");
      if (fp == 0) begin
        $display("Error opening file: %s", filename);
        $finish;
      end
      
      while ($fscanf(fp, "%h", file_data) == 1) begin
        s_axis_maintop_data <= file_data;
        pio<=2;
        //s_axis_maintop_valid <= 1;
        @(posedge clk);
        while (!uut.u_top.datagen_fifo_ready) @(posedge clk);  // Wait for ready signal
        //s_axis_maintop_valid <zz 0;
        pio<=0;
        wait_n = $urandom % throttle;
        repeat (wait_n) @(posedge clk);
      end
      
      $fclose(fp);
    end
  endtask
  
  // Task to toggle m_axis_maintop_ready for a duration of time
  task automatic data_ready_task(input int duration_cycles);
    int cycle_count;
    begin
      cycle_count = 0;
      while (cycle_count < duration_cycles) begin
        m_axis_maintop_ready <= $random; // Set to ready; can adjust as needed
        cycle_count = cycle_count + 1;
        @(posedge clk);
      end
      m_axis_maintop_ready <= 1; // Ensure it remains ready
    end
  endtask
 initial begin
   #10000
   $finish;
 end
  // VCD dump for waveform analysis
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
