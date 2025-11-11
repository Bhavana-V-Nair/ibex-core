`timescale 1ns / 1ps

module tb_ibex_fetch_fifo();

    // Clock and reset signals
    logic clk_i = 0;
    logic rst_ni = 0;
    
    // FIFO signals
    logic        clear_i = 0;
    logic [1:0]  busy_o;
    
    // Input port
    logic        in_valid_i = 0;
    logic [31:0] in_addr_i = 0;
    logic [31:0] in_rdata_i = 0;
    logic        in_err_i = 0;
    
    // Output port
    logic        out_valid_o;
    logic        out_ready_i = 1;  // Always ready to accept
    logic [31:0] out_addr_o;
    logic [31:0] out_rdata_o;
    logic        out_err_o;
    logic        out_err_plus2_o;
    
    // Clock generation - 100MHz (10ns period)
    always #5 clk_i = ~clk_i;
    
    // FIFO instantiation with ResetAll=1 to avoid X signals
    ibex_fetch_fifo #(
        .NUM_REQS(2),
        .ResetAll(1'b1)  // This eliminates X signals
    ) dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .clear_i(clear_i),
        .busy_o(busy_o),
        .in_valid_i(in_valid_i),
        .in_addr_i(in_addr_i),
        .in_rdata_i(in_rdata_i),
        .in_err_i(in_err_i),
        .out_valid_o(out_valid_o),
        .out_ready_i(out_ready_i),
        .out_addr_o(out_addr_o),
        .out_rdata_o(out_rdata_o),
        .out_err_o(out_err_o),
        .out_err_plus2_o(out_err_plus2_o)
    );
    
    // Test sequence
    initial begin
        $display("=== Starting FIFO Test ===");
        
        // Step 1: Reset the system
        $display("Step 1: Applying reset...");
        rst_ni = 0;
        #100;  // Hold reset for 100ns
        rst_ni = 1;
        #50;   // Wait a bit after reset
        $display("Reset released");
        
        // Step 2: Send first instruction
        $display("Step 2: Sending first instruction...");
        @(posedge clk_i);  // Wait for clock edge
        in_valid_i = 1;
        in_addr_i = 32'h00000000;
        in_rdata_i = 32'hDEADBEEF;
        in_err_i = 0;
        
        @(posedge clk_i);  // One clock cycle
        in_valid_i = 0;    // Remove valid
        
        // Step 3: Wait and observe
        #100;
        
        // Step 4: Send second instruction
        $display("Step 3: Sending second instruction...");
        @(posedge clk_i);
        in_valid_i = 1;
        in_addr_i = 32'h00000004;
        in_rdata_i = 32'hCAFEBABE;
        
        @(posedge clk_i);
        in_valid_i = 0;
        
        // Step 5: Let it run and observe output
        #200;
        
        // Step 6: Send third instruction
        $display("Step 4: Sending third instruction...");
        @(posedge clk_i);
        in_valid_i = 1;
        in_addr_i = 32'h00000008;
        in_rdata_i = 32'h12345678;
        
        @(posedge clk_i);
        in_valid_i = 0;
        
        // Let simulation run
        #300;
        
        $display("=== Test Complete ===");
        $finish;
    end
    
    // Monitor what's happening
    always_ff @(posedge clk_i) begin
        if (out_valid_o) begin
            $display("Time %0t: FIFO Output - Addr: %08h, Data: %08h", 
                     $time, out_addr_o, out_rdata_o);
        end
        if (in_valid_i) begin
            $display("Time %0t: FIFO Input  - Addr: %08h, Data: %08h", 
                     $time, in_addr_i, in_rdata_i);
        end
    end

endmodule

