module systolic_array_ws #(
    parameter N = 4,                                           
    parameter WIDTH = 32                                           
)(
    input clk,
    input reset,                                                 
    input start,                                           
    input signed [WIDTH-1 : 0]   in_left [0 : N-1],              
    input signed [2*WIDTH-1 : 0] in_up [0 : N-1],                
    output signed [2*WIDTH-1 : 0] out_down [0 : N-1]             
);
                         
    // Internal wires
    logic signed [WIDTH-1 : 0]   hor_wires [0 : N-1][0 : N]; 
    logic signed [2*WIDTH-1 : 0] ver_wires  [0 : N][0 : N-1]; 
    
    // Controller Wires
    wire global_load;
    wire global_en;
    
    controller #(.N(N)) controller (
        .clk(clk),
        .rst(reset),
        .start(start),
        .load(global_load),
        .en(global_en)
    );
        
    genvar i, j;                                                 
    generate
        for (i=0; i<N; i++) begin: ROWS
            for (j=0; j<N; j++) begin: COLS
                proc_element_ws #(.WIDTH(WIDTH)) pe_inst(
                    .clk(clk),
                    .reset(reset),
                    .en(global_en),     
                    .load(global_load), 
                    .in_left(hor_wires[i][j]),        
                    .in_up(ver_wires[i][j]),          
                    .out_right(hor_wires[i][j+1]),    
                    .out_down(ver_wires[i+1][j])      
                );
            end
        end
    endgenerate
        
    // Boundary conditions
    genvar k;
    generate
        for (k=0; k<N; k++) begin
            assign hor_wires[k][0] = in_left[k];  
            assign ver_wires[0][k] = in_up[k];    
            assign out_down[k] = ver_wires[N][k]; 
        end
    endgenerate
        
endmodule