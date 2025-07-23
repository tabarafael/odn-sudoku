package main

import "core:fmt"

// verifies a 4 dimentional vector against the sudoku rules
sudoku_validate :: proc(vector: [3][3][3][3]int, vector_size: int) -> Error_1 {
	expected_sum := get_triangule_number(vector_size)
	for v1 in 0 ..< vector_size {
		for v2 in 0 ..< vector_size {
			create_vecton :: proc() -> [3][3][3][3]int

			if got_sum := get_sum_a_b(vector, v1, v2); got_sum != expected_sum {
				return .bad_row
			}
			if got_sum := get_sum_x_y(vector, v1, v2); got_sum != expected_sum {
				return .bad_column
			}
			if got_sum := get_sum_y_b(vector, v1, v2); got_sum != expected_sum {
				return .bad_quadrant
			}
		}
	}
	return nil
}

//For a given xy, sums all ab - Visually those are the columns
get_sum_x_y :: proc(vector: [3][3][3][3]int, v1, v2: int) -> (total: int = 0) {
	for _, x in 0 ..< 3 {
		for y in 0 ..< 3 {
			total += int(vector[x][y][v1][v2])
		}
	}
	return
}

//For a given ab, sums all xy - Visually those are the rows
get_sum_a_b :: proc(vector: [3][3][3][3]int, v1, v2: int) -> (total: int = 0) {
	for _, a in 0 ..< 3 {
		for b in 0 ..< 3 {
			total += int(vector[v1][v2][a][b])
		}
	}
	return
}

//For a given yb, sums all xa - Visually those are the quadrants
get_sum_y_b :: proc(vector: [3][3][3][3]int, v1, v2: int) -> (total: int = 0) {
	for _, y in 0 ..< 3 {
		for b in 0 ..< 3 {
			total += int(vector[v1][y][v2][b])
		}
	}
	return
}


get_triangule_number :: proc(n: int) -> int {
	// math.pow is annoying to use damn
	t := n * n
	return t * (t + 1) / 2
}

print_array :: proc(arr: [3][3][3][3]int, depth: int = 0) {
	for x in arr {fmt.println("")
		for y in x {fmt.println(y)}
	}
}
