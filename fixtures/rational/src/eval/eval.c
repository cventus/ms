#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <assert.h>

#include "rational.h"
#include "eval.h"

struct llrat eval(struct token *tokens, size_t n)
{
	struct token *t;
	struct stack s;
	long long ll;
	struct llrat a, b, c;
	size_t i;

	stack_init(&s, sizeof a);

	for (i = 0; i < n; i++) {
		t = tokens + i;
		if (t->type == NUMBER) {
			ll = strtoll(t->text, NULL, 10);
			if (errno) {
				fail("number out of range: %s\n", t->text);
			}
			a = llrat_make(ll, 0LL, 1LL);
			if (!stack_push(&s, &a)) { abort(); }
			continue;
		} else {
			assert(t->type == OPERATOR);
		}
		stack_pop(&b, &s);
		stack_pop(&a, &s);
		switch (*t->text) {
		case '+': c = llrat_add(a, b); break;
		case '-': c = llrat_sub(a, b); break;
		case '*': c = llrat_mul(a, b); break;
		case '/': c = llrat_div(a, b); break;
		default: abort();
		}
		if (!stack_push(&s, &c)) { abort(); }
	}
	stack_pop(&a, &s);
	assert(stack_is_empty(&s));
	return a;
}
