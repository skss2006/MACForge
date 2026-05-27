`timescale 1ns / 1ps

module controller #(
    parameter N = 4
)(
    input clk,
    input rst,
    input start,
    output load, // 1 = Load Weights, 0 = Compute
    output en  
);

    reg [7:0] cycle_count;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 8'd0;
        end 
        else if (start && cycle_count < N) begin
            cycle_count <= cycle_count + 1'b1;
        end
    end


    assign en = start; 
    assign load = (cycle_count < N); // Stays high for exactly 'N' cycles

endmodule