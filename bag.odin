package main
import "core:math/rand"

SUDOKU_SIZE :: 9

Bag :: struct {
	size:  u8,
	array: [SUDOKU_SIZE]u8,
}

// creating a tetris bag
// it is an array of a random permutation of numbers 1-9
bag_new :: proc() -> Bag #no_bounds_check {
	b := Bag {
		array = {1, 2, 3, 4, 5, 6, 7, 8, 9},
		size  = SUDOKU_SIZE, // created full
	}

	// fisher yates shuffle
	// it is backwards because we are using mod(i) to only switch
	// on the untouched values
	// and also doesn't act on the index 0
	// because the last switch will always be in place
	#no_bounds_check for i := SUDOKU_SIZE - 1; i > 0; i -= 1 {
		j: int = int(rand.int31()) % i
		b.array[i], b.array[j] = b.array[j], b.array[i]
	}
	return b
}

// very crude append
bag_append :: proc(bag: ^Bag, value: ^u8) #no_bounds_check {
	bag.array[bag.size] = value^
	bag.size += 1
}

bag_shuffle :: proc(bag: ^Bag) {
	if bag.size < 1 {
		return
	}
	value := bag.array[0]
	copy(bag.array[0:], bag.array[1:])
	bag.array[bag.size - 1] = value
}

//very unsafe pop
bag_pop_front :: proc(bag: ^Bag) -> (result: u8) #no_bounds_check {
	result = bag.array[0]
	if bag.size > 1 {
		copy(bag.array[0:], bag.array[1:])
	}
	bag.size -= 1
	return
}
