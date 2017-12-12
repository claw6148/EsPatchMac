//
//  EsPatch.m
//  EsPatch
//
//  Created by ChileungL on 12/12/2017.
//  Copyright © 2017 ChileungL. All rights reserved.
//

#import "EsPatch.h"
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#include "hook_func.h"
#include <arpa/inet.h>
#include <curl/curl.h>

extern CFStringRef PrimarySvc;
extern CFStringRef PrimaryIP;
extern char FakeIP[16];
extern in_addr_t FakeIP_numeric;

typedef struct {
    size_t pos;
    char buf[512];
}USERDATA;

size_t recv_cbk(char *ptr, size_t size, size_t nmemb, void *userdata) {
    
    USERDATA *ud=userdata;
    size_t len=size*nmemb;
    if(ud->pos+len < 512) {
        memcpy(ud->buf+ud->pos,ptr,len);
        ud->pos+=len;
    } else {
        len=0;
    }
    
    return len;
}

int get_wlanip(const char *url,char *wlanip) {
    
    int ret=0;
    CURL *curl=curl_easy_init();
    if(curl) {
        USERDATA ud;
        memset(&ud,0,sizeof(ud.buf));
        curl_easy_setopt(curl, CURLOPT_URL,url);
        curl_easy_setopt(curl, CURLOPT_HEADERDATA,&ud);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA,&ud);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION,recv_cbk);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION,recv_cbk);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT,2);
        curl_easy_perform(curl);
        curl_easy_cleanup(curl);
        char *fieldName="wlanuserip=";
        char *addr=strstr(ud.buf,fieldName);
        if(addr) {
            int len;
            addr+=strlen(fieldName);
            for(len=0;len<16;++len) {
                if((addr[len]<'0'||addr[len]>'9')&&addr[len]!='.') break;
            }
            strncpy(wlanip,addr,len);
            ret=1;
        }
    }
    
    return ret;
}
/*
int get_primary_info(CFStringRef *PrimarySvc,CFStringRef *PrimaryIP){
 
    int ret=0;
    SCDynamicStoreRef DynStore;
    if((DynStore=SCDynamicStoreCreate(NULL,CFSTR("EsPatch"),NULL,NULL))) {
        CFPropertyListRef PtyList;
        if((PtyList=SCDynamicStoreCopyValue(DynStore,CFSTR("State:/Network/Global/IPv4")))) {
            CFStringRef Value;
            if((Value=CFDictionaryGetValue(PtyList, CFSTR("PrimaryService")))) {
                *PrimarySvc=CFStringCreateWithFormat(NULL, NULL, CFSTR("State:/Network/Service/%@/IPv4"), Value);
                if((PtyList=SCDynamicStoreCopyValue(DynStore,*PrimarySvc))) {
                    CFArrayRef Arr;
                    if((Arr=CFDictionaryGetValue(PtyList, CFSTR("Addresses")))) {
                        if(CFArrayGetCount(Arr)>0) {
                            *PrimaryIP=CFArrayGetValueAtIndex(Arr,0);
                            ret=1;
                        }
                    }
                }
            }
        }
    }
 
    return ret;
}
*/

int showErr(NSString *str){
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert setMessageText:@"EsPatch by ChiL."];
    [alert setInformativeText:str];
    [alert addButtonWithTitle:@"重试"];
    [alert addButtonWithTitle:@"本次停用EsPatch"];
    
    return [alert runModal]==NSAlertSecondButtonReturn;
}

int init_env(){
    
    int ret=1;
    int site_idx=1;
    char *site_list[]={
        "http://www.qq.com\0",
        "http://www.baidu.com\0",
        "http://www.sina.com.cn\0"
    };/*
    while(!get_primary_info(&PrimarySvc,&PrimaryIP)){
        if(showErr(@"无法获取本机IP地址")) {ret=0; goto _cleanup;}
    }*/
    while(!get_wlanip(site_list[site_idx%3],(char*)&FakeIP)) {
        if(showErr(@"无法获取BRAS提供的客户端IP地址\n\n可能的原因\n  * 请求超时\n  * 已经联网")) {ret=0; goto _cleanup;}
        site_idx++;
    }
    FakeIP_numeric=inet_addr(FakeIP);
_cleanup:
    
    return ret;
}

void showInfo(){
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setMessageText:@"EsPatch by ChiL."];
    [alert setInformativeText:@"构建日期：2017-12-16\n\n主页：https://4fk.me/proj-EsPatch\n邮箱：a@4fk.me"];
    [alert runModal];
    
}

void __attribute__((constructor)) fuck(){
    
    if(init_env()) {
        init_hook_func();
        showInfo();
    }
    
}
