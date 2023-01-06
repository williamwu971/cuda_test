//
// Created by Xiaoxiang Wu on 2022/5/14.
//

#ifndef COMP5426A2_ASM_H
#define COMP5426A2_ASM_H

#include <sys/time.h>
#include <time.h>
#include <omp.h>

//#define USEOMP
//#define NOUNROLLING
//#define DEBUG

#ifdef USEOMP
#include <omp.h>
#define OMP_NUM_THREAD 4
#endif

#define die(msg, args...) \
   do {                         \
      fprintf(stderr,"(%s,%d,%s) " msg "\n", __FUNCTION__ , __LINE__,strerror(errno), ##args); \
      fflush(stderr);fflush(stdout); \
      exit(-1); \
   } while(0)

#define declare_timer u_int64_t elapsed; \
   struct timeval st, et;

#define start_timer do { \
    gettimeofday(&st,NULL); \
} while(0);


#define stop_timer do { \
   gettimeofday(&et,NULL); \
   elapsed = ((et.tv_sec - st.tv_sec) * 1000000) + (et.tv_usec - st.tv_usec) + 1; \
} while(0);

//void my_printf(const char *fmt, ...) {
//    va_list args;
//    va_start(args, fmt);
//    printf(fmt, args);
//    va_end(args);
//}
//
//void my_puts(const char *fmt) {
//    puts(fmt);
//}
//
//#define printf(...) my_printf(__VA_ARGS__)
//#define puts(...) my_puts(__VA_ARGS__)
#endif //COMP5426A2_ASM_H
