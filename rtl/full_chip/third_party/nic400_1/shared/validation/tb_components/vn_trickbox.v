// --========================================================================--
//  The confidential and proprietary information contained in this file may
//  only be used by a person authorised under and to the extent permitted
//  by a subsisting licensing agreement from ARM Limited.
//   (C) COPYRIGHT 2008-2013 ARM Limited.
//       ALL RIGHTS RESERVED
//  This entire notice must be reproduced on all copies of this file
//  and copies of this file may only be made by a person if such person is
//  permitted to do so under the terms of a subsisting license agreement
//  from ARM Limited.
//
// ----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Revision          : 96879
//
// Date                   :  2010-10-08 12:12:59 +0100 (Fri, 08 Oct 2010)
//
// Release Information    : PL401-r1p2-00rel0
//
// ----------------------------------------------------------------------------
// Purpose : VN token interface trickbox
//
// Description : This block generates vvalid based on incoming vnet and gates 
//               axi channel handshakes when no token is granted.
//
// --========================================================================--

// -----------------------------------------------------------------------------
//  Module Declaration
// -----------------------------------------------------------------------------

module vn_trickbox (

    // Clock and reset
    clk,
    resetn,
    
    // VN0 Valid/Ready
    vawvalid_0,
    vawready_0,
    varvalid_0,
    varready_0,
    vwvalid_0,
    vwready_0,
    
    // vn1 Valid/Ready
    vawvalid_1,
    vawready_1,
    varvalid_1,
    varready_1,
    vwvalid_1,
    vwready_1,

    // vn2 Valid/Ready
    vawvalid_2,
    vawready_2,
    varvalid_2,
    varready_2,
    vwvalid_2,
    vwready_2,

    // vn3 Valid/Ready
    vawvalid_3,
    vawready_3,
    varvalid_3,
    varready_3,
    vwvalid_3,
    vwready_3,

    // AW Valid/Ready FRM
    awvalid_i,
    awready_o,
    
    // AW Valid/Ready DUT
    awvalid_o,
    awready_i,

    // AW vnet
    awvnet,
    
    // AR Valid/Ready FRM
    arvalid_i,
    arready_o,
    
    // AR Valid/Ready DUT
    arvalid_o,
    arready_i,
    
    // AW vnet
    arvnet,
    
    // W Valid/Ready FRM
    wvalid_i,
    wready_o,
    
    // W Valid/Ready DUT
    wvalid_o,
    wready_i,
    
    // AW vnet
    wvnet

);

// -----------------------------------------------------------------------------
//  Parameter Declaration
// -----------------------------------------------------------------------------

parameter VNET_VALUE0 = 0;
parameter VNET_VALUE1 = 1;
parameter VNET_VALUE2 = 2;
parameter VNET_VALUE3 = 3;


// -----------------------------------------------------------------------------
//  Port Declaration
// -----------------------------------------------------------------------------

    // Clock and reset
    input           clk;
    input           resetn;
    
    // vn0 Valid/Ready
    output          vawvalid_0;
    input           vawready_0;
    output          varvalid_0;
    input           varready_0;
    output          vwvalid_0;
    input           vwready_0;
    
    // vn1 Valid/Ready
    output          vawvalid_1;
    input           vawready_1;
    output          varvalid_1;
    input           varready_1;
    output          vwvalid_1;
    input           vwready_1;
    
    // vn2 Valid/Ready
    output          vawvalid_2;
    input           vawready_2;
    output          varvalid_2;
    input           varready_2;
    output          vwvalid_2;
    input           vwready_2;

    // vn3 Valid/Ready
    output          vawvalid_3;
    input           vawready_3;
    output          varvalid_3;
    input           varready_3;
    output          vwvalid_3;
    input           vwready_3;

    // AW Valid/Ready FRM
    input           awvalid_i;
    output          awready_o;
    
    // AW Valid/Ready DUT
    output          awvalid_o;
    input           awready_i;

    // AW vnet
    input     [3:0] awvnet;
    
    // AR Valid/Ready FRM
    input           arvalid_i;
    output          arready_o;
    
    // AR Valid/Ready DUT
    output          arvalid_o;
    input           arready_i;
    
    // AR vnet
    input     [3:0] arvnet;
    
    // W Valid/Ready FRM
    input           wvalid_i;
    output          wready_o;
    
    // W Valid/Ready DUT
    output          wvalid_o;
    input           wready_i;
    
    // W vnet
    input     [3:0] wvnet;

// -----------------------------------------------------------------------------
//  Internal Signals
// -----------------------------------------------------------------------------

    wire           awpass;
    wire           arpass;
    wire           wpass;
    wire     [3:0] vawvalid_next;
    wire     [3:0] vawready_mask;
    reg      [3:0] vawvalid_reg;
    wire     [3:0] varvalid_next;
    wire     [3:0] varready_mask;
    reg      [3:0] varvalid_reg;
    wire     [3:0] vwvalid_next;
    wire     [3:0] vwready_mask;
    reg      [3:0] vwvalid_reg;

// -----------------------------------------------------------------------------
// AW Channel Gates
// -----------------------------------------------------------------------------

    // Generate mask
    assign awpass    = |(vawvalid_reg & vawready_mask);
    // Generate a-handshake
    assign awvalid_o = awpass & awvalid_i;
    assign awready_o = awpass & awready_i;
    
// -----------------------------------------------------------------------------
// AR Channel Gates
// -----------------------------------------------------------------------------

    // Generate mask
    assign arpass    = |(varvalid_reg & varready_mask);
    // Generate a-handshake
    assign arvalid_o = arpass & arvalid_i;
    assign arready_o = arpass & arready_i;
    
// -----------------------------------------------------------------------------
// AW Channel Gates
// -----------------------------------------------------------------------------

    // Generate mask
    assign wpass     = |(vwvalid_reg & vwready_mask);
    // Generate a-handshake
    assign wvalid_o  = wpass & wvalid_i;
    assign wready_o  = wpass & wready_i;
    
// -----------------------------------------------------------------------------
// Individual AW Sticky Valids
// -----------------------------------------------------------------------------

    // Sticky vawvalid generation
    assign vawvalid_next[0] = &(awvnet ~^ VNET_VALUE0) | (vawvalid_reg[0] & ~vawready_mask[0]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign vawvalid_next[1] = &(awvnet ~^ VNET_VALUE1) | (vawvalid_reg[1] & ~vawready_mask[1]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign vawvalid_next[2] = &(awvnet ~^ VNET_VALUE2) | (vawvalid_reg[2] & ~vawready_mask[2]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign vawvalid_next[3] = &(awvnet ~^ VNET_VALUE3) | (vawvalid_reg[3] & ~vawready_mask[3]); // Request on vnet, maintain sticky valid, Remove on handshake

    // Demux vvalids
    assign {vawvalid_3, vawvalid_2, vawvalid_1, vawvalid_0 } = vawvalid_reg;
            
    // Concat vreadys
    assign vawready_mask = {vawready_3, vawready_2, vawready_1, vawready_0};
            
    always @(posedge clk or negedge resetn)
        begin : p_sticky_vawvalid
            if(~resetn)
                begin
                    vawvalid_reg <= 4'h0;
                end
            else
                begin
                    vawvalid_reg <= vawvalid_next;
                end
        end // p_sticky_vawvalid

// -----------------------------------------------------------------------------
// Individual AR Sticky Valids
// -----------------------------------------------------------------------------

    // Sticky varvalid generation
    assign varvalid_next[0] = &(arvnet ~^ VNET_VALUE0) | (varvalid_reg[0] & ~varready_mask[0]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign varvalid_next[1] = &(arvnet ~^ VNET_VALUE1) | (varvalid_reg[1] & ~varready_mask[1]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign varvalid_next[2] = &(arvnet ~^ VNET_VALUE2) | (varvalid_reg[2] & ~varready_mask[2]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign varvalid_next[3] = &(arvnet ~^ VNET_VALUE3) | (varvalid_reg[3] & ~varready_mask[3]); // Request on vnet, maintain sticky valid, Remove on handshake

    // Demux vvalids
    assign {varvalid_3, varvalid_2, varvalid_1, varvalid_0 } = varvalid_reg;
            
    // Concat vreadys
    assign varready_mask = {varready_3, varready_2, varready_1, varready_0};
            
    always @(posedge clk or negedge resetn)
        begin : p_sticky_varvalid
            if(~resetn)
                begin
                    varvalid_reg <= 4'h0;
                end
            else
                begin
                    varvalid_reg <= varvalid_next;
                end
        end // p_sticky_varvalid

// -----------------------------------------------------------------------------
// Individual W Sticky Valids
// -----------------------------------------------------------------------------

    // Sticky vwvalid generation
    assign vwvalid_next[0]  = &(wvnet ~^ VNET_VALUE0) | (vwvalid_reg[0] & ~vwready_mask[0]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign vwvalid_next[1]  = &(wvnet ~^ VNET_VALUE1) | (vwvalid_reg[1] & ~vwready_mask[1]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign vwvalid_next[2]  = &(wvnet ~^ VNET_VALUE2) | (vwvalid_reg[2] & ~vwready_mask[2]); // Request on vnet, maintain sticky valid, Remove on handshake
    assign vwvalid_next[3]  = &(wvnet ~^ VNET_VALUE3) | (vwvalid_reg[3] & ~vwready_mask[3]); // Request on vnet, maintain sticky valid, Remove on handshake

    // Demux vvalids
    assign {vwvalid_3, vwvalid_2, vwvalid_1, vwvalid_0 } = vwvalid_reg;
            
    // Concat vreadys
    assign vwready_mask = {vwready_3, vwready_2, vwready_1, vwready_0};
            
    always @(posedge clk or negedge resetn)
        begin : p_sticky_vwvalid
            if(~resetn)
                begin
                    vwvalid_reg <= 4'h0;
                end
            else
                begin
                    vwvalid_reg <= vwvalid_next;
                end
        end // p_sticky_vwvalid


endmodule
