
typedef struct packed {
    
logic [11:0] BWPstart;
logic [8:0] BWPsize;
logic [1:0] copeset;
logic [6:0] slotnumber;
logic [15:0] Nid;
logic [3:0] startsymbol;
logic [1:0] startsymbolindex;
logic [12:0] dmrsoffset;
logic [44:0] freqbitmap;
  logic [0:0] coreset_type;
} config_input_t;

typedef struct packed {

  logic [30:0] Cinit;
    logic [15:0] pnseqlength;
    logic [12:0] dmrsoffset;
    logic [44:0] freqbitmap;   
} config_out_t;
