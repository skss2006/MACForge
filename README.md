# D09 - MACForge 
Building a weight stationary systolic array, a tool to make matrix multiplication efficient

## Architecture 
### Modules
#### MAC UNIT
The Multiply and Accumulate Units, "MAC units" in short are the building blocks of the systolic array. They have two (data) input ports and two (data) output ports (not considering the control ports involved such as clk, rst, load). Each MAC unit has an internal register of its own to store the weights given to it during loading phase. This module is named proc_element_ws.sv in the repository.
#### CONTROLLER
Controller module has one purpose, time the loading phase and compute phases perfectly and control the triggers such as en and load. For a NxN matrix it takes N clock cycles to load in the data into the MAC units and 3N-1 cycles in compute phase to get the output matrix in its entirety. This timing is calculated by the Controller module which ultimately is a counter, with two if statements for when counter is below N and above N but below 4N-1. The controller module is heavily reliant on the testbench for its working as the start wire is controlled by the testbench and the start wire is also responsible for controlling en. This module is named as controller.sv in the repository. 
#### SYSTOLIC ARRAY
The Systolic array is nothing but all the MAC units connected together using hor_wires and ver_wires which are defined using 2D arrays in the code. This module is named as systolic_array_ws.sv in the repository.
### Data Flow
#### LOAD PHASE
Data flow is quite simple. In load phase when load = 1, one of the two matrices to be multiplied is loaded into the systolic array, it is inputted in row N-1 first and row 0 last as this is how the algorithm works. The weights flow in through in_up, get stored in weight register and are passed to next PE (processing element or MAC unit) through out_down wire. These in_up and out_down are assigned to ver_wires in the systolic array module.
#### COMPUTE PHASE 
In compute phase, i.e. load = 0, the second matrix is given as input row wise, in a delayed manner, with a delay of one clock cycle per row, row 0 has a delay of 0 clock cycles, row 1 has a delay of 1 clock cycle and so on. These elements are inputted through in_left and outputted through out_right to the next MAC unit. 
### Computation
The MAC units are loaded with weights, the inputs are given through in_left, the MAC units do the following - out_down = in_left*weight + in_up, this is basically adding previous sum to the multiplication of the weight and input element of the second matrix.
## File Structure
### Code
Includes all the .sv files, system verilog files, which hold the code for the systolic array.
### Testbench
Holds the testbench which includes three test cases, multiplication of given matrix against identity matrix, two known matrices and two completely random matrices. 
### Sim
Holds the python wrapper which helps visualize how the code works and how the matrix is achieved, in a cycle-by-cycle manner. Understanding and decoding waveforms can be tedious and especially when so many variables are involved, hence it is beneficial for us to use a wrapper instead. 
## Parameters
### WIDTH
WIDTH is used to tell how many bit numbers are being used. This makes the code very easy to modify depending on how many bit numbers are given as input, rather than using a fixed bit width which would cause us to make multiple changes in the code for a small width change unlike current case where changing one singular parameter suffices the operation.
### N
N is the number of rows and columns the NxN matrix has. 
## How to Run
- Clone the repo locally.
- Download and set up in Vivado.
- Set systolic_array_ws.sv as top module in Vivado.
- Testbench is systolic_array_ws_tb.sv.
- Run Simulation.
- Run the Python wrapper in the sim/ folder for cycle-by-cycle visualization.