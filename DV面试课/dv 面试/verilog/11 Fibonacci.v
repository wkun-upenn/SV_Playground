module fibonacci(
    input clock, reset,
    input [7:0] nth_number,
    output [19:0] fibonacci_number
);

reg [19:0] previous_value, current_value;
reg [7:0] internal_counter;
reg number_ready;

always @(posedge reset) begin
    previous_value <= 'd0;    //1st Fibonacci Number
    current_value <= 'd1;     //2nd Fibonacci Number 
    internal_counter <= 'd1;
end

always @(posedge clock) begin
    internal_counter <= internal_counter + 1;
    current_value <= current_value + previous_value;
    previous_value <= current_value;
    
    if (internal_counter == (nth_number-2))
        number_ready <= 1;
    else
        number_ready <= 0;
end

assign fibonacci_number = current_value;

endmodule

//======================================================================================

module fibonacci(
    input wire clk,           // Clock signal
    input wire reset,         // Reset signal
    output reg [31:0] fib     // Output for the Fibonacci number
);

    reg [31:0] fib_n1;        // Register to store F(n-1)
    reg [31:0] fib_n2;        // Register to store F(n-2)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fib <= 32'd1;     // Initial value F(1) = 1
            fib_n1 <= 32'd1;  // F(1)
            fib_n2 <= 32'd0;  // F(0)
        end else begin
            fib <= fib_n1 + fib_n2;  // Current Fibonacci number F(n) = F(n-1) + F(n-2)
            fib_n2 <= fib_n1;        // Update F(n-2) to F(n-1)
            fib_n1 <= fib;           // Update F(n-1) to F(n)
        end
    end

endmodule













