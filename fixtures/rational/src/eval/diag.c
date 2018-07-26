#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "eval.h"

void fail(char const *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	exit(EXIT_FAILURE);
}

void syntax_error(char const *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	fprintf(stderr, "syntax error: ");
	vfprintf(stderr, fmt, ap);
	fprintf(stderr, "\n");
	va_end(ap);
	exit(EXIT_FAILURE);
}

void unexpected(char const *token)
{
	syntax_error("unexpected ``%s''", token);
}
