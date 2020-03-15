package main

/*
#include <stdio.h>
#include <stdlib.h>

typedef char* (*callbkfn)(char*, char*);

extern char* munge_rubyishly(callbkfn fn, char* name, char* userdata);

char* munge_rubyishly(callbkfn fn, char* name, char* userdata) {
	printf("WISH ME LUCK");
  return fn(name, userdata);
}
*/
import "C"
import "fmt"

// because import "C" is uni-directional. So you can't export and define c
// functions in the same file. It's a little bonkers
// as per https://github.com/golang/go/issues/20639


func send_to_ruby(fp C.callbkfn, name *C.char, userdata *C.char) string {
  fmt.Println("Here goes nothin")
  foo := C.munge_rubyishly(fp, name, userdata)
  return C.GoString(foo)
}
