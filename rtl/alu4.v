module alu4#(parameter N=4)(
	input clk,
	input [1:0] opcode,
	input [3:0] A,
	input [3:0] B,
	output reg [3:0] y,
	output reg cout,
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
		case(opcode)
			2'b00:{cout,y}=A+B;
			2'b01:{cout,y}=A-B;
			2'b10:y=A&B;
			2'b11:y=A^B;
			default:y=4'b0000;
		endcase
	end
	assign led_out=~y;
endmodule