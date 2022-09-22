
// snippet from: https://stackoverflow.com/questions/240353/convert-a-preprocessor-token-to-a-string
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#define AT __FILE__ ":" TOSTRING(__LINE__)


/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   IEEE_754_types.h                                   :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: akharrou <akharrou@student.42.us.org>      +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2019/11/02 12:41:37 by akharrou          #+#    #+#             */
/*   Updated: 2019/12/24 19:04:35 by akharrou         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef IEEE_754_TYPES_H
# define IEEE_754_TYPES_H

/*
** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
**  Header(s).
*/

# include <stdint.h>

/*
** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
**  Macro(s).
*/

# define IS_BIG_ENDIAN (0)

/*
** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
**  IEEE 754 Standard Floating-Point Cases Summary
**
**                 ----------------------------
**                | sign | exponent | mantissa |
**   ------------------------------------------|
**  | +zero       |   0  |  all 0s  |  all 0s  |
**  |------------------------------------------|
**  | -zero       |   1  |  all 0s  |  all 0s  |
**  |------------------------------------------|
**  | +inf        |   0  |  all 1s  |  all 0s  |
**  |------------------------------------------|
**  | -inf        |   1  |  all 1s  |  all 0s  |
**  |------------------------------------------|
**  | nan -- QNaN |   /  |  all 1s  | 1X...XX  |
**  |------------------------------------------|
**  | nan -- SNaN |   /  |  all 1s  | 00...01  |
**  |             |      |          |     .    |
**  |             |      |          |     .    |
**  |             |      |          | 01...11  |
**  |------------------------------------------|
**  | +subnormal  |   0  |  all 0s  | 00...01  |
**  |             |      |          |     .    |
**  |             |      |          |     .    |
**  |             |      |          | 11...11  |
**  |------------------------------------------|
**  | -subnormal  |   1  |  all 0s  | 00...01  |
**  |             |      |          |     .    |
**  |             |      |          |     .    |
**  |             |      |          | 11...11  |
**  |------------------------------------------|
**  | +normal     |   0  |  00...01 | XX...XX  |
**  |             |      |      .   |          |
**  |             |      |      .   |          |
**  |             |      |  11...10 |          |
**  |------------------------------------------|
**  | -normal     |   1  |  00...01 | XX...XX  |
**  |             |      |      .   |          |
**  |             |      |      .   |          |
**  |             |      |  11...10 |          |
**   ------------------------------------------
*/

/*
** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
**  Single Precision (float)  --  Standard IEEE 754 Floating-point Specification
*/

# define IEEE_754_FLOAT_MANTISSA_BITS (23)
# define IEEE_754_FLOAT_EXPONENT_BITS (8)
# define IEEE_754_FLOAT_SIGN_BITS     (1)

# define IEEE_754_FLOAT_BIAS          ((1L << (IEEE_754_FLOAT_EXPONENT_BITS - 1)) - 1)  /* 2^{exponent_bits - 1} - 1 ; 127 */
# define IEEE_754_FLOAT_EXPONENT_MAX  ((1L << IEEE_754_FLOAT_EXPONENT_BITS) - 1)        /* 2^{exponent_bits} - 1     ; 255 */
# define IEEE_754_FLOAT_IMPLICIT_BIT  ((1UL << IEEE_754_FLOAT_MANTISSA_BITS))           /* 2^{mantissa_bits}         ; 8388607 */

# define IEEE_754_FLOAT_SUBNORMALS(exponent, mantissa) ((exponent == 0) && (mantissa >= 1 && mantissa <= ((1UL << IEEE_754_FLOAT_MANTISSA_BITS) - 1)))
# define IEEE_754_FLOAT_ZERO(exponent, mantissa)       ((exponent == 0) && (mantissa == 0))
# define IEEE_754_FLOAT_INF(exponent, mantissa)        ((exponent == IEEE_754_FLOAT_EXPONENT_MAX) && (mantissa == 0))
# define IEEE_754_FLOAT_NAN(exponent, mantissa)        ((exponent == IEEE_754_FLOAT_EXPONENT_MAX) && (mantissa != 0))

# if (IS_BIG_ENDIAN == 1)
    typedef union {
        float value;
        struct {
            int8_t   sign     : IEEE_754_FLOAT_SIGN_BITS;
            int16_t  exponent : IEEE_754_FLOAT_EXPONENT_BITS;
            uint32_t mantissa : IEEE_754_FLOAT_MANTISSA_BITS;
        };
    } IEEE_754_float;
# else
    typedef union {
        float value;
        struct {
            uint32_t mantissa : IEEE_754_FLOAT_MANTISSA_BITS;
            int16_t  exponent : IEEE_754_FLOAT_EXPONENT_BITS;
            int8_t   sign     : IEEE_754_FLOAT_SIGN_BITS;
        };
    } IEEE_754_float;
# endif

/*
** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
**  Double Precision (double) --  Standard IEEE 754 Floating-point Specification
*/

# define IEEE_754_DOUBLE_MANTISSA_BITS (52)
# define IEEE_754_DOUBLE_EXPONENT_BITS (11)
# define IEEE_754_DOUBLE_SIGN_BITS     (1)

# define IEEE_754_DOUBLE_BIAS          ((1L << (IEEE_754_DOUBLE_EXPONENT_BITS - 1)) - 1)  /* 2^{exponent_bits - 1} - 1 ; 1023 */
# define IEEE_754_DOUBLE_EXPONENT_MAX  ((1L << IEEE_754_DOUBLE_EXPONENT_BITS) - 1)        /* 2^{exponent_bits} - 1     ; 2047 */
# define IEEE_754_DOUBLE_IMPLICIT_BIT  ((1UL << IEEE_754_DOUBLE_MANTISSA_BITS))           /* 2^{mantissa_bits}         ; 4503599627370496 */

# define IEEE_754_DOUBLE_SUBNORMALS(exponent, mantissa) ((exponent == 0) && (mantissa >= 1 && mantissa <= ((1UL << IEEE_754_DOUBLE_MANTISSA_BITS) - 1)))
# define IEEE_754_DOUBLE_ZERO(exponent, mantissa)       ((exponent == 0) && (mantissa == 0))
# define IEEE_754_DOUBLE_INF(exponent, mantissa)        ((exponent == IEEE_754_DOUBLE_EXPONENT_MAX) && (mantissa == 0))
# define IEEE_754_DOUBLE_NAN(exponent, mantissa)        ((exponent == IEEE_754_DOUBLE_EXPONENT_MAX) && (mantissa != 0))

# if (IS_BIG_ENDIAN == 1)
    typedef union {
        double value;
	uint64_t uint64;
	int64_t  int64;
        struct {
            int8_t   sign     : IEEE_754_DOUBLE_SIGN_BITS;
            int16_t  exponent : IEEE_754_DOUBLE_EXPONENT_BITS;
            uint64_t mantissa : IEEE_754_DOUBLE_MANTISSA_BITS;
        };
    } IEEE_754_double;
# else
    typedef union {
        double value;
	uint64_t uint64;
	int64_t  int64;
	struct {
		uint32_t low;
		uint32_t high;
	};
	struct {
	    uint64_t umantissa : IEEE_754_DOUBLE_MANTISSA_BITS;
	    uint16_t uexponent : IEEE_754_DOUBLE_EXPONENT_BITS;
	    uint8_t  usign     : IEEE_754_DOUBLE_SIGN_BITS;
	};
        struct {
            uint64_t mantissa : IEEE_754_DOUBLE_MANTISSA_BITS;
            int16_t  exponent : IEEE_754_DOUBLE_EXPONENT_BITS;
            int8_t   sign     : IEEE_754_DOUBLE_SIGN_BITS;
        };
    } IEEE_754_double;
# endif

/*
** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
**  Extended Precision (long double)  --  Standard IEEE 754 Floating-point Specification
*/

# define IEEE_754_LDOUBLE_MANTISSA_BITS (63)
# define IEEE_754_LDOUBLE_EXPLICIT_BITS (1)
# define IEEE_754_LDOUBLE_EXPONENT_BITS (15)
# define IEEE_754_LDOUBLE_SIGN_BITS     (1)

# define IEEE_754_LDOUBLE_BIAS          ((1L << (IEEE_754_LDOUBLE_EXPONENT_BITS - 1)) - 1)  /* 2^{exponent_bits - 1} - 1 ; 16383 */
# define IEEE_754_LDOUBLE_EXPONENT_MAX  ((1L << IEEE_754_LDOUBLE_EXPONENT_BITS) - 1)        /* 2^{exponent_bits} - 1     ; 32767 */
# define IEEE_754_LDOUBLE_IMPLICIT_BIT  ((1UL << IEEE_754_LDOUBLE_MANTISSA_BITS))

# define IEEE_754_LDOUBLE_SUBNORMALS(exponent, mantissa) ((exponent == 0) && (mantissa >= 1 && mantissa <= ((1UL << IEEE_754_LDOUBLE_MANTISSA_BITS) - 1)))
# define IEEE_754_LDOUBLE_ZERO(exponent, mantissa)       ((exponent == 0) && (mantissa == 0))
# define IEEE_754_LDOUBLE_INF(exponent, mantissa)        ((exponent == IEEE_754_LDOUBLE_EXPONENT_MAX) && (mantissa == 0))
# define IEEE_754_LDOUBLE_NAN(exponent, mantissa)        ((exponent == IEEE_754_LDOUBLE_EXPONENT_MAX) && (mantissa != 0))

# if (IS_BIG_ENDIAN == 1)
    typedef union {
        long double value;
        struct {
            int8_t   sign     : IEEE_754_LDOUBLE_SIGN_BITS;
            int16_t  exponent : IEEE_754_LDOUBLE_EXPONENT_BITS;
            int16_t  explict  : IEEE_754_LDOUBLE_EXPLICIT_BITS;
            uint64_t mantissa : IEEE_754_LDOUBLE_MANTISSA_BITS;
        };
    } IEEE_754_ldouble;
# else
    typedef union {
        long double value;
        struct {
            uint64_t mantissa : IEEE_754_LDOUBLE_MANTISSA_BITS;
            int16_t  explict  : IEEE_754_LDOUBLE_EXPLICIT_BITS;
            int16_t  exponent : IEEE_754_LDOUBLE_EXPONENT_BITS;
            int8_t   sign     : IEEE_754_LDOUBLE_SIGN_BITS;
        };
    } IEEE_754_ldouble;
# endif

#endif /* IEEE_754_TYPES_H */


/* added by fabrizio sebasiani 2021-01-08 */

// coutformat = "%s | %g | %.17g | 0x%016llx | %.17g | %d"
// cfile.write(f'\tprintf("{coutformat}\\n","{e}",_r,_r,DOUBLE_2_HEX(_r), _m , _e );\n')

#define DECLARE_PRIVATE() double _r; int _e = 0; double _m;
#define D(_name,_value) IEEE_754_double _name; _name.value = _value
#define DUMP(v) _m = frexp(v.value,&_e); printf("%s |g %g %.17g 0x%016llx |m %.17g e %d | S=%d MANT=%ld 0x%lx EXP=%hd 0x%hx\n",TOSTRING(v),v.value,v.value,DOUBLE_2_HEX(v.value),_m,_e,(int8_t)v.sign,(uint64_t)v.mantissa,(uint64_t)v.mantissa,(int16_t)v.exponent,(int16_t)v.exponent)

/*
 * #define DBL_MAX 1.7976931348623157E+308
#define DBL_MIN -1.7976931348623157E+308
*/

#define DUMP_64(x) printf("%s [64] S= %20ld U= %20lu X= %16lx\n",TOSTRING(x),x,x,x)
#define DUMP_32(x) printf("%s [32] S= %10d  U= %10u  X= %8x\n",TOSTRING(x),x,x,x)
#define DUMP_16(x) printf("%s [16] S= %10hd  U= %10hu  X= %4x\n",TOSTRING(x),x,x,x)
#define DUMP_8(x)  printf("%s  [8] S= %3d  U= %3u X= %2x\n",TOSTRING(x),x,x,x)

#define MSG(_msg) printf("%s\n",_msg);
#define TITLE(_msg) printf("==========[ %-30s ]===========\n",_msg);

/* clear last ULP bit. n can be 1 or 2 ; */
#define CLEAR_ULP(v,ulp_n) do { v.umantissa &= (ulp_n==1 ? ~0x01 : (ulp_n == 2 ? ~0x03 : 0x0 )); } while(0)
#define CLEAR_ULP_XY(x,y,ulp_n) do { CLEAR_ULP(x,ulp_n); CLEAR_ULP(y,ulp_n); } while(0)


#define ASSERT_EQ(x,y) do {			\
    if((x) != (y)) {				\
       MSG("ASSERT_EQ FAILED are different:");	\
       DUMP_64((uint64_t)(x));			\
       DUMP_64((uint64_t)(y));			\
       DUMP_32((uint32_t)(x));			\
       DUMP_32((uint32_t)(y));			\
       DUMP_16((uint16_t)(x));			\
       DUMP_16((uint16_t)(y));			\
       /* exit(1); */				\
       return 1;				\
    }						\
  } while(0)


#define CLEAR_ULP_RAW(d,ulp_n) do { uint64_t *x=(uint64_t*) (void*) &d; *x &= (ulp_n==1 ? ~0x01 : (ulp_n == 2 ? ~0x03 : 0x0 )); } while(0)
#define CLEAR_ULP_RAW_XY(x,y,ulp_n) do { CLEAR_ULP_RAW(x,ulp_n); CLEAR_ULP_RAW(y,ulp_n); } while(0)

#define DECL_CASTED_2INT64(d,pointer) uint64_t *pointer=(uint64_t*) (void*) &d
#define DECL_CASTED_2DOUBLE(d,pointer) double *pointer=(double*) (void*) &d
#define SET_CASTED_DOUBLE2INT64(output_uint64_lvalue, input_double_lvalue) do { DECL_CASTED_2INT64(input_double_lvalue,p); output_uint64_lvalue=*p; } while(0)

#define GET_MANTISSA_AS_UINT64(_m,_double) do {	\
    DECL_CASTED_2INT64(_double,_v);		\
    /* extract mantissa: */			\
    _m = *_v & 0x000FFFFFFFFFFFFFUL;		\
  } while(0)

#define GET_SIGN_AS_UINT8(_s,_double) do {	\
    DECL_CASTED_2INT64(_double,_v);		\
    /* extract mantissa: */			\
    _s = (uint8_t) ( *_v >> 63);			\
  } while(0)

#define GET_EXP_AS_UINT16(_e,_double) do { \
    DECL_CASTED_2INT64(_double,_v);			     \
    /* extract exponent: */				     \
    _e = (uint16_t) ((*_v & 0x7FF0000000000000UL) >> 52);     \
  } while(0)

/* test the GET_XXX family macro agaist a struct x declared with D(x) */
#define TEST_GET(x) {					\
  uint64_t m; uint16_t e; uint8_t s;			\
  GET_MANTISSA_AS_UINT64(m,x.value);			\
  GET_EXP_AS_UINT16(e,x.value);				\
  GET_SIGN_AS_UINT8(s,x.value);				\
  ASSERT_EQ(x.usign, s);				\
  ASSERT_EQ(x.mantissa,m);				\
  ASSERT_EQ(x.uexponent,e);				\
} while(0)

/* function return bit differences in _nbits 
   _nbits shall be unsigned.
   ~0 is returned if exponent or sign are different

   this macro have been tested using:
 
   c-expr 'D(x,0);D(near,0); int i; int j; for(i=0;i<1000;i++) { x.uint64=mcg64(); near.value=x.value; for(j=0;j<10;j++) { near.value= nextafter(near.value,near.value+1); printf("i=%d j=%d\n",i,j); COMPARE(x,near); }; }; ' 

*/
#define ULP_DIFF(_nbits,_double_x,_double_y) do {			\
  /* extract raw mantissa from numbers: */				\
  uint64_t mx,my;							\
  uint16_t ex,ey;							\
  uint8_t  sx,sy;							\
  GET_MANTISSA_AS_UINT64(mx,_double_x);					\
  GET_MANTISSA_AS_UINT64(my,_double_y);					\
  GET_EXP_AS_UINT16(ex,_double_x);					\
  GET_EXP_AS_UINT16(ey,_double_y);					\
  GET_SIGN_AS_UINT8(sx,_double_x);					\
  GET_SIGN_AS_UINT8(sy,_double_y);					\
  if (ex!=ey || sx!=sy) {						\
    _nbits=~0; /* return 0xFFF... */					\
  }else{								\
    /* return difference: 0 means no diff, 1 or 2 are ok; >2 is bad */	\
    _nbits = mx>my ? mx-my : my-mx;					\
  }									\
  } while(0)


#define ULP_DIFF_STATEMENT(_res_ulp,_double_x,_double_y) \
  uint8_t _res_ulp;							\
  do {									\
    double xx = _double_x;						\
    double yy = _double_y;						\
    ULP_DIFF(_res_ulp,xx,yy);						\
  } while(0)
  

#define COMPARE(v1,v2) do { \
    TITLE("BEGIN COMPARISION");			 \
    DUMP(v1);DUMP(v2);				 \
    uint8_t n_ulp;					 \
    if(v1.value<v2.value) {			 \
      MSG("--> " TOSTRING(v1) " < " TOSTRING(v2));	\
    }else if(v1.value>v2.value) {			\
      MSG("--> "TOSTRING(v1) " > " TOSTRING(v2));	\
    }else{						\
      MSG("--> "TOSTRING(v1) " == " TOSTRING(v2));	\
    }							\
    ULP_DIFF(n_ulp,v1.value,v2.value);			\
    DUMP_8(n_ulp);						\
    TITLE("END COMPARISION");				\
  } while(0)

