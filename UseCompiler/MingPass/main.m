#include <stdio.h>

int main(void) {
  int i;
  scanf("%i", &i);
  printf("%i\n", i + 2);
}

void swap(int x, int y) {
  int temp;
  temp = x;
  x = y;
  y = temp;
}

void func1(void) {
}

void func2(void) {
}

void counter(void) {
  static int count = 1;
  printf("%d\n", count);
  count++;
}