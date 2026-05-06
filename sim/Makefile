# Phase B — run from: cd sim && make run
SIMV    ?= ./simv
VCS     ?= vcs -full64 -sverilog +incdir+../rtl -f rtl_files.f ram.v tb_openmsp430_minimal.v -o simv
LOGDIR  ?= logs

# Gate-level (after DC produces ../syn/netlist.v). DC uses rvt+lvt+hvt target_library,
# so VCS needs all three verilog cell files (not only RVT).
SAED32_HOME     ?= /usr/local/synopsys/pdk/SAED32_EDK
NETLIST_VERILOG ?= $(SAED32_HOME)/lib/stdcell_rvt/verilog/saed32nm.v \
	$(SAED32_HOME)/lib/stdcell_lvt/verilog/saed32nm_lvt.v \
	$(SAED32_HOME)/lib/stdcell_hvt/verilog/saed32nm_hvt.v

.PHONY: compile run run-t0 run-t1 run-all-now run-phaseb run-phaseb-netlist \
        run-phaseb-both gen-pmem compile-netlist clean

compile:
	$(VCS) 2>&1 | tee compile.log

run: compile
	@mkdir -p $(LOGDIR)
	$(SIMV) -no_save +TEST_ID=0 2>&1 | tee $(LOGDIR)/run_default.log
	@grep -q "TB_OPENMSP430_MINIMAL: PASS" $(LOGDIR)/run_default.log && echo ">>> OK: PASS in $(LOGDIR)/run_default.log" || (echo ">>> FAIL"; exit 1)

run-t0: compile
	@mkdir -p $(LOGDIR)
	$(SIMV) -no_save +TEST_ID=0 2>&1 | tee $(LOGDIR)/run_t00.log
	@grep -q "TB_OPENMSP430_MINIMAL: PASS" $(LOGDIR)/run_t00.log && echo ">>> OK: t00" || (echo ">>> FAIL t00"; exit 1)

run-t1: compile
	@mkdir -p $(LOGDIR)
	$(SIMV) -no_save +TEST_ID=1 2>&1 | tee $(LOGDIR)/run_t01.log
	@grep -q "TB_OPENMSP430_MINIMAL: PASS" $(LOGDIR)/run_t01.log && echo ">>> OK: t01" || (echo ">>> FAIL t01"; exit 1)

gen-pmem:
	python3 scripts/gen_phaseb_pmem.py

# Ideal RTL: 20 tests, hierarchical WDT/MPY checks enabled
# Logs go to logs_ideal/ to avoid clobbering netlist run logs.
run-phaseb: gen-pmem compile
	@chmod +x scripts/run_tests_now.sh 2>/dev/null || true
	@LOGDIR=logs_ideal bash scripts/run_tests_now.sh

run-all-now: run-phaseb

# Gate-level DUT + behavioral RAM/TB (needs syn/netlist.v + SAED32 verilog)
compile-netlist:
	@test -f ../syn/netlist.v || (echo "ERROR: ../syn/netlist.v not found. Run: cd ../syn && dc_shell -f run_syn.tcl | tee syn.log"; exit 1)
	vcs -full64 -sverilog +define+GATE_LEVEL_SIM +delay_mode_zero +incdir+../rtl \
	  timescale.v ram.v tb_openmsp430_minimal.v \
	  ../syn/netlist.v \
	  $(addprefix -v ,$(NETLIST_VERILOG)) \
	  -o simv_netlist 2>&1 | tee compile_netlist.log

# Netlist: same 20 runs; +PER_CHK_OFF avoids hierarchical regs if DC flattens or X on gated nodes
# Logs go to logs_netlist/ to avoid clobbering ideal RTL run logs.
run-phaseb-netlist: gen-pmem compile-netlist
	@chmod +x scripts/run_tests_now.sh 2>/dev/null || true
	@SIMV=./simv_netlist SIMV_EXTRA=+PER_CHK_OFF LOGDIR=logs_netlist bash scripts/run_tests_now.sh

run-phaseb-both: run-phaseb
	@if [ -f ../syn/netlist.v ]; then $(MAKE) run-phaseb-netlist; else echo ">>> Netlist skipped (no ../syn/netlist.v). Synthesize first."; fi

clean:
	rm -rf simv simv.daidir simv_netlist simv_netlist.daidir csrc ucli.key vc_hdrs.h compile.log compile_netlist.log run.log DVEfiles inter.vpd $(LOGDIR)/*.log logs_ideal/*.log logs_netlist/*.log
