# syn/run_syn_sweep.tcl
set search_path [list . ../rtl ../rtl/periph]
if {[info exists env(SAED32_HOME)]} {
  set saed $env(SAED32_HOME)
  lappend search_path $saed $saed/lib
  foreach corner {stdcell_rvt stdcell_lvt stdcell_hvt} {
    set dbd [file join $saed lib $corner db_nldm]
    if {[file isdirectory $dbd]} { lappend search_path $dbd }
  }
}
set_app_var search_path $search_path
set_app_var target_library "saed32rvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32hvt_ss0p75v125c.db"
set_app_var link_library "* $target_library"

set hdlin_enable_hier_map true
define_design_lib WORK -path ./WORK
file mkdir reports

# analyze/elaborate
set rtl_files {}
foreach f [glob -nocomplain ../rtl/*.v] {
  set b [file tail $f]
  if {$b eq "openMSP430_defines.v" || $b eq "openMSP430_undefines.v"} { continue }
  lappend rtl_files $f
}
analyze -format verilog -library WORK $rtl_files
analyze -format verilog -library WORK [glob ../rtl/periph/*.v]
elaborate openMSP430 -library WORK
current_design openMSP430
link
set_fix_multiple_port_nets -all -buffer_constants
set_verification_top

# Coarse-to-fine sweep: walk down until slack goes negative, then the last
# non-negative point is the Fmax. The earlier coarse pass already proved 4.0ns
# closes; we now push below 4.0ns to find the true closure edge.
set periods {4.0 3.6 3.2 2.8 2.4 2.0 1.8 1.6 1.4 1.2 1.0}
set best_period ""
set best_slack -9999

foreach p $periods {
  # remove_clock expects a 1-element list; in practice [all_clocks] can be empty.
  set clks [all_clocks]
  if {[llength $clks] > 0} {
    foreach c $clks {
      remove_clock $c
    }
  }
  create_clock -period $p -name dco_clk [get_ports dco_clk]

  compile_ultra -gate_clock
  set tp [get_timing_paths -max_paths 1 -delay max]
  set ws [get_attribute $tp slack]

  puts "SWEEP: period=$p ns, worst_slack=$ws"
  if {$ws >= 0} {
    set best_period $p
    set best_slack $ws
  } else {
    # First negative-slack point: timing has failed at this period. The previous
    # period is the true Fmax — stop probing further (compile_ultra is expensive).
    puts "SWEEP: negative slack at period=$p — stop, Fmax = ${best_period} ns"
    break
  }
}

if {$best_period eq ""} {
  puts "ERROR: no non-negative slack point found in sweep."
  exit 2
}


set clks [all_clocks]
if {[llength $clks] > 0} {
  foreach c $clks {
    remove_clock $c
  }
}
create_clock -period $best_period -name dco_clk [get_ports dco_clk]
compile_ultra -gate_clock -incremental

set fmax_mhz [expr {1000.0 / $best_period}]
puts "FINAL: best_period=${best_period}ns, Fmax=${fmax_mhz}MHz, slack=${best_slack}"

report_timing -significant_digits 4 -max_paths 10 > reports/timing_maxfreq.rpt
report_area -hierarchy > reports/area_maxfreq.rpt
report_power > reports/power_maxfreq.rpt
write_sdc -nosplit constraints_maxfreq.sdc
write -format verilog -hierarchy -output netlist_maxfreq.v
write_sdf -version 2.1 netlist_maxfreq.sdf

exit