#include <stdio.h>
#include <stdlib.h>

#include "fizz.h"
#include "buzz.h"

int main(int argc, char *argv[])
{
	int i, n, v, max;

	max = argc > 1 ? atoi(argv[1]) : 100;

	for (i = 0; i < max; i++) {
		n = i + 1;
		v = fizz(n);
		v |= buzz(n);
		if (!v) printf("%d", n);
		putchar('\n');
	}

	return 0;
}
