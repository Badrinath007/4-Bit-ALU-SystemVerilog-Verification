`timescale 1ns/1ps

// tb_alu4.sv - self-checking dynamic vector testbench for alu4
// Drives A/B/opcode through ADD, SUB, AND and XOR cases and checks
// y, cout and led_out. The RTL has no overflow/zero ports, so those
// conditions are computed here only for reporting.
module tb_alu4;
    logic       clk = 1'b0;
    logic [1:0] opcode;
    logic [3:0] A, B;

    wire [3:0] y;
    wire       cout;
    wire [3:0] led_out;
    wire       beat;

    alu4 dut (
        .clk     (clk),
        .opcode  (opcode),
        .A       (A),
        .B       (B),
        .y       (y),
        .cout    (cout),
        .led_out (led_out),
        .beat    (beat)
    );

    // 20 ns period = 50 MHz board oscillator
    always #10 clk = ~clk;

    int errors = 0;
    int checks = 0;

    // Reference model: returns {cout, y} exactly as the RTL case statement does
    function automatic logic [4:0] model(input logic [1:0] op,
                                         input logic [3:0] a,
                                         input logic [3:0] b);
        case (op)
            2'b00: model = {1'b0, a} + {1'b0, b};
            2'b01: model = {1'b0, a} - {1'b0, b};
            2'b10: model = {1'b0, a & b};
            2'b11: model = {1'b0, a ^ b};
            default: model = 5'b00000;
        endcase
    endfunction

    task automatic check_case(input logic [1:0] op,
                               input logic [3:0] a,
                               input logic [3:0] b,
                               input string      name);
        logic [4:0] exp;
        logic       exp_zero;
        logic       exp_ovf;

        opcode = op;
        A      = a;
        B      = b;
        #1;  // let combinational outputs settle

        exp      = model(op, a, b);
        exp_zero = (exp[3:0] == 4'b0000);

        // Signed overflow: operands same sign (add) or different sign (sub),
        // and the result sign differs from A.
        case (op)
            2'b00:   exp_ovf = (a[3] == b[3]) && (exp[3] != a[3]);
            2'b01:   exp_ovf = (a[3] != b[3]) && (exp[3] != a[3]);
            default: exp_ovf = 1'b0;
        endcase

        checks++;

        if ({cout, y} !== exp) begin
            errors++;
            $display("FAIL %-24s op=%b A=%2d B=%2d : got cout=%b y=%b, expected cout=%b y=%b",
                     name, op, a, b, cout, y, exp[4], exp[3:0]);
        end else if (led_out !== ~y) begin
            errors++;
            $display("FAIL %-24s : led_out=%b, expected %b", name, led_out, ~y);
        end else begin
            $display("PASS %-24s op=%b A=%2d B=%2d -> cout=%b y=%b (zero=%b overflow=%b)",
                     name, op, a, b, cout, y, exp_zero, exp_ovf);
        end
    endtask

    initial begin
        $display("=== alu4 dynamic vector test ===");

        // ADD: basic, zero, carry-out and signed overflow
        check_case(2'b00, 4'd0,  4'd0,  "ADD zero");
        check_case(2'b00, 4'd5,  4'd3,  "ADD basic");
        check_case(2'b00, 4'd8,  4'd8,  "ADD carry + zero result");
        check_case(2'b00, 4'd15, 4'd15, "ADD carry max");
        check_case(2'b00, 4'd7,  4'd1,  "ADD signed overflow");
        check_case(2'b00, 4'd8,  4'd8,  "ADD overflow + carry");

        // SUB: basic, borrow, zero and signed overflow
        check_case(2'b01, 4'd5,  4'd3,  "SUB basic");
        check_case(2'b01, 4'd3,  4'd5,  "SUB borrow");
        check_case(2'b01, 4'd8,  4'd8,  "SUB zero");
        check_case(2'b01, 4'd0,  4'd1,  "SUB borrow wrap");
        check_case(2'b01, 4'd8,  4'd1,  "SUB signed overflow");
        check_case(2'b01, 4'd7,  4'd15, "SUB signed overflow 2");

        // AND
        check_case(2'b10, 4'd5,  4'd3,  "AND basic");
        check_case(2'b10, 4'd0,  4'd15, "AND zero");
        check_case(2'b10, 4'd15, 4'd10, "AND mask");

        // XOR
        check_case(2'b11, 4'd5,  4'd3,  "XOR basic");
        check_case(2'b11, 4'd15, 4'd15, "XOR zero");
        check_case(2'b11, 4'd10, 4'd5,  "XOR mixed");
        check_case(2'b11, 4'd0,  4'd0,  "XOR zero both");

        $display("---------------------------------------------");
        $display("Checks: %0d, Errors: %0d", checks, errors);
        $display("RESULT: %s", (errors == 0) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
