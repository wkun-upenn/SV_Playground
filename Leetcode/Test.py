#!/usr/bin/env python3
"""Unified test runner for LeetCode solutions.

Usage:
    python Test.py          # run all
    python Test.py all      # run all
    python Test.py 73 102   # run specific problems
"""

import sys
import copy
import importlib.util
from pathlib import Path
from collections import deque

LEETCODE_DIR = Path(__file__).parent


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def build_tree(vals):
    if not vals:
        return None
    root = TreeNode(vals[0])
    q = deque([root])
    i = 1
    while q and i < len(vals):
        node = q.popleft()
        if i < len(vals) and vals[i] is not None:
            node.left = TreeNode(vals[i])
            q.append(node.left)
        i += 1
        if i < len(vals) and vals[i] is not None:
            node.right = TreeNode(vals[i])
            q.append(node.right)
        i += 1
    return root

def load_solution(problem_num):
    matches = list(LEETCODE_DIR.glob(f"{problem_num}.*.py"))
    if not matches:
        raise FileNotFoundError(f"No file found for problem {problem_num}")
    filepath = matches[0]
    spec = importlib.util.spec_from_file_location(f"problem_{problem_num}", filepath)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.Solution()

def load_interview(filename):
    filepath = LEETCODE_DIR / filename
    spec = importlib.util.spec_from_file_location(filename.replace(":", "_"), filepath)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------------------
# Problem 73 — Set Matrix Zeroes
# ---------------------------------------------------------------------------

def test_73():
    Sol = type(load_solution(73))
    cases = [
        ([[1,1,1],[1,0,1],[1,1,1]],          [[1,0,1],[0,0,0],[1,0,1]]),
        ([[0,1,2,0],[3,4,5,2],[1,3,1,5]],    [[0,0,0,0],[0,4,5,0],[0,3,1,0]]),
        ([[1]],                               [[1]]),
        ([[0]],                               [[0]]),
        ([[1,0]],                             [[0,0]]),
        ([[1,2,3],[4,5,6],[7,8,9]],           [[1,2,3],[4,5,6],[7,8,9]]),
        ([[0,0,0],[0,0,0],[0,0,0]],           [[0,0,0],[0,0,0],[0,0,0]]),
        ([[1,0,3]],                           [[0,0,0]]),
    ]
    for fn in [Sol.set_matrix_zeroes, Sol.set_matrix_zeroes_fast]:
        print(f"  [{fn.__name__}]")
        for i, (inp, expected) in enumerate(cases):
            matrix = copy.deepcopy(inp)
            fn(matrix)
            assert matrix == expected, (
                f"Case {i+1} FAILED\n  Input:    {inp}\n  Expected: {expected}\n  Got:      {matrix}"
            )
            print(f"    Case {i+1} PASSED")


# ---------------------------------------------------------------------------
# Problem 102 — Binary Tree Level Order Traversal
# ---------------------------------------------------------------------------

def test_102():
    sol = load_solution(102)
    cases = [
        ([3, 9, 20, None, None, 15, 7],   [[3], [9, 20], [15, 7]]),
        ([1],                              [[1]]),
        ([],                               []),
        ([1, 2, 3, 4, 5],                 [[1], [2, 3], [4, 5]]),
        ([1, None, 2, None, 3],            [[1], [2], [3]]),
        ([1, 2],                           [[1], [2]]),
    ]
    for i, (vals, expected) in enumerate(cases):
        root = build_tree(vals)
        result = sol.levelOrder(root)
        assert result == expected, (
            f"Case {i+1} FAILED\n  Input:    {vals}\n  Expected: {expected}\n  Got:      {result}"
        )
        print(f"  Case {i+1} PASSED")


# ---------------------------------------------------------------------------
# Problem 190 — Reverse Bits
# ---------------------------------------------------------------------------

def test_190():
    sol = load_solution(190)
    cases = [
        (0b00000010100101000001111010011100, 964176192),   # LeetCode example 1
        (0b11111111111111111111111111111101, 3221225471),  # LeetCode example 2
        (0,  0),
        (1,  2147483648),   # 1 << 31
        (0b11111111111111111111111111111111, 4294967295),  # all ones
    ]
    for i, (inp, expected) in enumerate(cases):
        result = sol.reverseBits(inp)
        assert result == expected, (
            f"Case {i+1} FAILED\n  Input:    {bin(inp)}\n  Expected: {expected}\n  Got:      {result}"
        )
        print(f"  Case {i+1} PASSED")


# ---------------------------------------------------------------------------
# Problem 128 — Longest Consecutive Sequence
# ---------------------------------------------------------------------------

def test_128():
    sol = load_solution(128)
    cases = [
        ([100,4,200,1,3,2],         4),   # 1,2,3,4
        ([0,3,7,2,5,8,4,6,0,1],    9),   # 0-8
        ([],                         0),
        ([1],                        1),
        ([1,2,3,4,5],               5),
        ([5,4,3,2,1],               5),   # reversed order
        ([1,1,1,1],                  1),   # all duplicates
        ([1,3,5,7],                  1),   # no consecutive
        ([-3,-2,-1,0,1],            5),   # negatives
    ]
    for i, (inp, expected) in enumerate(cases):
        result = sol.longestConsecutive(list(inp))
        assert result == expected, (
            f"Case {i+1} FAILED\n  Input:    {inp}\n  Expected: {expected}\n  Got:      {result}"
        )
        print(f"  Case {i+1} PASSED")


# ---------------------------------------------------------------------------
# Interview — Check Brackets
# ---------------------------------------------------------------------------

def test_check_brackets():
    m = load_interview("Interview:Check_Brackets.py")
    cases = [
        ("(a{b[c]d}e)",  {'()': 1, '{}': 1, '[]': 1}),
        ("(a{b)c}",      "Error"),
        ("([)]",         "Error"),
        ("",             {'()': 0, '{}': 0, '[]': 0}),
        ("((()))",       {'()': 3, '{}': 0, '[]': 0}),
        ("{[()]}",       {'()': 1, '{}': 1, '[]': 1}),
        ("(]",           "Error"),
        ("(((",          "Error"),
    ]
    for i, (inp, expected) in enumerate(cases):
        result = m.check_brackets(inp)
        assert result == expected, (
            f"Case {i+1} FAILED\n  Input:    {inp!r}\n  Expected: {expected}\n  Got:      {result}"
        )
        print(f"  Case {i+1} PASSED")


# ---------------------------------------------------------------------------
# Registry & runner
# ---------------------------------------------------------------------------

PROBLEM_TESTS = {
    73:  test_73,
    102: test_102,
    128: test_128,
    190: test_190,
}

INTERVIEW_TESTS = {
    "check_brackets": test_check_brackets,
}

def run(keys, registry):
    passed = failed = 0
    for key in keys:
        label = f"Problem {key}" if isinstance(key, int) else f"Interview: {key}"
        print(f"\n[{label}]")
        try:
            registry[key]()
            passed += 1
        except AssertionError as e:
            print(f"  {e}")
            failed += 1
        except Exception as e:
            print(f"  ERROR: {e}")
            failed += 1
    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed out of {passed+failed} problem(s)")


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or args == ["all"]:
        run(sorted(PROBLEM_TESTS.keys()), PROBLEM_TESTS)
        run(sorted(INTERVIEW_TESTS.keys()), INTERVIEW_TESTS)
    else:
        nums = []
        interviews = []
        for arg in args:
            try:
                n = int(arg)
                if n in PROBLEM_TESTS:
                    nums.append(n)
                else:
                    print(f"Unknown problem: {n} (available: {sorted(PROBLEM_TESTS.keys())})")
            except ValueError:
                if arg in INTERVIEW_TESTS:
                    interviews.append(arg)
                else:
                    print(f"Unknown interview problem: {arg!r} (available: {sorted(INTERVIEW_TESTS.keys())})")
        if nums:
            run(nums, PROBLEM_TESTS)
        if interviews:
            run(interviews, INTERVIEW_TESTS)
