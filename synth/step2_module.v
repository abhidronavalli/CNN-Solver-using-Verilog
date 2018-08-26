/*************************************************************************************************

Author: Abhiram Dronavalli
Project: ECE564: Hardware Design of Convolutional Neural Network Solver
Files:

	1. Design Files:

		a. MyDesign.v
		b. quad_module.v
		c. step2_module.v
		d. controller.v

	2. Testbench Files:

		g. ece564_project_tb_top.v
		h. sram.v

Modules:	
	top
		mac1

About:

This module consists the step2 logic for final classification. Basic logic is same as that for
quad_module.v

****************************************************************************************************/

module step2_module
(
    output wire [15:0] dom_data,        // Final output data
    output wire [8:0] dim_addr,         // Output address for step 1 data
    output wire [9:0] bvm_addr,         // Output address for filter data
    output reg [2:0] dom_addr,          // Output address to store final data

    output reg dom_enable,              // to controller
    output wire dom_data_rdy,           // to top
    output reg finish,                  // to controller

    input wire [15:0] dim_data,         // input data from step 1
    input wire [15:0] bvm_data,         // filter vector data

    input wire [9:0] filter_origin,     // offset for filter address generation
    input wire enable,                  // from controller
    input wire reset,                   // slave reset from controller
    input wire clk                      // from top
);

reg [1:0] dim_x_addr;
reg [3:0] dim_y_addr;
reg [5:0] filter_addr;

reg dim_x_enable, filter_addr_enable, mac_enable, mac_enable_tmp, mac_enable_tmp2;
reg dom_addr_enable;
wire dim_y_enable;

parameter A_width = 16;
parameter B_width = 16;
 
reg TC;
reg [5:0] data_count;

wire [15:0] a_in, b_in;
reg [31:0] c_in;
wire [31:0] out;
wire [31:0] dom_data_out;
reg [5:0] filter_count;

//------------------------------------ Logic towards Controller and Top ------------------------------------//
// Logic for the control and status signals to controller

always @ (posedge clk)
begin
    if(reset)
    begin  
        dom_enable <= 1'b0;
        finish <= 1'b0;
    end
    else if(enable)
    begin
        dom_enable <= 1'b0;
        finish <= 1'b0;

        if(filter_addr == 6'b111101) dom_enable <= 1'b1;

        if(dom_addr == 3'b111 && dom_data_rdy) finish <= 1'b1;
    end
end

assign dom_data_rdy = (data_count == 6'b111111);

//---------------------------------------Address Path Logic---------------------------------------//
// Counters to generate a co-ordinate of the dim and bvm address which are later concatenated to
// generate a complete address.
// Address format: 
//          For DIM MEMORY: 0x (z-coordinate)(y-coordinate)(x-coordinate)
//          For BVM MEMORY: Offset + Counter Value + Filter Count
//          For DOM MEMORY: 3-bit counter counting till 8

always @ (posedge clk)
begin
  if(reset) dim_x_addr <= 2'b0;
  else if(dim_x_enable) dim_x_addr <= dim_x_addr + 1'b1;
end

always @ (posedge clk)
begin
  if(reset) dim_y_addr <= 4'b0;
  else if(dim_y_enable) dim_y_addr <= dim_y_addr + 1'b1;
end

always @ (posedge clk)
begin
    if(reset) filter_addr <= 6'b0;
    else if(filter_addr_enable) filter_addr <= filter_addr + 1'b1;
end

always @ (posedge clk)
begin
    if(reset) dom_addr <= 3'b0;
    else if(dom_addr_enable) dom_addr <= dom_addr + 1'b1;
end

assign dim_addr = {1'b1, dim_y_addr, 2'b0, dim_x_addr};
assign bvm_addr = {4'b0, filter_addr} + filter_origin + {filter_count, 4'b0};

//--------------------------------------Address Path Control--------------------------------------//
// Control logic to control the enables of the counters for address co-ordinate generation
// Masks(Parallel-In Serial-Out Register) used to model the sub-quadrant within the quadrant.

always @ (posedge clk)
begin
    if(reset)
    begin
        dim_x_enable <= 1'b0;
        filter_addr_enable <= 1'b0; 
        dom_addr_enable <= 1'b0;
        filter_count <= 4'b0;
    end
    else 
    begin
        dim_x_enable <= 1'b0;
        filter_addr_enable <= 1'b0;
        if(enable)
        begin
            dim_x_enable <= 1'b1;
            filter_addr_enable <= 1'b1;
            if(dom_data_rdy) 
            begin
                dom_addr_enable <= 1'b1;
                filter_count <= filter_count + 3'b100;
            end
            else dom_addr_enable <= 1'b0;
        end
    end
end

assign dim_y_enable = (dim_x_addr == 2'b11);

//---------------------------------------Data Path Logic---------------------------------------//
// Logic surrounding the MAC IP which controls when data is read and written

assign a_in = mac_enable ? dim_data : 16'b0;
assign b_in = mac_enable ? bvm_data : 16'b0;
assign dom_data_out = mac_enable ? (dom_data_rdy ? (out[31] ? 31'b0 : {16'b0,out[31:16]}) : out[31:0]) : 31'b0;


always @ (posedge clk)
begin
	if(reset) c_in <= 31'b0;
	else if(mac_enable) c_in <= dom_data_out;
end

assign dom_data = dom_data_out[15:0];

//--------------------------------------Data Path Control--------------------------------------//
// Control logic for the data flow to the MAC IP 

// Shift register to sync data and address control
always @ (posedge clk)
begin
	mac_enable_tmp <= enable;
end

always @ (posedge clk)
begin
	mac_enable_tmp2 <= mac_enable_tmp;
end

always @ (posedge clk)
begin
	mac_enable <= mac_enable_tmp2;
end

// Counter to keep track of input data
always @ (posedge clk)
begin
	if(reset)
	begin
		data_count <= 6'b0;
		TC <= 1'b1;
	end
	else if(mac_enable)
	begin
		if(data_count == 6'b111111) data_count <= 6'b0;
		else data_count <= data_count + 1'b1;
	end
end

//-------------------------------------- MAC IP Connections --------------------------------------//

DW02_mac #(A_width, B_width) mac1
( 
		.A(a_in), 
		.B(b_in), 
		.C(c_in), 
		.TC(TC), 
		.MAC(out) 
);

endmodule