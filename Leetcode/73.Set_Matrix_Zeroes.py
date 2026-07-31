class Solution(object):
    # O(m+n) space
    def set_matrix_zeroes(matrix):
        row = set()
        col = set()

        for r in range(len(matrix)):
            for c in range(len(matrix[0])):
                if matrix[r][c] == 0:
                    row.add(r)
                    col.add(c)

        for r in range(len(matrix)):
            for c in range(len(matrix[0])):
                if r in row or c in col:
                    matrix[r][c] = 0

    # O(1) space — use first row/col as markers
    def set_matrix_zeroes_fast(matrix):
        m, n = len(matrix), len(matrix[0])
        first_row_zero = any(matrix[0][c] == 0 for c in range(n))
        first_col_zero = any(matrix[r][0] == 0 for r in range(m))

        for r in range(1, m):
            for c in range(1, n):
                if matrix[r][c] == 0:
                    matrix[r][0] = 0
                    matrix[0][c] = 0

        for r in range(1, m):
            for c in range(1, n):
                if matrix[r][0] == 0 or matrix[0][c] == 0:
                    matrix[r][c] = 0

        if first_row_zero:
            for c in range(n):
                matrix[0][c] = 0

        if first_col_zero:
            for r in range(m):
                matrix[r][0] = 0