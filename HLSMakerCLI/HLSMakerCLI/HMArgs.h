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

/*
 For HandBrake, see http://handbrake.fr
 For mediafilesegmenter, see https://developer.apple.com/downloads/index.action?=http%20live%20streaming%20tools
 */

@interface HMArgs : NSObject

@property (nonatomic, copy) NSString* executablePath;
@property (nonatomic, copy) NSString* sourceFile;       // -i
@property (nonatomic, copy) NSString* outputDirectory;  // -o default is current execution directory
@property (nonatomic, copy) NSString* baseName;         // -b default is outputDirectory.lastPathComponent
@property (nonatomic, copy) NSArray* hlsTypes;          // -t NSArray<NSNumber<HLSType>> ; default is ALL HLSTypes
@property (nonatomic, copy) NSString* handbrakePath;    // -h default tries current execution directory, then /usr/bin
@property (nonatomic, copy) NSString* mediafilesegmenterPath; // -m default tries current execution directory, then /usr/bin

- (NSArray*) validate; // returns an array of errors

@end
