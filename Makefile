show_synth_%: %.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed"

show_tb_%: %_tb.v
	iverilog -o simulations/out.vvp $*_tb.v $*.v
	vvp simulations/out.vvp
	gtkwave simulations/dump.vcd simulations/$* simulations/$*_settings.gtkw
