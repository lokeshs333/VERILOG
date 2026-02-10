timescale 1ns/ps
`define TRUE    1'b1
`define FALSE   1'b0
`define RED     2'd0
`define YELLOW  2'd1
`define GREEN   2'd2

// State definition          HWY        CNTRY
`define S0      3'd0   // GREEN      RED
`define S1      3'd1   // YELLOW     RED
`define S2      3'd2   // RED        RED
`define S3      3'd3   // RED        GREEN
`define S4      3'd4   // RED        YELLOW

// Delays
`define Y2RDELAY 3     // Yellow to red delay
`define R2GDELAY 2     // Red to green delay

module sig_control (
    hwy,
    cntry,
    X,
    clock,
    clear
);

// I/O ports
output [1:0] hwy, cntry;      // GREEN, YELLOW, RED
reg    [1:0] hwy, cntry;

input X;                      // Car present on country road
input clock, clear;

// Internal state variables
reg [2:0] state;
reg [2:0] next_state;

// ------------------------------------------------------------
// Initial conditions
// ------------------------------------------------------------
initial begin
    state      = `S0;
    next_state = `S0;
    hwy        = `GREEN;
    cntry      = `RED;
end

// ------------------------------------------------------------
// State register (state changes only on clock edge)
// ------------------------------------------------------------
always @(posedge clock) begin
    state = next_state;
end

// ------------------------------------------------------------
// Output logic (Moore-style FSM)
// ------------------------------------------------------------
always @(state) begin
    case (state)
        `S0: begin
            hwy   = `GREEN;
            cntry = `RED;
        end

        `S1: begin
            hwy   = `YELLOW;
            cntry = `RED;
        end

        `S2: begin
            hwy   = `RED;
            cntry = `RED;
        end

        `S3: begin
            hwy   = `RED;
            cntry = `GREEN;
        end

        `S4: begin
            hwy   = `RED;
            cntry = `YELLOW;
        end

        default: begin
            hwy   = `GREEN;
            cntry = `RED;
        end
    endcase
end

// ------------------------------------------------------------
// Next-state logic
// ------------------------------------------------------------
always @(state or clear or X) begin
    if (clear)
        next_state = `S0;
    else begin
        case (state)
            `S0: begin
                if (X)
                    next_state = `S1;
                else
                    next_state = `S0;
            end

            `S1: begin
                repeat (`Y2RDELAY) @(posedge clock);
                next_state = `S2;
            end

            `S2: begin
                repeat (`R2GDELAY) @(posedge clock);
                next_state = `S3;
            end

            `S3: begin
                if (X)
                    next_state = `S3;
                else
                    next_state = `S4;
            end

            `S4: begin
                repeat (`Y2RDELAY) @(posedge clock);
                next_state = `S0;
            end

            default: next_state = `S0;
        endcase
    end
end

endmodule
























//Stimulus Module
module stimulus;

wire [1:0] MAIN_SIG, CNTRY_SIG;
reg CAR_ON_CNTRY_RD;

//if TRUE, indicates that there is car on
//the country road
reg CLOCK, CLEAR;

//Instantiate signal controller
sig_control SC(MAIN_SIG, CNTRY_SIG, CAR_ON_CNTRY_RD, CLOCK, CLEAR);

//Set up monitor
initial
    $monitor($time, " Main Sig = %b Country Sig = %b Car_on_cntry = %b",
             MAIN_SIG, CNTRY_SIG, CAR_ON_CNTRY_RD);

//Set up clock
initial
begin
    CLOCK = `FALSE;
    forever #5 CLOCK = ~CLOCK;
end

//control clear signal
initial
begin
    CLEAR = `TRUE;
    repeat (5) @(negedge CLOCK);
    CLEAR = `FALSE;
end

//apply stimulus
initial
begin
    CAR_ON_CNTRY_RD = `FALSE;

    #200 CAR_ON_CNTRY_RD = `TRUE;
    #100 CAR_ON_CNTRY_RD = `FALSE;

    #200 CAR_ON_CNTRY_RD = `TRUE;
    #100 CAR_ON_CNTRY_RD = `FALSE;

    #200 CAR_ON_CNTRY_RD = `TRUE;
    #100 CAR_ON_CNTRY_RD = `FALSE;

    #100 $stop;
end

endmodule














`timescale 1ns / 1ps
`define RED    2'd0
`define YELLOW 2'd1
`define GREEN  2'd2

// State definition
`define S0     3'd0   // HWY: GREEN,  CNTRY: RED
`define S1     3'd1   // HWY: YELLOW, CNTRY: RED
`define S2     3'd2   // HWY: RED,    CNTRY: RED
`define S3     3'd3   // HWY: RED,    CNTRY: GREEN
`define S4     3'd4   // HWY: RED,    CNTRY: YELLOW

// Delays (Clock cycles)
`define Y2RDELAY 3     
`define R2GDELAY 2     

module sig_control (
    output reg [1:0] hwy, 
    output reg [1:0] cntry,
    input X,         // Sensor: Car on country road
    input clock, 
    input clear
);

    reg [2:0] state;
    reg [2:0] next_state;
    reg [3:0] timer; // Internal counter for delays

    // ------------------------------------------------------------
    // State Register & Timer Logic (Sequential)
    // ------------------------------------------------------------
    always @(posedge clock or posedge clear) begin
        if (clear) begin
            state <= `S0;
            timer <= 4'd0;
        end else begin
            state <= next_state;
            
            // Increment timer if we stay in a timed state, reset if we move
            if (state == next_state)
                timer <= timer + 1'b1;
            else
                timer <= 4'd0;
        end
    end

    // ------------------------------------------------------------
    // Next-state Logic (Combinational)
    // ------------------------------------------------------------
    always @(*) begin
        case (state)
            `S0: begin
                if (X) next_state = `S1;
                else   next_state = `S0;
            end

            `S1: begin
                if (timer >= `Y2RDELAY - 1) next_state = `S2;
                else                        next_state = `S1;
            end

            `S2: begin
                if (timer >= `R2GDELAY - 1) next_state = `S3;
                else                        next_state = `S2;
            end

            `S3: begin
                if (!X) next_state = `S4;
                else    next_state = `S3;
            end

            `S4: begin
                if (timer >= `Y2RDELAY - 1) next_state = `S0;
                else                        next_state = `S4;
            end

            default: next_state = `S0;
        endcase
    end

    // ------------------------------------------------------------
    // Output Logic (Moore-style)
    // ------------------------------------------------------------
    always @(*) begin
        case (state)
            `S0: begin hwy = `GREEN;  cntry = `RED;    end
            `S1: begin hwy = `YELLOW; cntry = `RED;    end
            `S2: begin hwy = `RED;    cntry = `RED;    end
            `S3: begin hwy = `RED;    cntry = `GREEN;  end
            `S4: begin hwy = `RED;    cntry = `YELLOW; end
            default: begin hwy = `GREEN; cntry = `RED; end
        endcase
    end

endmodule





`timescale 1ns / 1ps

module sig_control_tb;

    // Inputs
    reg X;
    reg clock;
    reg clear;

    // Outputs
    wire [1:0] hwy;
    wire [1:0] cntry;

    // Instantiate the Unit Under Test (UUT)
    sig_control uut (
        .hwy(hwy), 
        .cntry(cntry), 
        .X(X), 
        .clock(clock), 
        .clear(clear)
    );

    // Clock generation (10ns period -> 100MHz)
    always #5 clock = ~clock;

    initial begin
        // Initialize Inputs
        clock = 0;
        clear = 1;
        X = 0;

        // 1. Reset the system
        $display("--- Resetting System ---");
        #20;
        clear = 0;

        // 2. Wait at Highway Green (S0)
        #40;
        $display("Time: %t | HWY: %b, CNTRY: %b (Should be Green/Red)", $time, hwy, cntry);

        // 3. Car arrives on country road (X=1)
        $display("--- Car detected on country road ---");
        X = 1;
        
        // Wait to see transition S1 -> S2 -> S3
        // Delay long enough to cover Y2RDELAY (3) and R2GDELAY (2)
        #100;
        $display("Time: %t | HWY: %b, CNTRY: %b (Should be Red/Green)", $time, hwy, cntry);

        // 4. Car stays for a while, then leaves (X=0)
        #50;
        $display("--- Country road clear ---");
        X = 0;

        // 5. Wait to see transition S4 -> S0
        #100;
        $display("Time: %t | HWY: %b, CNTRY: %b (Should be Green/Red again)", $time, hwy, cntry);

        // Finish simulation
        #50;
        $display("--- Simulation Complete ---");
        $stop;
    end

    // Monitor changes in terminal
    initial begin
        $monitor("Time=%0t | HWY=%d CNTRY=%d | Sensor X=%b | State=%d", 
                  $time, hwy, cntry, X, uut.state);
    end

endmodule
