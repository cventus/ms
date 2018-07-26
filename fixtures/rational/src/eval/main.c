#include <stdio.h>
#include <string.h>

#include "rational.h"
#include "eval.h"

int main(int argc, char *argv[])
{
	struct stack rpn;
	char *expr, *p, buf[512];
	size_t sz;
	int i;
	struct llrat rat;

	/* concatenate arguments */
	sz = argc;
	for (i = 1; i < argc; i++) {
		sz += strlen(argv[i]);
	}
	expr = malloc(sz);
	if (!expr) { abort(); }
	p = expr;
	for (i = 1; i < argc; i++) {
		sz = strlen(argv[i]);
		memcpy(p, argv[i], sz);
		p += sz;
		*p++ = ' ';
	}
	*p = '\0';

	rpn = shunt(expr);
	rat = eval(rpn.p, rpn.nmemb);
	stack_term(&rpn);
	llrat_string(buf, sizeof buf, rat);
	puts(buf);
	exit(EXIT_SUCCESS);
}
