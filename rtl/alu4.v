module alu4#(parameter N=4)(
	input clk,
	input [2:0] opcode,
	input [3:0] A,
	input [3:0] B,
	output reg [3:0] y,
	output reg cout,
	output zero,
	output reg overflow,
	output [3:0] led_out,
	output beat
	);

	reg [24:0] count=25'd0;
	always@(posedge clk) begin
		count<=count+1;
	end
	assign beat=count[24];

	always@(*) begin
		y=4'b0000;
		cout=1'b0;
		overflow=1'b0;
		case(opcode)
			3'b000:{cout,y}=A+B;                        // ADD
			3'b001:{cout,y}=A-B;                        // SUB (cout = borrow)
			3'b010:y=A&B;                               // AND
			3'b011:y=A|B;                               // OR
			3'b100:y=A^B;                               // XOR
			default:y=4'b0000;
		endcase

		// Signed overflow for ADD/SUB only
		case(opcode)
			3'b000: overflow=(~A[3]&~B[3]&y[3])|(A[3]&B[3]&~y[3]);
			3'b001: overflow=(A[3]&~B[3]&~y[3])|(~A[3]&B[3]&y[3]);
			default: overflow=1'b0;
		endcase
	end

	assign zero=(y==4'b0000);
	assign led_out=~y;
endmodule
