package main
import "core:math/rand"

Bag :: struct {
	size:  int,
	array: [SUDOKU_SIZE]int,
}

// creating a tetris bag
bag_new :: proc() -> (b: Bag) #no_bounds_check {
	#unroll for x in 0 ..< SUDOKU_SIZE {
		b.array[x] = x + 1
	}
	// fisher yates shuffle
	// it is backwards on purpose, and also doesn't act on the index 0
	for i := SUDOKU_SIZE - 1; i > 0; i -= 1 {
		j: int = int(rand.int31()) % SUDOKU_SIZE
		b.array[i], b.array[j] = b.array[j], b.array[i]
	}
	b.size = SUDOKU_SIZE // created full
	return
}

// very crude append
bag_append :: proc(bag: ^Bag, value: ^int) #no_bounds_check {
	// log.info("append")
	// log.info(bag)
	bag.array[bag.size] = value^
	bag.size += 1
	// log.info(bag)
}

//very unsafe pop
bag_pop_front :: proc(bag: ^Bag) -> (result: int) #no_bounds_check {
	// log.info("pop front")
	// log.info(bag)
	result = bag.array[0]
	if bag.size > 1 {
		copy(bag.array[0:], bag.array[1:])
	}
	bag.size -= 1
	bag.array[bag.size] = 0
	// log.info(bag)
	return
}
