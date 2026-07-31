class one_run_declarative;

    rand bit [15:0] value;
    rand bit [15:0] lo_mask;
    rand bit [15:0] hi_mask;

    constraint c_not_zero { value != 0; }

    constraint c_lo_mask { (lo_mask & (lo_mask + 1)) == 0; }

    constraint c_hi_mask { ((~hi_mask) & ((~hi_mask) + 1)) == 0; }

    constraint c_value { value == (lo_mask & hi_mask); }

endclass


module tb_one_run;
    initial begin
        one_run_declarative t = new();
        for (int i = 0; i < 12; i++) begin
            if (!t.randomize())
                $fatal(1, "randomize failed");
            $display("value = %016b  (0x%04h)", t.value, t.value);
        end
        $finish;
    end
endmodule
