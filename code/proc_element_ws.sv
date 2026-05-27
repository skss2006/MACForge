`timescale 1ns / 1ps

module proc_element_ws #(parameter WIDTH = 8) (
    input clk,
    input reset,                                 
    input en,           // Driven by controller
    input load,         // Driven by controller (1=Load, 0=Compute)
    input signed  [WIDTH - 1:0]   in_left,   // Matrix A inputs
    input signed  [2*WIDTH - 1:0] in_up,     
    output reg signed [WIDTH - 1:0]   out_right, 
    output reg signed [2*WIDTH - 1:0] out_down   
);
        
    reg signed [WIDTH-1 : 0] weight;        
                                       
    always @(posedge clk) begin
        if (reset) begin                                
            out_right <= 0;
            out_down  <= 0;
            weight    <= 0;
        end
        else if (en) begin
            out_right <= in_left; // Activations always shift right
            
            if (load) begin                             
               
                weight   <= in_up[WIDTH-1 : 0]; // Lock the weight
                out_down <= in_up;              // Pass weight down the column
            end
            else begin                                  
                
                out_down <= in_up + (weight * in_left); 
            end
        end
    end             
endmodule