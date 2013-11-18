/*
 
 Copyright (C) 2013 Nolan O'Brien
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>

/**
    @discussion NOBThreadSafeMutableDictionary provides a thread safe dictionary
    @note Though \c NOBThreadSafeMutableDictionary is optimized, it still enforces thread synchronization and is therefore vastly slower than a normal NSMutableDictionary
 */
@interface NOBThreadSafeMutableDictionary : NSMutableDictionary

/**
    @discussion safely replace the object for a specified key.
    @param key the key to replace the object with.  Raises an \c NSInvalidArgumentException if \c nil.
    @param object the object to replace into the dictionary based on the provided key.  Raises an \c NSInvalidArgumentException if \c nil.
    @return returns the previous object paired with the provided key before it was replaced.  Returns \c nil if no object was paired with the provided key.
 */
- (id) replaceObjectForKey:(id<NSCopying>)key withObject:(id)object;

/**
    @discussion safely set an object for a key if and only if the dictionary does not have an object already paired with the provided key.
    @param object the object to set in the dictionary for the provided key.  Raises an \c NSInvalidArgumentException if \c nil.
    @param key the key to pair with the provided object. Raises an \c NSInvalidArgumentException if \c nil.
    @return Returns \c nil on success.  Returns the existing object that prevented the object being set on failure.
 */
- (id) exclusiveSetObject:(id)object forKey:(id<NSCopying>)key;

@end
