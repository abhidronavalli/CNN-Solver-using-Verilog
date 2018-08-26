vlog /afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW02_mac.v
vlog quad_module.v;
vlog step2_module.v;
vlog controller.v;
vlog MyDesign.v;
vlog -sv +define+TB_DISPLAY_INTERMEDIATE+TB_DISPLAY_EXPECTED ece564_project_tb_top.v;
vlog -sv sram.v;
vsim -novopt tb_top;
