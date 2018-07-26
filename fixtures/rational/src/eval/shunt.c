#include <stdlib.h>
#include <assert.h>
#include <limits.h>
#include <string.h>
#include <ctype.h>

#include "eval.h"

static void *alloc_guard(void *p)
{
	if (!p) { abort(); }
	return p;
}

static void save(struct token t, struct stack *ops)
{
	assert(ops != NULL);
	alloc_guard(stack_push(ops, &t));
}

static void output(struct token t, struct stack *rpn)
{
	assert(rpn != NULL);
	alloc_guard(stack_push(rpn, &t));
}

static int is_lparen(struct token t)
{
	assert(t.type == OPERATOR);
	return *t.text == '(';
}

static int is_left_assoc(struct token t)
{
	assert(t.type == OPERATOR);
	return *t.text == '/';
}

static int precedence(struct token t)
{
	assert(t.type == OPERATOR);
	switch (*t.text) {
	case '+': case '-': return 1;
	case '*': case '/': return 2;
	default: return 0;
	}
}

static int handle_operator(struct token t, struct stack *ops, struct stack *rpn)
{
	struct token u;

	switch (*t.text) {
	case '(': save(t, ops); break;

	case ')':
		while(1) {
			if (stack_is_empty(ops)) {
				syntax_error("unmatched parentheses");
			}
			stack_pop(&u, ops);
			if (is_lparen(u)) { break; }
			output(u, rpn);
		} 
		return 0;

	default:
		assert(strchr("+-*/", t.text[0]) != NULL);
		while (!stack_is_empty(ops)) {
			int pu, pt;

			stack_peek(&u, ops);
			if (is_lparen(u)) { break; }
			pu = precedence(u);
			pt = precedence(t);
			if (pu > pt || (pu == pt && is_left_assoc(u))) {
				stack_pop(&u, ops);
				output(u, rpn);
			} else {
				break;
			}
		}
		save(t, ops);
	}
	return 0;
}

static int next_token(char const **p, struct stack *ops, struct stack *rpn)
{
	struct token t;

	t = read_token(p);
	switch (t.type) {
	case SPACE:
		return 0;

	case INVALID:
		if (isdigit(*t.text)) {
			syntax_error("number %s is too big!", t.text);
		} else {
			syntax_error("bad token starting with ``%s''", t.text);
		}
		return -1;

	case NUMBER:
		output(t, rpn);
		return 0;

	case OPERATOR:
		return handle_operator(t, ops, rpn);
	}
	return -1;
}

struct stack shunt(char const *expr)
{
	char const *p;
	struct token t;
	struct stack ops, rpn;

	stack_init(&ops, sizeof(struct token));
	stack_init(&rpn, sizeof(struct token));

	p = expr;
	while (*p) {
		next_token(&p, &ops, &rpn);
	}
	while (!stack_is_empty(&ops)) {
		stack_pop(&t, &ops);
		if (is_lparen(t)) {
			syntax_error("unmatched parentheses");
		}
		output(t, &rpn);
	}
	stack_term(&ops);

	return rpn;
}
