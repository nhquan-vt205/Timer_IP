// ============================================================================
// Component : tb_timer_top_clk_rst - clock/reset generator of tb_timer_top
// Drives    : clk_o -> sys_clk, rst_n_o -> sys_rst_n (only driver of both)
// Timing    : first rising edge at CLK_PERIOD / 2; rst_n_o is the active-low
//             asynchronous reset of the spec. apply_reset asserts it
//             immediately; assert_reset asserts it at posedge + #1, i.e.
//             inside a cycle before that cycle's falling-edge sample and
//             without a clock edge in between; release is at posedge + #1
// Called by : tb_timer_top (reset_dut) and the test case
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top_clk_rst #(
  parameter CLK_PERIOD = 20
) (
  output reg clk_o,
  output reg rst_n_o
);

  initial begin
    clk_o   = 1'b0;
    rst_n_o = 1'b0;
  end

  always #(CLK_PERIOD / 2) clk_o = ~clk_o;

  // Asynchronous assertion at the next posedge + #1
  task assert_reset;
    begin
      @(posedge clk_o);
      #1;
      rst_n_o = 1'b0;
    end
  endtask

  // Release at the next posedge + #1
  task release_reset;
    begin
      @(posedge clk_o);
      #1;
      rst_n_o = 1'b1;
    end
  endtask

  // Assert now, hold n rising edges, release at posedge + #1
  task apply_reset;
    input integer n;
    begin
      rst_n_o = 1'b0;
      repeat (n) begin
        @(posedge clk_o);
      end
      #1;
      rst_n_o = 1'b1;
    end
  endtask

endmodule
