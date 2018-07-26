#ifndef TYPE
#error "TYPE is not defined!"
#endif

#ifndef UTYPE
#error "UTYPE is not defined!"
#endif

#ifndef UTYPE_MAX
#error "UTYPE_MAX is not defined!"
#endif

#ifndef TYPE_PFX
#error "TYPE_PFX is not defined!"
#endif

#define MAX_BIT (UTYPE_MAX ^ (UTYPE_MAX >> 1))
#define CONCAT_(a, b) a ## b
#define CONCAT(a, b) CONCAT_(a, b)
#define PREFIX(name) CONCAT(TYPE_PFX, name)
#define MANGLE(name) CONCAT(PREFIX(rat_), name)
#define STRINGIFY_(x) #x
#define STRINGIFY(x) STRINGIFY_(x)
