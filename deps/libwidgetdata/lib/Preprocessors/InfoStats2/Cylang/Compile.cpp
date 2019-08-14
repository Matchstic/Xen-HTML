//
//  Compile.cpp
//  test-is2-update
//
//  Created by Matt Clarke on 01/11/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#include "Compile.hpp"

#include "Driver.hpp"
#include "Syntax.hpp"

#include <sstream>

const std::string Compile(const std::string &code, bool strict, bool pretty) {
    CYPool pool;
    std::istream *stream = new std::istringstream(code);
    
    CYDriver driver(pool, *stream->rdbuf());
    driver.strict_ = strict;
    driver.debug_ = 0;
    
    if (driver.Parse() || !driver.errors_.empty()) {
        for (CYDriver::Errors::const_iterator error(driver.errors_.begin()); error != driver.errors_.end(); ++error) {
            printf("%s: %s (at line %d column %d)\n", error->warning_ ? "Warning" : "Error", error->message_.c_str(), error->location_.end.line, error->location_.end.column);
        }
        
        return "";
    }
    
    if (driver.script_ == NULL)
        return "";
    
    std::stringbuf str;
    CYOptions options;
    CYOutput out(str, options);
    out.pretty_ = pretty;
    driver.Replace(options);
    out << *driver.script_;
    
    // Cleanup
    delete stream;

    return str.str();
}
