# CS220 Midterm — 分阶段说明（团队自用 · 勿提交）

> **不要**把本文件打进提交 zip。对外 / 助教复现说明以根目录 **`README.md`** 与期中报告为准。

本文档把课程 **Project Midterm.pdf** 的要求拆成「阶段 → 要不要写代码 → 交付物 → 你们当前进度」，并收录 **`sim/` 终端复现步骤**（含新手易错点）。  
路径以仓库 **`midterm-team-5/`** 为根。

**关于子目录里的说明文件：**各目录下是简短的 **`FOLDER_INFO.txt`**（占位 + 一句话用途）；子目录**不**使用 `README.md` 命名，避免与根目录提交版混淆。

---

## 总览：哪些步骤**必须**有代码 / EDA 跑出来的东西？

| 类型 | 是否需要「代码或工具跑通」 |
|------|---------------------------|
| 目录结构、RTL 文件、报告**文字/图/表** | **不需要**仿真/综合即可先完成（但 RTL 本身是「代码」）。 |
| **仿真**（TB + 20 testcase + log） | **必须**：要能编译、运行、产生 pass 证据。 |
| **综合**（脚本 + timing/area 报告） | **必须**：Design Compiler 等跑通。 |
| **PrimeTime**（脚本 + 功耗报告） | **必须**：PTPX 跑通 + 向量。 |
| **A3 时钟域/同步器** | **以读 RTL + 报告为主**；**不要求**改 RTL 或写脚本，**图**放在报告里即可（LaTeX TikZ 或外部导出图均可）。 |

---

## Phase A1 — 交付目录

| 项目 | 内容 |
|------|------|
| **要做什么** | 建立 `rtl/`, `sim/`, `syn/`, `ptpx/`, `sw/`（与 PDF 一致）。 |
| **是否要写 Verilog/脚本** | **不必**；空目录 + 简短说明即可（已各有一份 `FOLDER_INFO.txt`）。 |
| **当前状态** | **已完成**（五目录齐全）。 |

---

## Phase A2 — Baseline RTL + 报告「Baseline RTL」章节

| 项目 | 内容 |
|------|------|
| **要做什么** | `rtl/` 内放完整 baseline；报告写来源、commit、各重要模块高层说明、**仅 bugfix** 的修改记录。 |
| **是否要写代码** | **需要**：RTL 文件必须在 `rtl/`（这是「交付代码」）。**不要求**此时已跑仿真/综合。 |
| **当前状态** | **基本完成**：`rtl/` 已有；报告在 `cs220 paper presentation/mid_proj.tex` 的 §Baseline RTL；commit 与 `openmsp430_src` 的 `HEAD` 已核对一致。 |

---

## Phase A3 — Clock domain & synchronizer analysis

| 项目 | 内容 |
|------|------|
| **要做什么** | 读 `omsp_clock_module.v`、`omsp_sync_cell.v`，`grep` 例化；报告独立小节：**时钟域说明 + 同步器表/图 + gated clock 注意点**。 |
| **是否要写代码** | **不要求**改 RTL 或新增 Python/Shell；**读代码 + 写报告 + 画图** 即可。图可用 TikZ、draw.io、手绘扫描。 |
| **当前状态** | **已完成（报告侧）**：`mid_proj.tex` 中有小节、表格、**TikZ 图（Figure）**及图注（含虚线说明）。若你本地还是旧 PDF，请重新编译。 |

---

## Phase A4 — 老师 proposal 反馈（激励 / 全块综合）

| 项目 | 内容 |
|------|------|
| **要做什么** | （1）综合/功耗要覆盖 **含 multiplier、watchdog 等** 的完整相关 RTL；（2）**仿真/向量**要能 **真正访问** multiplier、watchdog，不能全程 idle 还指望看出省电。 |
| **是否要写代码** | **需要**：体现在 **testbench / testcase / PTPX 向量** 与 **报告 Verification + PrimeTime 描述** 里；不是单独改 RTL 功能。 |
| **当前状态** | **代码/日志已齐**：见 Phase B 小节 **`make run-phaseb`**；报告章节仍须同步。 |

---

## Phase B — Verification（`sim/`）

| 项目 | 内容 |
|------|------|
| **要做什么** | 主 TB 例化 top DUT；**10 random + 10 corner** testcase，非平凡、ideal 全过；可选 netlist 仿真；报告：**TB 说明 + testcase 表（目标+期望）**。 |
| **是否要写代码** | **必须**：SystemVerilog/Verilog TB、`rtl_files.f`（或等价 filelist）、运行脚本、log。 |
| **当前状态** | **仿真代码侧已齐**：`TEST_ID=0..19` + `pmem*.mem`（`scripts/gen_phaseb_pmem.py`），**`make run-phaseb`** 顺序产出 **`logs/run_t00.log`…`run_t19.log`**，均含 **`TB_OPENMSP430_MINIMAL: PASS`**；程序镜像含对 **WDTCTL (0x0120)** 与 **MPY 块 (0x0130/0x0138 等)** 的写。**报告里** §Verification 表 + 波形/总线说明仍要你们自己写进 PDF。 |

### Phase B 留痕（提交 / 报告建议带什么）

| 留痕类型 | 建议保留路径 | 说明 |
|----------|----------------|------|
| 编译日志 | `sim/compile.log` | `vcs ... \| tee compile.log` 生成；报告可写「0 Error」或摘录末行。 |
| 运行日志 | `sim/run.log` | `./simv -no_save \| tee run.log`；需含 **`TB_OPENMSP430_MINIMAL: PASS`** 一行。 |
| 可选 | 终端截图或 PDF 附录 | 非必须，但能快速证明跑过；**不要**依赖 `.fsdb`/波形大文件除非老师明确要求。 |
| 20 case 日志 | `sim/logs/run_t00.log` … `run_t19.log` | **`make run-phaseb`** 自动生成；报告表格按 `TEST_ID` / R0–R9 / C0–C9 引用。 |

**结论：**Code deliverable 里 **TB + 20 镜像 + 一键回归** 已具备；**报告文字** 仍须把 Verification 与 A4 外设访问写清楚（可引用 `README.md` 里的 testcase 表）。

### `sim/` 终端复现（勿在 bash 里输入反引号）

**重要：**`` `timescale ...` `` 只存在于 Verilog 文件 **`sim/timescale.v`**。在终端输入 **反引号 `` ` ``** 会触发 bash「命令替换」，shell 会乱掉；若出现 `>` 续行，按 **`Ctrl+C`** 退出。

```bash
cd sim
```

（若从仓库外进，先 `cd <你的克隆路径>/midterm-team-5/sim`。）

生成 `pmem.mem`（若还没有）：

```bash
python3 << 'PY'
n = 2048
lines = ["4303"] * n
lines[n - 1] = "F000"
open("pmem.mem", "w").write("\n".join(lines) + "\n")
PY
```

编译：

```bash
vcs -full64 -sverilog +incdir+../rtl -f rtl_files.f ram.v tb_openmsp430_minimal.v -o simv 2>&1 | tee compile.log
```

仿真：

```bash
./simv -no_save 2>&1 | tee run.log
```

一键：

```bash
make run
```

**20 条回归（Phase B 交付）：**

```bash
make run-phaseb
```

**成功判据：**`run.log`（或终端）中出现 **`TB_OPENMSP430_MINIMAL: PASS`**；`make run` 末尾有 **`>>> OK: PASS found in run.log`**。全量 20 条以 **`logs/run_t00.log`…`run_t19.log`** 均含 PASS 为准。

| 文件 | 作用 |
|------|------|
| `timescale.v` | 仿真时间单位 |
| `rtl_files.f` | RTL file list（勿重复编 `periph/` 与 `rtl/` 同名模块） |
| `ram.v` | 程序/数据行为 RAM |
| `tb_openmsp430_minimal.v` | 当前主 TB（冒烟） |
| `pmem.mem` | 程序存储器初值（hex） |
| `Makefile` | `make run` / **`make run-phaseb`** |
| `scripts/gen_phaseb_pmem.py` | 生成 `pmem.mem` 与 `pmem_t00`…`t19` |

更细的验证设计讨论见：**`PHASE_B_GUIDE.md`**（仓库根目录）。

---

## Phase C — Software golden model（`sw/`）

| 项目 | 内容 |
|------|------|
| **要做什么** | 若需要 C/Python 金模型则放 `sw/`；若不需要，报告说明 **N/A + 理由**，`sw/` 可只保留 `FOLDER_INFO.txt`（并在报告写清 N/A）。 |
| **是否要写代码** | **视项目而定**；你们可以 **无独立 golden**，但报告要写清楚。 |
| **当前状态** | **仅 `FOLDER_INFO.txt`**；报告章节待补。 |

---

## Phase D — Synthesis（`syn/`）

| 项目 | 内容 |
|------|------|
| **要做什么** | 脚本 + wc corner DB；闭 timing 得 **Fmax**；该频率下 **area**、**slack**；报告写流程与数字。 |
| **是否要写代码** | **必须**：Tcl/Shell 综合脚本 + 工具跑出的报告文件。 |
| **当前状态** | **未做**（仅有 `syn/FOLDER_INFO.txt`）。 |

---

## Phase E — PrimeTime（`ptpx/`）

| 项目 | 内容 |
|------|------|
| **要做什么** | 功耗脚本 + **有代表性、足够长**的向量；平均（可选峰值）功耗；报告写方法与结果。 |
| **是否要写代码** | **必须**：PTPX 脚本 + 向量生成或从仿真导出 + 报告。 |
| **当前状态** | **未做**（仅有 `ptpx/FOLDER_INFO.txt`）。 |

---

## Phase F — 报告其余 + 复现说明

| 项目 | 内容 |
|------|------|
| **要做什么** | Validation、**优化实现计划**、**优化验证计划**、以及如何 **复现 sim / syn / ptpx**（报告正文 + 附录；根目录 **`README.md`** 为提交用简版）。 |
| **是否要写代码** | 复现说明多为 Markdown/纯文本；**内容依赖 B/D/E 已有命令与路径**。团队内部：**本文档 + `PHASE_B_GUIDE.md`**。 |
| **当前状态** | **未做**（或仅部分在 `mid_proj.tex` 外草稿）。 |

**与评分表的对照：**Handbook 里「Report: README」通常指报告中的 **复现说明章节**，**不等于**仓库里只能有一个文件；提交 zip 时请包含根目录 **`README.md`**。

---

## Phase G — Presentation

| 项目 | 内容 |
|------|------|
| **要做什么** | 口头报告幻灯片（2 pt）。 |
| **是否要写代码** | 否（幻灯片）。 |
| **当前状态** | 自行跟踪。 |

---

## 文件位置速查

| 内容 | 路径 |
|------|------|
| 期中报告 LaTeX | `cs220/cs220 paper presentation/mid_proj.tex` |
| RTL | `midterm-team-5/rtl/` |
| 仿真 | `midterm-team-5/sim/` |
| 综合 | `midterm-team-5/syn/` |
| 功耗 | `midterm-team-5/ptpx/` |
| 软件 / golden | `midterm-team-5/sw/` |
| 上游 clone（对 hash） | `midterm-team-5/openmsp430_src/` |
| 老师 proposal 反馈文字 | `midterm-team-5/feedback_proposal.txt` |

---

## 与你问题的一句话对照

- **A3**：**不要求**额外「实现」工程代码；**报告 + 图（已在 `mid_proj.tex`）**即可。  
- **从 Phase B 起**：**必须有可运行的仿真/综合/PTPX 代码与日志**，否则 PDF 里对应章节和 **Code deliverables** 无法算完成。

（完）
