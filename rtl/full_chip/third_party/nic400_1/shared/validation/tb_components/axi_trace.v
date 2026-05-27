module axi_trace
  (
   // Global Signals
   ACLK,
   ARESETn,

   // Write Address Channel
   AWID,
   AWADDR,
   AWLEN,
   AWSIZE,
   AWBURST,
   AWLOCK,
   AWCACHE,
   AWPROT,
//   AWUSER,
   AWVALID,
   AWREADY,

   // Write Channel
   WID,
   WLAST,
   WDATA,
   WSTRB,
//   WUSER,
   WVALID,
   WREADY,

   // Write Response Channel
   BID,
   BRESP,
//   BUSER,
   BVALID,
   BREADY,

   // Read Address Channel
   ARID,
   ARADDR,
   ARLEN,
   ARSIZE,
   ARBURST,
   ARLOCK,
   ARCACHE,
   ARPROT,
//   ARUSER,
   ARVALID,
   ARREADY,

   // Read Channel
   RID,
   RLAST,
   RDATA,
   RRESP,
//   RUSER,
   RVALID,
   RREADY
   );

//------------------------------------------------------------------------------
// Block Parameters
//------------------------------------------------------------------------------

  parameter UNIT_NAME   = "axi_trace";  // name for trace instance
  parameter ECHO        = 1'b1;         // if true, echo to transcript

  // The sizes of the instantiated RAMs
  parameter RAM_SIZE = 32'h00020000;

  // Set ADDR_WIDTH to the address-bus width required
  parameter ADDR_WIDTH  = 32;           // data bus width, default = 32-bit

  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH  = 64;           // data bus width, default = 64-bit

  // Select the number of channel ID bits required
  parameter ID_WIDTH    = 13;            // (A|W|R|B)ID width


  // logged timestamp width
  parameter TIMESTAMP_WIDTH = 32;


  // logged AW payload width
  parameter AW_WIDTH    = 16 +          // AWID width (padded to 16 bits)
                          32 +          // AWADDR width
                          4 +           // AWLEN width
                          3 +           // AWSIZE width
                          2 +           // AWBURST width
                          4 +           // AWCACHE width
                          3 +           // AWPROT width
                          2 +           // AWLOCK width
                          2;            // handshake signals

  // logged W payload width
  parameter W_WIDTH    = 16 +           // WID width (padded to 16 bits)
                          1 +           // WLAST width
                          2;            // handshake signals

  // logged W payload width
  parameter B_WIDTH    = 16 +           // BID width (padded to 16 bits)
                          2 +           // BRESP width
                          2;            // handshake signals

  // logged AR payload width
  parameter AR_WIDTH    = 16 +          // ARID width (padded to 16 bits)
                          32 +          // ARADDR width
                          4 +           // ARLEN width
                          3 +           // ARSIZE width
                          2 +           // ARBURST width
                          4 +           // ARCACHE width
                          3 +           // ARPROT width
                          2 +           // ARLOCK width
                          2;            // handshake signals

  // logged R payload width
  parameter R_WIDTH     = 16 +          // RID width (padded to 16 bits)
                          1 +           // RLAST width
                          2 +           // RRESP width
                          2;            // handshake signals

  // total memory width
  parameter MEM_WIDTH   = TIMESTAMP_WIDTH +
                          AW_WIDTH + 
                          W_WIDTH +
                          B_WIDTH +
                          AR_WIDTH +
                          R_WIDTH;



  // Do not override the following parameters: they must be calculated exactly
  // as shown below
  parameter ADDR_MAX    = ADDR_WIDTH-1; // addr max index
  parameter DATA_MAX    = DATA_WIDTH-1; // data max index
  parameter STRB_WIDTH  = DATA_WIDTH/8; // WSTRB width
  parameter STRB_MAX    = STRB_WIDTH-1; // WSTRB max index
  parameter ID_MAX      = ID_WIDTH-1;   // ID max index


  parameter ID_PAD_WIDTH = (ID_WIDTH > 16) ? 0 : 16-ID_WIDTH; // make ID up to 16 bits for log file


//------------------------------------------------------------------------------
// Inputs
//------------------------------------------------------------------------------

  // Global signals
  input                ACLK;
  input                ARESETn;

  // Write Address channel
  input     [ID_MAX:0] AWID;
  input   [ADDR_MAX:0] AWADDR;
  input          [3:0] AWLEN;
  input          [2:0] AWSIZE;
  input          [1:0] AWBURST;
  input          [3:0] AWCACHE;
  input          [2:0] AWPROT;
  input          [1:0] AWLOCK;
  input                AWVALID;
  input                AWREADY;

  // Write data channel
  input     [ID_MAX:0] WID;
  input   [DATA_MAX:0] WDATA;
  input   [STRB_MAX:0] WSTRB;
  input                WLAST;
  input                WVALID;
  input                WREADY;

  // Write completion channel
  input     [ID_MAX:0] BID;
  input          [1:0] BRESP;
  input                BVALID;
  input                BREADY;

  // Read Address channel
  input     [ID_MAX:0] ARID;
  input   [ADDR_MAX:0] ARADDR;
  input          [3:0] ARLEN;
  input          [2:0] ARSIZE;
  input          [1:0] ARBURST;
  input          [3:0] ARCACHE;
  input          [2:0] ARPROT;
  input          [1:0] ARLOCK;
  input                ARVALID;
  input                ARREADY;

  // Read data channel
  input     [ID_MAX:0] RID;
  input   [DATA_MAX:0] RDATA;
  input          [1:0] RRESP;
  input                RLAST;
  input                RVALID;
  input                RREADY;


//------------------------------------------------------------------------------
// Beginning of main code
//------------------------------------------------------------------------------

  //-----------------------------------------------------------
  // AXI TRACE LOGGING
  //-----------------------------------------------------------

  reg [AW_WIDTH-1:0] aw_chan_q;
  reg  [W_WIDTH-1:0] w_chan_q;
  reg  [B_WIDTH-1:0] b_chan_q;
  reg [AR_WIDTH-1:0] ar_chan_q;
  reg  [R_WIDTH-1:0] r_chan_q;

  // Count cycles since reset
  reg [TIMESTAMP_WIDTH-1:0] GlobalTimeStamp;
  always @(posedge ACLK or negedge ARESETn)
  if(~ARESETn)
    GlobalTimeStamp <= {TIMESTAMP_WIDTH{1'b0}};
  else
    GlobalTimeStamp <= GlobalTimeStamp + {{TIMESTAMP_WIDTH-1{1'b0}},1'b1}; 

  // Registered payload values - excepting the data
  always @(posedge ACLK) begin
    aw_chan_q   <= {{ID_PAD_WIDTH{1'b0}},AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWCACHE,AWPROT,AWLOCK,AWVALID,AWREADY};
    w_chan_q    <= {{ID_PAD_WIDTH{1'b0}},WID,WLAST,WVALID,WREADY};
    b_chan_q    <= {{ID_PAD_WIDTH{1'b0}},BID,BRESP,BVALID,BREADY};
    ar_chan_q   <= {{ID_PAD_WIDTH{1'b0}},ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARCACHE,ARPROT,ARLOCK,ARVALID,ARREADY};
    r_chan_q    <= {{ID_PAD_WIDTH{1'b0}},RID,RLAST,RRESP,RVALID,RREADY};
  end

  
  //-----------------------------------------------------------
  // LOG AXI SIGNALS AND TIMESTAMP
  //-----------------------------------------------------------
  reg [MEM_WIDTH-1:0] axi_ram_q[RAM_SIZE-1:0];
  reg          [31:0] axi_ram_ptr_q;  
  wire                do_log = 1'b1;

  // Update the RAM index pointer
  always @(posedge ACLK or negedge ARESETn)
  if(~ARESETn)
    axi_ram_ptr_q <= {MEM_WIDTH{1'b0}};
  else if (do_log && (axi_ram_ptr_q != (RAM_SIZE-1)))
    axi_ram_ptr_q <= axi_ram_ptr_q + 32'h00000001; 

  // Write the vector to RAM
  always @(posedge ACLK)
    if (do_log)
      axi_ram_q[axi_ram_ptr_q] <= {GlobalTimeStamp, 
                                  aw_chan_q,
                                  w_chan_q,
                                  b_chan_q,
                                  ar_chan_q,
                                  r_chan_q};




  //-----------------------------------------------------------
  // Binary trace file output
  //-----------------------------------------------------------

  integer     TraceFile;

  // default filename for binary trace file
  initial
    if (ECHO) begin
      TraceFile = $fopen({UNIT_NAME,".trc"}, "w");
      if (!TraceFile)
        begin
          $display("Could not open %s",{UNIT_NAME,".trc"});
          $finish;
        end
      $write("Generating trace file %s using handle %x\n", {UNIT_NAME,".trc"}, TraceFile);

      $fwrite(TraceFile,"%s\n",UNIT_NAME);
    end


  reg         TracingStarted;

  initial
    begin
      // wait for simulation to get started
      TracingStarted <= 1'b0;
      wait (ACLK === 1'b0)
        TracingStarted <= 1'b1;
        $write("Starting tracing to file %s\n",{UNIT_NAME,".trc"});
    end

  // Only log handshakes when something interesting happens
  //   - valid 0->1 or 1->0
  //   - ready 0->1 or 1->0
  //   - handshake (valid & ready)
  wire [4:0] axi_valid = {AWVALID, WVALID, BVALID, ARVALID, RVALID};
  wire [4:0] axi_ready = {AWREADY, WREADY, BREADY, ARREADY, RREADY};

  reg  [4:0] axi_valid_q;
  reg  [4:0] axi_ready_q;
  always @(posedge ACLK) begin
    axi_valid_q <= axi_valid;
    axi_ready_q <= axi_ready;
  end

//  wire do_log = |(
//                  ((axi_valid ^ axi_valid_q)) | 
//                  ((axi_ready ^ axi_ready_q)) |
//                  ((axi_valid & axi_ready))
//                 );


  always @(posedge ACLK)
    if (TracingStarted) // begin

    $fwrite(TraceFile,"%x %b %x %x %x %x %x %x %x\n",
            GlobalTimeStamp,
            ARESETn,
            {    1'b0,   AWCACHE, AWPROT, AWLOCK, AWLEN, AWVALID, AWREADY, {ID_PAD_WIDTH{1'b0}}, AWID},
            {{13{1'b0}},                          WLAST, WVALID,  WREADY,  {ID_PAD_WIDTH{1'b0}},  WID},
            {{12{1'b0}},                          BRESP, BVALID,  BREADY,  {ID_PAD_WIDTH{1'b0}},  BID},
            {    1'b0,   ARCACHE, ARPROT, ARLOCK, ARLEN, ARVALID, ARREADY, {ID_PAD_WIDTH{1'b0}}, ARID},
            {{11{1'b0}},                  RRESP,  RLAST, RVALID,  RREADY,  {ID_PAD_WIDTH{1'b0}},  RID},
            AWADDR,
            ARADDR);

//      if (ECHO && do_log)
//        $write("%s: %x %b %x %x %x %x %x %x %x\n",
//                UNIT_NAME,
//                GlobalTimeStamp,
//                ARESETn,
//                {    1'b0,   AWCACHE, AWPROT, AWLOCK, AWLEN, AWVALID, AWREADY, {ID_PAD_WIDTH{1'b0}}, AWID},
//                {{12{1'b0}},                          WLAST, WVALID,  WREADY,  {ID_PAD_WIDTH{1'b0}},  WID},
//                {{12{1'b0}},                          BRESP, BVALID,  BREADY,  {ID_PAD_WIDTH{1'b0}},  BID},
//                {    1'b0,   ARCACHE, ARPROT, ARLOCK, ARLEN, ARVALID, ARREADY, {ID_PAD_WIDTH{1'b0}}, ARID},
//                {{11{1'b0}},                  RRESP,  RLAST, RVALID,  RREADY,  {ID_PAD_WIDTH{1'b0}},  RID},
//                AWADDR,
//                ARADDR);
//    end

//-----------------------------------------------------------


  axi_ot_mon     u_axi_ot_mon(
      .awvalid        (AWVALID),
      .awready        (AWREADY),

      .wvalid         (WVALID),
      .wready         (WREADY),
      .wlast          (WLAST),

      .bvalid         (BVALID),
      .bready         (BREADY),

      .arvalid        (ARVALID),
      .arready        (ARREADY),

      .rvalid         (RVALID),
      .rready         (RREADY),
      .rlast          (RLAST),

      .aclk           (ACLK),
      .aresetn        (ARESETn)
  );
  defparam u_axi_ot_mon.UNIT_NAME = UNIT_NAME;

//-----------------------------------------------------------

endmodule // axi_trace
