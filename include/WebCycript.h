/* Cydget - open-source AwayView plugin multiplexer
 * Copyright (C) 2009-2015  Jay Freeman (saurik)
*/

/* GNU General Public License, Version 3 {{{ */
/*
 * Cydia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * Cydia is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cydia.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */

#ifndef WEBCYCRIPT_H
#define WEBCYCRIPT_H

@class WebView;

extern "C" void WebCycriptSetupView(WebView *webview);
extern "C" void WebCycriptRegisterStyle(const char *name, BOOL (*code)());

#endif//WEBCYCRIPT_H
