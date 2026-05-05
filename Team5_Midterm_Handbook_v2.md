# CS 220 Team 5 Midterm Execution Handbook (v2)
# CS 220 第五组 期中项目执行手册 (v2)

**Project**: openMSP430 Microcontroller Design and Optimization (Clock Gating)
**Team**: Andrew Permatigari, Kenneth Maina, Xingran Huang
**Baseline**: openMSP430 commit `92c883abb4518dbc35b027e6cad5ffef5b2fbb81`

---

## How to Use This Document / 如何使用本文档

**EN**: This handbook is structured around the instructor's grading rubric. Each "1 point item" maps to specific code work + report content. Follow steps in order, check items off as you complete them.

**CN**: 本手册以老师的评分细则为主线组织。每个"1 分项"对应具体的代码工作 + 报告内容。按顺序执行,完成一项打钩一项。

---

## Section 0: Grading Map (Most Important View) / 评分对照 (最重要的视图)

**EN**: Total = 10 points. Each item is graded as complete/partial/missing. "Each complete item will receive full credit" (PDF, page 3).

**CN**: 总分 10 分。每一项按完整/部分/缺失打分。老师 PDF 第 3 页原文: "Each complete item will receive full credit"。

| Points / 分值 | PDF Category / PDF 类别 | Deliverables for Full Credit / 满分要求 | Maps to Steps / 对应步骤 |
|---|---|---|---|
| **2 pt** | Midterm presentation | Slides covering baseline, PPA, testbench, future clock gating with risk analysis (synchronizers + activation) | Step 14 |
| **1 pt** | Report: write-up for individual sections | RTL / Verification / SW / Synthesis / PrimeTime sections all complete | Steps 2, 3-4 reports, 5, 7, 9 reports |
| **1 pt** | Report: validation of reported results | Comparison against openMSP430 docs / TI datasheet / literature, with traceable numbers | Step 10 |
| **1 pt** | Report: design and verification plan for optimizations | Clock gating implementation plan (with synchronizer analysis) + verification plan | Steps 11, 12 |
| **1 pt** | Report: README | How to reproduce all results from clean environment | Step 13 |
| **1 pt** | Code: baseline RTL + software golden model | Complete `rtl/` folder + non-empty `sw/` folder | Steps 2, 5 |
| **1 pt** | Code: verification testbench + testcases | `sim/` with main TB + 20 testcases passing both ideal and netlist sim | Steps 3, 4, 6, 8 |
| **1 pt** | Code: synthesis scripts | `syn/` with tcl script + reports | Step 7 |
| **1 pt** | Code: PrimeTime scripts | `ptpx/` with tcl script + reports | Step 9 |

**EN — Critical insight**: Even if a section feels small (e.g., software golden model for a CPU project), leaving it empty risks the whole 1-point item. Every item that the rubric explicitly names must produce visible output.

**CN — 关键提示**: 即便某个板块看起来很小 (例如 CPU 项目的软件 golden model),留空就会丢掉整个 1 分项。评分细则里点名的每一项都必须有可见产出。

---

## Section 1: Recommended Report Structure / 推荐报告结构

Use these as `\section` headings in LaTeX. Maps directly to PDF "Please refer to above on what to include for each section":

LaTeX 中可直接作为 `\section` 标题。直接对应 PDF "Please refer to above on what to include for each section":

```
1.  Introduction (Team and design choice) / 介绍 (团队与设计选择)
2.  Baseline RTL                          / 基线 RTL
    2.1 Source and Version
    2.2 Module Overview
    2.3 Modifications (currently none)
3.  Verification                          / 验证
    3.1 Testbench Architecture
    3.2 Testcase Summary Table (20 cases)
    3.3 Ideal vs Netlist Simulation
4.  Software Golden Model                 / 软件参考模型
5.  Synthesis                             / 综合
    5.1 Script Functionality
    5.2 Methodology
    5.3 Maximum Frequency Determination
    5.4 Final PPA Results
6.  PrimeTime Power Analysis              / PrimeTime 功耗分析
    6.1 Script Functionality
    6.2 Test Vector Generation
    6.3 Average Power Result
    6.4 Hierarchical Power Breakdown
7.  Validation of Reported Results        / 结果验证
8.  Optimization Implementation Plan      / 优化实施计划
    8.1 Target Modules and Approach
    8.2 Clock Domain and Synchronizer Analysis
    8.3 Trade-off Analysis
9.  Optimization Verification Plan        / 优化验证计划
10. README: Reproducing Results           / README 复现说明
11. References                            / 参考文献
```

---

## Section 2: Instructor Proposal Feedback (Must Address) / 老师 Proposal 反馈 (必须回应)

| # | Feedback (EN) | 反馈 (CN) | Lands in / 落地位置 |
|---|---|---|---|
| 1 | Synchronizers must be carefully handled when gating clocks across domains | 在跨时钟域 gate 时钟时,同步器必须小心处理 | Step 11, Report Section 8.2 |
| 2 | Must synthesize all peripheral blocks since they are gating targets | 必须综合所有外设模块,因为它们是 gating 目标 | Step 7, Report Section 5 |
| 3 | Testcases must actively exercise multiplier and watchdog so baseline power includes their activity | 测试用例必须激活 multiplier 和 watchdog,使 baseline 功耗包含它们的活动 | Steps 4 + 8 + 9, Report Sections 3.2 + 6.2 + 9 |
| 4 | Start early and communicate | 尽早开始并保持沟通 | Now / 现在 |

---

# EXECUTION STEPS / 执行步骤

# Step 1: Project Setup / 项目搭建

**Status / 状态**: ✅ DONE

## Server Operations / 服务器操作

```bash
cd ~
mkdir -p cs220/midterm-team-5
cd cs220/midterm-team-5
mkdir rtl sim sw syn ptpx report
```

**EN**: PDF "Submission Instruction" point 1 mandates folder name `midterm-team-N` and the subfolder names.

**CN**: PDF 第 3 页提交说明第 1 点强制要求文件夹叫 `midterm-team-N`,子文件夹名固定。

---

# Step 2: Clone openMSP430 Baseline / 克隆基线代码

**Status / 状态**: ✅ DONE

## Server Operations

```bash
cd ~/cs220/midterm-team-5
git clone https://github.com/olgirard/openmsp430.git openmsp430_src
cp openmsp430_src/core/rtl/verilog/*.v rtl/
cp -r openmsp430_src/core/rtl/verilog/periph rtl/
cd openmsp430_src && git rev-parse HEAD
# Recorded: 92c883abb4518dbc35b027e6cad5ffef5b2fbb81 (2018-03-31)
```

**EN — Critical for feedback point 2**: Copy the entire `periph/` directory. The `multiplier`, `watchdog`, and other peripherals MUST be in `rtl/` because synthesis must include them.

**CN — 落地反馈点 2**: 必须复制整个 `periph/` 目录。乘法器、看门狗等外设必须在 `rtl/` 里,因为综合时必须包含它们。

## Report Section / 对应报告 Section 2: Baseline RTL

### Instructor Original Wording / 老师原文

PDF page 1, "Baseline RTL":
> "Code: All Verilog RTL files should be in a folder called rtl.
> Report: A high-level explanation of each important design module. For any changes to the baseline RTL, document the changes made and justifications. Changes should only be fixing bugs and not adding new features."

### What to Write

**EN**: Three subsections:
1. **2.1 Source and Version**: GitHub URL, commit hash, date
2. **2.2 Module Overview**: One paragraph per important module (frontend, execution unit, memory backbone, clock module, multiplier, watchdog, sync cells, other peripherals). Highlight that:
   - Clock module already gates `cpu_mclk` but NOT peripherals (motivates optimization)
   - Multiplier and watchdog are optimization targets
   - All peripherals are included in synthesis scope (feedback point 2)
3. **2.3 Modifications**: Currently no changes; bug fixes only, no new features per PDF

**CN**: 三个子小节:
1. **2.1 来源和版本**: GitHub 链接、commit hash、日期
2. **2.2 模块概览**: 每个重要模块写一段 (frontend、execution unit、memory backbone、clock module、multiplier、watchdog、同步器、其他外设)。要点:
   - Clock module 已经 gate 了 `cpu_mclk` 但**没有**外设 (引出优化动机)
   - Multiplier 和 watchdog 是优化目标
   - 所有外设都在综合范围内 (反馈点 2)
3. **2.3 修改记录**: 目前无改动; PDF 要求"只能修 bug,不能加 feature"

### Status

✅ All three subsections drafted in previous chat.

---

# Step 3: Write Verification Testbench / 写验证 Testbench

**Status / 状态**: ❌ NOT STARTED

## Server Operations

```bash
cd ~/cs220/midterm-team-5/sim
ls ~/cs220/midterm-team-5/openmsp430_src/core/sim/rtl_sim/  # reference templates
touch tb_openMSP430.v
```

**EN**: Write `tb_openMSP430.v` that:
- Instantiates `openMSP430` top module as DUT
- Generates `mclk` and `lfxt_clk`
- Drives reset sequence
- Loads program memory via `$readmemh`
- Defines termination (e.g., specific PC address or cycle count)
- Implements pass/fail checking

**CN**: 写 `tb_openMSP430.v`:
- 例化 `openMSP430` 顶层作为 DUT
- 产生 `mclk` 和 `lfxt_clk`
- 驱动复位序列
- 用 `$readmemh` 加载程序内存
- 定义结束条件 (特定 PC 地址或周期数)
- 实现通过/失败检查

## Report Section / 对应报告 Section 3.1 + 3.3: Testbench Architecture, Ideal vs Netlist

### Instructor Original Wording

PDF page 1, "Verification":
> "Code: All verification and simulation files should be in a folder called sim. There should be the main Verilog testbench that instantiates the top DUT module. It should also generate all the required stimulus signals. If external test vectors are used to supply the stimulus, you need to include the test vector generators."
>
> "Report: You will include a high-level description of the functionality of your testbench. If your netlist testbench is different, please describe how it is different from the ideal testbench."

### What to Write

**EN**:
1. Testbench architecture: DUT instantiation, clock generation, reset, stimulus
2. Stimulus method: how programs load
3. Termination conditions
4. Pass/fail checking mechanism
5. **Ideal vs Netlist TB**: state whether shared or separate. If separate, describe SDF back-annotation differences

**CN**:
1. Testbench 架构: DUT 例化、时钟产生、复位、激励
2. 激励方式: 程序怎么加载
3. 结束条件
4. 通过/失败检查机制
5. **理想 vs 网表 TB**: 说明共用还是分开。如分开,描述 SDF 反标差异

---

# Step 4: Design and Implement 20 Testcases / 设计 20 个测试用例

**Status / 状态**: ❌ NOT STARTED

## Server Operations

```bash
cd ~/cs220/midterm-team-5/sim
mkdir testcases
```

### Required Set / 必需集合

**10 Corner Case Testcases**:

| # | Testcase | Goal |
|---|---|---|
| 1 | Power-on reset | Verify reset state |
| 2 | Warm reset | Verify mid-execution reset |
| 3 | Interrupt response (timer/external) | Verify IRQ handling |
| 4 | LPM0~LPM4 entry/exit | Verify low-power mode FSM |
| 5 | **Multiplier extreme values (0×N, MAX×MAX, signed/unsigned)** | **Activate multiplier** (feedback 3) |
| 6 | **Watchdog timeout and feed sequence** | **Activate watchdog** (feedback 3) |
| 7 | Register boundary access (R0/PC, R1/SP) | Verify special register behavior |
| 8 | Long-distance branch | Verify PC update for far jumps |
| 9 | Memory boundary address access | Verify memory map edges |
| 10 | SDI debug interface | Verify debug protocol |

**10 Random Constrained Testcases**:

| # | Testcase | Goal |
|---|---|---|
| 1 | Random ALU arithmetic | Verify ADD/SUB/CMP randomness |
| 2 | Random ALU logic | Verify AND/OR/XOR/BIT |
| 3 | Random addressing modes | Verify all 7 addressing modes |
| 4 | Random length loops | Stress branch + counter |
| 5 | **Random multiplier consecutive operations** | **Activate multiplier** (feedback 3) |
| 6 | **Random watchdog config sequences** | **Activate watchdog** (feedback 3) |
| 7 | Random interrupt timing | Stress IRQ entry timing |
| 8 | Random branches | Stress conditional execution |
| 9 | Random peripheral read/write | Stress SFR access |
| 10 | **CPU + multi-peripheral concurrent load (mixed ALU + multiplier + watchdog)** | **Realistic workload** (feedback 3, also for PrimeTime SAIF) |

**EN — Bold testcases address feedback point 3**: They actively exercise multiplier and watchdog, ensuring baseline power measurement includes their dynamic activity. Without this, the post-optimization clock gating would show no measurable improvement.

**CN — 加粗测试用例落地反馈点 3**: 它们主动激活 multiplier 和 watchdog,使 baseline 功耗测量包含其动态活动。否则后续 clock gating 优化没法显示可测量的改善。

## Report Section / 对应报告 Section 3.2: Testcase Summary Table

### Instructor Original Wording

PDF page 1, "Verification":
> "You will need to write both random-constrained testcases and corner case testcases to verify your DUT. You should target to write 10 testcases for each type. These testcases should mainly check for the correctness of your design's functionalities. All testcases should be non-trivial and must pass (for both ideal and netlist simulations)."
>
> "For each testcase you develop, include a brief summary of the verification goal and expected result. You may use a table to summarize these testcases."

### What to Write

**EN**:
1. **20-row summary table**: ID / Type (corner/random) / Goal / Expected Result / Pass-Fail (ideal) / Pass-Fail (netlist)
2. **Special paragraph (feedback point 3)**: explicitly state which testcases activate multiplier and watchdog, and explain that this enables meaningful power comparison after clock gating optimization

**CN**:
1. **20 行汇总表**: 编号 / 类型 / 目标 / 预期结果 / 通过状态 (理想) / 通过状态 (网表)
2. **专门段落 (反馈点 3)**: 明确指出哪些测试用例激活 multiplier 和 watchdog,说明这样后续 clock gating 优化的功耗对比才有意义

---

# Step 5: Software Golden Model / 软件参考模型

**Status / 状态**: ❌ NOT STARTED

## ⚠️ Important Note / 重要提示

**EN**: The PDF says "If your design requires a software golden model" — but the grading rubric explicitly groups "Baseline RTL and software golden model" as one 1-point item. **Do NOT leave `sw/` empty or just put a README saying "not used"** — this risks the entire 1-point item being marked incomplete.

For openMSP430 (a CPU), a golden model IS reasonable: use `msp430-gcc` to compile reference programs, capture expected register/memory states, compare against RTL simulation output.

**CN**: PDF 写的是"如果你的设计需要"软件 golden model,但评分细则明确把"基线 RTL + 软件 golden model"作为同一个 1 分项。**不要把 `sw/` 留空或只放一个 README 说"没用到"** — 这样会让整个 1 分项被判不完整。

对于 openMSP430 (CPU 设计),做一个 golden model 是合理的: 用 `msp430-gcc` 编译参考程序,记录期望的寄存器/内存状态,跟 RTL 仿真输出对比。

## Server Operations

```bash
cd ~/cs220/midterm-team-5/sw
which msp430-gcc  # confirm tool exists on bender
mkdir reference_programs golden_outputs
touch golden_check.py  # comparison script
```

**EN — Recommended approach**:
1. Use `msp430-gcc` to compile each testcase source (`.s43` or `.c`) into a `.elf`
2. Use `msp430-objdump` or a small simulator to extract expected register/memory state at end of execution
3. Write a Python script that compares RTL simulation output (memory dump or register log) against this reference
4. Pass/fail = match rate

**CN — 推荐方案**:
1. 用 `msp430-gcc` 把每个测试用例源码 (`.s43` 或 `.c`) 编译成 `.elf`
2. 用 `msp430-objdump` 或简单模拟器提取执行结束时的期望寄存器/内存状态
3. 写 Python 脚本对比 RTL 仿真输出 (内存 dump 或寄存器 log) 与参考状态
4. 通过/失败 = 匹配率

## Report Section / 对应报告 Section 4: Software Golden Model

### Instructor Original Wording

PDF page 1, "Software Golden Model":
> "Code: If you design requires a software golden model to verify its correctness and performance (AI accuracy, image fidelity etc.), these models (Python, C++ etc.) should be in a folder called sw."
>
> "Report: A high-level description of how your software golden model reflects the hardware implementation. Specify what metric(s) you choose to evaluate the software performance of your DUT."

### What to Write

**EN**:
1. Implementation approach (msp430-gcc + Python comparison script)
2. How model maps to hardware: register file (R0~R15), memory map, ALU operation semantics
3. Metric chosen: functional correctness rate (target 100% match across all 20 testcases)
4. Invocation: how to run golden check for one testcase

**CN**:
1. 实现方式 (msp430-gcc + Python 对比脚本)
2. 模型怎么对应硬件: 寄存器堆 (R0~R15)、内存映射、ALU 操作语义
3. metric 选择: 功能正确率 (目标 20 个测试全部 100% 匹配)
4. 调用方式: 怎么对一个 testcase 跑 golden check

---

# Step 6: Run Ideal RTL Simulation / 跑理想 RTL 仿真

**Status / 状态**: ❌ NOT STARTED

## ⚠️ Note: Both Ideal and Netlist Sim Required / 注意: 理想和网表仿真都必须做

**EN**: PDF page 1 says testcases "must pass (for both ideal and netlist simulations)". This is mandatory, not optional. You can share one testbench OR use separate testbenches; the testcases themselves can be the same. Step 6 is the ideal sim run; Step 8 is the netlist sim run.

**CN**: PDF 第 1 页明确测试用例"必须通过 (理想仿真和网表仿真都要)"。这是强制要求,不是可选。可以共用 testbench 或分开两个; 测试用例可以一样。Step 6 是理想仿真,Step 8 是网表仿真。

## Server Operations

```bash
cd ~/cs220/midterm-team-5/sim

# Option 1: VCS (commercial)
vcs -full64 -sverilog ../rtl/*.v ../rtl/periph/*.v tb_openMSP430.v -o simv
./simv

# Option 2: Icarus Verilog (open source)
iverilog -o simv ../rtl/*.v ../rtl/periph/*.v tb_openMSP430.v
vvp simv
```

Run all 20 testcases. All must pass.

跑所有 20 个测试用例。必须全部通过。

## Report Section

No new section. **Update Step 4's testcase summary table** with "Pass" in the ideal-sim column.

无新章节。**回填 Step 4 测试用例汇总表**的"理想仿真通过"列。

---

# Step 7: Synthesis (Design Compiler) / 综合

**Status / 状态**: ❌ NOT STARTED

## Server Operations

```bash
cd ~/cs220/midterm-team-5/syn
mkdir reports
touch run_syn.tcl
```

### Synthesis Script Skeleton / 综合脚本框架

```tcl
# Library setup — PDF mandates worst-case corner ss0p75v125c
set link_library "* saed32rvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32hvt_ss0p75v125c.db"
set target_library "saed32rvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32hvt_ss0p75v125c.db"

# Read RTL — KEY: include periph (instructor feedback point 2)
analyze -format verilog [glob ../rtl/*.v]
analyze -format verilog [glob ../rtl/periph/*.v]
elaborate openMSP430

current_design openMSP430

# Clock constraint — iterate to find max frequency
create_clock -period 5.0 -name mclk [get_ports mclk]

# Synthesize
compile_ultra

# Reports
report_timing > reports/timing.rpt
report_area   > reports/area.rpt
report_power  > reports/power.rpt

# Outputs for downstream PrimeTime
write -format verilog -hierarchy -output netlist.v
write_sdc constraints.sdc
write_sdf netlist.sdf
```

```bash
dc_shell -f run_syn.tcl | tee syn.log
```

**EN — Maximum frequency search**: Iterate `-period`. If timing slack is negative, increase period (lower frequency). If slack is large positive, decrease period (higher frequency). Find period where slack is near zero but non-negative. That period gives max frequency.

**CN — 最大频率搜索**: 迭代 `-period`。如果 slack 为负,增大周期 (降频)。如果 slack 大正,减小周期 (升频)。找到 slack 接近 0 但非负的周期,该周期对应最大频率。

## Report Section / 对应报告 Section 5: Synthesis

### Instructor Original Wording

PDF page 2, "Synthesis":
> "The design must be synthesized with worst-case corners:
> - saed32rvt_ss0p75v125c.db
> - saed32lvt_ss0p75v125c.db
> - saed32hvt_ss0p75v125c.db
> Note, you may mix and match LVT, RVT, and HVT cells to your design.
>
> The priority is to close timing (no negative slacks) with the maximum frequency. Then with this frequency, derive the area and power (with PrimeTime)."
>
> "Report: Describe the main functionality of your synthesis script, any special synthesis methodology (top-down, incremental etc.), and how you determined the maximum frequency for your design. Summarize the final frequency (in MHz) and area (in um2 or mm2) of your baseline design. For this frequency, report the timing slack in the critical path(s)."

### What to Write

**EN**:
1. Script functionality (library / read / constraints / compile / report / output)
2. **Synthesis scope statement (feedback point 2)**: explicitly state ALL peripherals included
3. Methodology (top-down vs incremental — for our size, top-down is sufficient)
4. Max frequency search iteration log: starting period, slack observed, adjustment, final period
5. Final results table:
   - Max Frequency (MHz)
   - Total Area (um² or mm²)
   - Critical Path Slack
   - Critical Path Location (which module)

**CN**:
1. 脚本功能 (库/读取/约束/综合/报告/输出)
2. **综合范围声明 (反馈点 2)**: 明确所有外设包含在内
3. 方法论 (top-down vs incremental,对我们这个规模 top-down 足够)
4. 最大频率搜索迭代日志: 起始周期、观察 slack、调整、最终周期
5. 最终结果表:
   - 最大频率 (MHz)
   - 总面积 (um² 或 mm²)
   - 关键路径 slack
   - 关键路径位置 (哪个模块)

---

# Step 8: Run Netlist Simulation, Generate SAIF / 跑网表仿真生成 SAIF

**Status / 状态**: ❌ NOT STARTED

## ⚠️ Two Purposes / 两个目的

**EN**: This step serves two requirements:
1. **PDF Verification requirement**: testcases must pass in netlist sim (gate-level)
2. **PrimeTime input**: SAIF file with toggle activity, MUST cover multiplier and watchdog (feedback point 3)

**CN**: 这一步同时满足两个要求:
1. **PDF 验证要求**: 测试用例必须在网表仿真 (门级) 通过
2. **PrimeTime 输入**: SAIF 文件 (信号翻转活动),必须覆盖 multiplier 和 watchdog (反馈点 3)

## Server Operations

```bash
cd ~/cs220/midterm-team-5/sim

# Modify testbench to add SAIF dump:
# initial begin
#   $set_gate_level_monitoring("on");
#   $set_toggle_region(tb.dut);
#   #1000 $toggle_start;
#   ... run testcase ...
#   $toggle_stop;
#   $toggle_report("activity.saif", 1.0e-9, "tb.dut");
# end

vcs -full64 -sverilog ../syn/netlist.v tb_openMSP430.v \
    -v $SAED32_PATH/verilog/saed32nm.v \
    +neg_tchk -negdelay \
    -o simv_netlist
./simv_netlist
```

**EN — Critical**: For the SAIF that PrimeTime will use, run testcase #10 from random set (CPU + multi-peripheral concurrent load) — this is the realistic workload that activates multiplier AND watchdog AND ALU together. This is what feedback point 3 demands.

**CN — 关键**: PrimeTime 用的 SAIF 要跑随机集第 10 个测试用例 (CPU 加多外设并发负载) — 这是同时激活 multiplier 和 watchdog 和 ALU 的真实工作负载。这正是反馈点 3 要的。

## Report Section

This step's report content folds into Section 6.2 (PrimeTime Test Vector Generation). Also update Step 4 table with "Pass" in netlist-sim column.

这一步内容并入 Section 6.2 (PrimeTime 测试向量生成)。同时回填 Step 4 表格"网表仿真通过"列。

---

# Step 9: PrimeTime Power Analysis / PrimeTime 功耗分析

**Status / 状态**: ❌ NOT STARTED

## Server Operations

```bash
cd ~/cs220/midterm-team-5/ptpx
mkdir reports
touch run_pt.tcl
```

### PrimeTime Script Skeleton

```tcl
set link_path "* saed32rvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32hvt_ss0p75v125c.db"
read_verilog ../syn/netlist.v
link_design openMSP430
read_sdc ../syn/constraints.sdc
read_saif ../sim/activity.saif -strip_path tb.dut
update_power
report_power > reports/power.rpt
report_power -hierarchy > reports/power_hier.rpt
```

```bash
pt_shell -f run_pt.tcl | tee pt.log
```

## Report Section / 对应报告 Section 6: PrimeTime Power Analysis

### Instructor Original Wording

PDF page 2, "PrimeTime":
> "Code: Your main PrimeTime script to measure the DUT netlist's power consumption and any generated reports should be in a folder called ptpx. The power should be measured by test vectors representative of real workloads for your DUT. The power should also be measured across an extended period of time (cycles) to reflect the average power consumption. You may optionally evaluate the peak power by reasonably stressing all of the DUT's inputs."
>
> "Report: Describe the main functionality of your ptpx script, any special power measurement methodology, and how you generated the input test vectors for your power measurement. Summarize the average (and optionally peak) power consumption (in mW or W) of your baseline design."

### What to Write

**EN**:
1. **6.1 Script functionality**: library, netlist, SDC, SAIF, update_power, report_power
2. **6.2 Test vector generation**: 
   - Which testcase generated the SAIF (testcase #10 mixed workload)
   - **What activities it exercises (must mention ALU + multiplier + watchdog) — feedback point 3**
   - How many cycles captured (must be "extended" per PDF)
3. **6.3 Average power result** (mW)
4. **6.4 Hierarchical power breakdown**: per-module power. **Highlight multiplier and watchdog contribution** — this empirically justifies why they are optimization targets
5. Optional: peak power

**CN**:
1. **6.1 脚本功能**: 库、网表、SDC、SAIF、update_power、report_power
2. **6.2 测试向量生成**:
   - 哪个测试用例生成了 SAIF (第 10 个混合负载)
   - **激活了什么活动 (必须提到 ALU + 乘法 + watchdog) — 反馈点 3**
   - 抓了多少周期 (PDF 要求"extended")
3. **6.3 平均功耗结果** (mW)
4. **6.4 分模块功耗分解**: 各模块功耗。**突出 multiplier 和 watchdog 占比** — 实证证明它们是优化目标的合理性
5. 可选: 峰值功耗

---

# Step 10: Validation Section / 结果验证

**Status / 状态**: ❌ NOT STARTED

## No Server Operations / 无服务器操作

## Report Section / 对应报告 Section 7: Validation

### Instructor Original Wording

PDF page 2, "Midterm Report" point 2:
> "Validation of your reported PPA values and software metrics. You may validate against official documentations of these designs, and/or related designs in the literature."

### What to Write

**EN**:
1. Comparison table: your frequency / area / power vs reference sources
2. Reference sources to cite:
   - OpenCores openMSP430 official ASIC synthesis data (project page)
   - TI MSP430 datasheet for similar chip power numbers
   - Published literature on MSP430-class designs
3. **Traceability**: each number in your table should have a footnote pointing to the log/report file path that produced it (e.g., "from `syn/reports/timing.rpt` line 42")
4. Justification: explain why your numbers are reasonable, or any deviations

**CN**:
1. 对比表: 你们的频率/面积/功耗 vs 参考来源
2. 引用的参考:
   - OpenCores openMSP430 项目页官方 ASIC 综合数据
   - TI MSP430 datasheet 类似芯片功耗
   - 文献中 MSP430 类设计的论文
3. **可追溯性**: 表里每个数字都要脚注指向产生它的 log/report 文件路径 (例如"来自 `syn/reports/timing.rpt` 第 42 行")
4. 论证: 解释为什么数字合理,或解释偏差

### Grading

Worth **1 full point** by itself. Do not skip.

单独占 **1 整分**。不能跳过。

---

# Step 11: Optimization Implementation Plan / 优化实施计划

**Status / 状态**: ❌ NOT STARTED

## No Server Operations

## Report Section / 对应报告 Section 8: Optimization Implementation Plan

### Instructor Original Wording

PDF page 2, "Midterm Report" point 3:
> "A detailed plan on implementing your proposed optimizations. Preliminary results are optional."

### What to Write

**EN**:

**8.1 Target Modules and Approach**:
- Hardware multiplier (`omsp_multiplier.v`) and watchdog timer (`omsp_watchdog.v`)
- Extend existing `omsp_clock_gate` instantiation pattern in `omsp_clock_module.v`
- Enable signal sources:
  - Multiplier: SFR write detection (peripheral enable + address range match)
  - Watchdog: WDTHOLD bit state

**8.2 Clock Domain and Synchronizer Analysis (feedback point 1)** — this is the critical subsection:
- List of all clock domains: mclk, smclk, aclk, dco_clk, lfxt_clk
- Diagram or table of which modules each clock drives
- Synchronizer placement table: every `omsp_sync_cell` instantiation, source domain, destination domain
- **Identification of sync paths whose target-side clock must NOT be gated** (otherwise data loss / metastability)
- Conclusion: which clock domains are safe to gate at the multiplier and watchdog level

**8.3 Trade-off Analysis** (from proposal slide 5):
- Area increase: clock-gating cells add gates, but small for two peripherals
- Design complexity: synchronizer review + more complex testing
- Clock skew: gated clock may arrive later, potentially limits maximum frequency

**CN**:

**8.1 目标模块与方案**:
- 硬件乘法器 (`omsp_multiplier.v`) 和看门狗 (`omsp_watchdog.v`)
- 扩展 `omsp_clock_module.v` 中现有 `omsp_clock_gate` 例化模式
- 使能信号来源:
  - 乘法器: SFR 写访问检测 (外设 enable + 地址范围匹配)
  - 看门狗: WDTHOLD 位状态

**8.2 时钟域和同步器分析 (反馈点 1)** — 这是关键子小节:
- 所有时钟域列表: mclk, smclk, aclk, dco_clk, lfxt_clk
- 各时钟驱动哪些模块的图或表
- 同步器位置表: 每个 `omsp_sync_cell` 例化、源时钟域、目标时钟域
- **识别哪些同步路径的目标侧时钟不能被 gate** (否则会数据丢失/亚稳态)
- 结论: 在 multiplier 和 watchdog 这一级,哪些时钟域可以安全 gate

**8.3 权衡分析** (来自 proposal slide 5):
- 面积增加: clock-gating cell 增加门数,但两个外设量不大
- 设计复杂度: 同步器审查 + 测试更复杂
- 时钟偏移: gated clock 可能晚到,可能限制最大频率

---

# Step 12: Optimization Verification Plan / 优化验证计划

**Status / 状态**: ❌ NOT STARTED

## No Server Operations

## Report Section / 对应报告 Section 9: Optimization Verification Plan

### Instructor Original Wording

PDF page 2, "Midterm Report" point 4:
> "A detailed plan on how to verify your proposed optimizations. If you use software models, explain how you plan to modify the software models to reflect your hardware changes."

### What to Write

**EN**:
1. **Functional regression**: same 20 testcases must pass post-optimization (both ideal and netlist sim). Clock gating must not change functional behavior.
2. **Power comparison methodology**: identical SAIF input, identical PrimeTime flow, before vs after. Compare:
   - Average total power
   - Hierarchical breakdown (multiplier and watchdog modules specifically)
   - Per-clock-network power (mclk vs gated multiplier/watchdog clocks)
3. **Statement addressing feedback point 3**: cite Section 3.2 testcases that activate multiplier and watchdog. Without this baseline activity, post-optimization comparison would show no improvement.
4. **Software golden model modification**: NONE required. Clock gating is purely hardware-level and behaviorally equivalent. Golden model output is unchanged.

**CN**:
1. **功能回归**: 同样 20 个测试用例优化后必须全过 (理想和网表仿真都要)。Clock gating 不应改变功能行为。
2. **功耗对比方法**: 相同 SAIF、相同 PrimeTime 流程、优化前 vs 优化后。对比:
   - 平均总功耗
   - 分模块分解 (尤其 multiplier 和 watchdog)
   - 各时钟网络功耗 (mclk vs gated multiplier/watchdog 时钟)
3. **落地反馈点 3 声明**: 引用 Section 3.2 中激活 multiplier 和 watchdog 的测试用例。如果 baseline 没活动,优化后对比就看不出改善。
4. **软件 golden model 修改**: 无需修改。Clock gating 纯硬件层、行为等价、golden model 输出不变。

### Grading

Step 11 + Step 12 together worth **1 full point** ("Design and verification plan for proposed optimizations").

Step 11 + Step 12 共占 **1 整分** ("优化的设计与验证计划")。

---

# Step 13: README / 复现说明

**Status / 状态**: ❌ NOT STARTED

## Server Operations

```bash
cd ~/cs220/midterm-team-5
touch README.md
```

## Report Section / 对应报告 Section 10: README

### Instructor Original Wording

PDF page 2, "Midterm Report" point 5:
> "A README section on how to execute your RTL simulation, hardware verification, synthesis, PrimeTime, and software verification to recreate reported results. The README should also explain any new packages, libraries, and/or virtual environment you introduced to accomplish the simulation, verification, and synthesis of your baseline."

### What to Write

**EN**:
1. **Environment dependencies**: tool versions (VCS, DC, PrimeTime), library paths (SAED32), msp430-gcc version, any Python packages
2. **Directory structure** of the submission
3. **Step-by-step reproduction commands**:
   - RTL simulation: `cd sim && make sim` or explicit vcs/iverilog commands
   - Synthesis: `cd syn && dc_shell -f run_syn.tcl`
   - Netlist sim: `cd sim && make netlist_sim`
   - PrimeTime: `cd ptpx && pt_shell -f run_pt.tcl`
   - Software verification: `cd sw && python golden_check.py`
4. **Troubleshooting**: common issues and fixes (e.g., library path not set)

**CN**:
1. **环境依赖**: 工具版本 (VCS、DC、PrimeTime)、库路径 (SAED32)、msp430-gcc 版本、Python 包
2. **提交件目录结构**
3. **逐步复现命令**:
   - RTL 仿真: `cd sim && make sim` 或显式 vcs/iverilog 命令
   - 综合: `cd syn && dc_shell -f run_syn.tcl`
   - 网表仿真: `cd sim && make netlist_sim`
   - PrimeTime: `cd ptpx && pt_shell -f run_pt.tcl`
   - 软件验证: `cd sw && python golden_check.py`
4. **故障排除**: 常见问题与修复 (例如库路径未设置)

### Grading

Worth **1 full point** by itself. Easy to do, do not skip.

单独占 **1 整分**。容易拿分,不能漏。

---

# Step 14: Midterm Presentation / 期中演示

**Status / 状态**: ❌ NOT STARTED

## What to Build / 要做什么

**EN**: ~8-10 slides. **Worth 2 points — the largest single grading item.** Coverage:
1. Project intro and baseline (1 slide): openMSP430 overview
2. RTL module overview + clock domain map (1 slide)
3. Verification methodology + testcase table highlights (1-2 slides)
4. Synthesis results: max freq, area, critical path (1 slide)
5. PrimeTime results: average power, hierarchical breakdown — emphasize multiplier/watchdog contribution (1 slide)
6. Validation comparison table (1 slide)
7. **Optimization plan with explicit responses to instructor feedback** (1-2 slides):
   - "Synchronizer analysis: we identified X paths that must keep ungated clock" (feedback 1)
   - "Synthesis covers all peripherals" (feedback 2)
   - "Testcases #5, #6, #10 activate multiplier and watchdog" (feedback 3)
8. Verification plan (1 slide)

**CN**: 约 8-10 页。**占 2 分,是单项最大分值。** 覆盖如上。**第 7 页务必明确回应老师 3 点反馈**,这是给老师看到"你们听进去了"的关键。

---

# Step 15: Final Packaging and Submission / 最终打包提交

**Status / 状态**: ❌ NOT STARTED

## Server Operations

```bash
cd ~/cs220
# Remove backup folder before zipping
rm -rf midterm-team-5/openmsp430_src
# Verify final structure
ls midterm-team-5/
# Should see: README.md rtl/ sim/ sw/ syn/ ptpx/

# Zip
zip -r midterm-team-5.zip midterm-team-5/
```

### Final Submission Checklist

| Item | Format | Required |
|---|---|---|
| `midterm-team-5.zip` | ZIP archive | ✅ |
| `Midterm_Report.pdf` | PDF | ✅ |
| `Midterm_Presentation.pdf` or `.pptx` | PDF or PPTX | ✅ |

### Final Zip Structure

```
midterm-team-5/
├── README.md
├── rtl/         (Verilog source files including periph/)
├── sim/         (testbench + 20 testcases + sim outputs + activity.saif)
├── sw/          (msp430-gcc reference programs + golden_check.py)
├── syn/         (run_syn.tcl + reports/ + netlist.v + constraints.sdc + netlist.sdf)
└── ptpx/        (run_pt.tcl + reports/)
```

### Instructor Original Wording

PDF page 3, "Submission Instruction":
> "1) For the code deliverables, place all the required folders (rtl, sim etc.) into a top-level folder called midterm-team-N, where N is your team number. Then place this midterm-team-N folder into a zip file. Make sure that any paths or directory variables are pointing to the correct locations within this midterm-team-N folder.
> 2) Midterm report.
> 3) Midterm presentation."

---

# Master Progress Tracker / 总进度追踪表

| Step | Description | Code | Report | Status | Points Risk |
|---|---|---|---|---|---|
| 1 | Project setup | ✅ | N/A | ✅ DONE | — |
| 2 | Clone baseline | ✅ | ✅ | ✅ DONE | — |
| 3 | Testbench | ❌ | ❌ | NOT STARTED | Code item 2 (1 pt) |
| 4 | 20 testcases | ❌ | ❌ | NOT STARTED | Code item 2 (1 pt) |
| 5 | Software golden model | ❌ | ❌ | NOT STARTED | Code item 1 (1 pt, paired with RTL) |
| 6 | Ideal RTL simulation | ❌ | (update Step 4 table) | NOT STARTED | Code item 2 (1 pt) |
| 7 | Synthesis | ❌ | ❌ | NOT STARTED | Code item 3 (1 pt) |
| 8 | Netlist sim + SAIF | ❌ | (folds into Step 9) | NOT STARTED | Code item 2 + 4 |
| 9 | PrimeTime | ❌ | ❌ | NOT STARTED | Code item 4 (1 pt) |
| 10 | Validation | N/A | ❌ | NOT STARTED | Report item 2 (1 pt) |
| 11 | Optimization plan | N/A | ❌ | NOT STARTED | Report item 3 (1 pt, paired with Step 12) |
| 12 | Verification plan | N/A | ❌ | NOT STARTED | Report item 3 (1 pt) |
| 13 | README | ❌ | ❌ | NOT STARTED | Report item 4 (1 pt) |
| 14 | Presentation | N/A | ❌ | NOT STARTED | Presentation (2 pt) |
| 15 | Submission | ❌ | ❌ | NOT STARTED | All |

---

# Suggested Execution Timeline / 建议执行时间线

**EN**:
- **Day 1**: Freeze `rtl/` + commit hash; finalize Section 2 (Baseline RTL) report; ensure `sw/` has at minimum a working golden_check.py skeleton
- **Day 2-4**: Build `sim/`: main TB + 20 testcases all green in ideal sim; testcase table written into report
- **Day 5-7**: `syn/`: three-corner library setup, frequency sweep, close timing; Section 5 (Synthesis) report numbers complete
- **Day 8-10**: `ptpx/`: SAIF generation from netlist sim (using testcase #10 mixed workload to hit peripherals); Section 6 (PrimeTime) report numbers complete
- **Day 11**: Sections 7 (Validation), 8 (Optimization Plan), 9 (Verification Plan), 10 (README); verify zip structure
- **Day 12**: Presentation rehearsal; checklist against grading rubric

**CN**:
- **第 1 天**: 冻结 `rtl/` + commit hash; 写完 Section 2 (Baseline RTL); `sw/` 至少有可跑的 golden_check.py 骨架
- **第 2-4 天**: 搭 `sim/`: 主 TB + 20 测试用例理想仿真全绿; 测试用例表写进报告
- **第 5-7 天**: `syn/`: 三 corner 库设置、扫频、闭 timing; Section 5 (Synthesis) 数字齐
- **第 8-10 天**: `ptpx/`: 用网表仿真 (跑测试用例 #10 混合负载打到外设) 生成 SAIF; Section 6 (PrimeTime) 数字齐
- **第 11 天**: Sections 7 (Validation)、8 (优化计划)、9 (验证计划)、10 (README); 检查 zip 结构
- **第 12 天**: 演示排练; 对照评分表逐项打钩

---

# Suggested Team Division of Labor / 建议团队分工

**EN**:
- **Andrew / Kenneth** (with RTL background): Steps 7 (Synthesis), 8 (Netlist sim), 9 (PrimeTime). Highest tool complexity, depends on EDA expertise.
- **Xingran**: Steps 2-Report (done), 3 (TB description), 4 (Testcase table), 5 (Software model investigation and Python script), 10 (Validation comparison), 11-12 (Optimization plan writing), 13 (README), 14 (Presentation). Heavy on reading and writing.
- **Joint review**: All members review Section 8.2 (synchronizer analysis) and feedback responses in presentation.

**CN**:
- **Andrew / Kenneth** (有 RTL 基础): 步骤 7 (综合)、8 (网表仿真)、9 (PrimeTime)。工具复杂度最高,依赖 EDA 经验。
- **Xingran**: 步骤 2 报告 (已完成)、3 (TB 描述)、4 (测试用例表)、5 (软件模型调研和 Python 脚本)、10 (Validation 对比)、11-12 (优化计划写作)、13 (README)、14 (Presentation)。偏读写。
- **联合审阅**: 所有成员审阅 Section 8.2 (同步器分析) 和演示中对反馈的回应。

---

*End of Handbook v2. Update this document as you complete steps.*
*手册 v2 结束。完成一步更新一次。*
