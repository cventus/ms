#include "sum.h"

int test_zero_plus_one_is_one(void)
{
	if (sum(0.0, 1.0) != 1.0) {
		return -1;
	}
	return 0;
}

int test_one_plus_one_is_two(void)
{
	if (sum(1.0, 1.0) != 2.0) {
		return -1;
	}
	return 0;
}

int test_zero_plus_zero_is_zero(void)
{
	if (sum(0.0, 0.0) != 0.0) {
		return -1;
	}
	return 0;
}
