/*
 Copyright (C) 2020 Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include <stdio.h>
#import <notify.h>
#include <dlfcn.h>

#import "../../../deps/libwidgetinfo/daemon/Connection/XENDIPCDaemonListener.h"
#import "../../../deps/libwidgetinfo/Shared/XENDLogger.h"
#import "kern_memorystatus.h"

#pragma mark - Raise SpringBoard's memory high water mark

static int springboardLaunchToken;
typedef int (*memorystatus_control_sig)(uint32_t command, pid_t pid, uint32_t flags, void *buffer, size_t buffersize);
static int (*_memorystatus_control)(uint32_t command, pid_t pid, uint32_t flags, void *buffer, size_t buffersize);

// See: https://github.com/mariociabarra/jetslammed/blob/master/jetslammed_daemon.m#L100
static memorystatus_priority_entry_t *get_priority_list(int *size)
{
    memorystatus_priority_entry_t *list = NULL;

    *size = _memorystatus_control(MEMORYSTATUS_CMD_GET_PRIORITY_LIST, 0, 0, NULL, 0);
    if ( *size <= 0)
    {
        NSLog(@"Can't get list size: %d!", *size);
        goto exit;
    }

    list = (memorystatus_priority_entry_t*)malloc( *size);
    if (!list)
    {
        NSLog(@"Can't allocate list!");
        goto exit;
    }

    *size = _memorystatus_control(MEMORYSTATUS_CMD_GET_PRIORITY_LIST, 0, 0, list, *size);
    if ( *size <= 0)
    {
        NSLog(@"Can't retrieve list!");
        goto exit;
    }

exit:
    return list;
}

// See: https://github.com/mariociabarra/jetslammed/blob/master/jetslammed_daemon.m#L129
static int getCurrentHighwatermark(int pid) {
    memorystatus_priority_entry_t *entries = NULL;
    int size;
    int64_t currentWater = -1;

    entries = get_priority_list(&size);
    if (!entries)
    {
        goto exit;
    }

    /* Locate */
    for (int i = 0; i < size/sizeof(memorystatus_priority_entry_t); i++ )
    {
        if (entries[i].pid == pid) {
            currentWater = entries[i].limit;
            break;
        }
    }

    free(entries);

exit:
    return (int) currentWater;
}

static int memoryCapacity() {
    // Reads the system max capacity from jetsam properties
    
    NSString *basepath = @"/System/Library/LaunchDaemons/";
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basepath error:nil];
    NSString *path;
    
    for (NSString *item in contents) {
        if ([item hasPrefix:@"com.apple.jetsamproperties."]) {
            path = item;
            break;
        }
    }
    
    if (!path) return 0;
    
    NSString *absolutePath = [NSString stringWithFormat:@"%@%@", basepath, path];
    NSDictionary *jetsamProperties = [NSDictionary dictionaryWithContentsOfFile:absolutePath];
    
    if (!jetsamProperties) return 0;
    
    NSString *version = @"Version4";
    NSDictionary *plistDevice = [[jetsamProperties objectForKey:version] objectForKey:@"PListDevice"];
    
    if (!plistDevice) {
        NSLog(@"Failed to read plist device");
        return 0;
    }
    
    NSNumber *capacity = [plistDevice objectForKey:@"MemoryCapacity"];
    return capacity ? [capacity intValue] : 0;
}

static void applySpringBoardMemoryProfile(pid_t pid) {
    int physicalMemory = memoryCapacity();
    if (physicalMemory == 0) {
        XENDLog(@"Not setting memory high-water-mark for pid: %d; invalid memory capacity", pid);
        return;
    }
    
    // Set SpringBoard's high watermark to be 50% of physical
    int allowed = (float)physicalMemory * 0.5;
    int current = getCurrentHighwatermark(pid);
    
    if (current >= allowed) {
        XENDLog(@"Not setting memory high-water-mark to %d for pid: %d; already is greater", allowed, pid);
    } else {
        int rc = _memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK,
                                      pid,
                                      allowed,
                                      0,
                                      0);
        
        XENDLog(@"setting memory high-water-mark to %d for pid: %d, with result: %d", allowed, pid, rc);
    }
}

static void applySelfProfile() {
    // Increase local memory limit to 100 MB
    pid_t pid = getpid();
    
    // call memorystatus_control
    memorystatus_memlimit_properties_t memlimit;
    memlimit.memlimit_active = 100;
    memlimit.memlimit_inactive = 100;
    
    int rc = _memorystatus_control(MEMORYSTATUS_CMD_SET_MEMLIMIT_PROPERTIES,
                                   pid,  // pid
                                   0,  // flags
                                   &memlimit,  // buffer
                                   sizeof(memlimit));  // buffersize
    
    XENDLog(@"setting memory limit for self (pid: %d), with result: %d", pid, rc);
}

#pragma mark - Setup

int main (int argc, const char * argv[]) {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion <= 9) {
        // Just run the run loop forever.
        [[NSRunLoop currentRunLoop] run];
        
        return EXIT_SUCCESS;
    } else {
        // Enable logging to FS
        [XENDLogger setFilesystemLoggingEnabled:YES];
        
        // Monitor for SpringBoard launched notifications, to apply jetsam tweaks
        // XXX: This, well, isn't amazing. It won't work too well alongside other tweaks that raise the limit.
        // But, as long as the limit is raised by at least some amount, all is well.
        {
            void *handle = dlopen(NULL, 0);
            _memorystatus_control = (memorystatus_control_sig)dlsym(handle, "memorystatus_control");
            
            notify_register_dispatch("com.matchstic.widgetinfo/springboardLaunch", &springboardLaunchToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0l), ^(int token) {
                
                // State on this notification is the PID of SpringBoard
                uint64_t pid = UINT64_MAX;
                notify_get_state(springboardLaunchToken, &pid);
                
                if (pid > 0) {
                    // Raise the memory limit on this PID
                    applySpringBoardMemoryProfile((pid_t)pid);
                }
            });
            
            // Apply our own memory profile
            applySelfProfile();
        }
        
        return libwidgetinfo_main_ipc();
    }
}

