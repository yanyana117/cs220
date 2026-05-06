//----------------------------------------------------------------------------
// openMSP430 Phase B testbench — DUT + stimulus + constrained-random + checks
// (timescale in timescale.v, first in rtl_files.f)
//----------------------------------------------------------------------------
`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module tb_openmsp430_minimal;

    // Constrained-random delay for IRQ pulse (10 "random" test IDs 0..9)
    class cr_irq_delays;
        rand int unsigned irq_cycles;
        constraint c_irq { irq_cycles >= 120; irq_cycles <= 3800; }
        constraint c_skew {
            irq_cycles dist {
                [120:900]   :/ 2,
                [901:2400]  :/ 5,
                [2401:3800] :/ 2
            };
        }
    endclass

    // Memory buses
    wire [`DMEM_MSB:0] dmem_addr;
    wire               dmem_cen;
    wire        [15:0] dmem_din;
    wire         [1:0] dmem_wen;
    wire        [15:0] dmem_dout;

    wire [`PMEM_MSB:0] pmem_addr;
    wire               pmem_cen;
    wire        [15:0] pmem_din;
    wire         [1:0] pmem_wen;
    wire        [15:0] pmem_dout;

    wire        [13:0] per_addr;
    wire        [15:0] per_din;
    wire         [1:0] per_we;
    wire               per_en;
    wire        [15:0] dma_dout;
    wire               dma_ready;
    wire               dma_resp;

    reg         [15:1] dma_addr;
    reg         [15:0] dma_din;
    reg                dma_en;
    reg                dma_priority;
    reg          [1:0] dma_we;
    reg                dma_wkup;

    reg                dco_clk;
    wire               dco_enable;
    wire               dco_wkup;
    reg                dco_local_enable;
    reg                lfxt_clk;
    wire               lfxt_enable;
    wire               lfxt_wkup;
    reg                lfxt_local_enable;
    wire               mclk;
    reg                reset_n;
    wire               puc_rst;
    reg                nmi;
    reg  [`IRQ_NR-3:0] irq;
    wire [`IRQ_NR-3:0] irq_acc;
    reg                cpu_en;
    reg                dbg_en;
    reg                dbg_uart_rxd;
    reg                dbg_i2c_scl;
    reg                dbg_i2c_sda_in;
    reg          [6:0] dbg_i2c_addr;
    reg          [6:0] dbg_i2c_broadcast;
    reg                scan_enable;
    reg                scan_mode;
    reg                wkup;

    wire        [15:0] per_dout;
    assign per_dout = 16'h0000;

    integer tb_idx;
    integer test_id;
    int     chk_disable;

    reg [8*64-1:0] pmem_file;

    ram #(`PMEM_MSB, `PMEM_SIZE) pmem_0 (
        .ram_dout (pmem_dout),
        .ram_addr (pmem_addr),
        .ram_cen  (pmem_cen),
        .ram_clk  (mclk),
        .ram_din  (pmem_din),
        .ram_wen  (pmem_wen)
    );

    ram #(`DMEM_MSB, `DMEM_SIZE) dmem_0 (
        .ram_dout (dmem_dout),
        .ram_addr (dmem_addr),
        .ram_cen  (dmem_cen),
        .ram_clk  (mclk),
        .ram_din  (dmem_din),
        .ram_wen  (dmem_wen)
    );

    openMSP430 dut (
        .aclk              (),
        .aclk_en           (),
        .dbg_freeze        (),
        .dbg_i2c_sda_out   (),
        .dbg_uart_txd      (),
        .dco_enable        (dco_enable),
        .dco_wkup          (dco_wkup),
        .dmem_addr         (dmem_addr),
        .dmem_cen          (dmem_cen),
        .dmem_din          (dmem_din),
        .dmem_wen          (dmem_wen),
        .irq_acc           (irq_acc),
        .lfxt_enable       (lfxt_enable),
        .lfxt_wkup         (lfxt_wkup),
        .mclk              (mclk),
        .dma_dout          (dma_dout),
        .dma_ready         (dma_ready),
        .dma_resp          (dma_resp),
        .per_addr          (per_addr),
        .per_din           (per_din),
        .per_en            (per_en),
        .per_we            (per_we),
        .pmem_addr         (pmem_addr),
        .pmem_cen          (pmem_cen),
        .pmem_din          (pmem_din),
        .pmem_wen          (pmem_wen),
        .puc_rst           (puc_rst),
        .smclk             (),
        .smclk_en          (),
        .cpu_en            (cpu_en),
        .dbg_en            (dbg_en),
        .dbg_i2c_addr      (dbg_i2c_addr),
        .dbg_i2c_broadcast (dbg_i2c_broadcast),
        .dbg_i2c_scl       (dbg_i2c_scl),
        .dbg_i2c_sda_in    (dbg_i2c_sda_in),
        .dbg_uart_rxd      (dbg_uart_rxd),
        .dco_clk           (dco_clk),
        .dmem_dout         (dmem_dout),
        .irq               (irq),
        .lfxt_clk          (lfxt_clk),
        .dma_addr          (dma_addr),
        .dma_din           (dma_din),
        .dma_en            (dma_en),
        .dma_priority      (dma_priority),
        .dma_we            (dma_we),
        .dma_wkup          (dma_wkup),
        .nmi               (nmi),
        .per_dout          (per_dout),
        .pmem_dout         (pmem_dout),
        .reset_n           (reset_n),
        .scan_enable       (scan_enable),
        .scan_mode         (scan_mode),
        .wkup              (wkup)
    );

    initial begin
        test_id     = 0;
        chk_disable = 0;
        if (!$value$plusargs("TEST_ID=%d", test_id))
            test_id = 0;
        if ($test$plusargs("PER_CHK_OFF"))
            chk_disable = 1;

        for (tb_idx = 0; tb_idx < `DMEM_SIZE / 2; tb_idx = tb_idx + 1)
            dmem_0.mem[tb_idx] = 16'h0000;

        if (test_id == 0)
            pmem_file = "pmem.mem";
        else if (test_id < 20)
            $sformat(pmem_file, "pmem_t%02d.mem", test_id);
        else
            pmem_file = "pmem.mem";

        #10 $readmemh(pmem_file, pmem_0.mem);
        $display("TB: TEST_ID=%0d (program memory loaded)", test_id);
    end

    // Optional VCD dump for PrimeTime PX power analysis with representative
    // test-vector activity. Triggered by +VCD_DUMP=<path>; with no plusarg
    // nothing is dumped, so default sim behavior is unchanged.
    reg [8*256-1:0] vcd_path;
    initial begin
        if ($value$plusargs("VCD_DUMP=%s", vcd_path)) begin
            $dumpfile(vcd_path);
            $dumpvars(0, dut);
            $display("TB: VCD dump enabled -> %0s", vcd_path);
        end
    end

    initial begin
        dco_clk          = 1'b0;
        dco_local_enable = 1'b0;
        forever begin
            #25;
            dco_local_enable = (dco_enable === 1'b1) ? dco_enable : (dco_wkup === 1'b1);
            if (dco_local_enable | scan_mode)
                dco_clk = ~dco_clk;
        end
    end

    initial begin
        lfxt_clk          = 1'b0;
        lfxt_local_enable = 1'b0;
        forever begin
            #763;
            lfxt_local_enable = (lfxt_enable === 1'b1) ? lfxt_enable : (lfxt_wkup === 1'b1);
            if (lfxt_local_enable)
                lfxt_clk = ~lfxt_clk;
        end
    end

    initial begin
        reset_n = 1'b1;
        #93;
        reset_n = 1'b0;
        #593;
        reset_n = 1'b1;
    end

    initial begin
        irq              = {`IRQ_NR - 2{1'b0}};
        nmi              = 1'b0;
        dma_addr         = 15'h0000;
        dma_din          = 16'h0000;
        dma_en           = 1'b0;
        dma_priority     = 1'b0;
        dma_we           = 2'b00;
        dma_wkup         = 1'b0;
        cpu_en           = 1'b1;
        dbg_en           = 1'b0;
        dbg_uart_rxd     = 1'b1;
        dbg_i2c_scl      = 1'b1;
        dbg_i2c_sda_in   = 1'b1;
        dbg_i2c_addr     = 7'h00;
        dbg_i2c_broadcast = 7'h00;
        scan_enable      = 1'b0;
        scan_mode        = 1'b0;
        wkup             = 1'b0;
    end

    // Random-constrained testcase IDs 0..9: IRQ0 pulse after randomize()-driven delay
    initial begin : cr_irq_stimulus
        int unsigned cr_seed;
        cr_irq_delays R;
        int unsigned cycles;
        cr_seed = 32'hACE1_5BCD;
        void'($value$plusargs("CR_SEED=%d", cr_seed));
        wait (reset_n === 1'b1);
        if (!$test$plusargs("NO_CR_IRQ") && test_id >= 0 && test_id <= 9) begin
            R = new();
            process::self().srandom(cr_seed ^ (test_id * 32'h9E3779B9));
            if (!R.randomize())
                $fatal(1, "TB: cr_irq_delays.randomize failed");
            cycles = R.irq_cycles;
            repeat (cycles) @(posedge mclk);
            irq[0] = 1'b1;
            @(posedge mclk);
            irq[0] = 1'b0;
            $display("TB: constrained-random IRQ0 pulse (TEST_ID=%0d, delay_cycles=%0d)", test_id,
                     cycles);
        end
    end

    // Corner testcase IDs 10..19: single NMI glitch (fixed, non-random)
    initial begin : corner_nmi_glitch
        wait (reset_n === 1'b1);
        if (!$test$plusargs("NO_CORNER_NMI") && test_id >= 10 && test_id <= 19) begin
            repeat (800) @(posedge mclk);
            nmi = 1'b1;
            @(posedge mclk);
            nmi = 1'b0;
            $display("TB: corner NMI pulse (TEST_ID=%0d)", test_id);
        end
    end

    initial begin : run_and_check
        wait (reset_n === 1'b1);
        repeat (50000) @(posedge mclk);

`ifndef GATE_LEVEL_SIM
        // RTL: hierarchical refs to integrated peripherals (flattened away after DC)
        if (!chk_disable) begin
            if (dut.watchdog_0.wdtctl[7] !== 1'b1) begin
                $display("TB_OPENMSP430_MINIMAL: FAIL (WDTHOLD not latched, wdtctl=0x%02x)",
                         dut.watchdog_0.wdtctl);
                $fatal(1, "WDT functional check");
            end
            if (dut.multiplier_0.reslo === 16'h0000) begin
                $display("TB_OPENMSP430_MINIMAL: FAIL (MPY RESLO still 0 — multiplier not exercised)");
                $fatal(1, "MPY functional check");
            end
        end

        $display(
            "TB_OPENMSP430_MINIMAL: PASS (TEST_ID=%0d, 50000 mclk cycles, wdtctl=0x%02x reslo=0x%04h)",
            test_id, dut.watchdog_0.wdtctl, dut.multiplier_0.reslo);
`else
        $display("TB_OPENMSP430_MINIMAL: PASS (TEST_ID=%0d, 50000 mclk cycles, gate-level)", test_id);
`endif
        $finish(0);
    end

endmodule
