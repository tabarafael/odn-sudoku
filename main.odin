#+feature dynamic-literals
// remove dynamics
package main
import "core:bytes"
import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:mem"
import "core:time"

SUDOKU_SIZE :: 9
SIZE :: 3
_ :: mem

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
Error :: union #shared_nil {
	Error_1,
	Error_2,
}
Error_1 :: enum {
	none,
	bad_row,
	bad_column,
	bad_quadrant,
}
Error_2 :: enum {
	none,
	eseese,
}

Logger_Opts :: log.Options{.Level, .Terminal_Color} | log.Full_Timestamp_Opts

main :: proc() {
	// later we can run with many different sizes
	logger := log.create_console_logger(opt = Logger_Opts)
	defer log.destroy_console_logger(logger)
	context.logger = logger

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)

		context.allocator = mem.tracking_allocator(&track)
		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	do_magic(3)
}

do_magic :: proc(size: int) {
	v := create_vector()
	if err := verify_vector(v, 3); err != .none {
		fmt.println(err)
	}
}

create_vector :: proc() -> [3][3][3][3]int {
	full_backoff: for {
		full_backoff_lock: int = 500
		v := [SIZE][SIZE][SIZE][SIZE]int{}
		column_bag: [SIZE][SIZE][SUDOKU_SIZE]int
		quadrant_bag: [SIZE][SIZE][SUDOKU_SIZE]int
		size_column_bag: [SIZE][SIZE]int
		size_quadrant_bag: [SIZE][SIZE]int

		loop_line_x: for x := 0; x < SIZE; x += 1 {
			loop_line_y: for y := 0; y < SIZE; y += 1 {
				log.info("resetting bags")
				savepoint_v := v
				bag, size_bag := new_bag()
				savepoint_column_bag := column_bag
				savepoint_quadrant_bag := quadrant_bag
				savepoint_size_column_bag := size_column_bag
				savepoint_size_quadrant_bag := size_quadrant_bag

				loop_line_a: for a := 0; a < SIZE; a += 1 {
					loop_line_b: for b := 0; b < SIZE; b += 1 {
						loop_lock := SUDOKU_SIZE + 1
						loop_over_bag: for {
							// time.sleep(time.Second * 1)
							log.info("inside loop over bag")
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

							log.info(bag)
							add := pop_front(&bag, &size_bag)
							for stashed in column_bag[a][b] {
								if add == stashed {
									loop_lock -= 1
									append(&bag, &add, &size_bag)
									continue loop_over_bag
								}
							}
							for stashed in quadrant_bag[x][a] {
								if add == stashed {
									loop_lock -= 1
									append(&bag, &add, &size_bag)
									continue loop_over_bag
								}
							}
							v[x][y][a][b] = add
							append(&column_bag[a][b], &add, &size_column_bag[a][b])
							append(&quadrant_bag[x][a], &add, &size_quadrant_bag[x][a])
							continue loop_line_b
						}
					}
				}
			}
		}

		print_array(v)
		return v
	}
}


/*

here on are sudoku checker

*/
// verifies a 4 dimentional vector against the rules
verify_vector :: proc(vector: [3][3][3][3]int, vector_size: int) -> Error_1 {
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

// array manipulation

// very crude append
append :: proc(array: ^[SUDOKU_SIZE]int, value: ^int, size: ^int) #no_bounds_check {
	log.info("append size:", size^, "value:", value^)
	log.info(array)
	array^[size^] = value^
	size^ += 1
	log.info(array)
}

//very unsafe pop
pop_front :: proc(array: ^[SUDOKU_SIZE]int, size: ^int) -> (result: int) #no_bounds_check {
	// log.info("pop front- size:", size^)
	// log.info(array)
	result = array[0]
	if size^ > 1 {
		copy(array[0:], array[1:])
	}
	size^ -= 1
	array[size^] = 0
	// log.info(array)
	return
}

// creating a tetris bag
new_bag :: proc() -> (b: [SUDOKU_SIZE]int, size: int = SUDOKU_SIZE) #no_bounds_check {
	#unroll for x in 0 ..< SUDOKU_SIZE {
		b[x] = x + 1
	}
	// fisher yates shuffle
	// it is backwards on purpose, and also doesn't act on the index 0
	for i := SUDOKU_SIZE - 1; i > 0; i -= 1 {
		j: int = int(rand.int31()) % SUDOKU_SIZE
		b[i], b[j] = b[j], b[i]
	}
	return
}
