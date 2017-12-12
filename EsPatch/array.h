//
//  util.h
//  EsPatch
//
//  Created by ChileungL on 2017/12/14.
//  Copyright © 2017年 ChileungL. All rights reserved.
//

typedef struct {
    int size;
    uint64_t elem[1];
}ARRAY;

ARRAY *arr_init(int size);
int arr_exist(ARRAY *arr,uint64_t v);
int arr_add(ARRAY *arr,uint64_t v);
void arr_zero(ARRAY *arr);

