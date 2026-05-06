###################################################################

# Created by write_sdc on Tue May 5 23:35:29 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
create_clock [get_ports dco_clk]  -period 3.6  -waveform {0 1.8}
