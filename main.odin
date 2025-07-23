package main

import "core:fmt"

SUDOKU_SIZE :: 9
SIDE_SIZE :: 3

main :: proc() {
	sudoku_create()
}

sudoku_create :: proc() #no_bounds_check {
	full_backoff: for {
		full_backoff_lock: int = 10 // could use some fine tuning
		column_bag: [SIDE_SIZE][SIDE_SIZE]Bag
		quadrant_bag: [SIDE_SIZE][SIDE_SIZE]Bag

		// loops x and y are the index of the lines
		loop_line_x: for x := 0; x < SIDE_SIZE; x += 1 {
			loop_line_y: for y := 0; y < SIDE_SIZE; y += 1 {

				bag := bag_new()
				savepoint_column_bag := column_bag
				savepoint_quadrant_bag := quadrant_bag

				// loops a and b are the index of the columns
				loop_line_a: for a := 0; a < SIDE_SIZE; a += 1 {
					loop_line_b: for b := 0; b < SIDE_SIZE; b += 1 {

						// this loop will run until a legal value is found or xyab
						loop_over_bag: for loop_lock := bag.size; loop_lock >= 1; {

							for index in 0 ..< column_bag[a][b].size {
								if bag.array[0] == column_bag[a][b].array[index] {
									loop_lock -= 1
									bag_shuffle(&bag)
									continue loop_over_bag
								}
							}
							for index in 0 ..< quadrant_bag[x][a].size {
								if bag.array[0] == quadrant_bag[x][a].array[index] {
									loop_lock -= 1
									bag_shuffle(&bag)
									continue loop_over_bag
								}
							}
							add := bag_pop_front(&bag)
							bag_append(&column_bag[a][b], &add)
							bag_append(&quadrant_bag[x][a], &add)
							continue loop_line_b
						}
						// if the loop_lock is empty, that should mean we tried
						// all possible conbinations of that bag
						// so we go bag to retry another permutation
						full_backoff_lock -= 1
						if full_backoff_lock < 1 {
							// each retry, we give the full_backoff_lock another try
							// after so many retries, we might have an impossible to complete
							// board, so we need to start from zero again
							continue full_backoff
						}

						// load the savepoints so that no change during this iteration
						// affects the next one
						column_bag = savepoint_column_bag
						quadrant_bag = savepoint_quadrant_bag
						y -= 1 // give back the round

						continue loop_line_y // jump way back
					}
				}
			}
		}

		#force_inline print_sudoku(column_bag)
		break
	}
}

print_sudoku :: proc(bag: [3][3]Bag) #no_bounds_check {
	#unroll for k in 0 ..< 3 {
		#unroll for i in 0 ..< 3 {
			fmt.println(bag[k][i].array)
		}
	}
}
