module tb_pn_sequence_generator;

  // Ports
  reg clk;
  reg reset;
  reg valid;
  reg data_out_ready;
  reg [2:0] data_in;
  wire ready;
  wire [2:0] data_out;
  wire axi_tvalid;
  wire pn_seq_out;

  // Instantiate the DUT
  pn_sequence_generator uut (
    .clk(clk),
    .reset(reset),
    .valid(valid),
    .data_out_ready(data_out_ready),
    .data_in(data_in),
    .ready(ready),
    .data_out(data_out),
    .axi_tvalid(axi_tvalid),
    .pn_seq_out(pn_seq_out)
  );

  // Clock Generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset Task
  task automatic reset_task;
    begin
      @(posedge clk);
      reset = 1'b1;
      #15;
      reset = 1'b0;
      #5;
      reset = 1'b1;
      $display("INFO: Reset Done!");
    end
  endtask

  // Reading Files Task
  task automatic pdsch_CDD(
    input string file_ip,
    input int throttle
  );
    int file_in;
    reg [2:0] pn_in_data;
    int wait_n;
    int data_cntr = 0;

    begin
      file_in = $fopen(file_ip, "r");
      if (file_in == 0) begin
        $display("Error: Could not open input file.");
        $finish;
      end else begin
        $display("INFO: FILE Opened");
      end

      while ($fscanf(file_in, "%b", pn_in_data) == 1) begin
        data_in = pn_in_data;  // Blocking assignment for the task
        valid = 1'b1;          // Blocking assignment
        $display("INFO: Read data=%b", pn_in_data);

        // Wait for the DUT to be ready
        while (!ready) @(posedge clk);

        // Add random delay
        wait_n = $urandom % throttle;
        repeat(wait_n) @(posedge clk);

        valid = 1'b0;          // Blocking assignment
        @(posedge clk);

        // Control data_out_ready based on data_cntr
        if (data_cntr == 4) begin
          data_out_ready = 1'b0;  // Blocking assignment
          repeat(10) @(posedge clk);
          data_out_ready = 1'b1;  // Blocking assignment
        end

        data_cntr = data_cntr + 1;
      end

      $display("WAIT=%0d", wait_n);
      $fclose(file_in);
    end
  endtask

  localparam string IP_FILE = "input_sequences.txt";  // Ensure the file exists

  initial begin
    data_in = 3'b000;
    valid = 1'b0;
    data_out_ready = 1'b1;
    
    // Apply reset
    reset_task;

    // Run the pdsch_CDD task
    pdsch_CDD(IP_FILE, 13);

    repeat(7) @(posedge clk);
    $finish;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_pn_sequence_generator);  // Specify the module name to avoid VCD warning
  end

  initial begin
    $monitor("Time=%0t | state=%b | counter=%d | data_in=%b | valid=%b | ready=%b | data_out_ready=%b | pn_seq_out=%b | data_out=%b | axi_tvalid=%b", 
             $time, uut.state, uut.counter, data_in, valid, ready, data_out_ready, pn_seq_out, data_out, axi_tvalid);
  end

  // Ensure axi_tvalid follows valid
  assign axi_tvalid = valid;

endmodule
