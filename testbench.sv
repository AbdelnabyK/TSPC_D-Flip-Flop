`timescale 1ns/100fs
`default_nettype none 
module testbench;

// Parameters
parameter real digital_tick = 10; // Time between events in ns

// Logical signals
logic din;                // Data input of the flip-flop (D)
logic clk;                // Clock signal for the flip-flop
wire dout;                // Output of the flip-flop (Q)

// Real signals for board configuration
real load_capacitor_val;  // Load capacitor value
real din_tt_val;          // Transition time for data input
real din_delay_val = 0.0; // Delay for data input
real clk_tt_val;          // Transition time for clock input
real clk_delay_val = 0.0; // Delay for clock input

// Real signals for measured output from the board
real propagation_time   ;
int slope_index = 3;
int capa_index = 4;
int clk_delay_val_index = 0;

// Board instantiation
board bdut(
    .clk_logic(clk),
    .din_logic(din),
    .load_capacitor_val(load_capacitor_val),
    .din_tt_val(din_tt_val),
    .clk_tt_val(clk_tt_val),
    .din_delay_val(din_delay_val),
    .clk_delay_val(clk_delay_val),
    .propagation_time(propagation_time),
    .dout_electrical(dout)
);



localparam NBSLOPES = 7 ;
localparam NBCAPA = 7 ;
localparam real slope_values[0:NBSLOPES-1] = '{0.001,0.03,0.07,0.10,0.13,0.17,0.20} ; // ns
localparam real capa_values[0:NBCAPA-1] = '{0.02,1.25,2.5,5,11,21,42}; // fF

// Defines a file name for storing output results
string outfilename ;
// Define a file pointer for the file.
int outfile ;
// Define the standard error channel.
integer STDERR = 32'h8000_0002;
logic dout_ref ;
always @(posedge clk)
    dout_ref <= din ;
    
initial
begin:simu
   slope_index = 3;
   capa_index = 4;
   clk_delay_val_index = 0;
   din_tt_val = 0.1e-9 ;
   din_delay_val = 0.0 ;
   clk_delay_val = 0.0 ;
   load_capacitor_val = capa_values[capa_index]*1.0e-15 ;
   clk_tt_val = slope_values[slope_index]*1.0e-9 ;

   // The ouput file
   $swrite(outfilename,"measurements.dat") ;

   // Open the file for writing
   outfile = $fopen(outfilename,"w") ;

   // Write parameter infos on the first line of the resulting file
   $fwrite(outfile,"delay(ps)  propagation_time(ns) dout_ref dout");
   $fwrite(outfile,"\n") ;

   // At time 0 input is initialized to 0
   din = 1'b0 ;
  clk = 1'b0 ;

   for( clk_delay_val_index=100; clk_delay_val_index >=0; clk_delay_val_index--)
begin

clk_delay_val = clk_delay_val_index*1.0e-12 ;
din = 1'b0 ;
clk = 1'b0 ;
#(digital_tick) ;
clk = 1'b1 ;
#(digital_tick) ;
clk = 1'b0 ;
#(digital_tick) ;
din = 1'b1 ;
clk = 1'b1 ;
#(digital_tick+ clk_delay_val) ;
if(dout != dout_ref)
        begin
           $fdisplay(STDERR,"\033[91m testbench: at time %0t: din:%0d, dout:%0d \033[0m",   $realtime,dout_ref,dout) ;
           $fdisplay(STDERR,"\033[92m testbench: ERROR detected from testbench\033[0m" ) ;
           $fflush(STDERR) ;
           $fflush(outfile) ;
           $finish ;
        end
$fwrite(outfile,"%f %f %d %d \n", clk_delay_val/10.0e-12, propagation_time/1.0e-9, dout_ref, dout);

      
      din = 1'b0 ;
      #(digital_tick) ;
      end
   $fclose(outfile) ;
   $stop ;
end

endmodule
