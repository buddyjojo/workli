#include <stdio.h>
#include <stdlib.h>

int main()
{
  printf("Executing worklipe.cmd...");
  system("cmd /C X:\\worklipe.cmd");
  return 0;
}
 
//batchexec.exe was compiled with aarch64-w64-mingw32-gcc from https://github.com/xt-sys/xtchain
