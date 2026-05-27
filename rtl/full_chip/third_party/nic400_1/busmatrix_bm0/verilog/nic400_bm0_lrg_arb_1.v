//-=============================================================================
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
// (C) COPYRIGHT 2012 ARM Limited.
// ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//-============================================================================
//  Version and Release Control Information:
//
//   File Revision       : 104536
//
//   Date                :  2011-02-15 18:32:59 +0000 (Tue, 15 Feb 2011)
//
//   Release Information : PL401-r1p2-00rel0
//
//-=============================================================================
//  Purpose : Least-recently-granted Arbiter (LRG Arbiter)
//            Implements the LRG algorithm
//
// --=========================================================================--

// ---------------------------------------------------------------------------
// Priority Matrix
//
// Conceptually, a priority matrix is a store of all relative priorities in
// a request-grant system.
//
// 1-bit flags are stored in a matrix with 2 indices:
//   [row][column]
//
// Each flag stores the answer to the following question:
//   Is requester[column] of higher priority than requester[row]?
//   1'b1 = yes
//   1'b0 = no
//
//      0   1   2   3
// 0 | P00 P01 P02 P03 |
// 1 | P10 P11 P12 P13 |
// 2 | P20 P21 P22 P23 |
// 3 | P30 P31 P32 P33 |
//
// There is some redundancy built into the matrix, There are 0's across the
// diagonal since a requester cannot be of higher priority than itself.
// Also, the priority of index [row][column] is the inverse of index [column][row]
//
//       0    1    2    3
// 0 |   0   P01  P02  P03 |
// 1 | ~P01   0   P12  P13 |
// 2 | ~P02 ~P12   0   P23 |
// 3 | ~P03 ~P13 ~P23   0  |
//
// Thus, the following are the only entries that must be stored, since all
// others can be inferred:
//
//      0   1   2   3
// 0 |     P01 P02 P03 |
// 1 |         P12 P13 |
// 2 |             P23 |
// 3 |                 |
//
// The number of bits required to store the state is given by the following
// equation:
//
//   bits = [n*(n-1)]/2    Note: this is O(n^2)
//
//   WIDTH   Bits
//     2       1
//     3       3
//     4       6
//     8      28
//    16     120
//
// ---------------------------------------------------------------------------
// A priority matrix in operation:
//
// Consider a 4x4 priority matrix showing the following priority queue
//  0, 1, 3, 2
//
// If requester 1 is granted access, it then moves to the bottom of the
// priority queue
//  0, 3, 2, 1
//
// Below are the 'before' and 'after' matrices:
//      0   1   2   3                 0   1   2   3
//   -------------------           -------------------
// 0 |  0   0   0   0  |         0 |  0   0   0   0  |
// 1 |  1   0   0   0  |   -->   1 |  1   0   1   1  |
// 2 |  1   1   0   1  |         2 |  1   0   0   1  |
// 3 |  1   1   0   0  |         3 |  1   0   0   0  |
//
// To transform from the 'before' matrix to the 'after' matrix, all flags in
// row 1 are set to 1'b1, and all flags in column 1 are set to 1'b0 (With
// the exception of the main diagonal).
// ---------------------------------------------------------------------------
// Granting access to a requester
//
// A particular request will be granted when there are no requests from
// higher-priority requesters.  The logic equation for requester 1 in a
// 4-requester system is shown below:
//
// grant_1 = req_1 &
//           ~(req_0 & p[1][0]) &
//           ~(req_2 & p[1][2]) &
//           ~(req_3 & p[1][3])
//
// More generically, this can also be written as:
//
// grant_1 = req_1 &
//           ~((req_0 & p[1][0]) |
//             (req_1 & p[1][1]) | < -- Note: p[1][1] = 1'b0
//             (req_2 & p[1][2]) |
//             (req_3 & p[1][3]))
// ---------------------------------------------------------------------------

module nic400_bm0_lrg_arb_1
// Parameter List
#(
  parameter WIDTH = 2
)
// Port List
(
  input  wire              aclk,         // Clock
  input  wire              aresetn,      // Active-low reset
  input  wire              update_en,   // Enable for update logic
  input  wire  [WIDTH-1:0] request,     // Requests
  output wire  [WIDTH-1:0] grant        // Grants
);

  // ---------------------------------------------------------------------------
  // Wire and Register Declarations
  // ---------------------------------------------------------------------------

  reg [WIDTH-1:0] p     [WIDTH-1:0]; // Entire priority matrix
  reg [WIDTH-1:0] p_reg [WIDTH-1:0]; // Priority matrix storage elements
  reg [WIDTH-1:0] p_en  [WIDTH-1:0]; // Enables for storage elements

  reg [WIDTH-1:0] grant_i;           // Internal grant signal

  // ---------------------------------------------------------------------------
  // Grant Logic
  // ---------------------------------------------------------------------------

  assign grant = grant_i;


  always @*
  begin : p_comb_grant
    integer requester;

    for ( requester=0; requester<WIDTH; requester=requester+1 )
    begin

      //
      // From example:
      // grant_1 = req_1 &
      //           ~((req_0 & p[1][0]) |
      //             (req_1 & p[1][1]) | <-- Note: p[1][1] = 1'b0
      //             (req_2 & p[1][2]) |
      //             (req_3 & p[1][3]))
      //

      grant_i[requester] = request[requester] & ~|(request & p[requester]);

    end // End for each requester
  end // End p_comb_grant

  // ---------------------------------------------------------------------------
  // Update Logic
  // ---------------------------------------------------------------------------

  // p[][] stores the entire priority matrix
  // Alias the p_reg registers to fill the priority matrix
  always @*
  begin : p_comb_p_alias
    integer row; // Row
    integer column; // Column

    for ( row=0; row<WIDTH; row=row+1 )
    begin
      for ( column=0; column<WIDTH; column=column+1 )
      begin
        if ( row < column )
        begin

          p[row][column] = p_reg[row][column];

        end // End if row < column
        else if ( row == column )
        begin

          p[row][column] = 1'b0;

        end // End if row == column
        else // if ( row > column )
        begin

          p[row][column] = ~p_reg[column][row];

        end // End if row > column
      end // End for each column
    end // End for each row
  end // End p_comb_p_alias



  // ---------------------------------------------------------------------------
  // Priority Matrix Storage Elements
  // ---------------------------------------------------------------------------

  // Enables
  always @*
  begin : p_comb_priorities
    integer row; // Row
    integer column; // Column

    for ( row=0; row<WIDTH; row=row+1 )
    begin
      for ( column=row+1; column<WIDTH; column=column+1 ) // Start column at row + 1 to
      begin                                   // capture half of the matrix

        //
        // To push the requester to the bottom of the queue, all flags in
        // the requester's row are set to 1'b1, and all flags in the
        // requester's column are set to 1'b0 (With the excpetion of the
        // main diagonal).
        //
        // update_en:
        //   The storage elements in the priority matrix will only update
        //   when update_en is 1'b1.
        //

        p_en[row][column]  = update_en & (grant_i[row] | grant_i[column]);

      end // End for each column
    end // End for each row
  end // End p_comb_priorities

  // Storage Elements
  always @(posedge aclk or negedge aresetn)
  begin : p_seq_priorities
    integer row;
    integer column;

    if (!aresetn)
    begin
      for ( row=0; row<WIDTH; row=row+1 )
      begin
        for ( column=row+1; column<WIDTH; column=column+1 ) // Start column at row + 1 to
        begin                                   // capture half of the matrix

          //
          // Reset is not technically required.  However, the first few
          // arbitrations would be indeterminate, causing validation concerns.
          //
          p_reg[row][column] <= 1'b0;

        end
      end
    end else begin
      for ( row=0; row<WIDTH; row=row+1 )
      begin
        for ( column=row+1; column<WIDTH; column=column+1 ) // Start column at row + 1 to
        begin                                   // capture half of the matrix

          if (p_en[row][column])
            p_reg[row][column] <= grant_i[row];

        end
      end
    end
  end // End p_seq_priorities


endmodule

// --================================= End ===================================--