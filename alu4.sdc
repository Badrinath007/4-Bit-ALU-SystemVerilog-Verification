# alu4.sdc
# Timing constraints for DE2-115 (Cyclone IV E, EP4CE115F29C7)
# 50 MHz board oscillator -> 20.000 ns period

# 1. 50 MHz system clock
create_clock -name clk -period 20.000 [get_ports {clk}]

# 2. Input delays relative to clk
set_input_delay -clock clk -max 3.000 [get_ports {A[*]}]
set_input_delay -clock clk -min 1.000 [get_ports {A[*]}]

set_input_delay -clock clk -max 3.000 [get_ports {B[*]}]
set_input_delay -clock clk -min 1.000 [get_ports {B[*]}]

set_input_delay -clock clk -max 3.000 [get_ports {opcode[*]}]
set_input_delay -clock clk -min 1.000 [get_ports {opcode[*]}]

# 3. Output delays relative to clk
# NOTE: alu4 has no alu_out/overflow/zero ports; y/led_out/beat are the real outputs.
set_output_delay -clock clk -max 3.000 [get_ports {y[*]}]
set_output_delay -clock clk -min 1.000 [get_ports {y[*]}]

set_output_delay -clock clk -max 3.000 [get_ports {cout}]
set_output_delay -clock clk -min 1.000 [get_ports {cout}]

set_output_delay -clock clk -max 3.000 [get_ports {led_out[*]}]
set_output_delay -clock clk -min 1.000 [get_ports {led_out[*]}]

set_output_delay -clock clk -max 3.000 [get_ports {beat}]
set_output_delay -clock clk -min 1.000 [get_ports {beat}]

# Derive clock uncertainty so setup/hold slack includes PLL/clock jitter margin
derive_clock_uncertainty
