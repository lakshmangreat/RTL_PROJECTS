 // Design code
module skid_buffer
  #(w=3)

//Module i/o ports
(   input clk, 
    input reset,
 //Input axi interface
    input s_valid,
    input [w-1:0] s_data,
    output logic s_ready,
    //output axi interface
    output logic [w-1:0] m_data,
    output logic m_valid,
    input m_ready
);
    
    // Internal register
    logic skid_valid;
    logic [w-1:0] skid_data;
    
//declaring internal register axi valid
    always@(posedge clk)
        begin
            if(reset)
                begin
                    skid_valid<=0;
                end
            else if((s_valid && s_ready) && 
                    (m_valid && !m_ready))  //if reciever is not ready to accept
                begin                               //skid_valid gets high indicating data 
                    skid_valid<=1;                     //data is storing in buffer
                end
            else if(m_ready)
                begin
                    skid_valid<=0;
                end
        end
  
 
  always@(posedge clk)
    begin
      if( reset)
        begin
          skid_data<=0;
        end
      else if ( m_ready)  //if input ready gets low input data gets 
        begin                  
          skid_data<=0;
        end
      else if(( s_valid) && (s_ready))
        begin
          skid_data<=s_data;
        end
      else
        begin
        end
    end
  
  
 //output axi port
      always@(*)
        begin
          m_valid=s_valid || skid_valid;
           s_ready=!skid_valid;
        end
  
 //output      
  always @(*)
     begin
          if(skid_valid)
            m_data=skid_data;
          else if( s_valid && s_ready)
            m_data=s_data;
          else
            m_data=0;
        end
  
endmodule
  
