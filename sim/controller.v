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

About:

This module consists the controller logic which models a Moore FSM with 16 states. Each of the states
control the enables of the 4 quadrant modules(step1) and the step2 module. Also, each state controls
the behaviour of the MUX in the top module. Slave reset is also generated here to reset the child
modules once the global reset is triggered or once the current computation finishes.

****************************************************************************************************/

module controller
(
        output reg reset_slave, 

        output reg quad0_en,
        output reg quad1_en,
        output reg quad2_en,
        output reg quad3_en,
        output reg step2_en,

        output reg [2:0] driver,

        input wire quad0_fin,
        input wire quad1_fin,
        input wire quad2_fin,
        input wire quad3_fin,
        input wire step2_fin,

        input wire quad0_sp_en,
        input wire quad1_sp_en,
        input wire quad2_sp_en,
        input wire quad3_sp_en,
        input wire dom_en,

        input wire go,
        input wire reset,
        input wire clk

);

parameter [3:0] //synopsys enum states
		RESET = 4'd0,
		
		QUAD0_READ = 4'd1,
		QUAD0_WAIT = 4'd2,
		QUAD0_WRITE = 4'd3,
		
		QUAD1_READ = 4'd4,
		QUAD1_WAIT = 4'd5,
		QUAD1_WRITE = 4'd6,

		QUAD2_READ = 4'd7,
		QUAD2_WAIT = 4'd8,
		QUAD2_WRITE = 4'd9,

		QUAD3_READ = 4'd10,
		QUAD3_WAIT = 4'd11,
		QUAD3_WRITE = 4'd12,

        STEP2_READ = 4'd13,
        STEP2_WAIT = 4'd14,
        STEP2_WRITE = 4'd15;

reg [3:0] /* synopsys enum states */ current_state, next_state;

always @ (posedge clk)
begin
	if(reset)
    begin
        current_state <= RESET;
    end
	else
    begin
        current_state <= next_state;
    end
end
       

always @ (*)
begin
	case(current_state) // synopsys full_case parallel_case
		RESET:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b111;
            reset_slave = 1'b1;
			if(go) next_state = QUAD0_READ;
			else next_state = RESET;
		end
		
		QUAD0_READ:
		begin
			quad0_en = 1'b1;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b000;
            reset_slave = 1'b0;
            if(quad0_fin) next_state = QUAD1_READ;
            else if(quad0_sp_en) next_state = QUAD0_WAIT;
			else next_state = QUAD0_READ;
		end
		
		QUAD0_WAIT:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b000;
            reset_slave = 1'b0;
			next_state = QUAD0_WRITE;
		end
		
		QUAD0_WRITE:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b000;
            reset_slave = 1'b0;
			next_state = QUAD0_READ;
		end

		QUAD1_READ:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b1;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
            driver = 3'b001;
            reset_slave = 1'b0;
            if(quad1_fin) next_state = QUAD2_READ;
			else if(quad1_sp_en) next_state = QUAD1_WAIT;
			else next_state = QUAD1_READ;
		end
		
		QUAD1_WAIT:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b001;
            reset_slave = 1'b0;
			next_state = QUAD1_WRITE;
		end
		
		QUAD1_WRITE:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b001;
            reset_slave = 1'b0;
			next_state = QUAD1_READ;
		end
		
		QUAD2_READ:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b1;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b010;
            reset_slave = 1'b0;
            if(quad2_fin) next_state = QUAD3_READ;
			else if(quad2_sp_en) next_state = QUAD2_WAIT;
			else next_state = QUAD2_READ;
		end
		
		QUAD2_WAIT:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b010;
            reset_slave = 1'b0;
			next_state = QUAD2_WRITE;
		end
		
		QUAD2_WRITE:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b010;
            reset_slave = 1'b0;
			next_state = QUAD2_READ;
		end

		QUAD3_READ:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b1;
            step2_en = 1'b0;
			driver = 3'b011;
            reset_slave = 1'b0;
			if (quad3_fin) next_state = STEP2_READ;
            else if(quad3_sp_en) next_state = QUAD3_WAIT;
            else next_state = QUAD3_READ;
		end
		
		QUAD3_WAIT:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b011;
            reset_slave = 1'b0;
			next_state = QUAD3_WRITE;
		end
		
		QUAD3_WRITE:
		begin
			quad0_en = 1'b0;
			quad1_en = 1'b0;
			quad2_en = 1'b0;
			quad3_en = 1'b0;
            step2_en = 1'b0;
			driver = 3'b011;
            reset_slave = 1'b0;
			next_state = QUAD3_READ;
		end
		
        STEP2_READ:
        begin
            quad0_en = 1'b0;
            quad1_en = 1'b0;
            quad2_en = 1'b0;
            quad3_en = 1'b0;
            step2_en = 1'b1;
            driver = 3'b100;
            reset_slave = 1'b0;
            if(step2_fin) next_state = RESET;
            else if(dom_en) next_state = STEP2_WAIT;
            else next_state = STEP2_READ;
        end

        STEP2_WAIT:
        begin
            quad0_en = 1'b0;
            quad1_en = 1'b0;
            quad2_en = 1'b0;
            quad3_en = 1'b0;
            step2_en = 1'b0;
            driver = 3'b100;
            reset_slave = 1'b0;
            next_state = STEP2_WRITE;
        end

        STEP2_WRITE:
        begin
            quad0_en = 1'b0;
            quad1_en = 1'b0;
            quad2_en = 1'b0;
            quad3_en = 1'b0;
            step2_en = 1'b0;
            driver = 3'b100;
            reset_slave = 1'b0;
            next_state = STEP2_READ;
        end
	endcase
end
endmodule
