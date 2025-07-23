package main
import "core:log"

Bag :: struct {
	size:  int,
	array: [SUDOKU_SIZE]int,
}

// very crude append
bag_append :: proc(bag: ^Bag, value: ^int) #no_bounds_check {
	log.info("append")
	log.info(bag)
	bag.array[bag.size] = value^
	bag.size += 1
	log.info(bag)
}

//very unsafe pop
bag_pop_front :: proc(bag: ^Bag) -> (result: int) #no_bounds_check {
	log.info("pop front")
	log.info(bag)
	result = bag.array[0]
	if bag.size > 1 {
		copy(bag.array[0:], bag.array[1:])
	}
	bag.size -= 1
	bag.array[bag.size] = 0
	log.info(bag)
	return
}
