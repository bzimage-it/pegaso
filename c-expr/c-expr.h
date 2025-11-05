#define DBL_MAX 1.79769313486231571e+308
#define EPSILON 1e-10

#define GMX_F_PI_4 0.7853984832763671875

#define DUMP_64(x) printf("%s [64] S= %20ld U= %20lu X= %16lx\n",TOSTRING(x),x,x,x)
#define DUMP_32(x) printf("%s [32] S= %10d  U= %10u  X= %8x\n",TOSTRING(x),x,x,x)
#define DUMP_16(x) printf("%s [16] S= %10hd  U= %10hu  X= %4x\n",TOSTRING(x),x,x,x)
#define DUMP_8(x)  printf("%s  [8] S= %3d  U= %3u X= %2x\n",TOSTRING(x),x,x,x)


#include "IEEE_754_types.h"
