class Solution(object):
    def longestConsecutive(self, nums):
        if not nums:
            return 0

        nums.sort()
        res = 1          # minimum answer for non-empty list is 1
        cur_length = 1   # first element counts as length 1

        for i in range(1, len(nums)):  # ← start at 1, not 0
            if nums[i] == nums[i-1] + 1:
                cur_length += 1
                res = max(res, cur_length)
            elif nums[i] == nums[i-1]:
                pass
            else:
                cur_length = 1

        return res