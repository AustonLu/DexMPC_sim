module apb_trace
  (

    PCLK,
    PCLKEN,
    presetn,
    PSEL,
    PENABLE,
    PWRITE,
    PADDR,
    PWDATA,
    PREADY,
    PSLVERR,
    PRDATA

   );

//------------------------------------------------------------------------------
// Block Parameters
//------------------------------------------------------------------------------

  parameter UNIT_NAME   = "apb_trace";  // name for trace instance
  parameter ECHO        = 1'b1;         // if true, echo to transcript

  // The sizes of the instantiated RAMs
  parameter RAM_SIZE = 32'h00020000;

  // Set DATA_WIDTH to the data-bus width required
  parameter DATA_WIDTH  = 64;           // data bus width, default = 64-bit

  // Select the number of channel ID bits required
  parameter ID_WIDTH    = 13;            // (A|W|R|B)ID width


  // logged timestamp width
  parameter TIMESTAMP_WIDTH = 32;


  // logged AW payload width
  parameter AW_WIDTH    = 16 +          // AWID width (padded to 16 bits)
                          32 +          // AWADDR width
                          8 +           // AWLEN width
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
                          8 +           // ARLEN width
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
  parameter DATA_MAX    = DATA_WIDTH-1; // data max index
  parameter STRB_WIDTH  = DATA_WIDTH/8; // WSTRB width
  parameter STRB_MAX    = STRB_WIDTH-1; // WSTRB max index
  parameter ID_MAX      = ID_WIDTH-1;   // ID max index


  parameter ID_PAD_WIDTH = (ID_WIDTH > 16) ? 0 : 16-ID_WIDTH; // make ID up to 16 bits for log file


//------------------------------------------------------------------------------
// Inputs
//------------------------------------------------------------------------------

input         PENABLE;         // APB Enable
input         PWRITE;          // APB transfer(R/W) direction
input  [31:0] PADDR;           // APB address
input  [31:0] PWDATA;          // APB write data
input         PREADY;          // APB transfer completion signal for slaves
input         PSLVERR;         // APB transfer response signal for slaves
input  [31:0] PRDATA;          // APB read data for slave0
input         PSEL;
  
input         PCLK;
input         PCLKEN;
input         presetn;

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

  wire    [ID_MAX:0] WID = {ID_WIDTH{1'b0}};

  wire AWVALID = (PSEL && !PENABLE && PWRITE);
  wire AWREADY = 1'b1; // ever ready

  wire ARVALID = (PSEL && !PENABLE && !PWRITE);
  wire ARREADY = 1'b1; // ever ready

//   reg write_in_progress;
//   reg read_in_progress;
// 
//   always @(posedge PCLK or negedge presetn) begin
//     if(~presetn)
//     begin
//       write_in_progress <= 1'b0;
//       read_in_progress <= 1'b0;
//     end
//     else
//     begin
//       if (AWVALID && AWREADY)
//         write_in_progress <= 1'b1;
//       else
//         if (write_in_progress && PREADY)
//           write_in_progress <= 1'b0;
//       if (ARVALID && ARREADY)
//         read_in_progress <= 1'b1;
//       else
//         if (read_in_progress && PREADY)
//           read_in_progress <= 1'b0;
//     end
//   end

  wire WVALID = (PSEL && PENABLE && PWRITE);
  wire WREADY = PREADY;
  wire WLAST = WVALID; 

  wire RVALID = (PSEL && PENABLE && !PWRITE);
  wire RREADY = PREADY;
  wire RLAST = RVALID; 

  wire BVALID = (WVALID && WREADY && WLAST); // last cycle of W transfer
  wire BREADY = 1'b1; // ever ready

  wire [31:0] AWADDR = AWVALID ? PADDR : 32'hx;
  wire [31:0] ARADDR = ARVALID ? PADDR : 32'hx;

  // Count cycles since reset
  reg [TIMESTAMP_WIDTH-1:0] GlobalTimeStamp;
  always @(posedge PCLK  or negedge presetn)
  if(~presetn)
    GlobalTimeStamp <= {TIMESTAMP_WIDTH{1'b0}};
  else
    GlobalTimeStamp <= GlobalTimeStamp + {{TIMESTAMP_WIDTH-1{1'b0}},1'b1}; 

  // Registered payload values - excepting the data
  always @(posedge PCLK ) begin
    aw_chan_q   <= {{ID_PAD_WIDTH{1'b0}},{ID_WIDTH{1'b0}},PADDR,8'h00,3'h0,2'h0,4'h0,3'h0,1'b0,1'b0,AWVALID,AWREADY};
    w_chan_q    <= {{ID_PAD_WIDTH{1'b0}},{ID_WIDTH{1'b0}},WLAST,WVALID,WREADY};
    b_chan_q    <= {{ID_PAD_WIDTH{1'b0}},{ID_WIDTH{1'b0}},1'b0,PSLVERR,BVALID,BREADY};
    ar_chan_q   <= {{ID_PAD_WIDTH{1'b0}},{ID_WIDTH{1'b0}},PADDR,8'h00,3'h0,2'h0,4'h0,3'h0,1'b0,1'b0,ARVALID,ARREADY};
    r_chan_q    <= {{ID_PAD_WIDTH{1'b0}},{ID_WIDTH{1'b0}},RLAST,1'b0,PSLVERR,RVALID,RREADY};
  end

  
  //-----------------------------------------------------------
  // LOG AXI SIGNALS AND TIMESTAMP
  //-----------------------------------------------------------
  reg [MEM_WIDTH-1:0] axi_ram_q[RAM_SIZE-1:0];
  reg          [31:0] axi_ram_ptr_q;  
  wire                do_log = 1'b1;

  // Update the RAM index pointer
  always @(posedge PCLK  or negedge presetn)
  if(~presetn)
    axi_ram_ptr_q <= {MEM_WIDTH{1'b0}};
  else if (do_log && (axi_ram_ptr_q != (RAM_SIZE-1)))
    axi_ram_ptr_q <= axi_ram_ptr_q + 32'h00000001; 

  // Write the vector to RAM
  always @(posedge PCLK )
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
      wait (PCLK  === 1'b0)
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
  always @(posedge PCLK ) begin
    axi_valid_q <= axi_valid;
    axi_ready_q <= axi_ready;
  end

//  wire do_log = |(
//                  ((axi_valid ^ axi_valid_q)) | 
//                  ((axi_ready ^ axi_ready_q)) |
//                  ((axi_valid & axi_ready))
//                 );


  always @(posedge PCLK )
    if (TracingStarted) // begin

    $fwrite(TraceFile,"%x %b %x %x %x %x %x %x %x\n",
            GlobalTimeStamp,
            presetn,
            {{14{1'b0}},                                 AWVALID, AWREADY, 16'h0000},
            {{13{1'b0}},                          WLAST, WVALID,  WREADY,  16'h0000},
            {{14{1'b0}},                                 BVALID,  BREADY,  16'h0000},
            {{14{1'b0}},                                 ARVALID, ARREADY, 16'h0000},
            {{13{1'b0}},                          RLAST, RVALID,  RREADY,  16'h0000},
            AWADDR,
            ARADDR);

//      if (ECHO && do_log)
//        $write("%s: %x %b %x %x %x %x %x %x %x\n",
//                UNIT_NAME,
//                GlobalTimeStamp,
//                presetn,
//                {    1'b0,   AWCACHE, AWPROT, AWLOCK, AWLEN, AWVALID, AWREADY, {ID_PAD_WIDTH{1'b0}}, AWID},
//                {{12{1'b0}},                          WLAST, WVALID,  WREADY,  {ID_PAD_WIDTH{1'b0}},  WID},
//                {{12{1'b0}},                          BRESP, BVALID,  BREADY,  {ID_PAD_WIDTH{1'b0}},  BID},
//                {    1'b0,   ARCACHE, ARPROT, ARLOCK, ARLEN, ARVALID, ARREADY, {ID_PAD_WIDTH{1'b0}}, ARID},
//                {{11{1'b0}},                  RRESP,  RLAST, RVALID,  RREADY,  {ID_PAD_WIDTH{1'b0}},  RID},
//                AWADDR,
//                ARADDR);
//    end

//-----------------------------------------------------------

endmodule // axi4_trace
