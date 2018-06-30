#include <stdlib.h>
#include <stdio.h>

#include "test/check.h"

extern struct check_test check_tests[];

int main(void)
{
	struct check_test *t;
	int res;

	for (t = check_tests; t->test && t->description; t++) {
		res = t->test();
		if (res != 0) {
			fprintf(stderr, "%s = %d\n", t->description, res);
			exit(EXIT_FAILURE);
		}
	}
	exit(EXIT_SUCCESS);
}
