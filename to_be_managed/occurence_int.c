#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef MAX
#define MAX 234256000UL
#endif

#define SIZE (MAX+20000)


unsigned char test[MAX];

int main(int argc, char *argv[]) {
  printf("BUFFER SIZE: %lu | %lu\n",MAX,sizeof(test));
  memset(test,0,sizeof(test));
  unsigned long int x;
  while(scanf("%lu\n",&x) == 1) {
    // printf("> %d\n",x);
    test[x]++;
    if(x>=MAX) {
	printf("out of MAX: %lu\n",x);
	exit(2);
    }
    if(test[x] > 1) {
      printf ("duplicated %lu : %d\n",x,test[x]);
      exit(1);
    }
  }
}
