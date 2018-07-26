#include <stddef.h>
#include <limits.h>

#define STRING0(x) #x
#define STRING(x) STRING0(x) 

enum token_type
{
	INVALID,
	NUMBER,
	SPACE,
	OPERATOR
};

struct token
{
	enum token_type type;
	char text[2*sizeof STRING(LLONG_MAX)];
};

struct stack
{
	size_t size, nmemb, cap;
	void *p;
};

/* diagnostics */
void fail(char const *fmt, ...);
void syntax_error(char const *fmt, ...);
void unexpected(char const *token);

/* stack */
void stack_init(struct stack *s, size_t size);
void stack_term(struct stack *s);
void *stack_push(struct stack *s, void *data);
void stack_peek(void *dest, struct stack *s);
void stack_pop(void *dest, struct stack *s);
int stack_is_empty(struct stack *s);

/* parsing */
struct token read_token(char const **str);
struct stack shunt(char const *expr);

/* evaluation */
struct llrat eval(struct token *tokens, size_t n);
