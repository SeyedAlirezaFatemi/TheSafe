// Verilog module.
module SAFE(
    clk,
    reset,
    confirm,
    keypad,
    access_granted, 
    access_denied,
    seven_segment,
    seg_power,
	safe_state
    );

    // Declare inputs,outputs and internal variables
    input clk, reset, confirm;
    input [3:0] keypad;
    //
    output [6:0] seven_segment;
    output reg access_denied, access_granted;
    //         red led        green led
    output reg [3:0] seg_power = 4'b1110; // For managing seven_segments    
    //
    reg [3:0] memory [3:0];
    reg [3:0] dancing_number = 4'b0000; // The number sent to seven_segment 
    output reg [4:0] safe_state = 5'b00000;
    /* 
        safe_state = 00000 ==> Reset, waiting for the new passcode, #1 digit
        safe_state = 00001 ==> Reset, waiting for the new passcode, #2 digit
        safe_state = 00010 ==> Reset, waiting for the new passcode, #3 digit
        safe_State = 00011 ==> Reset, waiting for the new passcode, #4 digit **
        safe_state = 00100 ==> Locked, waiting for the correct passcode, #1 attempt, #1 digit
        safe_state = 00101 ==> Locked, waiting for the correct passcode, #1 attempt, #2 digit
        safe_state = 00110 ==> Locked, waiting for the correct passcode, #1 attempt, #3 digit
        safe_state = 00111 ==> Locked, waiting for the correct passcode, #1 attempt, #4 digit **
        safe_state = 01000 ==> Locked, waiting for the correct passcode, #2 attempt, #1 digit
        safe_state = 01001 ==> Locked, waiting for the correct passcode, #2 attempt, #2 digit
        safe_state = 01010 ==> Locked, waiting for the correct passcode, #2 attempt, #3 digit
        safe_state = 01011 ==> Locked, waiting for the correct passcode, #2 attempt, #4 digit **
        safe_state = 01100 ==> Locked, waiting for the correct passcode, #3 attempt, #1 digit
        safe_state = 01101 ==> Locked, waiting for the correct passcode, #3 attempt, #2 digit
        safe_state = 01110 ==> Locked, waiting for the correct passcode, #3 attempt, #3 digit
        safe_state = 01111 ==> Locked, waiting for the correct passcode, #3 attempt, #4 digit **
        safe_state = 10000 ==> Locked, waiting for reset
        safe_state = 10001 ==> Open, waiting for reset  or getting locked
    */
    reg [2:0] led_state = 3'b100;
    /* 
        led_state = 000 ==> Both leds off
        led_state = 001 ==> Green led turns on and then turns off with a delay
        led_state = 010 ==> Red led turns on and then turns off with a delay
        led_state = 011 ==> Red led turns on and then stays on
        led_state = 100 ==> Both leds on
    */
    reg [3:0] passcode [3:0]; // The passcode is stored in this Array
    reg [23:0] delay = 24'b0;
	reg is_delay = 1'b1;
    reg [2:0] check = 3'b000; // For checking all four digits of the code entered
    integer i;

    always @ (posedge confirm or posedge reset ) begin
        if (reset == 1) begin
            safe_state <= 5'b00000;
            led_state <= 3'b100;
			is_delay = 1'b1;
            for (i=0;i<4;i=i+1) begin
                passcode[i] <= 4'b0000;
                memory[i] <= 4'b0000;  
            end
        end
        else begin
            case (safe_state) 
                5'b00000 : begin
                    memory[3] <= keypad;
                    passcode[3] <= keypad;
                    safe_state <= 5'b00001;
					is_delay = 1'b0;
						  
                end
                5'b00001 : begin
                    memory[2] <= keypad;
                    passcode[2] <= keypad;
                    safe_state <= 5'b00010;
                end 
                5'b00010 : begin
                    memory[1] <= keypad;
                    passcode[1] <= keypad;
                    safe_state <= 5'b00011;
                end 
                5'b00011 : begin
                    for (i=0;i<4;i=i+1) begin
                        memory[i] <= 4'b0000;  
                    end
                    passcode[0] <= keypad;
                    safe_state <= 5'b00100;
                    led_state <= 3'b000;
                end
                5'b00100 : begin
                    memory[3] <= keypad;
					is_delay = 1'b0;
                    if (keypad == passcode[3] ) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b00101;
                end
                5'b00101 : begin
                    memory[2] <= keypad;
                    if (keypad == passcode[2]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b00110;
                end
                5'b00110 : begin
                    memory[1] <= keypad;
                    if (keypad == passcode[1]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b00111;
                end
                5'b00111 : begin
					is_delay = 1'b1;
                    if (keypad == passcode[0] && check==3'b011) begin
                        safe_state <= 5'b10001;
                        led_state <= 3'b001;
                        check <= 3'b000;
                        memory[0] <= 4'b1100; // OPen
                        memory[1] <= 4'b1011;
                        memory[2] <= 4'b1010;
                        memory[3] <= 4'b0000; 
                    end
                    else begin
                        safe_state <= 5'b01000;
                        led_state <= 3'b010;  
                        check <= 3'b000;
                        for (i=0;i<4;i=i+1) begin
                            memory[i] <= 4'b0000;  
                        end 
                    end
                end
                5'b01000 : begin
                    memory[3] <= keypad;
					is_delay = 1'b0;
                    if (keypad == passcode[3]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b01001;
                end
                5'b01001 : begin
                    memory[2] <= keypad;
                    if (keypad == passcode[2]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b01010;
                end    
                5'b01010 : begin
                    memory[1] <= keypad;
                    if (keypad == passcode[1]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b01011;
                end
                5'b01011 : begin
					is_delay = 1'b1;
                    if (keypad == passcode[0] && check==3'b011) begin
                        safe_state <= 5'b10001;
                        led_state <= 3'b001;
                        check <= 3'b000;
                        memory[0] <= 4'b1100; // OPen
                        memory[1] <= 4'b1011;
                        memory[2] <= 4'b1010;
                        memory[3] <= 4'b0000;   
                    end
                    else begin
                        safe_state <= 5'b01100; 
                        led_state <= 3'b010;
                        check <= 3'b000;
                        for (i=0;i<4;i=i+1) begin
                            memory[i] <= 4'b0000;  
                        end 
                    end 
                end
                5'b01100 : begin
                    memory[3] <= keypad;
					is_delay = 1'b0;
                    if (keypad == passcode[3]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b01101;
                end
                5'b01101 : begin
                    memory[2] <= keypad;
                    if (keypad == passcode[2]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end                
                    safe_state <= 5'b01110;
                end  
                5'b01110 : begin
                    memory[1] <= keypad;
                    if (keypad == passcode[1]) begin
                        check <= check + 1'b1;  
                    end
                    else begin
                        check <= 3'b000;   
                    end
                    safe_state <= 5'b01111;
                end   
                5'b01111 : begin
					is_delay = 1'b1;
                    if (keypad == passcode[0] && check==3'b011) begin
                        safe_state <= 5'b10001;
                        led_state <= 3'b001;
                        check <= 3'b000;
                        memory[0] <= 4'b1100; // OPen
                        memory[1] <= 4'b1011;
                        memory[2] <= 4'b1010;
                        memory[3] <= 4'b0000; 
                    end
                    else begin
                        safe_state <= 5'b10000;
                        led_state <= 3'b011;
                        check <= 3'b000;
                        memory[0] <= 4'b1111; // LOck
                        memory[1] <= 4'b1110;
                        memory[2] <= 4'b0000;
                        memory[3] <= 4'b1101;  
                    end
                end 
				5'b10001 : begin
					if (keypad == 4'b1111) begin
						safe_state <= 5'b00100;
                        for (i=0;i<4;i=i+1) begin
                            memory[i] <= 4'b0000;  
                        end
					end
				end
            endcase  
        end
    end

    always @(posedge clk) begin
            // GPU _ leds
            case (led_state) 
                3'b000 : begin
                    access_granted <= 1'b0;
                    access_denied <= 1'b0; 
                    delay <= 0; 
                end
                3'b011 : begin
                    access_granted <= 1'b0;
                    access_denied <= 1'b1; 
                    delay <= 0; 
                end
                3'b001 : begin  // Delay
					if (is_delay == 1) begin
					    if (delay == 15000000) begin
							access_granted <= 1'b0;
							access_denied <= 1'b0;			
						end
						else begin
							delay <= delay + 1;
							access_granted <= 1'b1;
							access_denied <= 1'b0;
                        end
					end	
					else begin
						delay <= 0;
	         		end
                end
                3'b010 : begin  // Delay
                    if (is_delay == 1) begin
					    if (delay == 15000000) begin
							access_granted <= 1'b0;
							access_denied <= 1'b0;			
						end
						else begin
							delay <= delay + 1;
							access_granted <= 1'b0;
							access_denied <= 1'b1;
                        end
					end	
					else begin
						delay <= 0;
	         		end
                end
                3'b100 : begin
                    access_granted <= 1'b1;
                    access_denied <= 1'b1;  
                    delay <= 0;     
                end
                default : begin
                    access_granted <= 1'b0;
                    access_denied <= 1'b0;
                    delay <= 0;
                end  
            endcase

            // GPU _ 7segs
            case (seg_power) 
                4'b1110 : begin
                    seg_power <= 4'b1101;
                    dancing_number <= memory[1];
                end
                4'b1101 : begin
                    seg_power <= 4'b1011;
                    dancing_number <= memory[2];
                end
                4'b1011 : begin
                    seg_power <= 4'b0111;
                    dancing_number <= memory[3];
                end
                4'b0111 : begin
                    seg_power <= 4'b1110;
                    dancing_number <= memory[0];
                end
            endcase
    end

    BCD_TO_7SEG BCD_DECODER(dancing_number,seven_segment);

endmodule

// Verilog module.
module BCD_TO_7SEG(
    bcd,
    leds
    );
     
    // Declare inputs, outputs and internal variables.
    input [3:0] bcd;
    output reg [6:0] leds;

    // always block for converting bcd digit into 7 segment format
    always @ (*) begin
        case (bcd) 
            4'b0000 :  leds = 7'b1111110; // O or 0
            4'b0001 :  leds = 7'b0110000; 
            4'b0010 :  leds = 7'b1101101; 
            4'b0011 :  leds = 7'b1111001; 
            4'b0101 :  leds = 7'b1011011; 
            4'b0110 :  leds = 7'b1011111; 
            4'b0111 :  leds = 7'b1110000; 
            4'b1000 :  leds = 7'b1111111; 
            4'b1001 :  leds = 7'b1110011; 
            4'b1010 :  leds = 7'b1100111; // P
            4'b1011 :  leds = 7'b1001111; // E
            4'b1100 :  leds = 7'b0010101; // n
            4'b1101 :  leds = 7'b0001110; // L
            4'b1110 :  leds = 7'b0001101; // c
            4'b1111 :  leds = 7'b0110111; // k
            // switch off 7 segment character when the bcd digit is not a decimal number.
            default :  leds = 7'b0000000; 
        endcase
    end
    
endmodule

/*
    Configurations

    // inputs
    NET "clk" LOC = "P55";
    NET "reset" LOC = "P87";
    NET "confirm" LOC = "P88";
    NET "keypad<0>" LOC = "P97";
    NET "keypad<1>" LOC = "P98";
    NET "keypad<2>" LOC = "P99";
    NET "keypad<3>" LOC = "P100";

    // 7seg
    NET "seven_segment<6>" LOC = "P118";
    NET "seven_segment<5>" LOC = "P116";
    NET "seven_segment<4>" LOC = "P117";
    NET "seven_segment<3>" LOC = "P121";
    NET "seven_segment<2>" LOC = "P112";
    NET "seven_segment<1>" LOC = "P114";
    NET "seven_segment<0>" LOC = "P111";
    NET "seg_power<0>" LOC = "P124";
    NET "seg_power<1>" LOC = "P115";
    NET "seg_power<2>" LOC = "P119";
    NET "seg_power<3>" LOC = "P120";


    // leds
    NET "access_granted" LOC = "P78";
    NET "access_denied" LOC = "P79";
    NET "safe_state<0>" LOC = "P80";
    NET "safe_state<1>" LOC = "P81";
    NET "safe_state<2>" LOC = "P82";
    NET "safe_state<3>" LOC = "P83";
    NET "safe_state<4>" LOC = "P84";

*/
