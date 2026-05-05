#!/usr/bin/env python3
"""
Generate Phase B program memory images (2048 x 16-bit words) for openMSP430.

Layout: code starts at word index 0 (PC=0xF000). Last word (index 2047) is reset vector 0xF000.

Instructions use rtl/omsp_frontend.v decode (MOV=ir[15:12]==4, R0 imm, R2 abs, etc.):
  MOV.W #imm, Rn  -> 0x4030 | n, imm
  MOV.W Rn, &addr -> 0x4000 | (n<<8) | 0x82, addr
"""
from __future__ import annotations

import os

NWORDS = 2048
RESET_VEC = 0xF000
NOP = 0x4303
SCRATCH_REG = 8  # R8 for all staged peripheral stores

# Byte addresses (omsp_system.h)
WDTCTL = 0x0120
OP1_MPY = 0x0130
OP1_MPYS = 0x0132
OP2 = 0x0138

WDTHOLD_PW = 0x5A80  # WDTPW | WDTHOLD


def fresh_mem() -> list[int]:
    return [NOP] * NWORDS


def set_reset_vector(m: list[int]) -> None:
    m[NWORDS - 1] = RESET_VEC


def emit_mov_imm_reg(m: list[int], idx: int, imm: int, reg: int) -> int:
    m[idx] = 0x4030 | (reg & 0xF)
    m[idx + 1] = imm & 0xFFFF
    return idx + 2


def emit_mov_reg_abs(m: list[int], idx: int, reg: int, abs_addr: int) -> int:
    m[idx] = 0x4000 | ((reg & 0xF) << 8) | 0x82
    m[idx + 1] = abs_addr & 0xFFFF
    return idx + 2


def emit_mov_imm_abs(m: list[int], idx: int, imm: int, abs_addr: int) -> int:
    idx = emit_mov_imm_reg(m, idx, imm, SCRATCH_REG)
    idx = emit_mov_reg_abs(m, idx, SCRATCH_REG, abs_addr)
    return idx


def emit_wdt_hold(m: list[int], idx: int) -> int:
    return emit_mov_imm_abs(m, idx, WDTHOLD_PW, WDTCTL)


def emit_mpy_unsigned(m: list[int], idx: int, op1: int, op2: int) -> int:
    idx = emit_mov_imm_abs(m, idx, op1 & 0xFFFF, OP1_MPY)
    idx = emit_mov_imm_abs(m, idx, op2 & 0xFFFF, OP2)
    return idx


def emit_mpy_signed(m: list[int], idx: int, op1: int, op2: int) -> int:
    idx = emit_mov_imm_abs(m, idx, op1 & 0xFFFF, OP1_MPYS)
    idx = emit_mov_imm_abs(m, idx, op2 & 0xFFFF, OP2)
    return idx


def fill_nops(m: list[int], start: int, count: int) -> int:
    for i in range(count):
        m[start + i] = NOP
    return start + count


def write_mem(path: str, m: list[int]) -> None:
    lines = [f"{w:04X}" for w in m]
    with open(path, "w", encoding="ascii") as f:
        f.write("\n".join(lines) + "\n")


def build_t00_baseline() -> list[int]:
    """R0: deterministic minimal WDT+MPY (default smoke still hits peripherals)."""
    m = fresh_mem()
    idx = 0
    idx = emit_wdt_hold(m, idx)
    idx = emit_mpy_unsigned(m, idx, 1, 1)
    set_reset_vector(m)
    return m


def build_random(tid: int) -> list[int]:
    """TEST_ID 1..9 : seeded operand / padding variation (R1..R9)."""
    assert 1 <= tid <= 9
    m = fresh_mem()
    seed = 1009 + tid * 997
    op1 = (seed % 200) + 1
    op2 = ((seed >> 3) % 200) + 1
    pad = (seed ^ (tid * 0x1B)) & 0x3F
    idx = 0
    idx = emit_wdt_hold(m, idx)
    idx = fill_nops(m, idx, pad)
    idx = emit_mpy_unsigned(m, idx, op1, op2)
    set_reset_vector(m)
    return m


def build_corner(tid: int) -> list[int]:
    """TEST_ID 10..19 : corner-style images (C0..C9)."""
    m = fresh_mem()
    idx = 0
    if tid == 10:
        # Corner: WDT hold first, then smallest MPY (report can still describe WDT focus)
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_unsigned(m, idx, 1, 1)
    elif tid == 11:
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_unsigned(m, idx, 3, 4)
    elif tid == 12:
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_unsigned(m, idx, 0xFFFF, 1)
    elif tid == 13:
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_unsigned(m, idx, 0x10, 0x10)
    elif tid == 14:
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_signed(m, idx, 0xFF80, 0x0004)
    elif tid == 15:
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_unsigned(m, idx, 2, 3)
        idx = emit_mpy_unsigned(m, idx, 5, 7)
    elif tid == 16:
        idx = emit_wdt_hold(m, idx)
        idx = fill_nops(m, idx, 250)
        idx = emit_mpy_unsigned(m, idx, 9, 9)
    elif tid == 17:
        idx = emit_wdt_hold(m, idx)
        for _ in range(6):
            idx = emit_mpy_unsigned(m, idx, 11, 13)
    elif tid == 18:
        # Two back-to-back unsigned multiply sequences (corner: pipeline / state reuse)
        idx = emit_wdt_hold(m, idx)
        idx = emit_mpy_unsigned(m, idx, 7, 6)
        idx = emit_mpy_unsigned(m, idx, 3, 5)
    else:
        idx = emit_wdt_hold(m, idx)
        idx = emit_mov_imm_abs(m, idx, 0x5A80, WDTCTL)
        idx = emit_mpy_unsigned(m, idx, 0x00FF, 0x00FF)

    set_reset_vector(m)
    return m


def main() -> None:
    sim_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(sim_dir)

    out00 = build_t00_baseline()
    write_mem("pmem.mem", out00)
    write_mem("pmem_t00.mem", list(out00))

    for tid in range(1, 10):
        write_mem(f"pmem_t{tid:02d}.mem", build_random(tid))
    for tid in range(10, 20):
        write_mem(f"pmem_t{tid:02d}.mem", build_corner(tid))

    print(f"Wrote pmem.mem, pmem_t00.mem .. pmem_t19.mem under {sim_dir}")


if __name__ == "__main__":
    main()
