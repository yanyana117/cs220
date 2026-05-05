# CS220 Project Midterm — Team 5 Code Deliverable

Baseline: **openMSP430** (trimmed top-level for course scope). This archive follows **Project Midterm.pdf** layout: `rtl/`, `sim/`, `syn/`, `ptpx/`, `sw/`.

## Directory layout

| Directory | Contents |
|-----------|----------|
| `rtl/` | Synthesizable Verilog RTL and `openMSP430_defines.v`. |
| `sim/` | Simulation file list (`rtl_files.f`), testbench, memory images, `Makefile`, logs (`compile.log`, `run.log`). |
| `syn/` | Synthesis scripts and reports (when run). |
| `ptpx/` | PrimeTime PX scripts and power reports (when run). |
| `sw/` | Optional software golden / trace tools; N/A unless stated in the report. |
| `openmsp430_src/` | Upstream reference clone; baseline **commit hash** is recorded in the **Midterm Report** (Baseline RTL). |

Each subdirectory may contain a one-line `FOLDER_INFO.txt` describing intent.

## Prerequisites

- **Synopsys VCS** (example: `vcs -full64 -sverilog …`) on the same machine or flow used to generate `sim/compile.log`.
- Python 3 (optional) to regenerate `sim/pmem.mem` if missing.

## Reproduce — RTL simulation (ideal)

From the **repository root** (`midterm-team-5/`):

```bash
cd sim
```

If `pmem.mem` is missing, generate the default image:

```bash
python3 << 'PY'
n = 2048
lines = ["4303"] * n
lines[n - 1] = "F000"
open("pmem.mem", "w").write("\n".join(lines) + "\n")
PY
```

Compile and run:

```bash
vcs -full64 -sverilog +incdir+../rtl -f rtl_files.f ram.v tb_openmsp430_minimal.v -o simv 2>&1 | tee compile.log
mkdir -p logs
./simv -no_save +TEST_ID=0 2>&1 | tee logs/run_default.log
```

Or (recommended):

```bash
make run
```

**Phase B — full regression (20 testcase IDs, 20 logs):**

```bash
cd sim
make run-phaseb
```

This runs `scripts/gen_phaseb_pmem.py` (refreshes `pmem.mem`, `pmem_t00.mem` … `pmem_t19.mem`), recompiles if needed, then runs `./simv` for `TEST_ID=0..19` into `sim/logs/run_t00.log` … `run_t19.log`.

**Expected result:** `sim/logs/run_default.log` (or console) contains `TB_OPENMSP430_MINIMAL: PASS`.

**Artifacts to archive with the submission:** `sim/compile.log`, `sim/logs/*.log`, program images (`pmem.mem`, `pmem_t00.mem` … `pmem_t19.mem`), `sim/scripts/gen_phaseb_pmem.py`, and the TB / filelist sources listed above. Copy the **Verification** table below into the midterm report PDF and add waveforms or bus-monitor notes as required by the rubric.

### Verification testcase map (ideal sim)

| Label | `+TEST_ID` | Program image | Intent |
|-------|------------|---------------|--------|
| R0 | 0 | `pmem.mem` | Deterministic WDT hold + small MPY |
| R1–R9 | 1–9 | `pmem_t01.mem` … `pmem_t09.mem` | Seeded varying operands / NOP padding |
| C0–C9 | 10–19 | `pmem_t10.mem` … `pmem_t19.mem` | Corner-style WDT/MPY ordering and operands |
| | | | |
| | | | *Log path pattern:* `sim/logs/run_tNN.log` (`NN` = two-digit `TEST_ID`). |

**TB features (Verification code, Midterm.pdf):**

- **Constrained-random** (SystemVerilog `randomize()` + `dist` constraints): for `TEST_ID=0..9`, an **IRQ0** pulse is injected after a random delay in `[120,3800]` cycles (repeatable via `+CR_SEED=<uint>`).
- **Corner** stimulus: for `TEST_ID=10..19`, a one-cycle **NMI** pulse is applied (disable with `+NO_CORNER_NMI` if needed).
- **Functional checks** (ideal RTL): after 50k `mclk` cycles, **WDTHOLD** must be latched in `dut.watchdog_0.wdtctl[7]` and **MPY RESLO** must be non-zero unless `+PER_CHK_OFF` is set (useful for gate-level if hierarchy is flattened).

## Reproduce — gate-level simulation (netlist)

**Project Midterm.pdf** requires testcases to pass **ideal and netlist** simulation (same TB/testcases is allowed).

1. Synthesize so `syn/netlist.v` exists (see below).
2. Set `SAED32_HOME` so `sim/Makefile` can find the **RVT+LVT+HVT** Verilog cell files (default: `saed32nm.v`, `saed32nm_lvt.v`, `saed32nm_hvt.v` under `lib/stdcell_*/verilog/`). Override `NETLIST_VERILOG` only if your PDK layout differs.
3. From `sim/`:

```bash
make run-phaseb-netlist
```

This compiles `simv_netlist` (DUT = `../syn/netlist.v`, `+define+GATE_LEVEL_SIM`, `+delay_mode_zero`) and runs the **same 20** `TEST_ID` values. The TB skips hierarchical WDT/MPY register checks in gate mode; optional `+PER_CHK_OFF` still disables the RTL-only runtime path if you compile without `GATE_LEVEL_SIM`.

**Ideal + netlist in one shot** (netlist step is skipped if `syn/netlist.v` is missing):

```bash
make run-phaseb-both
```

## Reproduce — synthesis (Design Compiler)

From `syn/` (set `SAED32_HOME` to the directory that contains the **.db** libraries listed in **Project Midterm.pdf**):

```bash
cd syn
export SAED32_HOME=/path/to/SAED32_EDK   # example; use your lab path
dc_shell -f run_syn.tcl | tee syn.log
```

Outputs (gitignored by default): `netlist.v`, `netlist.sdf`, `constraints.sdc`, `reports/*.rpt`. Then run **`make run-phaseb-netlist`** from `sim/`.

## Reproduce — PrimeTime PX

Scripts and power reports will live under `ptpx/` once the flow is finalized. Vectors are expected to come from `sim/` as described in the **Midterm Report → PrimeTime**.

## Software golden model

If no separate golden is used, the report states **N/A** with rationale (per PDF). Any scripts added later will be documented in the report and placed under `sw/`.

## Report

The written midterm document (PDF) is the authoritative place for **baseline provenance**, **clock-domain analysis**, **verification tables**, **synthesis / power numbers**, and **validation**. Paths inside this zip use **relative** locations from `midterm-team-5/` so results can be recreated after unzip without editing absolute paths.
