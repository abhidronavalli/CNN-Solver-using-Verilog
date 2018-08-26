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
		mac0

About:

This module consists the quadrant logic.

****************************************************************************************************/

module quad_module
(
	output wire [15:0] sp_data,			// output to be written to scratchpad memory
	output wire [8:0] dim_addr,			// output address A
	output wire [9:0] bvm_addr,			// output address B
	output reg quad_finish,				// to controller
	output reg sp_enable,				// to controller
    output wire sp_data_rdy,			// to top

	input wire [15:0] dim_data,			// input data A 
	input wire [15:0] bvm_data,			// input data B
	input wire [3:0] quad_a_x_origin,	// 0,6,0 6
	input wire [3:0] quad_a_y_origin,	// 0,0,6,6

	input wire sp_x_mask,				// 0,1,0,1
	input wire sp_y_mask,				// 0,0,1,1

	input wire [3:0] quad_a_x_mask,		// 1010
	input wire [3:0] quad_a_y_mask,		// 1001

	input wire quad_enable,				// from controller
	input wire reset,					// slave reset from controller
	input wire clk						// from top
);

reg [3:0] a_x_mask, a_y_mask;
reg [1:0] a_x_count, a_y_count;
reg a_x_enable,  a_z_enable, b_x_enable, b_y_enable, mac_enable, mac_enable_tmp, mac_enable_tmp2;
wire a_y_enable;
wire [3:0] a_x_addr, a_y_addr, sp_x_addr, sp_y_addr;
reg [3:0] b_x_addr, b_y_addr;
wire [3:0] dim_x_addr, dim_y_addr;
wire dim_z_addr;
wire [1:0] a_x_subquad_origin, a_y_subquad_origin, sp_x_subquad_origin, sp_y_subquad_origin;
wire [31:0] sp_data_out;

parameter A_width = 16;
parameter B_width = 16;
 
reg TC;
reg [3:0] data_count;

wire [15:0] a_in, b_in;
reg [31:0] c_in;
wire [31:0] out;

//---------------------------------------Logic towards Controller ---------------------------------------//
// Logic for the control and status signals to controller

always @ (posedge clk)
begin
	if(reset)
	begin
		quad_finish <= 1'b0;
		sp_enable <= 1'b0;
	end //(reset)
	
	else if(quad_enable)
	begin
		sp_enable <= 1'b0;
		if(a_y_count == 2'b10 && a_x_count == 2'b01) sp_enable <= 1'b1;
		if(a_x_mask[1] && a_y_mask[1] && b_x_addr[3] == 1'b1 && b_y_addr == 4'b0011) quad_finish <= 1'b1;
	end //(quad_enable)
end

assign sp_data_rdy = (data_count == 4'b1001);

//---------------------------------------Address Path Logic---------------------------------------//
// Counters to generate a co-ordinate of the dim and bvm address which are later concatenated to
// generate a complete address.
// Address format: 0x (z-coordinate)(y-coordinate)(x-coordinate)

always @ (posedge clk)
begin
	if(reset) a_x_count <= 2'b0;
	else if(a_x_enable)
	begin
		if(a_x_count == 2'b10) a_x_count <= 2'b0;
		else a_x_count <= a_x_count + 1'b1;
	end	//(a_x_enable)
end

always @ (posedge clk)
begin
	if(reset) a_y_count <= 2'b0;
	else if(a_y_enable)
	begin 
		if(a_y_count == 2'b10) a_y_count <= 2'b0;
		else a_y_count <= a_y_count + 1'b1;
	end //(a_y_enable)
end

always @ (posedge clk)
begin
	if(reset) b_x_addr <= 4'b0;
	else if(b_x_enable)
	begin
		if(b_x_addr == 4'b1000) b_x_addr <= 4'b0;
		else b_x_addr <= b_x_addr + 1'b1;
	end //(b_x_enable)	
end

always @ (posedge clk)
begin
	if(reset) b_y_addr <= 4'b0;
	else if(quad_enable && b_y_enable)
	begin
		if(b_y_addr == 4'b0011) b_y_addr <= 4'b0;
		else b_y_addr <= b_y_addr + 1'b1;
	end //(quad_enable && b_y_enable)
end

assign a_x_subquad_origin = a_x_mask[1] ? 2'b11 : 1'b0;	// x-coordinate offset read address
assign a_y_subquad_origin = a_y_mask[1] ? 2'b11 : 1'b0;	// y-coordinate offset read address

assign sp_x_subquad_origin = sp_x_mask ? 2'b10 : 1'b0;	// x-coordinate offset for write address
assign sp_y_subquad_origin = sp_y_mask ? 2'b10 : 1'b0;	// y-coordinate offset for write address

assign a_x_addr = a_x_count + a_x_subquad_origin + quad_a_x_origin;		// x-coordinate read address generation
assign sp_x_addr = a_x_mask[0] + sp_x_subquad_origin;					// x-coordinate write address generation

assign a_y_addr = a_y_count + a_y_subquad_origin + quad_a_y_origin;		// y-coordinate read address generation
assign sp_y_addr = a_y_mask[0] + sp_y_subquad_origin + (b_y_addr<<2);	// y-coordinate write address generation

assign dim_x_addr = a_z_enable ? sp_x_addr : a_x_addr;	// switch the x-coordinate between read and write address
assign dim_y_addr = a_z_enable ? sp_y_addr : a_y_addr;	// switch the y-coordinate between read and write address
assign dim_z_addr = a_z_enable ? 1'b1 : 1'b0;			// for read: 0, write: 1

assign dim_addr = {dim_z_addr, dim_y_addr, dim_x_addr};

assign bvm_addr = {2'b0, b_y_addr, b_x_addr};

//--------------------------------------Address Path Control--------------------------------------//
// Control logic to control the enables of the counters for address co-ordinate generation
// Masks(Parallel-In Serial-Out Register) used to model the sub-quadrant within the quadrant.

always @ (posedge clk)
begin
	if(reset)
	begin
		a_x_enable <= 1'b0;
		a_z_enable <= 1'b0;
		a_x_mask <= quad_a_x_mask;
		a_y_mask <= quad_a_y_mask;
		b_x_enable <= 1'b0;
		b_y_enable <= 1'b0;
	end //(reset)

	else
	begin
		if(quad_enable)
		begin
			a_x_enable <= 1'b1;
			a_z_enable <= 1'b0;
			b_x_enable <= 1'b1;
			b_y_enable <= 1'b0;

			if(a_y_count == 2'b10 && a_x_count == 2'b10)
			begin
				a_x_mask <= {a_x_mask[0],a_x_mask[3:1]}; // x-coordinate control for sub-quadrant
				a_y_mask <= {a_y_mask[0],a_y_mask[3:1]}; // y-coordinate control for sub-quadrant
				a_x_enable <= 1'b0;
				a_z_enable <= 1'b1;
				b_x_enable <= 1'b0;
			end //(a_y_count == 2'b10 && a_x_count == 2'b10)

			if(a_x_mask[1] && a_y_mask[1] && b_x_addr[3] == 1'b1) b_y_enable <= 1'b1;
		end //(quad_enable)
	end
end

assign a_y_enable = (a_x_count == 2'b10) ? 1'b1 : 1'b0;

//---------------------------------------Data Path Logic---------------------------------------//
// Logic surrounding the MAC IP which controls when data is read and written

always @ (posedge clk)
begin
	if(reset) c_in <= 32'b0;
	else if(mac_enable) c_in <= sp_data_out;
end

assign a_in = mac_enable ? (sp_data_rdy ? 16'b0 : dim_data) : 16'b0;
assign b_in = mac_enable ? (sp_data_rdy ? 16'b0 : bvm_data) : 16'b0;
assign sp_data_out = mac_enable ? (sp_data_rdy ? (out[31] ? 32'b0 : {16'b0,out[31:16]}) : out[31:0]) : 32'b0;

assign sp_data = sp_data_out[15:0];

//--------------------------------------Data Path Control--------------------------------------//
// Control logic for the data flow to the MAC IP 

// Shift register to sync data and address control
always @ (posedge clk)
begin
	mac_enable_tmp <= quad_enable;
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
		data_count <= 4'b0;
		TC <= 1'b1;
	end
	else if(mac_enable)
	begin
		if(data_count == 4'b1001) data_count <= 4'b0;
		else data_count <= data_count + 1'b1;
	end //(mac_enable)
end

//-------------------------------------- MAC IP Connections --------------------------------------//

DW02_mac #(A_width, B_width) mac0
( 
		.A(a_in), 
		.B(b_in), 
		.C(c_in), 
		.TC(TC), 
		.MAC(out) 
);
endmodule
