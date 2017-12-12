//
//  hook.c
//  GetIpAddr2
//
//  Created by ChileungL on 12/12/2017.
//  Copyright © 2017 ChileungL. All rights reserved.
//

#include "hook.h"

#include <mach-o/loader.h>
#include <mach/mach.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <dlfcn.h>
#include "udis86.h"

int set_rwe(void *addr,int size){
    
    int ret;
    task_t task;
    if((ret=task_for_pid(mach_task_self(), getpid(), &task))==KERN_SUCCESS) {
        ret=vm_protect(task,(vm_address_t)addr, size, 0, VM_PROT_READ|VM_PROT_WRITE|VM_PROT_EXECUTE);
    }
    
    return ret;
}

void get_avail_space(void *base,void **addr) {
    
    struct mach_header_64 *hdr=base;
    *addr=(void*)((pointer_t)base+sizeof(struct mach_header_64)+hdr->sizeofcmds);
    
}

int get_min_func_len(void *func,int min_len){
    
    ud_t ud_obj;
    ud_init(&ud_obj);
    ud_set_input_buffer(&ud_obj,func,min_len+64);
    ud_set_mode(&ud_obj, 64);
    ud_set_syntax(&ud_obj, UD_SYN_INTEL);
    int req_len=0;
    while (ud_disassemble(&ud_obj)&&req_len<min_len) {
        req_len+=ud_insn_len(&ud_obj);
    }
    
    return req_len;
}

void atomic_memcpy(void *dst, void *src, int len)
{
    u_char srcBuf[8];
    if(len > 8) return;
    memcpy(srcBuf, dst, 8);
    memcpy(srcBuf, src, len);
    __asm
    {
        lea rsi, srcBuf;
        mov rdi, dst;
        mov rax, [rdi];
        mov rdx, [rdi+4];
        mov rbx, [rsi];
        mov rcx, [rsi+4];
        lock cmpxchg8b[rdi];
    }
}

int hook(void *func,void *new_func,void *proxy_func,void **orig_func){
    
    int ret=0;
    u_char proxyBuf[]={
        0x48,0xB8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0xFF,0xE0,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0x90,
        0xE9,0x00,0x00,0x00,0x00};
    u_char jmpBuf[]={0xE9,0x00,0x00,0x00,0x00};
    int min_len=get_min_func_len(func,5);
    if(min_len>16) {ret=1;goto _cleanup;}
    memcpy(proxyBuf+12,func,min_len);
    if(proxyBuf[12]==0xE9) {ret=2;goto _cleanup;}
    if(set_rwe(proxy_func, sizeof(proxyBuf))) {ret=3;goto _cleanup;}
    if(set_rwe(func, 5)) {ret=4;goto _cleanup;}
    *((uint64_t*)(proxyBuf+2))=(uint64_t)new_func;
    *((uint64_t*)(proxyBuf+29))=((uint64_t)func+min_len)-((uint64_t)proxy_func+28)-5;
    memcpy((void*)proxy_func,proxyBuf,sizeof(proxyBuf));
    *((uint32_t*)(jmpBuf+1))=(uint32_t)((uint64_t)proxy_func-(uint64_t)func-5);
    atomic_memcpy(func,jmpBuf,sizeof(jmpBuf));
    *orig_func=(void*)((pointer_t)proxy_func+12);
_cleanup:
    
    return 0;
}

void unhook(void *func,void *orig_func) {
    
    atomic_memcpy(func,(void*)((pointer_t)orig_func+1), 5);
    
}

int get_func(const char *lib,const char *fn,void **addr,void **base) {
    
    void *dl=dlopen(lib,RTLD_LAZY);
    void *func=dlsym(dl, fn);
    if(!func) return 0;
    if(base) {
        Dl_info di;
        dladdr(func,&di);
        *base=di.dli_fbase;
    }
    *addr=func;
    
    return 1;
}
