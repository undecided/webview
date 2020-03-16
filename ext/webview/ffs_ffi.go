package main

/*
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef char* (*callbkfn)(char**, char*, char*);

extern char* bridge_to_ruby(callbkfn fn, char* name, char* userdata);

char* bridge_to_ruby(callbkfn fn, char* name, char* userdata) {
	char* output;
  fn(&output, name, userdata);
  return strdup(output);
}
*/
import "C"
import "fmt"
import "unsafe"

// because import "C" is uni-directional. So you can't export and define c
// functions in the same file. It's a little bonkers
// as per https://github.com/golang/go/issues/20639


func send_to_ruby(fp C.callbkfn, name *C.char, userdata *C.char) string {
  ruby_output := C.bridge_to_ruby(fp, name, userdata)
  fmt.Println("Return data: ", ruby_output)
  gostring_output := C.GoString(ruby_output)
  C.free(unsafe.Pointer(ruby_output))
  return gostring_output
}
