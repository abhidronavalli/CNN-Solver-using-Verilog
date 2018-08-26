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
		quad0
		quad1
		quad2
		quad3
		step2
		ctrl

About:

This is the top module of the DUT consisting of instantiations of each of the 4 quadrant logic modules,
step2 logic module and a controller module. This module also consists of additional logic to control
the input/output data/address from/to external SRAMs to/from corresponding child modules.

****************************************************************************************************/

//----------------------------------Additional design files-----------------------------------------//

`include "quad_module.v"
`include "controller.v"
`include "step2_module.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW02_mac.v"

//-------------------------------------------------------------------------------------------------//
module MyDesign (

            //---------------------------------------------------------------------------
            // Control
            //
            output reg                  dut__xxx__finish   ,
            input  wire                 xxx__dut__go       ,

            //---------------------------------------------------------------------------
            // b-vector memory
            //
            output reg  [ 9:0]          dut__bvm__address  ,
            output reg                  dut__bvm__enable   ,
            output reg                  dut__bvm__write    ,
            output reg  [15:0]          dut__bvm__data     ,  // write data
            input  wire [15:0]          bvm__dut__data     ,  // read data

            //---------------------------------------------------------------------------
            // Input data memory
            //
            output reg  [ 8:0]          dut__dim__address  ,
            output reg                  dut__dim__enable   ,
            output reg                  dut__dim__write    ,
            output reg  [15:0]          dut__dim__data     ,  // write data
            input  wire [15:0]          dim__dut__data     ,  // read data


            //---------------------------------------------------------------------------
            // Output data memory
            //
            output reg  [ 2:0]          dut__dom__address  ,
            output reg  [15:0]          dut__dom__data     ,  // write data
            output reg                  dut__dom__enable   ,
            output reg                  dut__dom__write    ,


            //----------------------------------------------------------------------------
            // General
            //
            input  wire                 clk             ,
            input  wire                 reset

            );

//------------------------ Quadrant 0 variables --------------------------------//

reg [15:0] quad0_dim_data, quad0_bvm_data;
wire [15:0] quad0_sp_data;
wire [8:0] quad0_dim_addr;
wire [9:0] quad0_bvm_addr;
reg [3:0] quad0_a_x_origin, quad0_a_y_origin, quad0_a_x_mask, quad0_a_y_mask;
reg sp0_x_mask, sp0_y_mask;
wire quad0_sp_data_rdy;

//------------------------ Quadrant 1 variables --------------------------------//

reg [15:0] quad1_dim_data, quad1_bvm_data;
wire [15:0] quad1_sp_data;
wire [8:0] quad1_dim_addr;
wire [9:0] quad1_bvm_addr;
reg [3:0] quad1_a_x_origin, quad1_a_y_origin, quad1_a_x_mask, quad1_a_y_mask;
reg sp1_x_mask, sp1_y_mask;
wire quad1_sp_data_rdy;

//------------------------ Quadrant 2 variables --------------------------------//

reg [15:0] quad2_dim_data, quad2_bvm_data;
wire [15:0] quad2_sp_data;
wire [8:0] quad2_dim_addr;
wire [9:0] quad2_bvm_addr;
reg [3:0] quad2_a_x_origin, quad2_a_y_origin, quad2_a_x_mask, quad2_a_y_mask;
reg sp2_x_mask, sp2_y_mask;
wire quad2_sp_data_rdy;

//------------------------ Quadrant 3 variables --------------------------------//

reg [15:0] quad3_dim_data, quad3_bvm_data;
wire [15:0] quad3_sp_data;
wire [8:0] quad3_dim_addr;
wire [9:0] quad3_bvm_addr;
reg [3:0] quad3_a_x_origin, quad3_a_y_origin, quad3_a_x_mask, quad3_a_y_mask;
reg sp3_x_mask, sp3_y_mask;
wire quad3_sp_data_rdy;

//-------------------------- Step 2 variables ----------------------------------//

reg [15:0] step2_dim_data, step2_bvm_data;
wire [2:0] step2_dom_addr;
wire [15:0] step2_dom_data;
wire [8:0] step2_dim_addr;
wire [9:0] step2_bvm_addr;
reg [9:0] step2_filter_origin;
wire step2_dom_data_rdy;

//------------------------ Controller variables --------------------------------//

wire quad0_en, quad1_en, quad2_en, quad3_en, step2_en;
reg go;
wire quad0_sp_en, quad1_sp_en, quad2_sp_en, quad3_sp_en, step2_dom_en;
wire quad0_fin, quad1_fin, quad2_fin, quad3_fin, step2_fin;
wire [2:0] driver;
wire reset_slave;

// Models MUX to control the data and address from and to the DUT from various modules
// The 'driver' acts as a control signal to this MUX
// Also models MUX to start and restart the controller 

always @ (posedge clk)
begin
	if(reset)
	begin
		dut__xxx__finish <= 1'b1;
		go <= 1'b0;
		
		dut__bvm__address <= 10'b0;
		dut__bvm__enable <= 1'b0;
		dut__bvm__write <= 1'b0;
		dut__bvm__data <= 16'b0;
		
		dut__dim__address <= 9'b0;
		dut__dim__enable <= 1'b0;
		dut__dim__write <= 1'b0;
		dut__dim__data <= 16'b0;
		
		dut__dom__address <= 3'b0;
		dut__dom__data <= 16'b0;
		dut__dom__enable <= 1'b0;
		dut__dom__write <= 1'b0;
		
		quad0_bvm_data <= 16'b0;
		quad0_dim_data <= 16'b0;
		quad0_a_x_origin <= 4'h0;
		quad0_a_y_origin <= 4'h0;
		sp0_x_mask <= 1'b0;
		sp0_y_mask <= 1'b0;
		quad0_a_x_mask <= 4'b0101;
		quad0_a_y_mask <= 4'b1001;
		
		quad1_bvm_data <= 16'b0;
		quad1_dim_data <= 16'b0;
		quad1_a_x_origin <= 4'h6;
		quad1_a_y_origin <= 4'h0;
		sp1_x_mask <= 1'b1;
		sp1_y_mask <= 1'b0;
		quad1_a_x_mask <= 4'b0101;
		quad1_a_y_mask <= 4'b1001;
		
		quad2_bvm_data <= 16'b0;
		quad2_dim_data <= 16'b0;
		quad2_a_x_origin <= 4'h0;
		quad2_a_y_origin <= 4'h6;
		sp2_x_mask <= 1'b0;
		sp2_y_mask <= 1'b1;
		quad2_a_x_mask <= 4'b0101;
		quad2_a_y_mask <= 4'b1001;
		
		quad3_bvm_data <= 16'b0;
		quad3_dim_data <= 16'b0;
		quad3_a_x_origin <= 4'h6;
		quad3_a_y_origin <= 4'h6;
		sp3_x_mask <= 1'b1;
		sp3_y_mask <= 1'b1;
		quad3_a_x_mask <= 4'b0101;
		quad3_a_y_mask <= 4'b1001;

		step2_bvm_data <= 16'b0;
		step2_dim_data <= 16'b0;
		step2_filter_origin <= 10'h40;
	end
	
	else
	begin 
		if(xxx__dut__go == 1'b1)
		begin
			dut__xxx__finish <= 1'b0;
			go <= 1'b1;
			dut__bvm__enable <= 1'b1;
			dut__dim__enable <= 1'b1;
			dut__dom__enable <= 1'b1;
		end
		else if(step2_fin == 1'b1)
		begin
			dut__xxx__finish <= 1'b1;
			go <= 1'b0;
			dut__bvm__enable <= 1'b0;
			dut__dim__enable <= 1'b0;
			dut__dom__enable <= 1'b0;
		end

		if(driver == 3'b111)
		begin
			dut__bvm__address <= 10'b0;
			dut__dim__address <= 9'b0;
			quad0_bvm_data <= 16'b0;
			quad0_dim_data <= 16'b0;
            		dut__dim__data <= 16'b0;
			dut__dom__data <= 16'b0;
			dut__dom__write <= 1'b0;
			dut__dim__write <= 1'b0;
		end
		if(driver == 3'b000)
		begin
			dut__bvm__address <= quad0_bvm_addr;
			dut__dim__address <= quad0_dim_addr;
			quad0_bvm_data <= bvm__dut__data;
			quad0_dim_data <= dim__dut__data;
            		dut__dim__data <= quad0_sp_data;
			dut__dom__data <= 16'b0;
			dut__dom__write <= 1'b0;
			if(quad0_sp_data_rdy)
			begin
				dut__dim__write <= 1'b1;
			end	
			else dut__dim__write <= 1'b0;
		end
		else if(driver == 3'b001)
		begin
			dut__bvm__address <= quad1_bvm_addr;
			dut__dim__address <= quad1_dim_addr;
			quad1_bvm_data <= bvm__dut__data;
			quad1_dim_data <= dim__dut__data;
            dut__dim__data <= quad1_sp_data;
			dut__dom__data <= 16'b0;
			dut__dom__write <= 1'b0;
            if(quad1_sp_data_rdy) dut__dim__write <= 1'b1;
            else dut__dim__write <= 1'b0;
		end
		else if(driver == 3'b010)
		begin
			dut__bvm__address <= quad2_bvm_addr;
			dut__dim__address <= quad2_dim_addr;
			quad2_bvm_data <= bvm__dut__data;
			quad2_dim_data <= dim__dut__data;
            dut__dim__data <= quad2_sp_data;
			dut__dom__data <= 16'b0;
			dut__dom__write <= 1'b0;
            if(quad2_sp_data_rdy) dut__dim__write <= 1'b1;
            else dut__dim__write <= 1'b0;
		end
		else if(driver == 3'b011)
		begin
			dut__bvm__address <= quad3_bvm_addr;
			dut__dim__address <= quad3_dim_addr;
			quad3_bvm_data <= bvm__dut__data;
			quad3_dim_data <= dim__dut__data;
            dut__dim__data <= quad3_sp_data;
			dut__dom__data <= 16'b0;
			dut__dom__write <= 1'b0;
            if(quad3_sp_data_rdy) dut__dim__write <= 1'b1;
            else dut__dim__write <= 1'b0;
		end
		else if(driver == 3'b100)
		begin
			dut__bvm__address <= step2_bvm_addr;
			dut__dim__address <= step2_dim_addr;
			dut__dom__address <= step2_dom_addr;
			step2_bvm_data <= bvm__dut__data;
			step2_dim_data <= dim__dut__data;
            dut__dom__data <= step2_dom_data;
			dut__dim__write <= 1'b0;
			if(step2_dom_data_rdy) dut__dom__write <= 1'b1;
			else dut__dom__write <= 1'b0;
		end
	end
end

//------------------------ Quadrant 0 connections --------------------------------//

quad_module quad0(

			//--------------------------------------------------------------------
            // Input Signals
            // // Data
			.dim_data			(quad0_dim_data),
		 	.bvm_data			(quad0_bvm_data),

			// // Address


			//--------------------------------------------------------------------
            // Output Signals
            // // Data
			.sp_data			(quad0_sp_data),

			// // Address
			.dim_addr			(quad0_dim_addr),
		 	.bvm_addr			(quad0_bvm_addr),

			//--------------------------------------------------------------------
            // Control and Status Signals
            //
			.quad_finish		(quad0_fin),
		 	.sp_enable			(quad0_sp_en),
			.sp_data_rdy    	(quad0_sp_data_rdy),

			.quad_enable		(quad0_en),
			.quad_a_x_origin	(quad0_a_x_origin),
		 	.quad_a_y_origin	(quad0_a_y_origin),
		 	.sp_x_mask			(sp0_x_mask),
		 	.sp_y_mask			(sp0_y_mask),
		 	.quad_a_x_mask		(quad0_a_x_mask),
		 	.quad_a_y_mask		(quad0_a_y_mask),

			//--------------------------------------------------------------------
            // Global Signals
            //
			.reset				(reset_slave),
		 	.clk				(clk)
		 );

//------------------------ Quadrant 1 connections --------------------------------//

quad_module quad1(

			//--------------------------------------------------------------------
            // Input Signals
            // // Data
			.dim_data			(quad1_dim_data),
		 	.bvm_data			(quad1_bvm_data),

			// // Address


			//--------------------------------------------------------------------
			// Output Signals
            // // Data
			.sp_data			(quad1_sp_data),

			// // Address
			.dim_addr			(quad1_dim_addr),
		 	.bvm_addr			(quad1_bvm_addr),

			//--------------------------------------------------------------------
            // Control and Status Signals
            //
			.quad_finish		(quad1_fin),
		 	.sp_enable			(quad1_sp_en),
            .sp_data_rdy    	(quad1_sp_data_rdy),

			.quad_enable		(quad1_en),
		 	.quad_a_x_origin	(quad1_a_x_origin),
		 	.quad_a_y_origin	(quad1_a_y_origin),
		 	.sp_x_mask			(sp1_x_mask),
		 	.sp_y_mask			(sp1_y_mask),
		 	.quad_a_x_mask		(quad1_a_x_mask),
		 	.quad_a_y_mask		(quad1_a_y_mask),

			//--------------------------------------------------------------------
            // Global Signals
            //
		 	.reset				(reset_slave),
		 	.clk				(clk)
		 );

//------------------------ Quadrant 2 connections --------------------------------//

quad_module quad2(

			//--------------------------------------------------------------------
            // Input Signals
            // // Data
			.dim_data			(quad2_dim_data),
		 	.bvm_data			(quad2_bvm_data),

			// // Address


			//--------------------------------------------------------------------
			// Output Signals
            // // Data
			.sp_data			(quad2_sp_data),

			// // Address
			.dim_addr			(quad2_dim_addr),
		 	.bvm_addr			(quad2_bvm_addr),

			//--------------------------------------------------------------------
            // Control and Status Signals
            //
			.quad_finish		(quad2_fin),
		 	.sp_enable			(quad2_sp_en),
            .sp_data_rdy    	(quad2_sp_data_rdy),

			.quad_enable		(quad2_en),
		 	.quad_a_x_origin	(quad2_a_x_origin),
		 	.quad_a_y_origin	(quad2_a_y_origin),
		 	.sp_x_mask			(sp2_x_mask),
		 	.sp_y_mask			(sp2_y_mask),
		 	.quad_a_x_mask		(quad2_a_x_mask),
		 	.quad_a_y_mask		(quad2_a_y_mask),
			 
			//--------------------------------------------------------------------
            // Global Signals
            //
		 	.reset				(reset_slave),
		 	.clk				(clk)
		 );

//------------------------ Quadrant 3 connections --------------------------------//

quad_module quad3(

			//--------------------------------------------------------------------
            // Input Signals
            // // Data
			.dim_data			(quad3_dim_data),
		 	.bvm_data			(quad3_bvm_data),

			// // Address


			//--------------------------------------------------------------------
			// Output Signals
            // // Data
			.sp_data			(quad3_sp_data),

			// // Address
			.dim_addr			(quad3_dim_addr),
		 	.bvm_addr			(quad3_bvm_addr),

			//--------------------------------------------------------------------
            // Control and Status Signals
            //
			.quad_finish		(quad3_fin),
		 	.sp_enable			(quad3_sp_en),
            .sp_data_rdy    	(quad3_sp_data_rdy),

			.quad_enable		(quad3_en),
		 	.quad_a_x_origin	(quad3_a_x_origin),
		 	.quad_a_y_origin	(quad3_a_y_origin),
		 	.sp_x_mask			(sp3_x_mask),
		 	.sp_y_mask			(sp3_y_mask),
		 	.quad_a_x_mask		(quad3_a_x_mask),
		 	.quad_a_y_mask		(quad3_a_y_mask),
			 
			//--------------------------------------------------------------------
            // Global Signals
            //
		 	.reset				(reset_slave),
		 	.clk				(clk)
		 );

//-------------------------- Step 2  connections ----------------------------------//

step2_module step2(
			//--------------------------------------------------------------------
            		// Input Signals
            		// // Data
            		.dim_data			(step2_dim_data),
			.bvm_data			(step2_bvm_data),
            
			// // Address
			
			
			
			//--------------------------------------------------------------------
			// Output Signals
            		// // Data
            		.dom_data 			(step2_dom_data),
            		
            		// // Address
            		
            		.dim_addr 			(step2_dim_addr),
			.bvm_addr			(step2_bvm_addr),
			.dom_addr 			(step2_dom_addr),
            		
            		//--------------------------------------------------------------------
            		// Control and Status Signals
            		//
            		.finish 			(step2_fin),
			.dom_enable			(step2_dom_en),
			.dom_data_rdy 		(step2_dom_data_rdy),
			
			.enable 			(step2_en),
			.filter_origin		(step2_filter_origin),
			
            		//--------------------------------------------------------------------
		   	// Global Signals
		  	//
			.reset 				(reset_slave),
			.clk 				(clk)
		);	

//------------------------ Controller connections --------------------------------//

controller ctrl(

			//--------------------------------------------------------------------
            // Input Signals
            //
			.quad0_fin      	(quad0_fin),
            .quad1_fin      	(quad1_fin),
            .quad2_fin      	(quad2_fin),
            .quad3_fin      	(quad3_fin),
            .step2_fin      	(step2_fin),

            .quad0_sp_en    	(quad0_sp_en),
            .quad1_sp_en    	(quad1_sp_en),
            .quad2_sp_en    	(quad2_sp_en),
            .quad3_sp_en    	(quad3_sp_en),
            .dom_en         	(step2_dom_en),

            .go             	(go),

			//--------------------------------------------------------------------
            // Output Signals
            //
			.quad0_en       	(quad0_en),
            .quad1_en       	(quad1_en),
            .quad2_en       	(quad2_en),
            .quad3_en       	(quad3_en),
            .step2_en       	(step2_en),

			.driver    			(driver),
			.reset_slave		(reset_slave),

			//--------------------------------------------------------------------
            // Global Signals
            //
            .reset          	(reset),
            .clk            	(clk)
        );
endmodule
