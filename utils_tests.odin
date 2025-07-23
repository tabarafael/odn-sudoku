package main

import "core:testing"

TEST_SOLVED_SUDOKU :: [3][3][3][3]int {
	{
		{{7, 3, 5}, {6, 1, 4}, {8, 9, 2}},
		{{8, 4, 2}, {9, 7, 3}, {5, 6, 1}},
		{{9, 6, 1}, {2, 8, 5}, {3, 7, 4}},
	},
	{
		{{2, 8, 6}, {3, 4, 9}, {1, 5, 7}},
		{{4, 1, 3}, {8, 5, 7}, {9, 2, 6}},
		{{5, 7, 9}, {1, 2, 6}, {4, 3, 8}},
	},
	{
		{{1, 5, 7}, {4, 9, 2}, {6, 8, 3}},
		{{6, 9, 4}, {7, 3, 8}, {2, 1, 5}},
		{{3, 2, 8}, {5, 6, 1}, {7, 4, 9}},
	},
}

@(test)
test_sudoku_validator :: proc(t: ^testing.T) {
	err := sudoku_validate(TEST_SOLVED_SUDOKU, 3)
	testing.expect(t, err == .none, "sudoku validate is not able to verify a solved puzzle")
}

@(test)
test_sum_a_b :: proc(t: ^testing.T) {
	total := get_sum_a_b(TEST_SOLVED_SUDOKU, 0, 0)
	testing.expect(t, total == 45, "sum_a_b is unable to get proper count")
}

@(test)
test_sum_x_y :: proc(t: ^testing.T) {
	total := get_sum_x_y(TEST_SOLVED_SUDOKU, 0, 0)
	testing.expect(t, total == 45, "sum_x_y is unable to get proper count")
}

@(test)
test_sum_y_b :: proc(t: ^testing.T) {
	total := get_sum_y_b(TEST_SOLVED_SUDOKU, 0, 0)
	testing.expect(t, total == 45, "sum_y_b is unable to get proper count")
}
