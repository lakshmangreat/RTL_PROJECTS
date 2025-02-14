module pdcch_controller #(parameter
                        CONFIG_BIT_OUT_WIDTH=$bits(config_out_t),
                          CONFIG_BIT_WIDTH = $bits(config_input_t)
)(
    input clk,
    input reset,
    
    // From the input skid buffer
    input s_cntlr_valid,
    input [CONFIG_BIT_WIDTH-1:0] s_cntlr_data,
    output logic s_cntlr_ready,
    
    // To the output skid buffer
    output logic m_cntlr_valid,
    output logic [CONFIG_BIT_OUT_WIDTH-1:0] m_cntlr_data,
    input logic m_cntlr_ready
);

// Configuration Structures
config_input_t  cntlr_in_config;
config_out_t    cntlr_out_config;

// Temporary Registers for calculations
logic [6:0] slotnumber;
logic [1:0] startsymbolindex ; // Constant index for simplicity
logic [15:0] Nid;
  logic [30:0] C_init;
  logic [15:0] pnseqlength;
  logic [12:0]  dmrsoffset;
  logic [44:0]freqbitmap;
  logic[12:0] dupc_1;
  logic[17:0] dupc_2;
  logic[17:0]dupc_3;
  logic[30:0] dupc_4;
  logic[30:0] dupc_5;

// FSM State Declaration
  typedef enum logic [3:0] {
    idle,
    caluculation,
    read,
  reg1,
  reg2,
    reg3,
  write
} fsm_state_t;

fsm_state_t state, next_state;

// State Transitions
always @(posedge clk ) begin
    if (reset) begin
        state <= idle;
    end else begin
        state <= next_state;
    end
end

// Next State Logic
  always @(*) begin
    case (state)
        idle: begin
       next_state =read;
        end
     read:begin
       if(s_cntlr_valid && s_cntlr_ready)
            next_state=caluculation;
          else
            next_state=read;
        end
        caluculation:
          begin
            next_state = reg1;
           
          end
      reg1 : begin
        next_state =reg2;
      end
      reg2 : begin
        next_state =reg3;
      end
      reg3 : begin
        next_state =write;
      end
        write: begin
            if (m_cntlr_ready) begin
                next_state = idle;
            end else begin
                next_state = write;
            end
        end
        default: next_state = idle;
    endcase
        end 

// FSM Output Logic
always @(posedge clk)
    begin
      if(reset)begin
        cntlr_out_config.C_init<=0;
        cntlr_out_config.pnseqlength<=0;
        cntlr_out_config.dmrsoffset<=0;
        cntlr_out_config.freqbitmap<=0;
        cntlr_in_config<=0;
      end
      else
        begin
  
  
  
        case (state)
         idle: begin
  // Check if the module is not ready to receive configuration data
  if (!m_cntlr_ready) begin
    // Set the output valid signal to indicate data is valid
    m_cntlr_valid <= 1;
  end
         
  else begin
    // If ready, reset the valid signal
    m_cntlr_valid <= 0;
  end
end

read: begin
  // If both input configuration valid and ready signals are asserted
  if (s_cntlr_valid && s_cntlr_ready) begin
    // Read configuration data from the input
    cntlr_in_config <= s_cntlr_data;
  end
  else begin
    // Maintain the current configuration if not ready
    cntlr_in_config <= cntlr_in_config;
  end
end

          
          
            caluculation: begin
                slotnumber <= cntlr_in_config.slotnumber;
                startsymbolindex <= cntlr_in_config.startsymbolindex;
                Nid <= cntlr_in_config.Nid;

                // Calculation for Cinit
              
              dupc_1     <= (14 * cntlr_in_config.slotnumber) + cntlr_in_config.startsymbolindex + 1;
              dupc_2    <=  (2 * cntlr_in_config.Nid + 1);
              dupc_3 <= (2 * cntlr_in_config.Nid);
              
 // cntlr_out_config.Cinit <= ((18'h20000 * (((14 * cntlr_in_config.slotnumber + cntlr_in_config.startsymbolindex + 1) * (2 * cntlr_in_config.Nid + 1)) + (2 * cntlr_in_config.Nid))) % 214748364);
              cntlr_out_config.dmrsoffset<= cntlr_in_config.dmrsoffset;
              if(cntlr_in_config.coreset_type==1)
                begin 
                  cntlr_out_config.pnseqlength <= (cntlr_in_config.BWPsize*cntlr_in_config.BWPstart)*6;
                end 
              else
                begin
                  cntlr_out_config.pnseqlength<= cntlr_in_config.BWPsize*6;
                 //cntlr_out_config.dmrsoffset<=0;
                end
              cntlr_out_config.freqbitmap<= cntlr_in_config.freqbitmap;
            
            end
          
            
            
                reg1: begin
                // cntlr_out_config.CINIT <= ((18'h20000*((var1*var2)+var3))% 2147483648);
                  dupc_5 <= (dupc_1*dupc_2); //13+18+1 bits = 31bits
            end
            
             reg2:begin 
               dupc_4 <= 18'h20000*((dupc_5)+dupc_3); end
            reg3: begin
                cntlr_out_config.C_init <=  dupc_4 % 32'sh80000000;
            end
   write: begin
  // Assign values to output signals from configuration
  C_init <= cntlr_out_config.C_init;
  pnseqlength <= cntlr_out_config.pnseqlength;
  dmrsoffset <= cntlr_out_config.dmrsoffset;
  freqbitmap <= cntlr_out_config.freqbitmap;

  // Handle data transfer if ready signal is asserted
  if (m_cntlr_ready) begin
    m_cntlr_data <= cntlr_out_config;
    m_cntlr_valid <= 1;
  end
  else begin
    // Maintain the current validity status if not ready
    if (!m_cntlr_ready) begin
      m_cntlr_valid <= m_cntlr_valid;
    end
    else begin
      m_cntlr_valid <= 0;
    end
  end
  end
     endcase      
        end
        end

// Ready Signal Logic
          always @(posedge clk)
            
            begin 
              if(reset)
        s_cntlr_ready=0;
      else
        begin
    case (state)
        idle: s_cntlr_ready = 0;
      read:s_cntlr_ready=1;
        caluculation: s_cntlr_ready = 0;
      reg1: s_cntlr_ready = 0;
      reg2: s_cntlr_ready = 0;
      reg3: s_cntlr_ready = 0;
        write: s_cntlr_ready = 0;
        default: s_cntlr_ready = 0;
    endcase
        end 
            end

endmodule
