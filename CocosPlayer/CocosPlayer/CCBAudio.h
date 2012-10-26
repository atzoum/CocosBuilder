//
//  CCBAudio.h
//  CocosPlayer
//
//  Created by Aris Tzoumas on 19/10/12.
//  Copyright 2012 Zynga. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "SimpleAudioEngine.h"

@interface CCBAudio : CCNode {
    
    int effectId_;
    
    NSString *audioFile_;
    GLubyte	  volume_;
    BOOL playing_;
    CDSoundSource *soundSource_;
    BOOL inNodePauseMode_;
    
}

@property(nonatomic,retain) NSString *audioFile;
@property(nonatomic,assign) GLubyte volume;
@property(nonatomic,assign) BOOL playing;


@end
