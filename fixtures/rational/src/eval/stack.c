#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "eval.h"

void stack_init(struct stack *s, size_t size)
{
	assert(s != NULL);
	assert(size > 0);
	s->size = size;
	s->nmemb = s->cap = 0;
	s->p = 0;
}

void stack_term(struct stack *s)
{
	assert(s != NULL);
	free(s->p);
}

void *stack_push(struct stack *s, void *data)
{
	assert(s != NULL);
	if (s->cap == s->nmemb) {
		size_t ncap = s->cap ? 2*s->cap : 8;
		void *q = realloc(s->p, ncap * s->size);
		if (!q) { return NULL; }
		s->cap = ncap;
		s->p = q;
	}
	void *p = (char *)s->p + s->size * s->nmemb++;
	if (data) { memcpy(p, data, s->size); }
	return p;
}

void stack_peek(void *dest, struct stack *s)
{
	assert(s != NULL);
	assert(!stack_is_empty(s));
	memcpy(dest, (char *)s->p + s->size * (s->nmemb - 1), s->size);
}

void stack_pop(void *dest, struct stack *s)
{
	assert(s != NULL);
	assert(!stack_is_empty(s));
	stack_peek(dest, s);
	s->nmemb--;
}

int stack_is_empty(struct stack *s)
{
	assert(s != NULL);
	return s->nmemb == 0;
}
