// --=========================================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from ARM Limited
//     (C) COPYRIGHT 2004-2013 ARM Limited
//           ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
//  Version and Release Control Information:
//
//  File Name           : FrsFileReader.v,v
//  File Revision       : 1.10
//
//  Release Information : BP144-MN-22001-r0p0-00alp1
// -----------------------------------------------------------------------------
//  Purpose             : FRM file reader
//
//                        A behavioral module that converts values in
//                        a stimulus file into signals. 
//                        This version is for Master channels. (B & R)
//
//                        Two flags are kept for each entry in the file list
//                        1) Complete.... the transaction has been completed 
//                           (read into the outstanding transaction block)
//                        2) Enable ... Transaction has seen it's trigger event
//                           (WLAST or AR)
//                        
// --=========================================================================--

`timescale 1ns / 1ps

module FrsFileReaderM
(
  ACLK,
  ARESETn,

  Enable_ID,
  Enable_ID_valid,
  Enable_ID_ready_in,
  Enable_ID_error,

  FileData,
  FileReady,
  FileValid,

  Time,

  Wait,
  Wait_valid,

  SyncValid,
  SyncReady

);


  // Module parameters
  parameter FILE_LEN        = 1000;                  // Length of stimulus memory
  parameter VECTOR_WIDTH    = 128;                   // Width of stimulus memory
  parameter STIM_FILE_NAME  = "";                    // Stimulus file name
  parameter MESSAGE_TAG     = "FileRdMasterAxi:";    // Message prefix
  parameter VERBOSE         = 1;                     // Verbosity control
  parameter FILE_ID         = 16'hd000;              // Used to identify file type
  parameter ID_WIDTH        = 8;
  parameter ID_BASE         = 8;
  parameter EW_WIDTH        = 8;
  parameter WAIT_BASE       = 0;
  parameter SYNC            = 0;
  parameter FIRST           = 0;                     //Bit in the memory that indicates 
  parameter OUTTRANS        = 16;
  parameter TIME_BASE       = 0;
  parameter TIME_WIDTH      = 8;
  parameter WAIT_FOR_HNDSHK = 1;                     //Wait for input handshk
  parameter LAST            = 8;
                                                     //the first beat of a transfer
  parameter ID_TOP          = ID_BASE + ID_WIDTH - 1;
  parameter TIME_TOP        = TIME_BASE + TIME_WIDTH - 1;
  parameter WAIT_TOP        = WAIT_BASE + EW_WIDTH - 1;

  // Calculated parameters - do not modify
  parameter VECTOR_MAX
              = VECTOR_WIDTH - 1;                    // Upper bound of stimulus memory vector

  parameter WAIT_MAX = VECTOR_MAX + 32 + 1;

  // Module Inputs
  input                 ACLK;                        // Clock input
  input                 ARESETn;                     // Reset async input active low

  input [31:0]          Time;

  input [ID_WIDTH-1:0]  Enable_ID;                   //ID of transaction to load
  input                 Enable_ID_valid;
  input                 Enable_ID_ready_in;
  output                Enable_ID_error;

  input  [EW_WIDTH-1:0] Wait;
  input                 Wait_valid;

  output [VECTOR_MAX:0] FileData;
  input                 FileReady;
  output                FileValid;

  output                SyncValid;        //Flag Valid Sync
  input                 SyncReady;        //Flag Sync Complete

//------------------------------------------------------------------------------
// Constant declarations
//------------------------------------------------------------------------------

//------ ------------------------------------------------------------------------
// Signal declarations
//------------------------------------------------------------------------------

// Input / Output Signals

  wire                ACLK;
  wire                ARESETn;

  wire [VECTOR_MAX:0] Check_sync;
  reg  [VECTOR_MAX:0] Entry;
  wire [VECTOR_MAX:0] ReplaceVector;

  reg  [FILE_LEN-1:0] Complete;
  reg  [FILE_LEN-1:0] Enable;

// Internal Signals

  // File array of length specified by FILE_LEN.
  // Contains the vector data from the file
  reg  [VECTOR_MAX:0] FileMem [0:(FILE_LEN - 1)]; // vector array

  reg   [WAIT_MAX:0] Waiting [0:OUTTRANS]; 
  reg          [31:0] WaitingValid;
  wire         [31:0] WaitingValidNxt;

  // Flag indicates that there is valid data in the array
  reg                 iFileValid;       // internal FileValid

  // Flag inidcates when to read the next vector
  wire                Update;           // update the array pointer

  // Pointers into stimulus array
  reg    [31:0]       ArrayPt;          // pointer to current stimulus vector
  reg    [31:0]       ArrayMax;         // limit of valid vectors in array
  wire   [31:0]       select;           // determine which array element to load
  reg    [31:0]       enable_trans;       // determine which array element to load

  //Working slots ....

  wire                 Replace;
  reg                  Start;
  reg                  Start_immediate;
  wire                 new_transaction;
  wire                 start_new_transaction;
  reg  [31:0]          Start_trans;
  reg  [31:0]          count;
  reg  [31:0]          check_count;
  reg  [WAIT_MAX:0]    CheckVector;
  wire [WAIT_MAX:0]    ArbVector;
  reg  [VECTOR_MAX:0]  IDVector;
  wire [VECTOR_MAX:0]  FileData;
  reg  [WAIT_MAX:0]    Wait_select;

  reg [WAIT_MAX:0]     WaitingVector;
  reg [31:0]           counter;
  wire                 get_next_beat;
  wire [ID_WIDTH-1:0]  beat_ID;
  wire                 enable_transaction;
  wire                 SyncComplete;

  reg                  EnableValid_reg;
  reg                  EnableReady_reg;
  wire                 EnablePulse;

//------------------------------------------------------------------------------
// Beginning of main code (behavioral)
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Set up the time format
//------------------------------------------------------------------------------

  initial
  begin : p_TimeFormatBhav
      $timeformat(-9, 0, " ns", 0);
  end


//----------------------------------------------------------------------------
// Open vector File
//----------------------------------------------------------------------------
// Loads the vector file into an array and determines the number of vectors in
// the array. This process is only executed once.

  initial
  begin : p_OpenFileBhav

    if (VERBOSE > 0)
      begin
        // report the stimulus file name
        $display(
          "%t %s %s %s",
          $time,
          MESSAGE_TAG,
          "Loading stimulus file",
          STIM_FILE_NAME
        );

        // report the stimulus array size
        $display(
          "%t %s %s %0d",
          $time,
          MESSAGE_TAG,
          "Stimulus array size",
          FILE_LEN
        );
      end

    // Load the file into memory
    $readmemh(STIM_FILE_NAME, FileMem);

    // Determine the number of vectors in the array
    ArrayMax = 32'h00000000;
    while ( (ArrayMax < FILE_LEN) && 
            (FileMem[ArrayMax] !== {VECTOR_WIDTH{1'bx}})  ) begin
            ArrayMax = ArrayMax + 1;
    end

  end


//------------------------------------------------------------------------------
// Complete logic 
// 
// Find Beat to replace one in the writing queue. 
//------------------------------------------------------------------------------

  //Get the ID of the beat about to be arbitarted
  assign ArbVector = (Start_immediate) ? {Enable_ID_ready_in, enable_trans, Entry} : Waiting[Start_trans];
  assign beat_ID   = ArbVector[ID_TOP:ID_BASE];

  //Select the next possible vector
  assign select        = ArbVector[WAIT_MAX-1:VECTOR_MAX+1] + 32'b1;
  assign ReplaceVector = FileMem[select];

  //Set up the other outputs
  assign Replace   = ((select < ArrayMax) &&
                       ~(ReplaceVector[SYNC]) &&
                       (ReplaceVector[ID_TOP:ID_BASE] == beat_ID) &&
                       ~(ReplaceVector[FIRST]) &&
                       start_new_transaction);

  //Detect the completion of a sync
  assign SyncComplete = SyncValid & SyncReady;

//------------------------------------------------------------------------------
// Complete
//
// Find first beat to add to the queue when enable signal occurs 
//------------------------------------------------------------------------------
  always @(ArrayPt or ArrayMax or Complete or Enable_ID)
     begin

          //Default 
          enable_trans = ArrayPt;
          Entry = FileMem[enable_trans];
          
          //find the first non complete ID match that is the first beat of a transaction
          while (((Complete[enable_trans] || ~Entry[FIRST] || (Entry[ID_TOP:ID_BASE] != Enable_ID))) && 
            ((enable_trans < ArrayMax) && ~(Entry[SYNC] && ~Complete[enable_trans]))) begin 

             //increment the pointer
             enable_trans = enable_trans + 1;
             Entry = FileMem[enable_trans];
          end
    end

  //Flag an error if the signal is not found
  assign Enable_ID_error = EnablePulse && (Entry[SYNC] || enable_trans == ArrayMax);
  assign enable_transaction = EnablePulse && ~Enable_ID_error;

//------------------------------------------------------------------------------
// Offset Logic for allowing 
//
//------------------------------------------------------------------------------

  always @(posedge ACLK or negedge ARESETn)
    begin
      if (~ARESETn) begin
        EnableValid_reg <= 1'b0;
        EnableReady_reg <= 1'b0;
      end else begin
        EnableValid_reg <= Enable_ID_valid;
        EnableReady_reg <= Enable_ID_ready_in;
      end
    end

  // Generate pulse for the start of each AR valid
  assign EnablePulse = (Enable_ID_valid && (~EnableValid_reg || (EnableValid_reg && EnableReady_reg))) ? 1'b1 : 1'b0;

//------------------------------------------------------------------------------
// Complete Registered logic Logic 
//------------------------------------------------------------------------------  
  always @ (posedge ACLK or negedge ARESETn)
  begin : p_CompleteReg

    if (!ARESETn) begin
      Complete <= {FILE_LEN{1'b0}};
    end else begin

       //Complete updated logic  
       if (Replace) begin
           Complete[select] <= 1'b1; 
       end

       //Complete new logic
       if (enable_transaction) begin
           Complete[enable_trans] <= 1'b1; 
       end

       //Sync
       if (SyncComplete) begin
           Complete[ArrayPt] <= 1'b1;
       end

   end
  end

//------------------------------------------------------------------------------
// Sync Logic 
//------------------------------------------------------------------------------

  //Report a sync if there are no incomplete transactions before a SYNC (i.e
  //ArrayPt points at a sync
  assign Check_sync = FileMem[ArrayPt];
  assign SyncValid  = Check_sync[SYNC] & ~FileValid & ~|WaitingValid;

//------------------------------------------------------------------------------
// Array pointer update signal
//------------------------------------------------------------------------------
  assign Update = (ArrayPt < ArrayMax) &&
                  (SyncComplete ||
                  Replace || enable_transaction);

  function [31:0] array_jump;

     input [FILE_LEN-1:0] Complete;
     input [31:0]         ArrayPt;
     input                SyncComplete;
     input [31:0]         Complete_now;
     input [31:0]         Enable_now;
 
     begin
        array_jump = {31'b0, SyncComplete};
        while(Complete[array_jump + ArrayPt] ||
                 (Complete_now == (array_jump + ArrayPt)) ||
                 (Enable_now == (array_jump + ArrayPt))) begin
             array_jump = array_jump + 1;
        end
     end

  endfunction

  always @ (posedge ACLK or negedge ARESETn)
   begin : p_ArrayPtReg

    if (!ARESETn) begin
       ArrayPt <= 1; //First vector is a channel code not a vector 
    end else if (Update) begin
       ArrayPt <= ArrayPt + array_jump(Complete, ArrayPt, SyncComplete,
                                         (select & {32{Replace}}),    // Complete the replaced transaction
                                         (enable_trans & {32{enable_transaction}}));    //Complete the enabled transaction
    end
  end

//------------------------------------------------------------------------------
// Waiting Logic 
//------------------------------------------------------------------------------

  //Entry in the FileMem line that is being enabled
  //ReplaceVector is the vector we are replacing


  //Waiting valid_next
  assign WaitingValidNxt = (start_new_transaction & ~enable_transaction & ~Replace) ? WaitingValid - 32'b1 :
                           (enable_transaction & (Replace || (~start_new_transaction & ~Replace))) ? WaitingValid + 32'b1 : WaitingValid;
                           
  //Clocked process to work around some memory limitationss of vlog'95
  always @(posedge ACLK) begin

       //Go through each valid 
       for (counter = 0; counter <= OUTTRANS; counter = counter + 1) begin

             //Update wait
             WaitingVector = Waiting[counter];
             if (Wait_valid && (WaitingVector[WAIT_TOP:WAIT_BASE] == Wait)) begin
                    WaitingVector[11] = 1'b0;
             end

             //Increase time by one if there is still a wait on the transaction
             if (WaitingVector[11] == 1'b1) begin
                 WaitingVector[TIME_TOP:TIME_BASE] = WaitingVector[TIME_TOP:TIME_BASE] + 32'b1;      
             end        

             //Update all ready flags 
             if (WaitingVector[WAIT_MAX] == 1'b0) begin
                 WaitingVector[WAIT_MAX] = Enable_ID_ready_in;    
             end

             //Option 0 .. If we are starting a transaction and it's a single beat do nothing.
             if (Start_immediate && ~Replace) begin
                  Waiting[counter] <= WaitingVector;
             //Option 1 .. deal with replace ... when a beat has arbitrated and can be replaced in the list
             end else if (Replace && (Start_trans == counter)) begin
                  Waiting[Start_trans] <= {(ArbVector[WAIT_MAX] | Enable_ID_ready_in), select, ReplaceVector[VECTOR_MAX:TIME_TOP+1], (ReplaceVector[TIME_TOP:TIME_BASE] + Time), ReplaceVector[TIME_BASE-1:0]};
             //Option 2 .. adding a new transaction at the end of the array
             end else if (enable_transaction && (counter == (WaitingValidNxt - 1))) begin
                  Waiting[counter] <= {Enable_ID_ready_in, enable_trans, Entry[VECTOR_MAX:TIME_TOP+1], (Entry[TIME_TOP:TIME_BASE] + Time), Entry[TIME_BASE-1:0]};
                  if (~Replace & start_new_transaction && (counter > Start_trans)) begin
                     Waiting[counter-1] <=  {WaitingVector[WAIT_MAX:TIME_TOP+1], WaitingVector[TIME_TOP:TIME_BASE], WaitingVector[TIME_BASE-1:0]};
                  end
             //Option 3 .. completing a transaction .. shuffle all the others up
             end else if (~Replace && start_new_transaction && (counter > Start_trans) && ~(enable_transaction && (counter == (WaitingValidNxt)))) begin
                  Waiting[counter-1] <=  {WaitingVector[WAIT_MAX:TIME_TOP+1], WaitingVector[TIME_TOP:TIME_BASE], WaitingVector[TIME_BASE-1:0]};
             //Option 4 ... just leave the value unchanged
             end else begin
                  Waiting[counter] <= WaitingVector;
             end
     
       end 
  end

  always @ (posedge ACLK or negedge ARESETn)
  begin : p_WaitingReg
    if (!ARESETn) begin
      WaitingValid <=  32'b0; 
    end else begin
      WaitingValid <= WaitingValidNxt;
    end
  end

//------------------------------------------------------------------------------
// Determine which transaction to send
// Select the oldest transaction which :
// 1) has no outstanding wait
// 2) has met its valid time
// 3) has no preceding transactions with the same ID
//
// Round Robin or random arbitartion options could be added here
//------------------------------------------------------------------------------

  always @(WaitingValid or Time or Entry or enable_transaction or new_transaction or Enable_ID_ready_in) begin

     Start = 1'b0;
     Start_trans = 32'b0;
     Start_immediate = 1'b0;

     while (Start_trans < WaitingValid && ~Start) begin
             CheckVector = Waiting[Start_trans];

             //IF time and wait ok check
             if (~CheckVector[11] && (Time >= CheckVector[TIME_TOP:TIME_BASE])) begin
                     //Indicate ok to start
                     Start = 1'b1;
                     //Stop transaction if previous transaction of the same ID exists
                     for (check_count = 0; check_count < Start_trans; check_count = check_count + 1) begin
                             IDVector = Waiting[check_count];
                             if (IDVector[ID_TOP:ID_BASE] == CheckVector[ID_TOP:ID_BASE]) begin
                                     //Prevent transaction from starting
                                     Start = 1'b0;
                             end
                     end        

                     //IF WAIT_FOR_HNDSHK stop any transaction that hasn't had ready else stop only last  
                     if (~(CheckVector[WAIT_MAX] | Enable_ID_ready_in) & ((WAIT_FOR_HNDSHK == 1'b1) | CheckVector[LAST])) begin
                         //Prevent transaction from starting
                         Start = 1'b0;
                     end
             end

             //Go onto next
             Start_trans = Start_trans + 1;
     end

     //Go back to the real started transaction
     Start_trans = Start_trans - 1;

     //Transactions are loaded into the WaitingValid array when they are enabled.
     //Hence we need to consider the latest transaction here to prevent a dead cycle
     if (~Start && enable_transaction && new_transaction) begin

             //If WAIT_FOR_HNDSHK test is ok
             if (Enable_ID_ready_in || ((WAIT_FOR_HNDSHK == 1'b0) && !Entry[LAST])) begin

                //IF time and wait ok check
                if (~Entry[11] && ~|Entry[TIME_TOP:TIME_BASE]) begin
                     //Indicate ok to start
                     Start = 1'b1;
                     Start_immediate = 1'b1;

                     //Stop transaction if previous transaction of the same ID exists
                     for (check_count = 0; check_count < WaitingValid; check_count = check_count + 1) begin
                             IDVector = Waiting[check_count];
                             if (IDVector[ID_TOP:ID_BASE] == Entry[ID_TOP:ID_BASE]) begin
                                     //Prevent transaction from starting
                                     Start = 1'b0;
                                     Start_immediate = 1'b0;
                             end
                     end        
                 end    
             end

             //Ensure that Start_trans does point at the next empty slot
             Start_trans = Start_trans + 1;

     end        

  end

  //new transaction signal
  assign new_transaction = FileReady | ~iFileValid;
  assign start_new_transaction = Start && new_transaction;
  assign get_next_beat = FileReady;


  //Register Outputs
  always @ (posedge ACLK or negedge ARESETn)
  begin : p_FileValidReg

    if (!ARESETn) begin
      iFileValid <= 1'b0;
      Wait_select <= {WAIT_MAX+1{1'b0}};
    end else if (new_transaction) begin
      iFileValid <= Start;
      Wait_select <= ArbVector;
    end
  end

  assign FileData  = Wait_select[VECTOR_MAX:0];
  assign FileValid = iFileValid;

  

//------------------------------------------------------------------------------
// OVL Assertions
//------------------------------------------------------------------------------
`ifdef ARM_ASSERT_ON

  //----------------------------------------------------------------------------
  // OVL_ASSERT: Stimulus file version check
  //----------------------------------------------------------------------------
  // Check the version of the stimulus file is compatible with this hdl
  // The upper 8 bits of the first word in the file identify the version
  //----------------------------------------------------------------------------
  // OVL_ASSERT_RTL

  assert_never
    #(0, 0, { MESSAGE_TAG,
      " Incompatible stimulus file: ", STIM_FILE_NAME }
    )
  fileversion
    (ACLK, ARESETn, (FileMem[0] >> 16) != FILE_ID);


  // OVL_ASSERT_END

`endif


endmodule

// --================================= End ===================================--

