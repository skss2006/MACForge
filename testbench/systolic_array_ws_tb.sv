`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.01.2026
// Design Name: 
// Module Name: systolic_array_ws_tb
// Project Name: MAC-Forge
// Description: Multi-test, 32-bit testbench for Weight-Stationary Systolic Array
//////////////////////////////////////////////////////////////////////////////////

module systolic_array_ws_tb; 

    // 1. Configuration (UPSCALED TO 32-BIT)
    parameter N = 4;
    parameter WIDTH = 32;

    // 2. Signals
    logic clk, reset, start; 
    logic signed [WIDTH-1 : 0] in_left [0 : N-1];
    logic signed [2*WIDTH-1 : 0] in_up [0 : N-1]; 
    logic signed [2*WIDTH-1 : 0] out_down [0 : N-1]; 

    // 3. Test Data Containers
    logic signed [WIDTH-1 : 0] matrix_A [0 : N-1][0 : N-1];
    logic signed [WIDTH-1 : 0] matrix_B [0 : N-1][0 : N-1];
    logic signed [2*WIDTH-1 : 0] expected_C [0 : N-1][0 : N-1];
    logic signed [2*WIDTH-1 : 0] captured_C [0 : N-1][0 : N-1]; 
    
    // Output File logic
    integer f, cycle_val, test_id;
    string current_test_name;

    // 4. Instantiate DUT
    systolic_array_ws #(.N(N), .WIDTH(WIDTH)) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .in_left(in_left),
        .in_up(in_up),
        .out_down(out_down)
    );

    // 5. Clock Generation
    initial clk = 0;
    always #5 clk = ~clk; 

    // 6. Main Test Procedure
    initial begin
        f = $fopen("D:/Data/MACForge/sim_data.csv", "w");
        $fwrite(f, "TestID,TestName,Cycle,C00,C01,C02,C03,C10,C11,C12,C13,C20,C21,C22,C23,C30,C31,C32,C33\n");
        
        $dumpfile("systolic_ws_wave.vcd");
        $dumpvars(0, systolic_array_ws_tb);
        
        // TEST 1: Identity
        setup_test_data(1);
        run_test_case(1, "Identity Matrix Test");

        // TEST 2: Negatives and Positives
        setup_test_data(2);
        run_test_case(2, "Signed Math Test");

        // TEST 3: Fully Random 32-bit Data
        setup_test_data(3);
        run_test_case(3, "Randomized 32-Bit Stress Test");

        $fclose(f);
        $display("\n === ALL TESTS COMPLETED SUCCESSFULLY ===");
        $finish;
    end

    // File Dump
    always @(posedge clk) begin
        if (start && !reset) begin
            cycle_val = cycle_val + 1;
            $fwrite(f, "%0d,%s,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
                test_id, current_test_name, cycle_val,
                captured_C[0][0], captured_C[0][1], captured_C[0][2], captured_C[0][3],
                captured_C[1][0], captured_C[1][1], captured_C[1][2], captured_C[1][3],
                captured_C[2][0], captured_C[2][1], captured_C[2][2], captured_C[2][3],
                captured_C[3][0], captured_C[3][1], captured_C[3][2], captured_C[3][3]
            );
        end
    end

    // --- TASKS ---

    task run_test_case(input integer id, input string name);
        begin
            $display("\n--- Starting %s ---", name);
            test_id = id;
            current_test_name = name;
            cycle_val = 0; 
            
            // Hardware Reset
            reset = 1; start = 0;
            init_ports();
            #20 reset = 0; 
            
            compute_golden_model();

            fork
                drive_system(); 
                capture_falling_outputs();
            join

            verify_results();
        end
    endtask

    task setup_test_data(input integer type_id);
        integer r, c;
        begin
            for(r=0; r<N; r++) begin
                for(c=0; c<N; c++) begin
                    captured_C[r][c] = 0; 
                    
                    if (type_id == 1) begin
                        // Test 1: Identity
                        matrix_A[r][c] = (r == c) ? 1 : 0;      
                        matrix_B[r][c] = (r * N) + c + 1;
                    end
                    else if (type_id == 2) begin
                        // Test 2: Signed Math 
                        matrix_A[r][c] = (r * N) - 5;      
                        matrix_B[r][c] = -((c * N) + 2);
                    end
                    else if (type_id == 3) begin
                        // Test 3: Random 32-bit
                        matrix_A[r][c] = $random;      
                        matrix_B[r][c] = $random;
                    end
                end
            end
        end
    endtask

    task init_ports();
        integer k;
        begin
            for(k=0; k<N; k++) begin
                in_left[k] = 0;
                in_up[k]   = 0;
            end
        end
    endtask

    task compute_golden_model();
        integer r, c, k;
        begin
            for(r=0; r<N; r++) begin
                for(c=0; c<N; c++) begin
                    expected_C[r][c] = 0;
                    for(k=0; k<N; k++) begin
                        expected_C[r][c] += matrix_A[r][k] * matrix_B[k][c];
                    end
                end
            end
        end
    endtask

    task drive_system();
        integer r, c, t, i;
        begin
            start = 1;
            
            // LOAD mode
            for (r = N-1; r >= 0; r--) begin
                @(negedge clk);
                for (c = 0; c < N; c++) in_up[c] = matrix_B[r][c];
                for (i = 0; i < N; i++) in_left[i] = 0; // Hold A at 0
            end
            
            // COMPUTE mode
            for (t = 0; t < (3*N) + N; t++) begin
                @(negedge clk); 
                for (c = 0; c < N; c++) in_up[c] = 0; // Feed 0 to top of MACs
                
                for (i = 0; i < N; i++) begin
                    in_left[i] = ((t >= i) && (t < i + N)) ? matrix_A[t - i][i] : 0;
                end
            end
            
            @(negedge clk);
            start = 0;
            init_ports();
        end
    endtask

    task capture_falling_outputs();
        integer t, c;
        begin
         
            for(t = 0; t < N; t++) @(negedge clk);

        
            for (t = 0; t < (3*N) + N; t++) begin 
                @(negedge clk);
                for (c = 0; c < N; c++) begin
                    if ( (t >= N + c) && (t < N + c + N) ) begin
                         captured_C[t - (N + c)][c] = out_down[c];
                    end
                end
            end
        end
    endtask

    task verify_results();
        integer r, c, errors;
        begin
            errors = 0;
            $display("\n-----------------------------------------");
            $display("       WS VERIFICATION RESULTS           ");
            $display("-----------------------------------------");
            for(r=0; r<N; r++) begin
                for(c=0; c<N; c++) begin
                    if(captured_C[r][c] !== expected_C[r][c]) begin
                        $display("[FAIL] Cell[%0d][%0d]: Expected %0d, Got %0d", 
                                 r, c, expected_C[r][c], captured_C[r][c]);
                        errors++;
                    end
                end
            end
            if(errors == 0) 
                $display(" [SUCCESS] All %0d MAC operations correct!", N*N);
            else 
                $display(" [FAILURE] Found %0d mismatches.", errors);
            $display("-----------------------------------------\n");
        end
    endtask

endmodule