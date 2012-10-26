//
//  CCActionManager+PausedTarget.m
//  CocosPlayer
//
//  Created by Aris Tzoumas on 23/10/12.
//  Copyright (c) 2012 Zynga. All rights reserved.
//

#import "CCActionManager+PausedTarget.h"

@implementation CCActionManager (PausedTarget)

-(BOOL) isTargetPaused:(id) target
{
    tHashElement *element = NULL;
	HASH_FIND_INT(targets, &target, element);
	return ( element && element->paused );
}

@end
