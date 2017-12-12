//
//  util.c
//  EsPatch
//
//  Created by ChileungL on 2017/12/14.
//  Copyright © 2017年 ChileungL. All rights reserved.
//

#include <string.h>
#include <stdlib.h>
#include "array.h"

void arr_zero(ARRAY *arr) {
    int arr_size=arr->size;
    memset(arr,0,sizeof(ARRAY)+sizeof(uint64_t)*arr_size);
    arr->size=arr_size;
}

ARRAY *arr_init(int size) {
    ARRAY *arr=(void*)malloc(sizeof(ARRAY)+sizeof(uint64_t)*size);
    arr->size=size;
    arr_zero(arr);
    return arr;
}

int arr_exist(ARRAY *arr,uint64_t v) {
    int ret=0;
    for(int i=0;i<arr->size;++i){
        if(arr->elem[i]==v) {
            ret=1;
            break;
        }
    }
    return ret;
}

int arr_add(ARRAY *arr,uint64_t v) {
    int i;
    if(arr_exist(arr,v)) return 0;
    for(i=0;i<arr->size;++i) {
        if(arr->elem[i]==0) arr->elem[i]=v;
    }
    return i!=arr->size;
}
