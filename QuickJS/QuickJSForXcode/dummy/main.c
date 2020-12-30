//
//  main.c
//  dummy
//
//  Created by ming on 2020/11/18.
//

#include <stdio.h>
#include <string.h>
#include "quickjs.h"
#include "quickjs-libc.h"

int main(int argc, const char * argv[]) {
    // insert code here...
    JSRuntime *rt = JS_NewRuntime();
    JSContext *ctx = JS_NewContext(rt);
    // for console.log()
    js_std_add_helpers(ctx, 0, NULL);
    
    // system modules (optional)
    js_init_module_std(ctx, "std");
    js_init_module_os(ctx, "os");
    
    // eval js script string
    const char *scripts = "console.log('hello quickjs')";
    JS_Eval(ctx, scripts, strlen(scripts), "main", 0);
    printf("Hello, World!\n");
    return 0;
}
