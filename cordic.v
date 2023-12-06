//////////////////////////////////////RESET CONTROLLER////////////////////////////////////////
module reset_controller(clk, rst, rst_correct);
input rst, clk;
output reg rst_correct;
initial begin
rst_correct = 1;
end
always@(rst) begin
rst_correct = rst;
end
endmodule

////////////////////////////////////////LATCH/////////////////////////////////////////////////
module latch(rst, show, xf, yf, cos, sin, neg_quadrant);
input show, rst;
input neg_quadrant; 
input [15:0]xf, yf;
output reg [16:0]cos, sin;
initial begin
cos = 0;
sin = 0;
end
always@(rst) begin
sin <= sin;
cos <= cos;
end
always@(show) begin
if(neg_quadrant) begin
sin <= ~(yf[15:0])+1;
end
else
sin <= yf[15:0];
cos <= xf[15:0];
end
endmodule

//////////////////////////////////////LOOK UP TABLE///////////////////////////////////////

module LUT(rst, rst1, clk, dir, theta, show);
input wire clk, dir, rst;
output show;
output reg rst1;
output [15:0]theta;
reg [4:0]counter;
reg [15:0] temp1;
initial begin
    temp1 = 0;
    counter = 0;
    rst1 = 1;
end
always@(rst) begin
rst1 = rst;
end
always@(negedge clk) begin
if(counter  == 5'd16 || rst1 == 1) begin
counter <= 0;
temp1 <= 0;
rst1 <= 1;
end
else begin
counter <= counter + 1;
end
end
always@(counter) begin
case (counter) 
5'd1 : temp1 = (dir == 1) ? 16'b0110010010000110 : ~16'b0110010010000110+1; //45.000, 0.785398163
5'd2 : temp1 = (dir == 1) ? 16'b0011101101011000 : ~16'b0011101101011000+1; //26.56505118, 0.463647609
5'd3 : temp1 = (dir == 1) ? 16'b0001111101011010 : ~16'b0001111101011010+1; //14.03624347, 0.244978663
5'd4 : temp1 = (dir == 1) ? 16'b0000111111101010 : ~16'b0000111111101010+1; //7.125016349, 0.124354994
5'd5 : temp1 = (dir == 1) ? 16'b0000011111111100 : ~16'b0000011111111100+1; //3.576334375, 0.06241881
5'd6 : temp1 = (dir == 1) ? 16'b0000001111111110 : ~16'b0000001111111110+1; //1.789910608, 0.031239833
5'd7 : temp1 = (dir == 1) ? 16'b0000000111111110 : ~16'b0000000111111110+1; //0.89517371, 0.015623728
5'd8 : temp1 = (dir == 1) ? 16'b0000000100000000 : ~16'b0000000100000000+1; //0.44761417, 0.00781234106
5'd9 : temp1 = (dir == 1) ? 16'b0000000010000000 : ~16'b0000000010000000+1; //0.2238105, 0.003906230132
5'd10 : temp1 = (dir == 1) ? 16'b0000000001000000 : ~16'b0000000001000000+1; //0.1119056, 0.001953122516
5'd11 : temp1 = (dir == 1) ? 16'b0000000000100000 : ~16'b0000000000100000+1; //0.055952891, 0.0009765621896
5'd12 : temp1 = (dir == 1) ? 16'b0000000000010000 : ~16'b0000000000010000+1; //0.027976452, 0.0004882812112
5'd13 : temp1 = (dir == 1) ? 16'b0000000000001000 : ~16'b0000000000001000+1; //0.013988227, 0.0002441406201
5'd14 : temp1 = (dir == 1) ? 16'b0000000000000100 : ~16'b0000000000000100+1; //0.006994113675, 0.0001220703119
5'd15: temp1 = (dir == 1) ? 16'b0000000000000010 : ~16'b0000000000000010+1; //0.003497056851, 0.00006103515617
5'd16: temp1 = (dir == 1) ? 16'b0000000000000001 : ~16'b0000000000000001+1; //0.00174528427, 0.00003051757812
endcase
end
assign theta = temp1;
assign show = counter[4];
endmodule


////////////////////////////////////////ACCUMULATOR//////////////////////////////////////////
module Accumulator(clk, rst, theta, dir, target);
input [15:0]theta;
input [15:0]target;
input clk;
input rst;
output reg dir;
reg [15:0]internal;
initial begin
    dir = 0;
    internal = 0;
end
always@(posedge clk) begin
if(rst) begin
dir = 0;
internal = target[15:0];
end
else begin
internal = internal + theta[15:0];
dir = internal[15];
end
end
endmodule


/////////////////////////////////////////MAIN///////////////////////////////////////////////
module Matrix(dir, rst, clk, xf, yf);
input dir, rst;
input clk;
reg [3:0]i;
reg [15:0]xi;
reg [15:0]yi;
output reg [15:0]xf;
output reg [15:0]yf;
initial begin
    xi = 16'b1001101101110100;
    yi = 16'b0000000000000000;
    xf = 0;
    yf = 0;
    i = 0;
end
always@(negedge clk) begin
    if(rst) begin
    xi <= 16'b1001101101110100;
    yi <= 16'b0000000000000000;
    xf <= 0;
    yf <= 0;
    i <= 0;
    end
    else begin  
    xf <= (dir == 0) ? (xi - (yi >> i)) : (xi + (yi >> i));
    yf <= (dir == 0) ? (yi + (xi >> i)) : (yi - (xi >> i));
    xi <= (dir == 0) ? (xi - (yi >> i)) : (xi + (yi >> i));
    yi <= (dir == 0) ? (yi + (xi >> i)) : (yi - (xi >> i));
    i <= i + 1;
    end
end
endmodule
////////////////////////////////////CORDIC//////////////////////////////////////////////

module cordic(rst, clk, target, cos, sin);
input wire clk;
input [15:0]target;
input rst;
output [15:0]cos, sin;


wire [15:0]theta;
wire [15:0] xf, yf;
wire dir, clk1, show;
wire rst1, rst_correct;


reset_controller r1(clk, rst, rst_correct);

LUT l1(rst_correct, rst1, clk, dir, theta, show);

Accumulator a1(clk, rst1, theta, dir, target);

Matrix m1(dir, rst1, clk, xf, yf);

latch l11(rst1, show, xf, yf, cos, sin, target[16]);
endmodule