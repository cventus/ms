#include <stdlib.h>
#include <string.h>
#include "eval.h"

struct token read_token(char const **str)
{
	char const *p;
	struct token t;
	size_t n;

	p = *str;
	t.text[1] = '\0';
	switch ((t.text[0] = *p)) {
	/* operators */
	case '+': case '-': case '*': case '/': case '(': case ')':
		t.type = OPERATOR;
		n = 1;
		break;

	/* white space */
	case ' ': case '\t': case '\n': case '\r': case '\v':
		t.type = SPACE;
		n = 1;
		break;

	default:
		n = strspn(p, "0123456789");
		if (n == 0 || n > sizeof t.text - 1) {
			/* something else */
			t.type = INVALID;
			n = 0;
		} else {
			/* number */
			t.type = NUMBER;
			memcpy(t.text + 1, p + 1, n - 1);
			t.text[n] = '\0';
		}
		break;
	}
	*str += n;
	return t;
}
