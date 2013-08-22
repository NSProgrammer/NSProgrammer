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

#import <UIKit/UIKit.h>

/**
    @param alertView The \c UIAlertView that was dismissed
    @param buttonIndex The index of the button used to dismiss the \c UIAlertView
 */
typedef void (^UIAlertViewCompletionBlock)(UIAlertView* alertView, NSInteger buttonIndex);

@interface UIAlertView (Extensions)

/**
    @see showAlertViewWithTitle:message:cancelButtonTitle:otherButtonTitle:completionBlock:
 */
+ (void) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
              cancelButtonTitle:(NSString*)cancelButtonTitle;

/**
    @see showAlertViewWithTitle:message:cancelButtonTitle:otherButtonTitle:completionBlock:
 */
+ (void) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
              cancelButtonTitle:(NSString*)cancelButtonTitle
                completionBlock:(UIAlertViewCompletionBlock)block;

/**
    @discussion a convenience method for showing a UIAlertView
    @param title The title of the alert.
    @param message The message of the alert.
    @param cancelButtonTitle The title of the cancel button.
    @param otherButtonTitle The title of the other button.  Passing \c nil will prevent an extra button from being shown.
    @param block The block to be called when the alert is completed.
 */
+ (void) showAlertViewWithTitle:(NSString*)title
                        message:(NSString*)message
              cancelButtonTitle:(NSString*)cancelButtonTitle
               otherButtonTitle:(NSString*)otherButtonTitle
                completionBlock:(UIAlertViewCompletionBlock)block;

/**
    @discussion a method to show the \c UIAlertView and utilize a completion block instead of a delegate for completion.
    @param block The completion block that will be called back when the alert is dismissed
    @note the \c UIAlertView object's \c delegate will be changed
 */
- (void) showWithCompletionBlock:(UIAlertViewCompletionBlock)block;

@end
