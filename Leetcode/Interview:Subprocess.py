def feasible(d, T, K):
    tmp_sum = 0
    K -= 1
    for i in range(len(d)):
        if tmp_sum + d[i] <= T:
            tmp_sum += d[i]
        else:
            tmp_sum = d[i]
            K -= 1
    return K >= 0


def split_array_min_max(d, K):
    # T must be at least max(d) (no partition can hold less than its biggest element)
    # T at most sum(d) (one partition holding everything)
    for T in range(max(d), sum(d) + 1):
        if feasible(d, T, K):
            return T
    return sum(d)   # fallback (shouldn't reach here)


# ---- Test ----
if __name__ == "__main__":
    tests = [
        ([7, 2, 5, 3, 10, 8, 1], 3, 14),
        ([7, 2, 5, 10, 8],       2, 18),
        ([1, 2, 3, 4, 5],        2, 9),
        ([1, 4, 4],              3, 4),
        ([1, 4, 4],              1, 9),
        ([10],                   1, 10),
    ]
    for d, K, expected in tests:
        got = split_array_min_max(d, K)
        status = "✓" if got == expected else "✗"
        print(f"{status} d={d}, K={K} → {got} (expected {expected})")