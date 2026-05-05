###################################################################

# Created by write_sdc on Mon May 4 00:59:43 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
create_clock [get_ports dco_clk]  -period 10  -waveform {0 5}
