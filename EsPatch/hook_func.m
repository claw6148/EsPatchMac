//
//  hook_func.m
//  EsPatch
//
//  Created by ChileungL on 2017/12/14.
//  Copyright © 2017年 ChileungL. All rights reserved.
//

#import "EsPatch.h"

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <hook.h>
#include "array.h"
/*
CFStringRef PrimarySvc;
CFStringRef PrimaryIP;
*/
char FakeIP[16]={0};
in_addr_t FakeIP_numeric;

ARRAY *arr_ptylist;
ARRAY *arr_dict;

typedef int(*t_getifaddrs)(struct ifaddrs **arg1);
typedef CFPropertyListRef(*t_SCDynamicStoreCopyValue)(SCDynamicStoreRef store,CFStringRef key);
typedef void*(*t_CFDictionaryGetValue)(CFDictionaryRef theDict, const void *key);
typedef void*(*t_CFArrayGetValueAtIndex)(CFArrayRef theArray, CFIndex idx);

t_getifaddrs Orig_getifaddrs;
t_SCDynamicStoreCopyValue Orig_SCDynamicStoreCopyValue;
t_CFDictionaryGetValue Orig_CFDictionaryGetValue;
t_CFArrayGetValueAtIndex Orig_CFArrayGetValueAtIndex;

void *Ptr_getifaddrs;
void *Ptr_SCDynamicStoreCopyValue;
void *Ptr_CFDictionaryGetValue;
void *Ptr_CFArrayGetValueAtIndex;

int My_getifaddrs(struct ifaddrs **arg1) {
    
    int Ret=Orig_getifaddrs(arg1);
    if(Ret==0) {
        struct ifaddrs *ifaddr=*arg1,*ifa;
        for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr == NULL)
                continue;
            if(ifa->ifa_addr->sa_family==AF_INET) {
                ((struct sockaddr_in*)ifa->ifa_addr)->sin_addr.s_addr=FakeIP_numeric;
            }
        }
    }
    
    return Ret;
}

/*
CFPropertyListRef My_SCDynamicStoreCopyValue(SCDynamicStoreRef store,CFStringRef key) {
    CFPropertyListRef PtyList=Orig_SCDynamicStoreCopyValue(store,key);
    if(CFStringCompare(key, PrimarySvc, 0)==kCFCompareEqualTo) {
        arr_add(arr_ptylist,(uint64_t)PtyList);
    }
    return PtyList;
}

void *My_CFDictionaryGetValue(CFDictionaryRef theDict, const void *key) {
    void *Ret=Orig_CFDictionaryGetValue(theDict,key);
    if(arr_exist(arr_ptylist,(uint64_t)theDict)) {
        arr_add(arr_dict,(uint64_t)Ret);
    }
    return Ret;
}


void *My_CFArrayGetValueAtIndex(CFArrayRef theArray, CFIndex idx) {
    void *Ret=Orig_CFArrayGetValueAtIndex(theArray, idx);
    if(arr_exist(arr_dict, (uint64_t)theArray)) {
        if(CFStringCompare(Ret, PrimaryIP, 0)==kCFCompareEqualTo) {
            Ret=(void*)CFStringCreateWithCString(0, FakeIP, kCFStringEncodingUTF8);
        }
    }
    return Ret;
}
*/
void init_hook_func(){
    arr_ptylist=arr_init(256);
    arr_dict=arr_init(256);
    void *base;
    void *space;
    get_func("/usr/lib/libSystem.dylib","getifaddrs",&Ptr_getifaddrs,&base);
    get_avail_space(base,&space);
    hook(Ptr_getifaddrs,My_getifaddrs,space,(void**)&Orig_getifaddrs);
    /*
    get_func("/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration","SCDynamicStoreCopyValue",&Ptr_SCDynamicStoreCopyValue,&base);
    get_avail_space(base,&space);
    hook(Ptr_SCDynamicStoreCopyValue,My_SCDynamicStoreCopyValue,space,(void**)&Orig_SCDynamicStoreCopyValue);
    
    get_func("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation","CFDictionaryGetValue",&Ptr_CFDictionaryGetValue,&base);
    get_func("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation","CFArrayGetValueAtIndex",&Ptr_CFArrayGetValueAtIndex,&base);
    get_avail_space(base,&space);
    hook(CFDictionaryGetValue,My_CFDictionaryGetValue,space,(void**)&Orig_CFDictionaryGetValue);
    hook(CFArrayGetValueAtIndex,My_CFArrayGetValueAtIndex,(void*)((pointer_t)space+35),(void**)&Orig_CFArrayGetValueAtIndex);
*/
}
