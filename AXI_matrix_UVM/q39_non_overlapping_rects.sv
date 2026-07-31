//=============================================================================
// Q39 : Non-Overlapping Rectangle Regions in a 2D Grid
//-----------------------------------------------------------------------------
// Repeatedly randomize a rectangle (top-left corner + dimensions) such that:
//   (1) each rectangle lies fully inside the ROWS x COLS grid,
//   (2) no two rectangles overlap (even partially),
//   (3) keep going until no free cell remains (cannot fit even a 1x1).
//
// Strategy used here : "Occupied Map"
//   Keep a bit[ROWS][COLS] grid marking taken cells. Before each randomize()
//   the map is fixed (non-rand), so the constraint just says: the new
//   rectangle may not cover any cell that is already 1.
//=============================================================================

//------------------------------------------------------------------
// Rectangle record
//------------------------------------------------------------------
typedef struct {
    int row, col;   // top-left corner (0-indexed)
    int h,   w;     // height, width (>= 1)
} rect_t;


//------------------------------------------------------------------
// Rectangle picker : randomizes ONE rectangle at a time
//------------------------------------------------------------------
class rect_picker #(parameter int ROWS = 8,
                    parameter int COLS = 8);

    // Randomizable fields for the current rectangle
    rand int row, col, h, w;

    // Occupied map : 1 = cell already taken by a chosen rectangle.
    // NOT rand -> acts as a constant during randomize().
    bit occupied [ROWS][COLS];

    // History of accepted rectangles
    rect_t chosen [$];

    //--- Boundary constraint : rectangle must fit inside the grid --------
    constraint c_bounds {
        row >= 0; col >= 0;
        h   >= 1; w   >= 1;
        row + h <= ROWS;
        col + w <= COLS;
    }

    //--- Non-overlap constraint (cell-level) ----------------------------
    // For every cell (r,c) that is already occupied, the new rectangle
    // must NOT cover it.  A cell is covered iff:
    //     row <= r < row+h  AND  col <= c < col+w
    constraint c_no_overlap {
        foreach (occupied[r, c]) {
            if (occupied[r][c])
                !(row <= r && r < row + h &&
                  col <= c && c < col + w);
        }
    }

    //--- Mark a chosen rectangle as occupied ----------------------------
    function void mark_occupied(rect_t r);
        for (int i = r.row; i < r.row + r.h; i++)
            for (int j = r.col; j < r.col + r.w; j++)
                occupied[i][j] = 1'b1;
        chosen.push_back(r);
    endfunction

    //--- Termination helper : does any free cell remain? ----------------
    // A 1x1 rectangle can go in ANY free cell, so one free cell is enough.
    function bit any_free_cell();
        foreach (occupied[r, c])
            if (!occupied[r][c]) return 1'b1;
        return 1'b0;
    endfunction

    //--- Manual overlap check (fallback verification) -------------------
    function bit no_overlap_check(int row, int col, int h, int w);
        for (int r = row; r < row + h; r++)
            for (int c = col; c < col + w; c++)
                if (occupied[r][c]) return 1'b0;   // hit an occupied cell
        return 1'b1;
    endfunction

    //--- Reset for a fresh run ------------------------------------------
    function void reset();
        foreach (occupied[r, c]) occupied[r][c] = 1'b0;
        chosen.delete();
    endfunction

endclass


//------------------------------------------------------------------
// Controller : drives the picker until the grid is packed
//------------------------------------------------------------------
class rect_controller #(parameter int ROWS = 8,
                        parameter int COLS = 8);

    rect_picker #(ROWS, COLS) picker;
    rect_t                    all_rects [$];

    function new();
        picker = new();
    endfunction

    task run();
        rect_t cur;
        int    attempt;
        int    MAX_ATTEMPTS = 1000;
        bit    success;

        picker.reset();
        all_rects.delete();

        // Keep picking while at least one free cell remains
        while (picker.any_free_cell()) begin
            success = 0;

            // Try up to MAX_ATTEMPTS times to land a valid rectangle
            for (attempt = 0; attempt < MAX_ATTEMPTS; attempt++) begin
                if (picker.randomize()) begin
                    // Double-check the solver result manually
                    if (picker.no_overlap_check(picker.row, picker.col,
                                                picker.h,   picker.w)) begin
                        cur = '{picker.row, picker.col, picker.h, picker.w};
                        picker.mark_occupied(cur);
                        all_rects.push_back(cur);
                        success = 1;
                        break;
                    end
                end
            end

            // Exhausted attempts -> remaining free cells are unreachable, stop
            if (!success) break;
        end

        // Report
        $display("Selected %0d non-overlapping rectangles:", all_rects.size());
        foreach (all_rects[i])
            $display("  [%0d] row=%0d col=%0d h=%0d w=%0d",
                     i, all_rects[i].row, all_rects[i].col,
                        all_rects[i].h,   all_rects[i].w);
    endtask

endclass


//------------------------------------------------------------------
// Top-level testbench
//------------------------------------------------------------------
module tb_q39;
    initial begin
        rect_controller #(.ROWS(8), .COLS(8)) ctrl;
        ctrl = new();
        ctrl.run();
        $finish;
    end
endmodule
