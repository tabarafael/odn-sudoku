package main
import "core:math/rand"

Bag :: struct {
	size:  u8,
	array: [SUDOKU_SIZE]u8,
}

// creating a tetris bag
bag_new :: proc() -> (b: Bag) #no_bounds_check {
	#unroll for x in 0 ..< SUDOKU_SIZE {
		b.array[x] = u8(x + 1)
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
bag_append :: proc(bag: ^Bag, value: ^u8) #no_bounds_check {
	bag.array[bag.size] = value^
	bag.size += 1
}

//very unsafe pop
bag_pop_front :: proc(bag: ^Bag) -> (result: u8) #no_bounds_check {
	result = bag.array[0]
	if bag.size > 1 {
		copy(bag.array[0:], bag.array[1:])
	}
	bag.size -= 1
	bag.array[bag.size] = 0
	return
}
