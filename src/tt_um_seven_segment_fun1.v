`default_nettype none

module tt_um_seven_segment_fun1 #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire reset = ! rst_n;
    wire [6:0] led_out;
    assign uo_out[6:0] = led_out;
    assign uo_out[7] = 1'b0;

    // use bidirectionals as outputs
    assign uio_oe = 8'b11111111;

    // put bottom 8 bits of second counter out on the bidirectional gpio
    assign uio_out = second_counter[7:0];

    // external clock is 10MHz, so need 24 bit counter ?? 50MHz ??
    reg [23:0] second_counter;
    reg [3:0] digit;
    reg [3:0] counterMAX;

    // Which animation is displayed
    wire [2:0] animation;
    assign animation = ui_in[7:5]; // hard switch, not pushbutton yet
    reg [2:0] prev_ani;

    // if external inputs are set then use that as compare count
    // otherwise use the hard coded MAX_COUNT
    wire [23:0] compare = ui_in == 0 ? MAX_COUNT: {6'b0, ui_in[7:0], 10'b0};

    // FSM states
    /* 
    localparam ST_IDLE = 3'b000;
    localparam ST_ANI1 = 3'b001;
    localparam ST_ANI2 = 3'b010;
    localparam ST_ANI3 = 3'b011;
    localparam ST_ANI4 = 3'b100;
    localparam ST_ANI5 = 3'b101;

    parameter STATE_BITS = 3;
    reg [STATE_BITS-1:0]currState = ST_IDLE;
    reg [STATE_BITS-1:0]nextState = ST_IDLE;
    */

    always @(posedge clk) begin
        // if reset, set counter to 0
        if (reset || (animation != prev_ani)) begin // || (animation != prev_ani)
            second_counter <= 0;
            digit <= 0;
            // currState <= ST_IDLE;
            // nextState <= ST_IDLE;
        end else begin
            // if up to 16e6
            if (second_counter == compare) begin
                // reset
                second_counter <= 0;

                // increment digit
                digit <= digit + 1'b1;
            
                // only count from 0 to counterMAX
                if (digit == counterMAX) // >= ? ist max noch inklodiert??
                    digit <= 0;

            end else begin
                // increment counter
                second_counter <= second_counter + 1'b1;
            end
            prev_ani <= animation; // ? cycles net through ?
        end
    end

    // instantiate segment display
    seg7 seg7(.counter(digit), .animation(animation), .segments(led_out));

    changing changing(.animation(animation), .limit(counterMAX)); // extra file, wegen durchlaufen?
/*
    always @(*) begin // when button
        currState <= nextState;
        case (currState)
            ST_IDLE: begin
                    counterMAX <= 9;
                    nextState <= ST_ANI1;
                end
            ST_ANI1: begin
                    counterMAX <= 6;
                    nextState <= ST_ANI2;
                end
            ST_ANI2: begin
                    counterMAX <= 6;
                    nextState <= ST_ANI3;
                end
            ST_ANI3: begin
                    counterMAX <= 6;
                    nextState <= ST_ANI4;
                end
            ST_ANI4: begin
                    counterMAX <= 5;
                    nextState <= ST_ANI5;
                end
            ST_ANI5: begin
                    counterMAX <= 5;
                    nextState <= ST_IDLE;
                end
            default: begin
                    currState <= ST_IDLE;
                end         
        endcase
    end
*/
    
endmodule

