#include <stdio.h>

#include "pythagoras.h"

int main(int argc, char *argv[])
{
	double a, b, c; 

	if (argc != 3 || parse(argv[1], &a) || parse(argv[2], &b)) {
		printf("usage: %s [x] [y]\n", argv[0]);
		return 1;
	} else {
		c = pythagoras(a, b);
		printf("sqrt(%g*%g + %g*%g) = %g\n", a, a, b, b, c);
		return 0;
	}
}
