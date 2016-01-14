#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX (234256000+20000)


char test[MAX];

int main(int argc, char *argv[]) {
  memset(test,0,sizeof(test));
  int i=0;
  int x;
  while(scanf("%d",&x) ) {
    test[x]++;
    if(test[x] > 1) {
      printf ("duplicated: %d\n",test[x]);
      exit(1);
    }
  }
}
