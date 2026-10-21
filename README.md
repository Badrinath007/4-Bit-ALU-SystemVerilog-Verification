# 4-Bit ALU with Hardware-in-the-Loop & Advanced Verification

A robust, synthesizable **4-bit Arithmetic Logic Unit (ALU)** designed in modern Verilog/SystemVerilog, targeting the Intel Cyclone IV E FPGA (EP4CE115F29C7). This project demonstrates a complete, automated digital design flow utilizing **OpenCode Desktop**, **QuestaSim** for comprehensive verification, and **Intel Quartus Prime** for synthesis and timing closure.

---

## 🚀 Key Features & Architecture

- **Expanded 3-Bit Opcode Support:**
  - `3'b000`: Addition (`ADD`) with carry-out and signed overflow.
  - `3'b001`: Subtraction (`SUB`) with borrow/carry and signed overflow.
  - `3'b010`: Bitwise AND (`AND`)
  - `3'b011`: Bitwise OR (`OR`)
  - `3'b100`: Exclusive-OR (`XOR`)
  - `3'b101–111`: Safe defaults (zero output, cleared flags).
- **Real Hardware Status Flags:** Dedicated combinational hardware output ports for `zero` (active high when result is `4'h0`), `overflow` (signed two's complement overflow detection), and `cout`.
- **Active-Low LED Display Mapping:** Includes inverted output driver (`led_out = ~y`) designed for active-low LED banks on FPGA development boards.

---

## 🧪 Verification Methodology (`QuestaSim`)

The testbench (`tb/tb_alu4.sv`) performs exhaustive self-checking verification:
- **Exhaustive State Space Sweep:** Tests all 8 opcodes across all 16 values of `A` and `B`, alongside specialized boundary vectors (zero results, max carry-out, signed wrap-arounds, and borrow cases).
- **Direct Hardware Assertions:** Validates actual DUT output ports (`y`, `cout`, `zero`, `overflow`, `led_out`) against behavioral reference models.

**Latest Simulation Results:**
- **Samples Verified:** 2,079
- **Total Assertions Checked:** 8,316
- **Pass Rate:** **100.00% (0 failures)**

---

## ⏱️ Synthesis & Timing Closure (`Quartus Prime`)

Targeting the **Intel Cyclone IV E (EP4CE115F29C7)** device family with a constrained 50 MHz clock (`20.00 ns` period via `alu4.sdc`):

| Resource / Metric | Utilization / Value |
|---|---|
| **Logic Elements** | 54 / 114,480 (<1%) |
| **Total Registers** | 25 |
| **Total Pins** | 24 / 529 (5%) |
| **Worst Setup Slack** | **+4.789 ns** (Slow 85°C corner) |
| **Worst Hold Slack** | +0.408 ns |
| **Timing Status** | Fully constrained & met |

---

## 🛠️ Toolchain & Automation
- **RTL Design:** Verilog-2001 / SystemVerilog (`rtl/alu4.v`)
- **Verification:** QuestaSim 10.7c (`vlog`, `vsim`)
- **Synthesis & Timing:** Intel Quartus Prime Lite (`quartus_sh`, TimeQuest STA)
- **Agentic Workflow:** Developed and iterated iteratively using **OpenCode Desktop**.
