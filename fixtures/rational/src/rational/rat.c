/* A compact rational number representation based on the Stern-Brocot tree
 *
 * The Stern-Brocot tree is a binary tree that contains all positive rational
 * numbers, such that each rational number occurs only once and in its most
 * simplified form. Nodes in the tree are defined by two rational numbers
 * r = a/b and s = c/d, where r < s, and they have the following properties:
 *
 *  - key(Node(r, s)) = mediant(r, s) = mediant(a/b, c/d) = (a+c)/(b+d)
 *  - left(Node(r, s)) = Node(r, mediant(r, s))
 *  - right(Node(r, s)) = Node(mediant(r, s), s)
 *  - key(left(n)) < key(n)
 *  - key(right(n)) > key(n)
 *
 * The root node R is defined as Node(0/1, 1/0), where 0/1 is the canonical
 * zero and the improper fraction 1/0 stands for positive infinity. The keys of
 * the first four levels of the tree look as follows:
 *
 *   0/1                                                                 1/0
 *    :                                1/1                                :
 *    :                1/2              |              2/1                :
 *    :        1/3      |      2/3      |      3/2      |      3/1        :
 *    :    1/4  |  2/5  |  3/5  |  3/4  |  4/3  |  5/3  |  5/2  |  4/1    :
 *    :     :   :   :   :   :   :   :   :   :   :   :   :   :   :   :     :
 *
 * The tree can be used to uniqely map rational numbers to integers by
 * enumerating the nodes (which is a neat proof of the contability of
 * rationals). In theory, a single integer would be an ideal data-structure to
 * represent rational numbers. A common way to represent rational numbers is to
 * store the numerator and denominator as two independent integer fields. Such
 * a representation allows multiple bit patterns for the same number (e.g. n/n
 * and 0/n) and canonicalization might be necessary before comparisons,
 * undesirable fractions like n/0 can be expressed, and you also need to figure
 * out how to store the sign.
 *
 * In practice, while N bits can be used to represent 2^N different rational
 * numbers, they might not be rational numbers you care about. For instance, N
 * bits can only represent O(N) integers if e.g. 0 maps to 0/1, positive
 * integers enumerate the tree breadth first, and negative integers similarly.
 *
 * To the right of the root node you find numbers greater than one. They can be
 * expressed as z + a/b = (z*b + a)/b for some integer z and 0 ≤ a < b.  If the
 * integer z is stored separately and another (unsigned) integer q is used to
 * identify a rational number 0 ≤ a/b < 1 then we end up with a fixed point
 * representation that could be useful when the numerators are typically small
 * and the integer part needs to have a greater range. If an integer has N
 * bits, then a convenient mapping for q is to map zero to itself, and positive
 * integers to left(R) or its decendents which have a maximum depth of N+1 in
 * ascending order. Then 1/2 is found at 1<<(N-1), 2/3 at 1<<(N-1) | 1<<(N-3),
 * etc. Comparing numbers in this representation is easy, but arithmetic is
 * tedious, especially when z < 0.
 *
 * This file implements this toy rational number format for some integer type
 * defined in TYPE, with the unsigned equivalent in UTYPE.
 */

#include <stdlib.h>
#include <limits.h>
#include <assert.h>

#include "gen.h"
#include "rational.h"

typedef struct PREFIX(rat) rat;
struct fraction
{
	UTYPE num, denom;
};

static int fraction_cmp(struct fraction a, struct fraction b)
{
	UTYPE l, r;

	l = a.num*b.denom;
	r = b.num*a.denom;
	if (l < r) return -1;
	if (l > r) return 1;
	return 0;
}

static struct fraction mediant(struct fraction a, struct fraction b)
{
	return (struct fraction){ a.num + b.num, a.denom + b.denom };
}

static TYPE gcd(TYPE a, TYPE b)
{
	return b ? gcd(b, a % b) : a;
}

static TYPE lcm(TYPE a, TYPE b)
{
	return PREFIX(abs)(b * (a / gcd(a, b)));
}

rat MANGLE(make)(TYPE whole, TYPE numerator, TYPE denominator)
{
	rat result;
	UTYPE i, j;
	TYPE g;

	if (denominator == 0) { denominator = 1; }

	assert(numerator >= 0);
	assert(denominator > 0);
	assert(numerator < denominator);

        j = 0;
	if (numerator > 0) {
        	i = MAX_BIT;
		g = gcd(numerator, denominator);
		struct fraction target = { numerator/g, denominator/g };
		struct fraction lo = { 0, 1 }, hi = { 1, 1 };
        	do {
                	struct fraction mid = mediant(lo, hi);
                	int cmp = fraction_cmp(target, mid);
                	if (cmp == 0) {
                        	j |= i;
                        	break;
                	} else if (cmp < 0) {
                        	hi = mid;
                	} else {
                        	lo = mid;
                        	j |= i;
                	}
                	i >>= 1;
        	} while (i);
	}

	result.z = whole;
        result.q = j;

	return result;
}

void MANGLE(get)(rat r, TYPE *whole, TYPE *numerator, TYPE *denominator)
{
	*whole = r.z;
	if (r.q == 0) {
		*numerator = 0;
		*denominator = 1;
	} else {
		UTYPE j, k;
		struct fraction lo = { 0, 1 }, hi = { 1, 1 };

		for (j = 0, k = MAX_BIT; r.q != (j | k) && k > 0; k >>= 1) {
			if (r.q < (j | k)) {
				hi = mediant(lo, hi);
			} else {
				j |= k;
				lo = mediant(lo, hi);
			}
		}
		struct fraction mid = mediant(hi, lo);
		*numerator = mid.num;
		*denominator = mid.denom;
	}
}

int MANGLE(cmp)(rat lhs, rat rhs)
{
	if (lhs.z < rhs.z) { return -1; }
	if (lhs.z > rhs.z) { return 1; }
	if (lhs.q < rhs.q) { return -1; }
	if (lhs.q > rhs.q) { return 1; }
	return 0;
}

rat MANGLE(add)(rat lhs, rat rhs)
{
	TYPE z, s, c, a, b, u, v, denom, lnum, rnum, sum;

	MANGLE(get)(lhs, &z, &a, &b);
	MANGLE(get)(rhs, &s, &u, &v);

	denom = lcm(b, v);
	lnum = a*(denom/b);
	rnum = u*(denom/v);
	if (denom - rnum <= lnum) {
		c = 1;
		sum = lnum + rnum - denom;
	} else {
		c = 0;
		sum = lnum + rnum;
	}

	return MANGLE(make)(z + s + c, sum, denom);
}

rat MANGLE(sub)(rat lhs, rat rhs)
{
	TYPE z, s, c, a, b, u, v, denom, lnum, rnum, diff;

	MANGLE(get)(lhs, &z, &a, &b);
	MANGLE(get)(rhs, &s, &u, &v);

	denom = lcm(b, v);
	lnum = a*(denom/b);
	rnum = u*(denom/v);
	if (rnum > lnum) {
		c = 1;
		diff = denom - rnum + lnum;
	} else {
		c = 0;
		diff = lnum - rnum;
	}

	return MANGLE(make)(s - z - c, diff, denom);
}

rat MANGLE(mul)(rat lhs, rat rhs)
{
	TYPE z, s, a, b, u, v, g, num, denom;
	PREFIX(div_t) dv;

	MANGLE(get)(lhs, &z, &a, &b);
	MANGLE(get)(rhs, &s, &u, &v);

	denom = b*v;
	num = z*b*u + s*a*v + (a*u);
	g = gcd(PREFIX(abs)(num), PREFIX(abs)(denom));
	num /= g;
	denom /= g;
	dv = PREFIX(div)(num, denom);
	if (dv.rem < 0) {
		dv.rem += denom;
		dv.quot--;
	}
	return MANGLE(make)(dv.quot, dv.rem, denom);
}

rat MANGLE(div)(rat dividend, rat divisor)
{
	TYPE z, s, a, b, u, v, num, denom, g;
	PREFIX(div_t) dv;

	MANGLE(get)(dividend, &z, &a, &b);
	MANGLE(get)(divisor, &s, &u, &v);

	num = v*(z*b + a);
	denom = b*(s*v + u);
	if (denom < 0) {
		num = -num;
		denom = -denom;
	}
	g = gcd(PREFIX(abs)(num), PREFIX(abs)(denom));
	num /= g;
	denom /= g;
	dv = PREFIX(div)(num, denom);
	if (dv.rem < 0) {
		dv.rem += denom;
		dv.quot--;
	}
	return MANGLE(make)(dv.quot, dv.rem, denom);
}

int MANGLE(sign)(struct PREFIX(rat) r)
{
	if (r.z < 0) return -1;
	if (r.z == 0 && r.q == 0) return 0;
	return 1;
}

UTYPE
MANGLE(quot)(struct PREFIX(rat) r)
{
	if (r.z < 0) {
		UTYPE borrow = r.q ? 0 : 1;
		/* support TYPE_MIN on 2's complement */
		return borrow + (UTYPE)-(r.z + 1);
	} else {
		return r.z;
	}
}

UTYPE
MANGLE(rem)(struct PREFIX(rat) r)
{
	TYPE z, a, b;
	MANGLE(get)(r, &z, &a, &b);
	if (z < 0) {
		return b - a;
	} else {
		return a;
	}
}

UTYPE
MANGLE(denom)(struct PREFIX(rat) r)
{
	TYPE z, a, b;
	MANGLE(get)(r, &z, &a, &b);
	return b;
}

size_t
MANGLE(string)(char *dest, size_t size, struct PREFIX(rat) r)
{
	char const *sign, *join;
	UTYPE quot, rem, denom;

	
	if (MANGLE(sign)(r) < 0) {
		sign = join =  "-";
	} else {
		sign = "";
		join = "+";
	}
	quot = MANGLE(quot)(r);
	rem = MANGLE(rem)(r);
	denom = MANGLE(denom)(r);

/* TYPE_PFX (i.e. "" int, "l" for long, and "ll" for long long), is the same
   as the interger format length specifier for int, long and long long, but is
   "j" for intmax_t, so to support it there would have to be another compile
   parameter */
#define F STRINGIFY(TYPE_PFX)
#define D "%" F "d"
#define U "%" F "u"

	if (rem == 0) {
		return snprintf(dest, size, D, r.z);
	} else if (quot == 0) {
		return snprintf(dest, size, "%s" U "/" U, sign, rem, denom);
	} else {
		return snprintf(dest, size, "%s" U "%s" U "/" U, sign, quot,
		                join, rem, denom);
	}
}
