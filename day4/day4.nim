import os
import unicode

const XMAS = "XMAS"
const MAS = "MAS"

proc find_word(lines: seq[string], word: string, start_row: int, start_col: int, delta_row: int, delta_col: int): int =
    for i, c in word:
        let row = start_row + delta_row * i
        let col = start_col + delta_col * i
        if row < 0 or col < 0 or row >= len(lines) or col >= len(lines[row]): return 0
        if lines[row][col] != c: return 0
    return 1

proc count_xmas(lines: seq[string]): int =
    var count = 0
    for row, line in lines:
        for col, char in line:
            if char != 'X': continue
            count += find_word(lines, XMAS, row, col, 1, 0)
            count += find_word(lines, XMAS, row, col, -1, 0)
            count += find_word(lines, XMAS, row, col, 0, 1)
            count += find_word(lines, XMAS, row, col, 0, -1)

            count += find_word(lines, XMAS, row, col, 1, 1)
            count += find_word(lines, XMAS, row, col, -1, -1)
            count += find_word(lines, XMAS, row, col, -1, 1)
            count += find_word(lines, XMAS, row, col, 1, -1)
    return count

proc find_diag_mas(lines: seq[string], word: string, center_row: int, center_col: int, delta_row: int, delta_col: int): int =
    let start_row = center_row - delta_row
    let start_col = center_col - delta_col
    return find_word(lines, word, start_row, start_col, delta_row, delta_col) or find_word(lines, word.reversed, start_row, start_col, delta_row, delta_col)



proc count_mas(lines: seq[string]): int =
    var count = 0
    for row, line in lines:
        for col, char in line:
            if char != 'A': continue
            count += find_diag_mas(lines, MAS, row, col, -1, 1) and find_diag_mas(lines, MAS, row, col, 1, 1)
    return count


proc read(): seq[string] =
    var lines: seq[string]
    for line in lines(stdin):
        lines.add line
    return lines

proc solve_part1(lines: seq[string]): int =
    return count_xmas(lines)

proc solve_part2(lines: seq[string]): int =
    return count_mas(lines)

proc main() =
    let lines = read()
    echo solve_part2(lines)
main()

