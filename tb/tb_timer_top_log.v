// ============================================================================
// Component : tb_timer_top_log - logger / result collector of tb_timer_top
// Owns      : pass_count, fail_count (only this module changes them)
// Called by : test case (item / sub1 / sub2 headers), u_chk (result,
//             error_msg), tb_timer_top (init, error_msg, summary)
// Log       : [ITEM] / [SUBITEM1] / [SUBITEM2] headers, aligned check lines,
//             [SUMMARY] and Test_result (check_sim_log.py, sim/report.csh)
// ============================================================================
`timescale 1ns/1ps

module tb_timer_top_log #(
  parameter TIME_W = 8,
  parameter NAME_W = 40,
  parameter VAL_W  = 8
);

  integer         pass_count;
  integer         fail_count;
  reg  [8*64-1:0] cur_item;
  reg  [8*64-1:0] cur_sub1;

  // Once per Item (init_test); a DUT reset does not call it
  task init;
    begin
      pass_count = 0;
      fail_count = 0;
      cur_item   = 0;
      cur_sub1   = 0;
    end
  endtask

  // Branch headers; a new parent clears the context of its children
  task item;
    input [8*64-1:0] name;
    begin
      cur_item = name;
      cur_sub1 = 0;
      $display("[ITEM] %0s", name);
    end
  endtask

  task sub1;
    input [8*64-1:0] name;
    begin
      if (cur_item == 0) begin
        error_msg("[LOG ERROR] [SUBITEM1] without [ITEM]");
      end
      cur_sub1 = name;
      $display("  [SUBITEM1] %0s", name);
    end
  endtask

  task sub2;
    input [8*64-1:0] name;
    begin
      if (cur_sub1 == 0) begin
        error_msg("[LOG ERROR] [SUBITEM2] without [SUBITEM1]");
      end
      $display("    [SUBITEM2] %0s", name);
    end
  endtask

  // One aligned check line: [time] case PASS|FAIL | expected: exp | actual: act
  task result;
    input [8*64-1:0] name;
    input            pass;
    input [8*64-1:0] exp_str;
    input [8*64-1:0] act_str;
    reg   [8*64-1:0] t_str;
    begin
      if (pass) begin
        pass_count = pass_count + 1;
      end
      else begin
        fail_count = fail_count + 1;
      end
      $sformat(t_str, "%0d", $time);
      $display("[%0s] %0s %0s | expected: %0s | actual: %0s",
               pad_left(t_str, TIME_W), pad_right(name, NAME_W),
               pass ? "PASS" : "FAIL",
               pad_left(exp_str, VAL_W), pad_left(act_str, VAL_W));
    end
  endtask

  // Failure without a comparison (timeout, logging error)
  task error_msg;
    input [8*64-1:0] msg;
    begin
      fail_count = fail_count + 1;
      $display("%0s", msg);
    end
  endtask

  // Summary and overall result (read by sim/report.csh)
  task summary;
    begin
      $display("[SUMMARY] PASS=%0d FAIL=%0d", pass_count, fail_count);
      if (fail_count == 0 && pass_count > 0) begin
        $display("Test_result: PASSED");
      end
      else begin
        $display("Test_result: FAILED");
      end
    end
  endtask

  // Number of characters of a string held in reg [8*64-1:0]
  function integer str_len;
    input [8*64-1:0] s;
    integer          k;
    begin
      str_len = 0;
      for (k = 0; k < 64; k = k + 1) begin
        if (s[8*k +: 8] != 8'h0) begin
          str_len = k + 1;
        end
      end
    end
  endfunction

  // s right-aligned in a field of w characters
  function [8*64-1:0] pad_left;
    input [8*64-1:0] s;
    input integer    w;
    integer          k;
    begin
      pad_left = s;
      for (k = str_len(s); k < w; k = k + 1) begin
        pad_left[8*k +: 8] = " ";
      end
    end
  endfunction

  // s left-aligned in a field of w characters
  function [8*64-1:0] pad_right;
    input [8*64-1:0] s;
    input integer    w;
    integer          k;
    begin
      pad_right = s;
      for (k = str_len(s); k < w; k = k + 1) begin
        pad_right = {pad_right[8*63-1:0], 8'h20};
      end
    end
  endfunction

endmodule
