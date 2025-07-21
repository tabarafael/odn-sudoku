#+feature dynamic-literals
package main
import "core:bytes"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import "core:time"

// TB_3 :: [3][3][3][3]int {
// 	{
// 		{{7, 3, 5}, {6, 1, 4}, {8, 9, 2}},
// 		{{8, 4, 2}, {9, 7, 3}, {5, 6, 1}},
// 		{{9, 6, 1}, {2, 8, 5}, {3, 7, 4}},
// 	},
// 	{
// 		{{2, 8, 6}, {3, 4, 9}, {1, 5, 7}},
// 		{{4, 1, 3}, {8, 5, 7}, {9, 2, 6}},
// 		{{5, 7, 9}, {1, 2, 6}, {4, 3, 8}},
// 	},
// 	{
// 		{{1, 5, 7}, {4, 9, 2}, {6, 8, 3}},
// 		{{6, 9, 4}, {7, 3, 8}, {2, 1, 5}},
// 		{{3, 2, 8}, {5, 6, 1}, {7, 4, 9}},
// 	},
// }
bad_row :: struct {
	message: string,
	value:   int,
}
bad_column :: struct {
	message: string,
	value:   int,
}
bad_quadrant :: struct {
	message: string,
	value:   int,
}
Error :: union {
	bad_row,
	bad_column,
	bad_quadrant,
}

main :: proc() {
	// later we can run with many different sizes
	do_magic(3)

}
do_magic :: proc(size: int) {
	v := create_vector()
	if r, err := verify_vector(v, 3); !r {
		fmt.println(err)
	}
}

create_vector :: proc() -> [3][3][3][3]int {
	rounds: int = 0
	full_backoff: for {
		full_backoff_lock: int = 500
		size :: 3
		v := [size][size][size][size]int{}
		column_bag: [3][3][dynamic]int
		quadrant_bag: [3][3][dynamic]int

		loop_line_x: for x := 0; x < size; x += 1 {
			loop_line_y: for y := 0; y < size; y += 1 {
				bag := new_bag(9)
				savepoint_v := v
				savepoint_column_bag := column_bag
				savepoint_quadrant_bag := quadrant_bag

				loop_line_a: for a := 0; a < size; a += 1 {
					loop_line_b: for b := 0; b < size; b += 1 {
						loop_lock := size * size + 1

						loop_over_bag: for {
							rounds += 1
							if full_backoff_lock < 1 {
								fmt.println("engaging full backoff")
								continue full_backoff
							}
							if loop_lock < 1 {
								v = savepoint_v
								column_bag = savepoint_column_bag
								quadrant_bag = savepoint_quadrant_bag
								y -= 1 // give back the round
								continue loop_line_y // jump way back
							}

							add := pop_front(&bag)
							for stashed in column_bag[a][b] {
								if add == stashed {
									loop_lock -= 1
									append(&bag, add)
									continue loop_over_bag
								}
							}
							for stashed in quadrant_bag[x][a] {
								if add == stashed {
									loop_lock -= 1
									append(&bag, add)
									continue loop_over_bag
								}
							}
							v[x][y][a][b] = add
							append(&column_bag[a][b], add)
							append(&quadrant_bag[x][a], add)
							continue loop_line_b
						}
					}
				}
			}
		}

		fmt.println("rounds:", rounds)
		print_array(v)
		return v
	}
}

// creating a tetris bag
new_bag :: proc(size: int) -> [dynamic]int {
	b: [dynamic]int
	for x in 1 ..= size {
		append(&b, x)
	}
	// fisher yates shuffle
	for i := size - 1; i > 0; i -= 1 {
		j: int = int(rand.int31()) % size
		b[i], b[j] = b[j], b[i]
	}
	return b
}
/*

here on are sudoku checker

*/
// verifies a 4 dimentional vector against the rules
verify_vector :: proc(vector: [3][3][3][3]int, vector_size: int) -> (bool, Error) {
	expected_sum := get_triangule_number(vector_size)
	for v1 in 0 ..< vector_size {
		for v2 in 0 ..< vector_size {
			create_vecton :: proc() -> [3][3][3][3]int

			if got_sum := get_sum_a_b(vector, v1, v2); got_sum != expected_sum {
				buf: [4]byte
				return false, bad_row {
					message = strings.concatenate(
						{"bad row=", strconv.itoa(buf[:], v1 + (v2 * vector_size) + 1)},
					),
					value = got_sum,
				}
			}
			if got_sum := get_sum_x_y(vector, v1, v2); got_sum != expected_sum {
				buf: [4]byte
				return false, bad_column {
					message = strings.concatenate(
						{"bad column=", strconv.itoa(buf[:], v1 + (v2 * vector_size) + 1)},
					),
					value = got_sum,
				}
			}
			if got_sum := get_sum_y_b(vector, v1, v2); got_sum != expected_sum {
				buf: [4]byte
				return false, bad_quadrant {
					message = strings.concatenate(
						{"bad quadrant=", strconv.itoa(buf[:], v1 + (v2 * vector_size) + 1)},
					),
					value = got_sum,
				}
			}
		}
	}
	return true, nil
}

get_triangule_number :: proc(n: int) -> int {
	// math.pow is annoying to use damn
	t := n * n
	return t * (t + 1) / 2
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

print_array :: proc(arr: [3][3][3][3]int, depth: int = 0) {
	for x in arr {fmt.println("")
		for y in x {fmt.println(y)}
	}
}
