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

/**
 @def STACK_CLEANUP_CGTYPE(type)
 Simple macro for using the stack to cleanup a Core Graphics object
 @par Example:
 @code
 STACK_CLEANUP_CGTYPE(CGColorRef) tmp = CGColorRetain(otherCGColor);
 @endcode
 */
#define STACK_CLEANUP_CGTYPE(type) __attribute__((cleanup(Cleanup_##type))) type

#define STACK_CLEANUP_CGTYPE_FUNCTION(name) \
__attribute__((unused)) NS_INLINE void Cleanup_##name##Ref(name##Ref* ptr) \
{ \
    if (*(name##Ref*)ptr) { name##Release(*(name##Ref*)ptr); } \
}

STACK_CLEANUP_CGTYPE_FUNCTION(CGColor)
STACK_CLEANUP_CGTYPE_FUNCTION(CGColorSpace)
STACK_CLEANUP_CGTYPE_FUNCTION(CGContext)
STACK_CLEANUP_CGTYPE_FUNCTION(CGDataConsumer)
STACK_CLEANUP_CGTYPE_FUNCTION(CGDataProvider)
STACK_CLEANUP_CGTYPE_FUNCTION(CGFont)
STACK_CLEANUP_CGTYPE_FUNCTION(CGFunction)
STACK_CLEANUP_CGTYPE_FUNCTION(CGGradient)
STACK_CLEANUP_CGTYPE_FUNCTION(CGImage)
STACK_CLEANUP_CGTYPE_FUNCTION(CGLayer)
STACK_CLEANUP_CGTYPE_FUNCTION(CGPath)
STACK_CLEANUP_CGTYPE_FUNCTION(CGPattern)
STACK_CLEANUP_CGTYPE_FUNCTION(CGShading)
