`timescale 1ns/1ps

// tb_alu4.sv - exhaustive self-checking testbench for alu4
//
// RTL opcodes:
//   3'b000 ADD   3'b001 SUB   3'b010 AND   3'b011 OR   3'b100 XOR
//   3'b101..3'b111 are unused and must produce y=0, cout=0, zero=1.
//
// The hardware zero and overflow outputs are checked against an independent
// reference model, not read back into their own computation.
//
// Coverage:
//   1. Exhaustive: all 8 opcode values x 16 A x 16 B = 2048 samples.
//   2. Named boundary cases: max carry, zero results, signed wrap-around,
//      borrow/subtraction edges, OR pass-through.
//   3. Immediate assertions on {cout, y}, zero, overflow and led_out.
module tb_alu4;
    logic       clk = 1'b0;
    logic [2:0] opcode;
    logic [3:0] A, B;

    wire [3:0] y;
    wire       cout;
    wire       zero;
    wire       overflow;
    wire [3:0] led_out;
    wire       beat;

    alu4 dut (
        .clk      (clk),
        .opcode   (opcode),
        .A        (A),
        .B        (B),
        .y        (y),
        .cout     (cout),
        .zero     (zero),
        .overflow (overflow),
        .led_out  (led_out),
        .beat     (beat)
    );

    // 20 ns period = 50 MHz board oscillator
    always #10 clk = ~clk;

    int samples    = 0;  // operand/opcode vectors applied
    int assertions = 0;  // immediate assertions evaluated (4 per sample)
    int failures   = 0;

    // Reference model: returns {cout, y} exactly as the RTL case statement does.
    function automatic logic [4:0] model(input logic [2:0] op,
                                         input logic [3:0] a,
                                         input logic [3:0] b);
        case (op)
            3'b000:   model = {1'b0, a} + {1'b0, b};
            3'b001:   model = {1'b0, a} - {1'b0, b};
            3'b010:   model = {1'b0, a & b};
            3'b011:   model = {1'b0, a | b};
            3'b100:   model = {1'b0, a ^ b};
            default:  model = 5'b00000;
        endcase
    endfunction

    function automatic string op_name(input logic [2:0] op);
        case (op)
            3'b000:   return "ADD";
            3'b001:   return "SUB";
            3'b010:   return "AND";
            3'b011:   return "OR";
            3'b100:   return "XOR";
            default:  return "UNUSED";
        endcase
    endfunction

    // Signed overflow: operands same sign for ADD or different sign for SUB,
    // and the result sign differs from A.
    function automatic logic ovf_model(input logic [2:0] op,
                                       input logic [3:0] a,
                                       input logic [3:0] b,
                                       input logic [3:0] r);
        case (op)
            3'b000:   return (a[3] == b[3]) && (r[3] != a[3]);
            3'b001:   return (a[3] != b[3]) && (r[3] != a[3]);
            default:  return 1'b0;
        endcase
    endfunction

    task automatic sample(input logic [2:0] op,
                          input logic [3:0] a,
                          input logic [3:0] b);
        opcode = op;
        A      = a;
        B      = b;
        #1;  // combinational settle
    endtask

    task automatic check(input logic [2:0] op,
                         input logic [3:0] a,
                         input logic [3:0] b,
                         input string      name,
                         input bit         verbose);
        logic [4:0] exp;
        logic       exp_zero;
        logic       exp_ovf;

        sample(op, a, b);
        exp      = model(op, a, b);
        exp_zero = (exp[3:0] == 4'b0000);
        exp_ovf  = ovf_model(op, a, b, exp[3:0]);

        samples++;

        // Assertion 1: carry and result
        assert ({cout, y} === exp)
            begin
                if (verbose)
                    $display("PASS  %-26s op=%s A=%2d B=%2d -> cout=%b y=%b zero=%b overflow=%b",
                             name, op_name(op), a, b, cout, y, zero, overflow);
            end
            else begin
                failures++;
                $display("FAIL  %-26s op=%s A=%2d B=%2d -> got cout=%b y=%b, expected cout=%b y=%b",
                         name, op_name(op), a, b, cout, y, exp[4], exp[3:0]);
            end
        assertions++;

        // Assertion 2: hardware zero flag
        assert (zero === exp_zero)
            begin
                if (verbose) $display("      zero     =%b (expected %b)", zero, exp_zero);
            end
            else begin
                failures++;
                $display("FAIL  %-26s zero=%b, expected %b (y=%b)", name, zero, exp_zero, y);
            end
        assertions++;

        // Assertion 3: hardware overflow flag
        assert (overflow === exp_ovf)
            begin
                if (verbose) $display("      overflow =%b (expected %b)", overflow, exp_ovf);
            end
            else begin
                failures++;
                $display("FAIL  %-26s overflow=%b, expected %b (A=%2d B=%2d y=%b)",
                         name, overflow, exp_ovf, a, b, y);
            end
        assertions++;

        // Assertion 4: LED output is the active-low complement of y
        assert (led_out === ~y)
            begin
                if (verbose) $display("      led_out  =%b matches ~y", led_out);
            end
            else begin
                failures++;
                $display("FAIL  %-26s led_out=%b, expected %b", name, led_out, ~y);
            end
        assertions++;
    endtask

    initial begin
        $display("============================================================");
        $display(" alu4 exhaustive verification (3-bit opcode)");
        $display("============================================================");

        // ------------------------------------------------------------------
        // 1. Exhaustive sweep: full 3-bit opcode space, all A, all B
        // ------------------------------------------------------------------
        $display("\n[1] Exhaustive sweep (8 opcodes x 16 A x 16 B)...");
        for (int op = 0; op < 8; op++)
            for (int a = 0; a < 16; a++)
                for (int b = 0; b < 16; b++)
                    check(op[2:0], a[3:0], b[3:0], "", 1'b0);

        $display("    Exhaustive sweep complete: %0d samples", samples);

        // ------------------------------------------------------------------
        // 2. Named boundary conditions
        // ------------------------------------------------------------------
        $display("\n[2] Boundary conditions...");

        // ADD: zero, maximum carry, carry+zero, signed wrap-around
        check(3'b000, 4'h0, 4'h0, "ADD zero",               1'b1);
        check(3'b000, 4'hF, 4'hF, "ADD max carry (F+F)",    1'b1);
        check(3'b000, 4'h8, 4'h8, "ADD carry + zero (8+8)", 1'b1);
        check(3'b000, 4'hF, 4'h1, "ADD carry + zero (F+1)", 1'b1);
        check(3'b000, 4'h7, 4'h1, "ADD signed overflow",    1'b1);
        check(3'b000, 4'h8, 4'hF, "ADD overflow + carry",   1'b1);

        // SUB: zero, borrow, all-ones wrap, signed overflow
        check(3'b001, 4'h5, 4'h3, "SUB basic",              1'b1);
        check(3'b001, 4'h3, 4'h5, "SUB borrow",             1'b1);
        check(3'b001, 4'h8, 4'h8, "SUB zero (8-8)",         1'b1);
        check(3'b001, 4'hF, 4'hF, "SUB zero (F-F)",         1'b1);
        check(3'b001, 4'h0, 4'h1, "SUB borrow wrap (0-1)",  1'b1);
        check(3'b001, 4'h0, 4'h8, "SUB borrow wrap (0-8)",  1'b1);
        check(3'b001, 4'h8, 4'h1, "SUB signed overflow",    1'b1);
        check(3'b001, 4'h7, 4'hF, "SUB signed overflow 2",  1'b1);

        // AND: all ones, zero outcomes, masking
        check(3'b010, 4'hF, 4'hF, "AND all ones",           1'b1);
        check(3'b010, 4'h0, 4'hF, "AND zero (0&F)",         1'b1);
        check(3'b010, 4'hA, 4'h5, "AND zero (A&5)",         1'b1);
        check(3'b010, 4'hF, 4'hA, "AND mask (F&A)",         1'b1);

        // OR: zero, pass-through, all ones
        check(3'b011, 4'h0, 4'h0, "OR zero (0|0)",          1'b1);
        check(3'b011, 4'hF, 4'h0, "OR all ones (F|0)",      1'b1);
        check(3'b011, 4'h5, 4'hA, "OR all ones (5|A)",      1'b1);
        check(3'b011, 4'h0, 4'hF, "OR pass-through (0|F)",  1'b1);
        check(3'b011, 4'hF, 4'hF, "OR all ones (F|F)",      1'b1);

        // XOR: zero outcomes, all ones, mixed
        check(3'b100, 4'h0, 4'h0, "XOR zero (0^0)",         1'b1);
        check(3'b100, 4'hF, 4'hF, "XOR zero (F^F)",         1'b1);
        check(3'b100, 4'hF, 4'h0, "XOR all ones (F^0)",     1'b1);
        check(3'b100, 4'h5, 4'hA, "XOR all ones (5^A)",     1'b1);
        check(3'b100, 4'h5, 4'h3, "XOR mixed",              1'b1);

        // Unused opcodes: default branch, zero flag must assert
        check(3'b101, 4'hF, 4'hF, "UNUSED opcode 101",      1'b1);
        check(3'b110, 4'hA, 4'h5, "UNUSED opcode 110",      1'b1);
        check(3'b111, 4'h0, 4'hF, "UNUSED opcode 111",      1'b1);

        // ------------------------------------------------------------------
        // 3. Results
        // ------------------------------------------------------------------
        $display("\n============================================================");
        $display(" Samples:    %0d", samples);
        $display(" Assertions: %0d", assertions);
        $display(" Failures:   %0d", failures);
        $display(" Pass rate:  %0.2f%%", 100.0 * (assertions - failures) / assertions);
        if (failures == 0)
            $display(" RESULT: PASS - 100%% test pass rate");
        else
            $display(" RESULT: FAIL");
        $display("============================================================");
        $finish;
    end
endmodule
