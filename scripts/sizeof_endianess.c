#include <stdio.h>

#define CR() printf("\n");
#define OFFSET(ident,offset) ( (int) (((char *)&ident)[offset] ))

#define PSIZE(type)     printf("%-13s | %2ld\n",#type,sizeof(type))

#define IS_EQ(x,offset,value) ( OFFSET(x,offset) == value )

#define ENDIANESS_PRINT(cond_little,cond_big) do { \
	if( cond_little) { \
			printf("little"); \
	}else if( cond_big ) { \
			printf("big endian"); \
	}else { \
			printf("mixed/unknown"); \
	} \
}while(0)

#define ENDIANESS(type) do { \
        if(sizeof(type) == 4) { \
		type x = (type) 0x01020304U; \
		printf("%02d %02d %02d %02d             | ", OFFSET(x,0) , OFFSET(x,1), OFFSET(x,2) , OFFSET(x,3)); \
		ENDIANESS_PRINT( IS_EQ(x,0,0x4) && IS_EQ(x,1,0x3) && IS_EQ(x,2,0x2) && IS_EQ(x,3,0x1), \
				  IS_EQ(x,0,0x1) && IS_EQ(x,1,0x2) && IS_EQ(x,2,0x3) && IS_EQ(x,3,0x4) ); \
	} \
        if(sizeof(type) == 2) { \
		type x = (type) 0x0102U; \
		printf("%02d %02d                   | ", OFFSET(x,0) , OFFSET(x,1) ); \
		ENDIANESS_PRINT( IS_EQ(x,0,0x2) && IS_EQ(x,1,0x1) , \
				 IS_EQ(x,0,0x1) && IS_EQ(x,1,0x2) ); \
	} \
	if(sizeof(type) == 8) { \
		type x = (type) 0x0102030405060708UL; \
		printf("%02d %02d %02d %02d %02d %02d %02d %02d | ", OFFSET(x,0) , OFFSET(x,1) , OFFSET(x,2) , OFFSET(x,3), OFFSET(x,4) , OFFSET(x,5) , OFFSET(x,6) , OFFSET(x,7) ); \
		ENDIANESS_PRINT(  IS_EQ(x,0,0x8) && IS_EQ(x,1,0x7) && IS_EQ(x,2,0x6) && IS_EQ(x,3,0x5) && IS_EQ(x,4,0x4) && IS_EQ(x,5,0x3) && IS_EQ(x,6,0x2) && IS_EQ(x,7,0x1) , \
				  IS_EQ(x,0,0x1) && IS_EQ(x,1,0x2) && IS_EQ(x,2,0x3) && IS_EQ(x,3,0x4) && IS_EQ(x,4,0x5) && IS_EQ(x,5,0x6) && IS_EQ(x,6,0x7) && IS_EQ(x,7,0x8) ); \
	} \
	if(sizeof(type) == 1) { printf("-                       | -"); } \
}while(0);

#define PSIZE_S_U(type) do { \
    printf("%-13s | %2ld      |     %2ld     | ",#type,sizeof(type),sizeof(unsigned type) ); \
    ENDIANESS(unsigned type); \
    CR(); \
} while(0);


int main()
{ 
  printf("INTEGER TYPE  | signed  |  unsigned  | 0x010203...             | Endianess\n");
  printf("--------------+---------+------------+-------------------------+--------------\n");
  PSIZE_S_U(int);
  PSIZE_S_U(char);
  PSIZE_S_U(short);
  PSIZE_S_U(long int);
  PSIZE_S_U(long long int);
  printf("--------------+---------+------------+-------------------------+--------------\n");
  printf("FLOATING POINT| size    |\n");
  printf("--------------+---------+\n");
  PSIZE(float);
  PSIZE(double);
  PSIZE(long double);
  CR();
} 
