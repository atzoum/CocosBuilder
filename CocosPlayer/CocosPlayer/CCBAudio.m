//
//  CCBAudio.m
//  CocosPlayer
//
//  Created by Aris Tzoumas on 19/10/12.
//  Copyright 2012 Zynga. All rights reserved.
//

#import "CCBAudio.h"
#import "SimpleAudioEngine.h"
#import "CCActionManager+PausedTarget.h"

@interface CCBAudio() {
    
}
@property (nonatomic,retain) CDSoundSource *soundSource;

@end

@implementation CCBAudio
@synthesize audioFile = audioFile_;
@synthesize volume = volume_;
@synthesize playing = playing_;
@synthesize soundSource = soundSource_;

-(id) init
{
    if ((self=[super init]) ) {
        self.audioFile = @"";
        playing_ = NO;
        effectId_ = -1;
        volume_ = 255;
        [self scheduleUpdate];
    }
    return self;
}

- (void) setPlaying:(BOOL)playing
{
    // switch state only on mutually exclusive events
    if (!((!playing_&& !playing) || (playing_&&playing)) && audioFile_ && [audioFile_ length] > 0 ) {
        playing_ = playing;
        
        if (playing_ && audioFile_) {
            NSString *fullPath = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:audioFile_];
            //effectId_ = [[SimpleAudioEngine sharedEngine] playEffect:fullPath];
            self.soundSource = [[SimpleAudioEngine sharedEngine] soundSourceForFile:fullPath];
            self.soundSource.looping = NO;
            effectId_ = soundSource_.soundId;
            [soundSource_ setGain:volume_/255.0f];
            [soundSource_ play];
            CCLOG(@"%@ start effectid: %d",audioFile_,effectId_);
        } else {
            if (effectId_ > -1 && soundSource_) {
                CCLOG(@"%@ stop effectid: %d",audioFile_,effectId_);                
                [soundSource_ stop];
                self.soundSource = nil;
                effectId_ = -1;
            }
        }
    }
}

- (void) setVolume:(GLubyte)volume
{
    if (volume_ != volume) {
        volume_ = volume;
        if (soundSource_) {
            [soundSource_ setGain:volume_/255.0f];
        }
    }
}

- (void) setAudioFile:(NSString *)audioFile
{
    if ([audioFile isEqualToString:audioFile_])
        return;
    [audioFile_ release];
    audioFile_ = [audioFile retain];
    if (audioFile_) {
        NSString *fullPath = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:audioFile_];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            // Preload file to be ready!
            [[SimpleAudioEngine sharedEngine] preloadEffect:fullPath];
        }
    }
}

-(void) onExitTransitionDidStart
{
    // stop playback
    self.playing = NO;
}

-(void) update:(ccTime)delta
{

    // Handle ActionManager pauseTarget, so that sound follows the action execution
    if (!inNodePauseMode_ && playing_ && [self.actionManager isTargetPaused:self] && soundSource_ && [soundSource_ isPlaying]) {
        CCLOG(@"Pausing sound due to ActionManager");
        [soundSource_ pause];   // pause sound if target is paused
        inNodePauseMode_ = YES;
    } else if (inNodePauseMode_ && playing_ && soundSource_ && ![soundSource_ isPlaying] && ![self.actionManager isTargetPaused:self] ) {
        CCLOG(@"Resuming sound due to ActionManager");
        [soundSource_ play];    // resume sound after target resumes
        inNodePauseMode_ = NO;
    }
}

-(void) dealloc
{
    [audioFile_ release];
    [soundSource_ release];
    [super dealloc];
}

@end
