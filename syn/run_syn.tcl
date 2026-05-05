# CS220 Midterm — baseline openMSP430 synthesis (Design Compiler)
# Usage (after setting library path — see README):
#   cd syn && dc_shell -f run_syn.tcl | tee syn.log
#
# Expects SAED32 .db files on search_path. Typical:
#   export SAED32_HOME=/path/to/SAED32_EDK
#   dc_shell -f run_syn.tcl

set search_path [list . ../rtl ../rtl/periph]
if {[info exists env(SAED32_HOME)]} {
  set saed $env(SAED32_HOME)
  lappend search_path $saed $saed/lib
  # Worst-corner .db files live under lib/stdcell_*/db_nldm (not only lib/)
  foreach corner {stdcell_rvt stdcell_lvt stdcell_hvt} {
    set dbd [file join $saed lib $corner db_nldm]
    if {[file isdirectory $dbd]} {
      lappend search_path $dbd
    }
  }
}

set_app_var search_path $search_path

# Worst-case corners per Project Midterm.pdf
set_app_var target_library "saed32rvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32hvt_ss0p75v125c.db"
set_app_var link_library "* $target_library"

set hdlin_enable_hier_map true
define_design_lib WORK -path ./WORK
file mkdir reports

# Resolve `include "openMSP430_defines.v"` via search_path (../rtl).
# Do not analyze openMSP430_defines.v / openMSP430_undefines.v alone: the
# defines file sets `OMSP_NO_INCLUDE`, and if DC compiles it before
# openMSP430.v, the module skips `include` and macros like DMEM_MSB vanish.
set rtl_files {}
foreach f [glob -nocomplain ../rtl/*.v] {
  set base [file tail $f]
  if {$base eq "openMSP430_defines.v" || $base eq "openMSP430_undefines.v"} {
    continue
  }
  lappend rtl_files $f
}
analyze -format verilog -library WORK $rtl_files
analyze -format verilog -library WORK [glob ../rtl/periph/*.v]

elaborate openMSP430 -library WORK
current_design openMSP430
link

# Master clock must be a real input. openMSP430 drives mclk/smclk as outputs
# (see openMSP430.v); constrain the on-chip DCO oscillator input instead.
create_clock -period 10.0 -name dco_clk [get_ports dco_clk]

set_fix_multiple_port_nets -all -buffer_constants

# compile_ultra -gate_clock requires a verification top (GHM-004); use the
# no-arg form — do not pass [current_design] (CMD-012 in W-2024 DC).
set_verification_top

compile_ultra -gate_clock

report_timing -significant_digits 4 -max_paths 10 > reports/timing.rpt
report_area -hierarchy > reports/area.rpt
report_power > reports/power.rpt

write -format verilog -hierarchy -output netlist.v
write_sdc -nosplit constraints.sdc
write_sdf -version 2.1 netlist.sdf

puts "Done: netlist.v netlist.sdf constraints.sdc reports/*.rpt"
exit
