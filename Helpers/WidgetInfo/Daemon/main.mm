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
#import "../../../deps/libwidgetinfo/daemon/Connection/XENDIPCDaemonListener.h"

int main (int argc, const char * argv[]) {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion <= 9) {
        // Just run the run loop forever.
        [[NSRunLoop currentRunLoop] run];
        
        return EXIT_SUCCESS;
    } else {
        return libwidgetinfo_main_ipc();
    }
}

