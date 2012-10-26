//
//  CCBPCCBAudio.h
//  CocosBuilder
//
//  Created by Aris Tzoumas on 18/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "SequencerTimelineDrawDelegate.h"
#import "WaveForm.h"

@interface CCBPCCBAudio : CCNode <SequencerTimelineDrawDelegate>{
    NSString *audioFile_;
    GLubyte	  volume_;
    BOOL playing_;
    WaveForm *waveForm_;
}


@property(nonatomic,retain) NSString *audioFile;
@property(nonatomic,assign) GLubyte volume;
@property(nonatomic,readwrite) BOOL playing;

@end
