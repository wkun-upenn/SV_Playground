def check_brackets(s):
    stack = []
    pairs = {')': '(', '}': '{', ']': '['}
    count = {'()': 0, '{}': 0, '[]': 0}
    
    for c in s:
        if c in '({[':
            stack.append(c)
        elif c in ')}]':
            if not stack or stack[-1] != pairs[c]:
                return "Error"
            open_br = stack.pop()
            if open_br == '(':
                count['()'] += 1
            elif open_br == '{':
                count['{}'] += 1
            else:
                count['[]'] += 1
    
    if stack:
        return "Error"
    return count