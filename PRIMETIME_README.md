# PrimeTime PX README (Professor-Requirement Aligned)
# PrimeTime PX 说明（与教授要求对齐）

This file is only for the **PrimeTime** deliverable in `Project Midterm.pdf`.
本文件只针对 `Project Midterm.pdf` 中的 **PrimeTime** 交付要求。

## 0) What must be delivered (exactly matching professor requirements)
## 0) 必须交付什么（严格对齐教授要求）

- **Code requirement**: main PrimeTime script + generated reports under `ptpx/`.
  **代码要求**：主 PrimeTime 脚本和生成报告必须放在 `ptpx/` 下。
- **Method requirement**:
  **方法要求**：
  - power measured with **representative test vectors** of real DUT workload,
    功耗必须由能代表真实 DUT 工作负载的**代表性测试向量**驱动测得。
  - measured over an **extended cycle window** for **average power**,
    必须在**足够长的周期窗口**上测量以反映**平均功耗**。
  - optional **peak power** with stressed inputs.
    可以可选地在高压测输入下评估**峰值功耗**。
- **Report requirement**:
  **报告要求**：
  - explain script functionality,
    说明脚本的主要功能。
  - explain methodology and how vectors were generated,
    说明测量方法以及向量如何生成。
  - summarize average power (and optional peak) in mW/W.
    以 mW/W 汇总平均功耗（可选峰值功耗）。

---

## 1) Files in this repo that satisfy those requirements
## 1) 本仓库中满足上述要求的文件

- Main script: `ptpx/run_ptpx.tcl`
  主脚本：`ptpx/run_ptpx.tcl`
- PrimeTime run log: `ptpx/ptpx.log` (default-activity run), `ptpx/ptpx_vcd.log` (if VCD run used)
  PrimeTime 运行日志：`ptpx/ptpx.log`（默认活动率运行），`ptpx/ptpx_vcd.log`（使用 VCD 时）。
- Generated reports:
  生成的报告：
  - `ptpx/reports/power.rpt`
  - `ptpx/reports/power_group.rpt`
  - `ptpx/reports/power_hier.rpt`
  - `ptpx/reports/timing_check.rpt`
- Vector source for representative workload:
  代表性负载向量来源：
  - netlist simulation flow in `sim/` (same Phase B real workloads),
    `sim/` 中的网表仿真流程（与 Phase B 一致的真实工作负载）。
  - optional VCD input expected by script: `sim/ptpx_t00.vcd`
    脚本可选读取的 VCD 输入：`sim/ptpx_t00.vcd`。
- Netlist + constraints inputs consumed by PTPX:
  PTPX 使用的网表与约束输入：
  - `syn/netlist_maxfreq.v`
  - `syn/constraints_maxfreq.sdc`
  - `syn/netlist_maxfreq.sdf` (optional but recommended)
    `syn/netlist_maxfreq.sdf`（可选但推荐）。

---

## 2) Full-score execution flow (step-by-step)
## 2) 满分执行流程（逐步）

### Step 1 — Prepare netlist and constraints at Fmax
### 第 1 步 — 准备 Fmax 下的网表与约束

From synthesis flow, make sure these exist:
先确认综合流程已生成以下文件：

- `syn/netlist_maxfreq.v`
- `syn/constraints_maxfreq.sdc`
- `syn/netlist_maxfreq.sdf` (recommended)
  `syn/netlist_maxfreq.sdf`（推荐）。

If missing, regenerate from your `syn/` flow first.
如果缺失，先回到 `syn/` 流程重新生成。

### Step 2 — Prepare representative activity vectors
### 第 2 步 — 准备代表性活动向量

Use the same non-trivial workloads from Phase B (random IRQ + corner NMI + WDT/MPY accesses), not idle-only vectors.
使用与 Phase B 相同的非平凡负载（随机 IRQ + corner NMI + WDT/MPY 访问），不要只用空闲向量。

At least one reproducible path:
至少保留一条可复现路径：

1. Run gate-level sim with your Phase B tests in `sim/`.
   在 `sim/` 中运行 Phase B 的门级仿真测试。
2. Dump VCD for selected representative testcase(s), e.g. `sim/ptpx_t00.vcd`.
   对选定的代表性 testcase 导出 VCD，例如 `sim/ptpx_t00.vcd`。
3. Keep vector generation command(s) in report text for reproducibility.
   在报告中写清向量生成命令，确保他人可复现。

> If VCD is not provided, script falls back to default toggle assumptions.  
> 如果没有提供 VCD，脚本会退回到默认翻转率假设。
> For best score, use **VCD-based activity** because it is tied to real workloads.
> 为了更贴合评分要求，建议使用**基于 VCD 的活动率**，因为它来自真实负载。

### Step 3 — Run PrimeTime PX
### 第 3 步 — 运行 PrimeTime PX

```bash
cd /home/cegrad/xhuan230/cs220/midterm-team-5/ptpx
export SAED32_HOME=/usr/local/synopsys/pdk/SAED32_EDK
```

#### 3A. Recommended (representative VCD activity)
#### 3A. 推荐方式（使用代表性 VCD 活动率）

```bash
export USE_VCD=1
pt_shell -f run_ptpx.tcl | tee ptpx_vcd.log
```

#### 3B. Fallback (no VCD, default switching)
#### 3B. 备选方式（无 VCD，使用默认活动率）

```bash
unset USE_VCD
pt_shell -f run_ptpx.tcl | tee ptpx.log
```

### Step 4 — Collect report numbers
### 第 4 步 — 收集报告数值

Primary numbers come from `ptpx/reports/power.rpt`:
主要功耗数值来自 `ptpx/reports/power.rpt`：

- `Total Power`
- `Cell Internal Power`
- `Net Switching Power`
- `Cell Leakage Power`

Breakdown and explainability:
分项解释与可分析性来自：

- `ptpx/reports/power_group.rpt` (clock/register/combinational share)
  `ptpx/reports/power_group.rpt`（时钟/寄存器/组合逻辑占比）。
- `ptpx/reports/power_hier.rpt` (hierarchical hotspots)
  `ptpx/reports/power_hier.rpt`（层次热点）。

Timing sanity at measurement point:
测量点时序合理性检查来自：

- `ptpx/reports/timing_check.rpt`

---

## 3) What `run_ptpx.tcl` does (for report write-up)
## 3) `run_ptpx.tcl` 在做什么（可直接写进报告）

`ptpx/run_ptpx.tcl` does the following in order:
`ptpx/run_ptpx.tcl` 按以下顺序执行：

1. builds search/link path to SAED32 worst-corner libraries (`rvt/lvt/hvt`, `ss0p75v125c`);
   构建 SAED32 最坏角库（`rvt/lvt/hvt`, `ss0p75v125c`）的搜索/链接路径。
2. enables power analysis mode (`power_enable_analysis`, averaged mode);
   开启功耗分析模式（`power_enable_analysis`，平均功耗模式）。
3. reads gate netlist (`../syn/netlist_maxfreq.v`) and links design `openMSP430`;
   读取门级网表（`../syn/netlist_maxfreq.v`）并链接 `openMSP430` 设计。
4. reads timing constraints (`../syn/constraints_maxfreq.sdc`);
   读取时序约束（`../syn/constraints_maxfreq.sdc`）。
5. optionally reads SDF (`../syn/netlist_maxfreq.sdf`) for sign-off delay annotation;
   可选读取 SDF（`../syn/netlist_maxfreq.sdf`）用于签核级延时回标。
6. runs `update_timing` and dumps `timing_check.rpt`;
   执行 `update_timing` 并输出 `timing_check.rpt`。
7. reads VCD activity when `USE_VCD=1` and file exists, otherwise sets default switching activity;
   当 `USE_VCD=1` 且文件存在时读取 VCD 活动率，否则设置默认翻转活动率。
8. runs `update_power`;
   执行 `update_power`。
9. dumps `power.rpt`, `power_group.rpt`, `power_hier.rpt`.
   输出 `power.rpt`、`power_group.rpt`、`power_hier.rpt`。

This maps directly to the professor’s required “script functionality + methodology + vector generation explanation”.
这与教授要求的“脚本功能 + 方法学 + 向量生成说明”一一对应。

---

## 4) Current measured result in this repo (default-activity run)
## 4) 本仓库当前测得结果（默认活动率运行）

From `ptpx/reports/power.rpt` currently present:
根据当前已有的 `ptpx/reports/power.rpt`：

- **Total Power** = `1.226e-03 W` = **1.226 mW**
- **Leakage** = `1.210e-03 W` (98.69%)
- **Internal** = `1.469e-05 W`
- **Switching** = `1.433e-06 W`

This run is valid as a baseline check, but for strongest grading alignment, also provide a **VCD-driven representative-workload run** and report those numbers as primary.
这组结果可作为基线检查，但若要最贴合评分要求，建议再提供**VCD 驱动的代表性负载结果**并作为主结果汇报。

---

## 5) Report section template (what to write)
## 5) 报告章节模板（应写内容）

Use this structure in the midterm report PrimeTime section:
期中报告 PrimeTime 部分建议按以下结构写：

1. **Script functionality**: summarize the 9 script steps above.
   **脚本功能**：概述上面 9 个脚本步骤。
2. **Measurement methodology**:
   **测量方法**：
   - corner/library used,
     使用的工艺角和库。
   - averaged power mode,
     平均功耗分析模式。
   - timing-constrained netlist at Fmax,
     Fmax 约束下的网表测量条件。
   - activity source (VCD vs fallback).
     活动率来源（VCD 或 fallback）。
3. **Vector generation method**:
   **向量生成方法**：
   - where vectors come from (`sim/`),
     向量来源（`sim/`）。
   - why representative (Phase B non-trivial workloads).
     为什么具有代表性（Phase B 的非平凡负载）。
4. **Results summary table**:
   **结果汇总表**：
   - total/internal/switching/leakage (mW),
     总功耗/内部功耗/开关功耗/漏电功耗（mW）。
   - optional group/hierarchy highlights.
     可选给出 group/hierarchy 亮点。
5. **Optional peak power plan/result**:
   **可选峰值功耗方案/结果**：
   - define stress vector method,
     定义高压测向量方法。
   - report peak if measured.
     若测了峰值则报告峰值。

---

## 6) Final checklist before submission
## 6) 提交前最终检查清单

- [ ] `ptpx/run_ptpx.tcl` exists and runs.
      `ptpx/run_ptpx.tcl` 存在且可运行。
- [ ] `ptpx/reports/power.rpt` generated from final run.
      `ptpx/reports/power.rpt` 已由最终运行生成。
- [ ] At least one representative-workload VCD-based run log saved (`ptpx_vcd.log`).
      至少保存一份代表性负载的 VCD 运行日志（`ptpx_vcd.log`）。
- [ ] PrimeTime section in report explains script + methodology + vector source + numeric summary.
      报告 PrimeTime 章节已写清脚本、方法、向量来源和数值汇总。
- [ ] All paths in write-up are relative to `midterm-team-5/` and reproducible.
      文中所有路径都相对 `midterm-team-5/` 且可复现。

