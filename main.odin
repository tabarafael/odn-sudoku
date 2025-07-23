package main

import "core:fmt"
import "core:mem"

SUDOKU_SIZE :: 9
SIDE_SIZE :: 3
_ :: mem

main :: proc() {
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

	sudoku_create()
}

sudoku_create :: proc() #no_bounds_check {
	full_backoff: for {
		full_backoff_lock: int = 10 // could use some fine tuning
		column_bag: [SIDE_SIZE][SIDE_SIZE]Bag
		quadrant_bag: [SIDE_SIZE][SIDE_SIZE]Bag

		loop_line_x: for x := 0; x < SIDE_SIZE; x += 1 {
			loop_line_y: for y := 0; y < SIDE_SIZE; y += 1 {

				bag := bag_new()
				savepoint_column_bag := column_bag
				savepoint_quadrant_bag := quadrant_bag

				loop_line_a: for a := 0; a < SIDE_SIZE; a += 1 {
					loop_line_b: for b := 0; b < SIDE_SIZE; b += 1 {
						loop_over_bag: for loop_lock := SUDOKU_SIZE + 1; loop_lock >= 1; {

							for stashed in column_bag[a][b].array {
								if bag.array[0] == stashed {
									loop_lock -= 1
									bag_shuffle(&bag)
									continue loop_over_bag
								}
							}
							for stashed in quadrant_bag[x][a].array {
								if bag.array[0] == stashed {
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
						full_backoff_lock -= 1
						if full_backoff_lock < 1 {
							fmt.eprintln("engaging full backoff")
							continue full_backoff
						}
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
