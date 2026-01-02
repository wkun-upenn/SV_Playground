///////////////////////////////////////////////////////////////////////////
// (c) Copyright 2013 Cadence Design Systems, Inc. All Rights Reserved.
//
// File name   : counter.sv
// Title       : Simple class
// Project     : SystemVerilog Training
// Created     : 2013-4-8
// Description : Simple counter class
// Notes       :
// 
///////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module counterclass;
    class counter;
        int count = 0;

        function void load(input int value);
            count = value;
        endfunction

        function int getcount();
            return count;
        endfunction

        function new(input int init);
            count = init;
        endfunction
    endclass

    class upcounter extends counter;
        function new(input int value);
            super.new(value);
        endfunction

        function void next();
            count = count + 1;
            $display("upcounter next %0d", count);
        endfunction
    endclass

    class downcounter extends counter;
        function new(input int value);
            super.new(value);
        endfunction

        function void next();
            count = count - 1;
            $display("downcounter next %0d", count);
        endfunction
    endclass

    initial begin
        upcounter up1 = new(123);
        downcounter down1 = new(321);

        up1.next();
        down1.next();
    end

endmodule
