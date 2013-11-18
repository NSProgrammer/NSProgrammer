//
//  UIAlertView+Extensions.m
//  NOBUILib
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

#import "UIAlertView+Extensions.h"
#include <objc/runtime.h>

static const char s_alertCompletionBlockKey;

@interface UIAlertViewDelegateHandler : NSObject <UIAlertViewDelegate>
@end

@implementation UIAlertViewDelegateHandler

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    UIAlertViewCompletionBlock block = objc_getAssociatedObject(alertView, &s_alertCompletionBlockKey);

    if (block)
    {
        block(alertView, buttonIndex);
    }
}

@end

@implementation UIAlertView (Extensions)

+ (void) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
              cancelButtonTitle:(NSString*)cancelButtonTitle
{
    [UIAlertView showAlertViewWithTitle:title
                                message:message
                      cancelButtonTitle:cancelButtonTitle
                       otherButtonTitle:nil
                        completionBlock:NULL];
}

+ (void) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
              cancelButtonTitle:(NSString*)cancelButtonTitle
                completionBlock:(UIAlertViewCompletionBlock)block
{
    [UIAlertView showAlertViewWithTitle:title
                                message:message
                      cancelButtonTitle:cancelButtonTitle
                       otherButtonTitle:nil
                        completionBlock:block];
}

+ (void) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
              cancelButtonTitle:(NSString*)cancelButtonTitle
               otherButtonTitle:(NSString*)otherButtonTitle
                completionBlock:(UIAlertViewCompletionBlock)block
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:cancelButtonTitle
                                          otherButtonTitles:nil];

    if (otherButtonTitle)
    {
        [alert addButtonWithTitle:otherButtonTitle];
    }

    [alert showWithCompletionBlock:block];
}

- (void) showWithCompletionBlock:(UIAlertViewCompletionBlock)block
{
    static UIAlertViewDelegateHandler* s_handler = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        s_handler = [[UIAlertViewDelegateHandler alloc] init];
    });
    
    if (block)
    {
        objc_setAssociatedObject(self, &s_alertCompletionBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    self.delegate = s_handler;
    [self show];
}

@end
