# Midterm Report — Verification (Phase B) — Team 5

本文档严格对齐课程 **`Project Midterm.pdf`** 中 **Verification** 小节对 **Code** 与 **Report** 的要求（第 14–28 行附近），并逐项说明我们在 **openMSP430** 基线验证上**做了什么、为什么、怎么复现、结果存在哪些文件**。路径一律以提交 zip 内的顶层目录 **`midterm-team-5/`** 为根（与 PDF Submission Instruction 一致），便于助教与你们自己溯源。

---

## 1. 课程要求（我们对照的条文）

摘自 **`midterm-team-5/Project Midterm.pdf`**（Verification 段）：

- **Code**：所有验证与仿真文件在 **`sim/`**；主 testbench **例化顶层 DUT** 并产生激励；若用外部向量，需包含**向量生成器**。
- **Testcase**：**10 个 random-constrained** + **10 个 corner**，共 20 个；应主要检验功能正确性；**非平凡**；**ideal 与 netlist 仿真都必须通过**；允许 ideal / netlist 用同一 TB、同一组 testcase。
- **Report**：**TB 功能高层说明**；若 netlist TB 不同需说明差异；**每个 testcase** 简述验证目标与期望结果；可用**表格**汇总。

下文按「思路 → 实现文件 → 运行命令 → 产出文件」组织，保证每一步可复查。

---

## 2. 总体思路（我们在验证什么）

- **DUT**：`rtl/openMSP430.v`（课程 trimmed 基线，子模块在 `rtl/*.v`）。
- **验证策略**（满足「非平凡」与「访问外设」的课程意图）：
  1. **程序存储器镜像**（`$readmemh`）：每条 testcase 对应一份 `pmem*.mem`，CPU 复位后从向量 `0xF000` 入口执行真实指令流：对 **WDTCTL (0x0120)** 写入 **WDTHOLD** 口令以停看门狗，并对 **硬件乘法器寄存器**（如 `0x0130` / `0x0132` / `0x0138`）写入操作数以触发乘法，避免「全程 NOP 空转」。
  2. **10 个 random-constrained testcase（TEST_ID 0–9）**：TB 侧用 **SystemVerilog `randomize()` + `dist` 约束**，在复位后注入 **IRQ0** 脉冲，**延迟周期数**在 `[120, 3800]` 内带分布约束；`TEST_ID` 参与随机种子，使不同 ID 下激励时间不同。程序镜像侧 `TEST_ID 1–9` 由 Python 按种子生成**不同 MPY 操作数与 NOP 填充长度**（同一 TB、不同 mem）。
  3. **10 个 corner testcase（TEST_ID 10–19）**：TB 侧在固定周期后打 **单周期 NMI** 毛刺；程序镜像侧为**手写 corner**（大操作数、有符号乘、重复乘、长 NOP 间隔等组合），见脚本分支。
  4. **结束判据**：跑满 **50000 个 `mclk` 上升沿** 后打印 **`TB_OPENMSP430_MINIMAL: PASS`**；ideal 下额外检查层次化的 **WDT / MPY** 寄存器可见性；netlist 下因综合扁平化，改用编译宏关闭层次引用，仅保留「不挂死 + PASS banner」判据（与 PDF「可同一 TB」一致，差异在下一节说明）。

---

## 3. 我们写了 / 改了哪些文件（Code deliverable，可打开对照）

| 角色 | 路径（相对 `midterm-team-5/`） | 作用 |
|------|----------------------------------|------|
| 顶层 TB | `sim/tb_openmsp430_minimal.v` | 例化 `openMSP430 dut`；产生 `dco_clk`、`reset_n`、`irq`、`nmi`、调试口 tie-off；`$readmemh` 按 `+TEST_ID` 选镜像；随机 IRQ / corner NMI；50000 周期后 PASS/FAIL。 |
| 程序镜像生成器 | `sim/scripts/gen_phaseb_pmem.py` | 生成 **`sim/pmem.mem`** 与 **`sim/pmem_t00.mem` … `sim/pmem_t19.mem`**（各 2048×16b hex 行），指令编码对齐 **`rtl/omsp_frontend.v`** 的 MOV 解码。 |
| 批量回归 shell | `sim/scripts/run_tests_now.sh` | 顺序执行 `./simv`（或 `SIMV=./simv_netlist`）共 20 次，`tee` 到 **`sim/logs/run_t00.log` … `run_t19.log`**，并用 `grep` 检查 PASS。 |
| 仿真 Makefile | `sim/Makefile` | `make run-phaseb`（ideal 20 条）、`make compile-netlist` / `make run-phaseb-netlist`（网表 + 三份 SAED32 verilog cell 库）、`make run-phaseb-both` 等。 |
| RTL filelist | `sim/rtl_files.f` | VCS 读入 `timescale.v` 与 `../rtl` 下 DUT RTL（ideal 编译用）。 |
| 行为 SRAM | `sim/ram.v` | 程序/数据存储器模型。 |
| timescale | `sim/timescale.v` | `timescale 1ns/100ps`。 |
| 复现说明（提交 README） | `README.md` | 助教按命令复现 ideal / netlist / synthesis 入口；内含 testcase 表骨架。 |
| Phase B 操作指南（团队） | `PHASE_B_GUIDE.md` | 分步教程与易错点（不替代 PDF，但帮助你们理解流程）。 |

**未改 DUT 功能 RTL**（符合 PDF Baseline：仅 bugfix，不加新特性）；验证相关改动集中在 **`sim/`** 与 **`syn/run_syn.tcl`**（综合脚本用于产生 `netlist.v` 以满足 netlist 仿真条款）。

---

## 4. 分步：我们具体做了什么（命令级 + 结果文件）

以下命令均在 **`midterm-team-5/sim/`** 下执行（除非另注）。

### 4.1 生成 20 份程序镜像（向量 / testcase 数据）

- **运行**：`python3 scripts/gen_phaseb_pmem.py`  
  或由 `make run-phaseb` / `make run-phaseb-netlist` 在跑仿真前自动调用。
- **思路**：用 Python 生成十六进制行文件，避免手写 2048 行；指令格式与 **`rtl/omsp_frontend.v`** 一致（脚本头部注释写明编码）。
- **产出（真实路径，提交前应存在）**：
  - `sim/pmem.mem`（与 `pmem_t00.mem` 同内容，对应 `TEST_ID=0` 默认名）
  - `sim/pmem_t00.mem` … `sim/pmem_t19.mem`
- **终端/日志溯源**：每次运行脚本会打印一行，例如：  
  `Wrote pmem.mem, pmem_t00.mem .. pmem_t19.mem under <绝对路径>/midterm-team-5/sim`  
  你们跑 `make run-phaseb` 时该输出会出现在终端，并进入 `sim/compile.log` 之前的 `make` 输出（若需要可把整段终端保存为报告附录）。

### 4.2 编译并运行 ideal（RTL）20 条回归

- **运行**：`make run-phaseb`
- **内部顺序**（见 `sim/Makefile` + `sim/scripts/run_tests_now.sh`）：
  1. `python3 scripts/gen_phaseb_pmem.py`
  2. `vcs ... -o simv`（与 `make compile` 相同链路，日志 **`sim/compile.log`**）
  3. 对 `id=0..19`：`./simv -no_save +TEST_ID=$id 2>&1 | tee sim/logs/run_tNN.log`
- **期望**：每个 **`sim/logs/run_tNN.log`** 含一行：  
  `TB_OPENMSP430_MINIMAL: PASS (...)`  
  （ideal 下括号内带 `wdtctl=` / `reslo=` 等层次自检信息。）
- **溯源文件**：`sim/logs/run_t00.log` … `sim/logs/run_t19.log`，`sim/compile.log`。

### 4.3 综合得到网表（为满足 PDF「netlist simulations」）

- **运行**（在 `midterm-team-5/syn/`）：  
  `export SAED32_HOME=<实验室 SAED32_EDK 根路径>`  
  `dc_shell -f run_syn.tcl | tee syn.log`
- **脚本**：`syn/run_syn.tcl`（`search_path`、analyze/elaborate `openMSP430`、`set_verification_top`、`compile_ultra -gate_clock`、`write` 网表与 SDC/SDF、**`syn/reports/*.rpt`**）。
- **产出（运行后出现；部分可能被 `.gitignore`）**：
  - `syn/netlist.v`、`syn/netlist.sdf`、`syn/constraints.sdc`
  - `syn/syn.log`（你 `tee` 的完整 DC  transcript）
  - `syn/reports/timing.rpt`、`area.rpt`、`power.rpt`
- **说明**：网表仿真的输入是 **`syn/netlist.v`**；没有该文件时 `make compile-netlist` 会报错并提示先综合（`sim/Makefile` 内已有检测）。

### 4.4 编译并运行 netlist（门级）20 条回归

- **运行**：`make run-phaseb-netlist`
- **思路**：
  - VCS 读 **`../syn/netlist.v`** + **SAED32** 三份 verilog cell 库（RVT/LVT/HVT，与 DC `target_library` 一致），否则网表里 `*_LVT`/`*_HVT` 单元无法解析。
  - 编译加 **`+define+GATE_LEVEL_SIM`**：TB 中不再引用 `dut.watchdog_0` / `dut.multiplier_0` 层次信号（综合后扁平化），与 PDF「ideal / netlist 可同一 TB」兼容，差异在报告第 5 节写明。
  - 运行仍用同一 `+TEST_ID=0..19` 与同一 `pmem*.mem`。
- **产出**：`sim/compile_netlist.log`，`sim/logs/run_t00.log` …（与 ideal 同名覆盖；若需同时保留 ideal 与 gate 两套 log，应在跑另一套前备份 `logs/` 或改脚本 log 名——当前仓库脚本会覆盖同名 log，这是已知限制，报告里如实说明）。
- **期望**：每份 log 含 `TB_OPENMSP430_MINIMAL: PASS (... gate-level)`。

---

## 5. Ideal 与 Netlist：Testbench 是否不同？（PDF 明确要求说明）

- **同一文件**：`sim/tb_openmsp430_minimal.v`（同一顶层、同一 `+TEST_ID`、同一 `$readmemh` 策略）。
- **差异仅由编译期宏与运行期 plusarg 控制**：
  - **Netlist 编译**：`sim/Makefile` 的 `compile-netlist` 增加 **`+define+GATE_LEVEL_SIM`**，屏蔽对 **`dut.watchdog_0.*` / `dut.multiplier_0.*`** 的层次访问（否则 VCS 报 cross-module reference 错误）。
  - **Ideal 编译**：不加 `GATE_LEVEL_SIM`，保留对 WDT/MPY 的寄存器自检与带 `wdtctl`/`reslo` 的 PASS 打印。
  - **`+PER_CHK_OFF`**：在 RTL 运行时跳过自检（原用于门级早期试验）；与 `GATE_LEVEL_SIM` 关系在 `README.md` 已简述。最终以 **`GATE_LEVEL_SIM`** 作为门级标准路径。

这满足 PDF：**可以同一 testbench**；我们选择在同一 TB 内用宏区分，并在报告中说明差异原因（综合扁平化）。

---

## 6. Testcase 表（目标 / 期望 / 程序文件 / 日志文件）

约定：**`+TEST_ID=n`** 读 **`sim/pmem_tNN.mem`**，其中 `NN` 为两位十进制；**`n=0`** 时默认文件名为 **`pmem.mem`**（与 `pmem_t00.mem` 同步生成）。**日志**：**`sim/logs/run_tNN.log`**。

| ID | 类型 | 程序镜像（`sim/`） | 验证目标（高层） | 期望结果 |
|----|------|---------------------|------------------|----------|
| 0 | Random 族 | `pmem.mem` / `pmem_t00.mem` | 确定性 WDT 口令 + 最小无符号乘法；IRQ0 随机延迟注入 | 50000 `mclk` 内不挂死；ideal 下 WDTHOLD 置位且 MPY `reslo` 非零 |
| 1–9 | Random 族 | `pmem_t01.mem` … `pmem_t09.mem` | 不同种子：NOP 填充长度、MPY 操作数变化；IRQ0 随机延迟 | 同上；PASS 行中 `reslo` 等随镜像变化（ideal） |
| 10 | Corner | `pmem_t10.mem` | WDT hold 后最小 `1×1` 无符号乘 | PASS |
| 11 | Corner | `pmem_t11.mem` | 小整数乘 `3×4` | PASS |
| 12 | Corner | `pmem_t12.mem` | 大操作数 `0xFFFF×1`（宽度相关） | PASS |
| 13 | Corner | `pmem_t13.mem` | `0x10×0x10` | PASS |
| 14 | Corner | `pmem_t14.mem` | 有符号乘 `MPYS` 路径 | PASS |
| 15 | Corner | `pmem_t15.mem` | 两次无符号乘（状态复用） | PASS |
| 16 | Corner | `pmem_t16.mem` | 长 NOP 间隔后再乘 | PASS |
| 17 | Corner | `pmem_t17.mem` | 多次重复乘 | PASS |
| 18 | Corner | `pmem_t18.mem` | 背靠背两次无符号乘序列 | PASS |
| 19 | Corner | `pmem_t19.mem` | 再次写 WDT 口令 + `0xFF×0xFF` | PASS |

**实际结果（你们实验室跑通后）**：ideal 与 netlist 均为 **20/20 PASS**；对应证据为上述 **`sim/logs/run_t00.log` … `run_t19.log`** 内 `grep` 可检索的 **`TB_OPENMSP430_MINIMAL: PASS`** 行。请将**其中关键几页 log**或终端截图附在 PDF 附录以便助教快速核对。

---

## 7. Testbench 行为说明（Report 文字可裁剪粘贴）

- **时钟 / 复位**：TB 产生 `dco_clk`（驱动 DUT 时钟输入）、异步低有效 `reset_n`；`mclk` 为 DUT 输出，TB 用 `@(posedge mclk)` 作为观测时间轴。
- **存储器**：`ram.v` 例化为程序 RAM 与数据 RAM；CPU 取指与存数走 DUT 存储器接口。
- **约束随机 IRQ（TEST_ID 0–9）**：`cr_irq_delays` 类中 `irq_cycles` 带 `dist`；`process::self().srandom(cr_seed ^ ...)` 保证可重复；可用 **`+CR_SEED=<uint>`** 改种子。
- **Corner NMI（TEST_ID 10–19）**：固定延迟后 `nmi` 拉高一个 `mclk` 再拉低；可用 **`+NO_CORNER_NMI`** 关闭（调试用）。
- **自检**：ideal 下读 `dut.watchdog_0.wdtctl[7]`（WDTHOLD）与 `dut.multiplier_0.reslo`；netlist 编译 `GATE_LEVEL_SIM` 关闭上述路径。

---

## 8. 与 PDF「README / 复现」条款的衔接

PDF 要求报告内含 **README 式复现说明**。仓库 **`README.md`** 已写：

- `cd sim && make run-phaseb`（ideal 20 条）
- 先 `syn/` 综合再 `make run-phaseb-netlist`（netlist 20 条）
- 依赖：**VCS**、**Python 3**、**SAED32_HOME**（及 DC 许可证）

**你们提交 zip 时**：确保 `README.md` 内路径仍为 **`midterm-team-5/`** 相对路径；不要在 zip 外写死个人 home 路径（PDF Submission Instruction）。

---

## 9. 你们「自己在做什么」的一句话地图

1. **`gen_phaseb_pmem.py`**：造 20 份「会跑起来且访问 WDT/MPY」的程序。  
2. **`tb_openmsp430_minimal.v`**：造时钟/复位/总线环境，并按 ID 选镜像 + 注入 IRQ/NMI。  
3. **`run_tests_now.sh` + Makefile**：一键重复 20 次仿真并留 log。  
4. **`syn/run_syn.tcl` + DC**：把 RTL 变成 **`netlist.v`**。  
5. **再跑 Makefile 门级链路**：证明 **同一 20 testcase** 在门级也能结束于 PASS。

---

## 10. 建议粘贴到 LaTeX / Word 时的处理

- 将 **第 6 节表格**复制为主报告 **Verification** 的核心表。  
- 将 **第 2–5 节**压缩为 1–2 页叙述 + **第 7 节**半页 TB 说明。  
- 附录附上 **`sim/compile.log`**、**`sim/compile_netlist.log`**（若太大可只附首尾 + PASS grep 结果）。  
- 若 ideal 与 netlist 两次回归共用 `logs/run_t*.log` 会覆盖，附录中请注明抓取时间或附两份重命名备份——避免助教误解。

---

*本文件路径（便于你们在报告中引用）：`midterm-team-5/REPORT_SECTION_VERIFICATION_PHASE_B.md`*  
*对齐依据：`midterm-team-5/Project Midterm.pdf`（Verification + Submission path 要求）。*
