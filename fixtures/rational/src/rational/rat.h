#include "gen.h"

/* begin public rat.h */


/* rational number (z*b + a)/b, 0 ≤ a < b */
struct PREFIX(rat)
{
	TYPE z;
	UTYPE q;
};

/* find the closest representation of z + a/b */
struct PREFIX(rat)
MANGLE(make)(TYPE z, TYPE a, TYPE b);

/* extract the encoded rational number into z + a/b form */
void
MANGLE(get)(struct PREFIX(rat), TYPE *z, TYPE *a, TYPE *b);

/* compare */
int
MANGLE(cmp)(struct PREFIX(rat), struct PREFIX(rat));

/* add */
struct PREFIX(rat)
MANGLE(add)(struct PREFIX(rat), struct PREFIX(rat));

/* subtract */
struct PREFIX(rat)
MANGLE(sub)(struct PREFIX(rat), struct PREFIX(rat));

/* multiply */
struct PREFIX(rat)
MANGLE(mul)(struct PREFIX(rat), struct PREFIX(rat));

/* divide */
struct PREFIX(rat)
MANGLE(div)(struct PREFIX(rat) dividend, struct PREFIX(rat) divisor);

/* sign (-1, 0, 1) of (z*b + a)/b */
int
MANGLE(sign)(struct PREFIX(rat));

/* unsigned quotient of "(z*b + a)/b" (i.e. z) */
UTYPE
MANGLE(quot)(struct PREFIX(rat));

/* remainder of "(z*b + a)/b" (i.e. a if z >= 0, b - a otherwise) */
UTYPE
MANGLE(rem)(struct PREFIX(rat));

/* denominator of "(z*b + a)/b" (i.e. b) */
UTYPE
MANGLE(denom)(struct PREFIX(rat));

/* create a string like z, -a/b, z+a/b or -z-a/b, return expected size of
   buffer (excluding string null terminator) */
size_t
MANGLE(string)(char *dest, size_t size, struct PREFIX(rat));

/* end public rat.h */
