//
//  CCBPCCBAudio.m
//  CocosBuilder
//
//  Created by Aris Tzoumas on 18/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "CCBPCCBAudio.h"

@implementation CCBPCCBAudio

@synthesize audioFile = audioFile_;
@synthesize volume = volume_;
@synthesize playing = playing_;


-(id) init
{
    if ((self=[super init]) ) {
        self.audioFile = @"sound.m4a";
        self.volume = 255;
        self.playing = NO;
        waveForm_ = [[WaveForm alloc] init];
    }
    return self;
}

-(BOOL) canDrawInterpolationForProperty:(NSString*) propName
{
    
    return ([@"playing" isEqualToString:propName]
            && self.audioFile
            && [[NSFileManager defaultManager] fileExistsAtPath:self.audioFile]);
}

-(void) drawInterpolationInRect:(NSRect) rect forProperty:(NSString*) propName withStartValue:(id) startValue endValue:(id) endValue andDuration:(float) duration
{
    NSString *absolutePath = self.audioFile;//[[ResourceManager sharedManager] toAbsolutePath:self.audioFile];
    absolutePath = self.audioFile;
    if (absolutePath && [[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        NSURL *audioFileURL = [NSURL fileURLWithPath:absolutePath];
        
        waveForm_.drawDuration = duration;
        if (![waveForm_.currentPath isEqualToString:[audioFileURL path]]) {
            [waveForm_ openAudioURL:audioFileURL];
        }
        
        [waveForm_ setInterpolRect:rect];
        [waveForm_ drawInRect:rect];
    }
}


-(void) dealloc
{
    [audioFile_ release];
    [waveForm_ release];
    [super dealloc];
}

@end
