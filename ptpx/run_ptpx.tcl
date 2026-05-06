# CS220 Midterm — PrimeTime PX power analysis at Fmax
#
# Usage:
#   cd ptpx
#   export SAED32_HOME=/usr/local/synopsys/pdk/SAED32_EDK
#   pt_shell -f run_ptpx.tcl | tee ptpx.log
#
# Inputs (from ../syn/):
#   netlist_maxfreq.v        — gate-level netlist at Fmax
#   constraints_maxfreq.sdc  — clock @ Fmax
#   netlist_maxfreq.sdf      — back-annotated cell delays (optional, used if present)
#
# Optional activity input:
#   ../sim/ptpx_t00.vcd      — VCD from a netlist sim of TEST_ID=0
#                              (set USE_VCD env var to enable; otherwise PrimeTime
#                               assigns a default 10% toggle rate via set_switching_activity)
#
# Outputs (under reports/):
#   power.rpt        — total / dynamic / leakage breakdown
#   power_group.rpt  — by power group (clock_network, register, combinational, …)
#   power_hier.rpt   — hierarchical
#   timing_check.rpt — sanity sign-off timing report at Fmax

set search_path [list .]
if {[info exists env(SAED32_HOME)]} {
  set saed $env(SAED32_HOME)
  lappend search_path $saed $saed/lib
  foreach corner {stdcell_rvt stdcell_lvt stdcell_hvt} {
    set dbd [file join $saed lib $corner db_nldm]
    if {[file isdirectory $dbd]} { lappend search_path $dbd }
  }
}
set_app_var search_path $search_path
set_app_var link_path "* saed32rvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32hvt_ss0p75v125c.db"

# Enable power analysis BEFORE link_design so PTPX-only commands
# (set_switching_activity, propagate_switching_activity, report_power) are available.
set_app_var power_enable_analysis true
set_app_var power_analysis_mode averaged

file mkdir reports

# Read the post-synthesis Fmax netlist
read_verilog ../syn/netlist_maxfreq.v
current_design openMSP430
link_design

# Worst-case operating conditions are the only ones characterized in these libs;
# pt picks them automatically from the .db, no set_operating_conditions needed.

# Constraints (clock at Fmax)
read_sdc ../syn/constraints_maxfreq.sdc

# Back-annotate cell delays if SDF is available (sign-off accuracy)
if {[file exists ../syn/netlist_maxfreq.sdf]} {
  read_sdf ../syn/netlist_maxfreq.sdf
}

# Update / sanity-check timing first
update_timing -full
report_timing -max_paths 5 -significant_digits 4 > reports/timing_check.rpt

# --- Power analysis -----------------------------------------------------------
# Two activity sources are supported. VCD gives sign-off-accurate dynamic power;
# default propagation gives a quick leakage-dominated estimate.
set vcd_path "../sim/ptpx_t00.vcd"
set use_vcd 0
if {[info exists env(USE_VCD)] && $env(USE_VCD) ne "0" && [file exists $vcd_path]} {
  set use_vcd 1
}

if {$use_vcd} {
  puts "PTPX: reading VCD activity from $vcd_path"
  read_vcd -strip_path tb_openmsp430_minimal/dut $vcd_path
} else {
  puts "PTPX: no VCD — using default switching activity (10% toggle, 50% static prob.)"
  set_switching_activity -toggle_rate 0.10 -static_probability 0.5 \
      -base_clock dco_clk [all_inputs]
  set_switching_activity -toggle_rate 0.10 -static_probability 0.5 \
      [all_registers -data_pins]
}

# Modern PrimeTime PX uses update_power (not propagate_switching_activity);
# it internally propagates activity through the design before report_power.
update_power

# Comprehensive power reports
report_power                                > reports/power.rpt
report_power -groups {clock_network register combinational sequential io_pad memory black_box} \
                                            > reports/power_group.rpt
report_power -hierarchy -levels 3           > reports/power_hier.rpt

puts "DONE: ptpx reports in ptpx/reports/"
exit
