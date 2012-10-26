//
//  WaveForm.h
//  CoreAudioTest
//
//  Created by Gyetván András on 6/25/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <AVFoundation/AVFoundation.h>
#import "WaveSampleProvider.h"
#import "WaveSampleProviderDelegate.h"

@interface WaveForm : NSObject
{
	CGPoint* sampleData;
	int sampleLength;
	WaveSampleProvider *wsp;	
    NSColor *orange;
	NSColor *darkgray;
    float drawDuration;
    float trackDuration;
    NSString *currentPath;
    CGRect interpolRect;
}

@property(nonatomic, assign) CGRect interpolRect;;
@property(nonatomic, assign) float drawDuration;
@property(nonatomic, retain) NSString *currentPath;

- (void) openAudioURL:(NSURL *)url;
- (void)drawInRect:(NSRect)rect;

@end
