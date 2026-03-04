show_synth_%: %.v
	yosys -q -p "read_verilog $<; proc; opt; select $*; show -colors 2 -width -signed"

SRCS := $(wildcard *.v)

show_tb_%: %_tb.v
	iverilog -o simulations/out.vvp $*_tb.v $*.v
	vvp simulations/out.vvp
	gtkwave simulations/dump.vcd simulations/$* simulations/$*_settings.gtkw

show_tb_top_%: %_tb.v
	iverilog -o simulations/out.vvp $(SRCS)
	vvp simulations/out.vvp
	gtkwave simulations/dump.vcd simulations/$* simulations/$*_settings.gtkw
