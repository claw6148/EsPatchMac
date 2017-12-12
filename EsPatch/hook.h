//
//  hook.h
//  GetIpAddr2
//
//  Created by ChileungL on 12/12/2017.
//  Copyright © 2017 ChileungL. All rights reserved.
//

void get_avail_space(void *base,void **addr);
int hook(void *func,void *new_func,void *proxy_func,void **orig_func);
void unhook(void *func,void *orig_func);
int get_func(const char *lib,const char *fn,void **addr,void **base);
