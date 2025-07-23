#+feature dynamic-literals
// remove dynamics
package main
import "core:bytes"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:time"

SUDOKU_SIZE :: 9
SIDE_SIZE :: 3
_ :: mem

Error :: union #shared_nil {
	Error_1,
}

Error_1 :: enum {
	none,
	bad_row,
	bad_column,
	bad_quadrant,
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
	if err := sudoku_validate(v, 3); err != .none {
		fmt.println(err)
	}
}

create_vector :: proc() -> [3][3][3][3]int {
	full_backoff: for {
		full_backoff_lock: int = 500
		v := [SIDE_SIZE][SIDE_SIZE][SIDE_SIZE][SIDE_SIZE]int{} // remove this V later
		column_bag: [SIDE_SIZE][SIDE_SIZE]Bag
		quadrant_bag: [SIDE_SIZE][SIDE_SIZE]Bag

		loop_line_x: for x := 0; x < SIDE_SIZE; x += 1 {
			loop_line_y: for y := 0; y < SIDE_SIZE; y += 1 {
				log.info("resetting bags")
				savepoint_v := v
				bag := bag_new()
				savepoint_column_bag := column_bag
				savepoint_quadrant_bag := quadrant_bag

				loop_line_a: for a := 0; a < SIDE_SIZE; a += 1 {
					loop_line_b: for b := 0; b < SIDE_SIZE; b += 1 {
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
							add := bag_pop_front(&bag)
							for stashed in column_bag[a][b].array {
								if add == stashed {
									loop_lock -= 1
									bag_append(&bag, &add)
									continue loop_over_bag
								}
							}
							for stashed in quadrant_bag[x][a].array {
								if add == stashed {
									loop_lock -= 1
									bag_append(&bag, &add)
									continue loop_over_bag
								}
							}
							v[x][y][a][b] = add
							bag_append(&column_bag[a][b], &add)
							bag_append(&quadrant_bag[x][a], &add)
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
