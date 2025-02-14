module data_router#
  (parameter DATA_WIDTH=64,  parameter CONFIG_BIT_WIDTH = $bits(config_input_t))(
    input clk,
    input reset,
    
    input  [DATA_WIDTH-1:0] 		router_input,
    input   						router_input_valid,
    output 	reg			    		router_input_ready,
    
    output reg [CONFIG_BIT_WIDTH-1:0]		config_output,
    output reg						config_output_valid,
    input 							config_output_ready,
    
    output 	reg	[DATA_WIDTH-1:0] 	router_data_output,
    output 	reg						router_data_output_valid,
    input 							router_data_output_ready

  );

  reg [9:0] config_length;
  reg [53:0] config_data;
  reg [3:0] config_counter;
  
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_CONFIG,
    STATE_CONFIG_VALID,
    STATE_DATA,
    STATE_DATA_VALID
  } state;

  state present_state, next_state;

  // State Transition Logic
  always @(posedge clk) begin
    if (reset)
      present_state <= STATE_IDLE;
    else
      present_state <= next_state;
  end

  // Next State Logic
  always @(*) begin
    case (present_state)
      STATE_IDLE: begin
        if (router_input_valid && router_input_ready)
          next_state = STATE_CONFIG; // Transition directly to config out
        else
          next_state = STATE_IDLE;
      end
      STATE_CONFIG: begin
        if (config_counter == config_length-1)begin
          if (router_input_valid && router_input_ready)
             next_state =  STATE_CONFIG_VALID;
          else 
            next_state = STATE_CONFIG;
        end
        else
          next_state = STATE_CONFIG;
      end
      STATE_CONFIG_VALID:begin
        if(config_output_ready)
            next_state=STATE_DATA;
          else
            next_state=  STATE_CONFIG_VALID;
        end
       STATE_DATA: begin
         if ( config_data == 1)
          next_state = STATE_DATA_VALID;
        else
          next_state =  STATE_DATA;
      end
      STATE_DATA_VALID:begin
        if(router_data_output_ready)
          next_state=STATE_IDLE;
        else
		  next_state=STATE_DATA_VALID;
      end
      default:next_state=STATE_IDLE;
    endcase
  end

  // Output and Register Update Logic
  always @(posedge clk) begin
    if (reset) begin
      config_output <= 0;
      config_output_valid <= 0;
      router_data_output <= 0;
      router_data_output_valid <= 0;
      config_length <= 0;
      config_data<= 0;
      config_counter <= 0;
    end else begin
      case (present_state)
        STATE_IDLE: begin
          config_counter <= 0;
          if (router_input_valid && router_input_ready) begin
           config_length <= router_input[9:0];
            config_data <= router_input[63:10];
          end
        end
        STATE_CONFIG: begin
          if (config_counter < config_length) begin
            if (config_counter == config_length - 1)
              config_output_valid   <= 1;

            if (router_input_valid && router_input_ready) begin
              config_output[config_counter * DATA_WIDTH +: DATA_WIDTH] <= router_input;
              config_counter <= config_counter + 1;
            end else begin
               config_output <=  config_output;
               config_output_valid <= config_output_valid;
            end
          end
        end
        STATE_CONFIG_VALID:begin
          if(!config_output_ready)
             config_output_valid<=config_output_valid;
          else
             config_output_valid<=0;
        end
        STATE_DATA: begin
          if (config_data!= 0) begin
            if (router_input_valid && router_input_ready) begin
              router_data_output <= router_input;
              router_data_output_valid <= 1;
              config_data<= config_data - 1;
            end else begin
              router_data_output <= router_data_output;
              router_data_output_valid <= router_data_output_valid;
            end
          end else begin
            router_data_output<= router_data_output;
            router_data_output_valid <= router_data_output_valid;
          end
        end
        STATE_DATA_VALID:begin 
          if(!router_data_output_ready)
             router_data_output_valid<=router_data_output_valid;
          else
             router_data_output_valid<=0;
            
        end
        
      endcase
    end
  end

  // Ready Signal Logic
  always @(*) begin
    if (reset)
      router_input_ready = 0;
    else begin
      case (present_state)
        STATE_IDLE: router_input_ready = 1;
        STATE_CONFIG: router_input_ready =  config_output_ready;
        STATE_CONFIG_VALID:router_input_ready=0;
         STATE_DATA: router_input_ready = router_data_output_ready;
        STATE_DATA_VALID:router_input_ready=0;
      endcase
    end
  end
endmodule
