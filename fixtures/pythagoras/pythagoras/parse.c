#include <stdlib.h>
#include <limits.h>
#include <errno.h>

#include "pythagoras.h"

int parse(char const *str, double *output)
{
	double x;
	char *endp;

	errno = 0;
	x = strtod(str, &endp);
	if (errno || *endp != '\0') return -1;
	*output = x;
	return 0;
}
