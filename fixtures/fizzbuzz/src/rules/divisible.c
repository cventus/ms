#include <stdio.h>

#include "divisible.h"

int divisible(int n, int divisor, char const *msg)
{
	return (n % divisor == 0) ? fputs(msg, stdout) : 0;
}
