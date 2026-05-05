# Phase B：仿真完整教程（代码 + 怎么测 + 报告）

对齐 **Project Midterm.pdf**：`sim/` 里要有 **主 TB**、**激励**、**10 random + 10 corner** testcase，**ideal 仿真全过**，报告 **Verification** 有表和 log 路径。  
DUT：**`rtl/openMSP430.v`**（你们当前 trimmed 版）。

**文档分工：**根目录 **`README.md`** = 提交用复现命令；**`TEAM_PRIVATE_PHASE_NOTES.md`** = 团队进度（勿提交）；**本文件** = Phase B 怎么做细部说明。

---

## 0. 你现在要干什么？（只看这一段 — 按顺序做）

**大目标：**作业要的 Phase B = **20 条可复现的仿真用例 + log + 报告表格**；其中至少几条要 **真的访问 multiplier / watchdog**（老师反馈）。

**仓库现状（已对齐 Midterm.pdf Verification 代码侧）：**`gen_phaseb_pmem.py` 生成 20 个镜像；TB 含 **约束随机 IRQ（0–9）**、**角点 NMI（10–19）**、**ideal 下 WDT/MPY 层次自检**；**`make run-phaseb`** = ideal 全回归；综合出 **`syn/netlist.v`** 后 **`make run-phaseb-netlist`** = 门级 20 条（默认 **`+PER_CHK_OFF`**，满足 PDF「网表也能跑完用例」；报告里可写清自检策略）。**`make run-phaseb-both`** = ideal + 网表（无网表则跳过第二步）。

### 0.1 `pmem*.mem` 放在哪个文件夹？（非常重要）

所有程序存储器十六进制文件必须和 testbench **同目录**，也就是：

```text
cs220/midterm-team-5/sim/     ← 你开终端要先 cd 到这里
├── pmem.mem                  ← TEST_ID=0（与 `pmem_t00.mem` 同步生成）
├── pmem_t00.mem … pmem_t19.mem ← `python3 scripts/gen_phaseb_pmem.py` 生成
├── tb_openmsp430_minimal.v   ← 里面的 $readmemh 只写文件名，不写路径
├── Makefile
└── logs/                     ← 跑仿真后自动生成的 log
```

**规则：**`$readmemh("pmem.mem", …)` 里的字符串是**相对当前工作目录**的。你总是在 **`sim/`** 里执行 `make run`，所以 **`pmem_t01.mem` 必须放在 `midterm-team-5/sim/`，不要放到 `rtl/` 或仓库根目录。**

**自己复制一份新程序文件时**（在终端里，人已站在 `sim/` 下）：

```bash
cd /home/cegrad/xhuan230/cs220/midterm-team-5/sim
cp pmem.mem pmem_t02.mem
```

然后在 `tb_openmsp430_minimal.v` 的 `case (test_id)` 里加 `2: pmem_file = "pmem_t02.mem";`，再在 `Makefile` 里加 `run-t2`（照抄 `run-t1`）。

---

### 0.2 「冒烟」（smoke test）是什么意思？

**冒烟** = **最小自检**：不证明设计完全正确，只证明 **「能编译、能复位、能跑几个周期、不立刻挂死、有一个明确的 PASS 打印」**。  
你们现在的 TB 跑 **50000 个 `mclk` 周期**，最后打印 **`TB_OPENMSP430_MINIMAL: PASS`**，这就是冒烟：**整条仿真链是通的**。  
Phase B 作业还要求在此基础上再加 **更多、更有针对性的用例**（corner / random），冒烟只是第一步。

---

### 0.3 第一遍跟我做（你只做复制：逐条命令）

下面假设你在 **Linux 机房 / 你的服务器**，路径与仓库一致；若路径不同，只改 **`cd`** 那一行。

**第 1 条命令 — 进入仿真目录**

```bash
cd /home/cegrad/xhuan230/cs220/midterm-team-5/sim
```

**第 2 条命令 — 跑默认冒烟（TEST_ID=0，读 `pmem.mem`）**

```bash
make run
```

**你看什么算成功：**终端最后一行有 **`>>> OK: PASS in logs/run_default.log`**。  
**你再做一件事：**用文件管理器或编辑器打开 **`sim/logs/run_default.log`**，搜索 **`PASS`**，确认有一行 **`TB_OPENMSP430_MINIMAL: PASS`**。

**第 3 条命令 — 跑第二条用例（TEST_ID=1，读 `pmem_t01.mem`）**

```bash
make run-t1
```

**成功：**终端有 **`>>> OK: t01`**；打开 **`sim/logs/run_t01.log`** 同样有 **`PASS`**。  
（`pmem_t01.mem` 已在 **`sim/`** 里建好，内容和 `pmem.mem` 一样——先让你习惯「两个用例、两个 log」。）

**第 4 步 — 用眼睛确认 TB 里「谁读哪个文件」**  
用编辑器打开 **`sim/tb_openmsp430_minimal.v`**，搜 **`case (test_id)`**，你应看到：

- `0:` → `pmem.mem`  
- `1:` → `pmem_t01.mem`  

到这里，**「文件夹放对 + 冒烟跑通 + 第二条 log 骨架」** 就做完了。后面 Phase B 就是重复 **复制 mem + 加 case + 加 Makefile 目标**，凑满 20 条，再写报告表格。

---

### 0.4 小结表（和 0.3 同一套事）

| 步 | 你要做什么 | 怎么判断做对了 |
|----|------------|----------------|
| **①** | `cd …/midterm-team-5/sim`，**`make run`** | **`>>> OK: PASS in logs/run_default.log`** |
| **②** | 打开 **`logs/run_default.log`** 搜 **`PASS`** | 能看到 **`TB_OPENMSP430_MINIMAL: PASS`** |
| **③** | 确认 **`sim/pmem_t01.mem`** 存在（已建好；以后新用例再 `cp`） | 在 **`sim/`** 列表里能看到 `pmem.mem` 和 `pmem_t01.mem` |
| **④** | 打开 **`tb_openmsp430_minimal.v`** 看 **`case (test_id)`** | `0`→`pmem.mem`，`1`→`pmem_t01.mem` |
| **⑤** | **`make run-t1`** | **`>>> OK: t01`**，`logs/run_t01.log` 里有 **PASS** |

**不要现在做的事：**不用先写很长报告；不用先学完整 MSP430 汇编——先 **log + case 分支** 跑通，再往里填「更难」的激励。

---

### 0.5 新手常问：`pmem_t01.mem` 是啥？`4303` 是啥？要手动跑 20 遍吗？

**`pmem_t01.mem` 是干什么的？**  
它是 **第 2 条用例**用的程序存储器镜像，和 `pmem.mem` 一样放在 **`sim/`** 里。TB 里 **`+TEST_ID=1`** 会读它；**`+TEST_ID=0`** 读 `pmem.mem`。  
现在它和 `pmem.mem` **内容相同**也没问题——目的是先让你习惯「两个用例、两个 log」，后面你改 `pmem_t01.mem` 里的十六进制，两条用例才会行为不同。

**为什么几乎全是 `4303`？**  
在 MSP430 指令里，**`0x4303` 表示一条 16 位的 NOP（空操作）**。程序区先全部填 NOP，CPU 取到的是「安全指令」，不会因为随机数据当指令而跑飞。  
**最后一行 `F000`：**是复位向量要跳转的入口地址（与你们 `pmem` 布局一致），让 CPU 从 **`0xF000`** 开始执行 NOP 循环。

**我是不是要一条一条指令跑 20 多遍？**  
- **不是**「一条 shell 命令里跑完 20 个不同的 CPU 程序」那种意思。  
- **是**：作业要 **20 个不同的 testcase**，每个 case 通常要 **启动一次仿真**（一次 `./simv` 或一次 `make run-tN`）。  
- **省事做法：**用 **一个脚本 / 一个 `make run-all-now`**，让电脑 **自动按顺序** 跑多次 `./simv`（你喝口水等它跑完）。这 **不等于** 只跑一次仿真就交 20 份 log。

**你现在仓库里只有 2 个 TEST_ID（0 和 1），所以可以：**

| 你想怎么跑 | 在 `sim/` 里输入什么 |
|------------|----------------------|
| 只跑默认（TEST_ID=0） | `make run` |
| 只跑第 2 条（TEST_ID=1） | `make run-t1` |
| 两条都跑（先 0 再 1，**一条命令**） | `make run-all-now` |
| 和 `make run` 一样但 log 名叫 `run_t00.log` | `make run-t0` |

以后你加到 `TEST_ID=2…19` 时：要么再增加 `make run-t2`…，要么把 **`sim/scripts/run_tests_now.sh`** 里的 `for id in 0 1` 改成 `for id in $(seq 0 19)`（并保证 TB 里 `case` 都有对应 `pmem` 文件）。

**千万不要**把终端提示符（如 `bender ...$`）或 **Verilog 代码**整段粘贴进 bash；只粘贴 **`cd ...`**、**`make run`** 这种纯命令行。反引号 `` ` `` 也不要在终端里当命令输入。

---

## 1. 你们现在做到哪了？

| 状态 | 内容 |
|------|------|
| **已完成** | `rtl_files.f`、`ram.v`、`timescale.v`、`tb_openmsp430_minimal.v`、`pmem.mem`、`Makefile`；**`+TEST_ID=N`** 选程序镜像；**`make run`** → 日志在 **`sim/logs/run_default.log`**；`compile.log` 可作留痕。 |
| **交付级 Phase B（仿真侧）** | **20 条** `TEST_ID=0..19`；**`make run-phaseb`** → `logs/run_t00.log`…`run_t19.log`；程序里含 **MOV.W #imm, &0x0120 / &0x013x**（WDTCTL / MPY 寄存器，见 `gen_phaseb_pmem.py`）。报告里仍要把 **§Verification** 表 + 截图/说明写进 PDF。 |

下面按「先能测 → 再扩用例 → 再写报告」顺序写。

---

## 2. 每次怎么「跑测试」？（复制即可）

在 **`midterm-team-5/sim/`**：

```bash
cd /home/cegrad/xhuan230/cs220/midterm-team-5/sim
make run
```

**成功：**`sim/logs/run_default.log`（或终端）里有 `TB_OPENMSP430_MINIMAL: PASS`；`make run` 末尾有 **`>>> OK: PASS in logs/run_default.log`**。  
**失败：**看 `compile.log` 里第一个 `Error-[...]`，或对应 `logs/*.log` 里的报错。

只重新仿真（已编过 `simv`）：

```bash
mkdir -p logs
./simv -no_save +TEST_ID=0 2>&1 | tee logs/run_quick.log
```

另一条用例（占位，与 t00 同一 `pmem.mem` 也可先跑通流程）：

```bash
make run-t1
```

---

## 3. 新用例在代码里一般长什么样？

核心思想：**每条用例 = 不同的激励 + 明确的结束条件 + 打印 PASS/FAIL**。

### 方式 A：只换程序存储器（不动 TB 结构）——适合大量 corner

1. 复制一份 `pmem.mem` → 例如 `pmem_t02_irq_pulse.mem`。  
2. 在 TB 里把 `$readmemh("pmem.mem", ...)` 改成 **`+define+PMEM_FILE=...`** 或用 **`$test$plusargs`** 选文件名（推荐，这样一条 `vcs` 编一次，多次运行换参数）。  
3. 仿真结束用 `$display("TEST=t02_mem_irq PASS"); $finish;`。

**测什么：**复位后执行路径、是否进中断、是否写外设等，都可通过 **指令 / 初值** 写在 `pmem` 里完成（需要会一点 MSP430 机器码，或用 gcc 生成后再转成 hex）。

### 方式 B：在 TB 里用 `+define+TEST_ID=N` 分支——适合 random / 时序类

```verilog
`ifdef TEST_ID
  `if TEST_ID == 2
     // initial: 不同的 delay、irq 脉冲时刻 …
  `endif
`endif
```

编译：

```bash
vcs -full64 -sverilog +define+TEST_ID=2 +incdir+../rtl -f rtl_files.f ram.v tb_openmsp430_minimal.v -o simv
./simv -no_save 2>&1 | tee logs/run_t02.log
```

### 方式 C：监测总线 / 层次信号（证明「访问过」外设）——适合交报告 + A4

CPU 对外设的访问最终会体现在 **`openMSP430` 顶层可见的 `per_en`、`per_addr`、`per_we`**（以及读回数据路径）上。你可以在 TB 里：

- 用 **`always @(posedge mclk)`** 在 `per_en==1` 时 `$display` 或计数；或  
- 对 **`dut.mem_backbone_0`** / **`dut.multiplier_0`** / **`dut.watchdog_0`** 做层次引用（模块名以 `openMSP430.v` 为准），在固定周期后 **assert 某个寄存器曾被写过**。

**RTL 里外设基址（写报告时要引用源码）：**

| 外设 | 文件 | `BASE_ADDR`（参数行） |
|------|------|------------------------|
| Watchdog | `rtl/omsp_watchdog.v` | `15'h0120` |
| Multiplier | `rtl/omsp_multiplier.v` | `15'h0130` |

片上 **`per_addr` 位宽与解码** 与 `omsp_mem_backbone` 里 **`PER_SIZE` / `PER_AWIDTH`** 有关；字节地址与 `per_addr` 的对应建议在仿真里 **临时加一两行 `$monitor("per_addr=%h per_en=%b", dut.per_addr, dut.per_en);`** 对照波形确认一次，再写进报告（避免手算错）。

---

## 4. 「10 corner + 10 random」可以各写什么？（示例清单）

下面每条都要：**可自动判 PASS**（`$display` + `$fatal` 或统计比较）+ **单独 log 文件名**（便于报告填表）。

### 4.1 Corner（10 条）——易控制、易解释

| ID | 思路 | 怎么测 |
|----|------|--------|
| C1 | 默认冒烟 | 当前 `pmem.mem` + 长跑无 hang → 已有。 |
| C2 | 复位拉长 | `reset_n` 低电平时间加倍，仍能 PASS。 |
| C3 | `cpu_en` 晚拉高 | release `reset_n` 后多等几千 `mclk` 再 `cpu_en=1`，仍能启动。 |
| C4 | `nmi` 单次脉冲 | 在固定周期拉高一拍 `nmi`，检查不死锁、log 无 Error。 |
| C5 | `irq` 某位脉冲 | 对 `irq[0]`（或你们确定安全的一位）打一拍，检查系统仍 PASS。 |
| C6 | 换复位向量 | `pmem` 最后一字仍指向有效代码区，但入口改到另一段 NOP 区。 |
| C7 | 看门狗 **写 WDTCTL（hold）** | 用 **指令或总线活动** 使 `watchdog_0` 收到写；PASS：仿真内检测到写事件或计数器停走（需你们定义可观测信号）。 |
| C8 | 乘除器 **写 OP1/OP2 读 RESLO** | 同上，使 `multiplier_0` 出现写/读；PASS：读回与 golden 一致或仅检测「发生过访问」。 |
| C9 | `lfxt` 与 `dco` 频比极端 | 改 TB 里 `#763` / `#25` 比例，仍能 PASS。 |
| C10 | `scan_mode` 常 0 与 1 各跑一次 | 若 ASIC 路径允许，两种均 0 Error。 |

C7/C8 若汇编太难，可先用 **「层次 monitor + 用 C 或其它方式生成 pmem」** 两条路并行；报告里写清楚你选的路径。

### 4.2 Random（10 条）——用 `$urandom` 控制「何时」而非「乱连 X」

| ID | 思路 |
|----|------|
| R1–R3 | `reset_n` 释放后等待 **`$urandom_range(10,500)`** 个 `mclk` 再 `cpu_en=1`。 |
| R4–R6 | 在仿真中段随机 **`#($urandom_range(...))`** 后给 `irq` 一个单周期脉冲（掩码固定为安全位）。 |
| R7–R10 | 随机决定 **第 N 个 mclk** 写外设相关程序流（若用 pmem 方案，可随机选 **不同预生成 mem 文件** 之一）。 |

**注意：**random 不能破坏「异步输入要干净、无毛刺」的前提；**脉冲宽度** 建议固定为 1～2 个 `dco_clk` 周期量级，用 `mclk` 对齐采样。

---

## 5. Makefile / 脚本：怎么一条命令跑一条用例？

思路：**不要**为 20 条复制 20 份 TB；用 **`+define`** 或 **`+plusarg`** 区分，log 到 `sim/logs/`。

示例（你可贴进 `sim/Makefile` 扩展）：

```makefile
LOGDIR := logs
$(LOGDIR):
	mkdir -p $(LOGDIR)

# 例：用 plusarg 选 pmem 文件名（需在 tb 里用 $value$plusargs 读入）
run-t02: $(LOGDIR)
	cd $(CURDIR) && ./simv -no_save +PMEM_FILE=pmem_t02.mem 2>&1 | tee $(LOGDIR)/run_t02.log
```

TB 侧增加（概念代码，需你们自己塞进 `initial`）：

```verilog
string pmem_path;
initial begin
  if (!$value$plusargs("PMEM_FILE=%s", pmem_path))
    pmem_path = "pmem.mem";
  $readmemh(pmem_path, pmem_0.mem);
end
```

然后 **20 个 make 目标** 或 **一个 shell `for i in ...`** 循环，最后 **`grep PASS logs/*.log | wc -l`** 应为 20。

---

## 6. 报告里 Phase B 要写什么？（与代码对应）

建议在 **`mid_proj.tex`（或你们主报告）** 增加 **Verification** 小节，至少：

1. **TB 结构**：DUT、`ram` 模型、时钟/复位、`dma`/`dbg` tie-off；顶层 `per_dout` 外部为 0 的原因（与 `openMSP430` 内部 OR 的关系）。  
2. **仿真工具与命令**：与根目录 **`README.md`** 一致，一行能复现。  
3. **表：20 testcase**  

| ID | 名称 | R/C | 验证目标 | 期望 | Log |
|----|------|-----|----------|------|-----|
| … | … | C/R | … | PASS / 数值 | `sim/logs/run_xx.log` |

4. **A4 / 老师反馈**：单独两行说明 **哪几个 ID** 命中 **multiplier**、**哪几个 ID** 命中 **watchdog**（可附 `per_addr` 监测截图或 log 片段）。

**顺序建议：**先让 C7/C8 有一条能 **稳定 PASS** 的「外设访问」用例，再批量复制 random 变体；报告表格 **随 log 文件名同步更新**，避免最后对不上。

---

## 7. 常见卡点（简短）

1. **不要在 bash 里输入反引号 `` ` ``**（会把 `` `timescale` `` 当成命令替换）；`timescale` 只在 **`sim/timescale.v`**。  
2. **`ASIC_CLOCKING` + `LFXT_DOMAIN`**：`lfxt_clk` 必须翻转（你们 TB 已跟上游一样用 `lfxt_enable` 门控）。  
3. **`cpu_en` 太早**：容易卡在复位域；保持「先 `reset_n` 释放，再若干周期后 `cpu_en`」。  
4. **`rtl_files.f`**：不要同时编译 `rtl/` 与 `rtl/periph/` 里 **同名模块**（如两份 `omsp_gpio`）。  
5. **层次路径**：若用 `dut.xxx`，以 **`verdi`/`simv` 层次浏览器** 或编译后 `elab.log` 为准，避免手写错例化名。

---

## 8. 推荐阅读顺序（新手）

1. 根目录 **`README.md`**：先把 **`make run`** 跑绿。  
2. **`openMSP430.v`**：确认 `per_*`、`pmem_*`、`dmem_*` 端口。  
3. **`omsp_mem_backbone.v`**：看 `PER_SIZE`、`per_addr` 怎么从 `eu_mab` 来。  
4. **`omsp_watchdog.v` / `omsp_multiplier.v`**：看 `BASE_ADDR` 与寄存器偏移。  
5. 回到本文件 **§4–§5**：加用例与 Makefile。  
6. 写报告 **§Verification** 表格。

---

## 9. 与 Step 0–7 旧结构的对照（保留）

| Step | 内容 |
|------|------|
| 0 | 仿真器统一为 **VCS**（你们机房已可用）。 |
| 1 | `rtl_files.f` **0 Error** 编译。 |
| 2 | TB 壳 + `ram` + 绑线（已基本完成）。 |
| 3 | 冒烟 PASS（已完成）。 |
| 4–5 | **本文件 §3–§5**：扩 20 条用例 + log。 |
| 6 | Netlist 仿真（等 Phase D + SDF 后再做）。 |
| 7 | 报告 Verification + 与 **`README.md`** 一致的复现说明。 |

更宏观阶段表：**`TEAM_PRIVATE_PHASE_NOTES.md`**。
