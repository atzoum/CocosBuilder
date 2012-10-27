//
//  CCSprite+DoubleResolution.m
//  CocosPlayer
//
//  Created by Aris Tzoumas on 27/10/12.
//  Copyright (c) 2012 Zynga. All rights reserved.
//

#import "CCSprite+DoubleResolution.h"

@implementation CCSprite (DoubleResolution)

-(void) setTextureRect:(CGRect)rect rotated:(BOOL)rotated untrimmedSize:(CGSize)untrimmedSize
{
	rectRotated_ = rotated;
#if __CC_PLATFORM_IOS
    
    if (CC_CONTENT_SCALE_FACTOR() > 1 && texture_.resolutionType == kCCResolutioniPhone) {
        [self setContentSize:CGSizeMake(untrimmedSize.width*CC_CONTENT_SCALE_FACTOR(),
                                        untrimmedSize.height*CC_CONTENT_SCALE_FACTOR())];
        [self setVertexRect:CGRectMake(rect.origin.x,
                                       rect.origin.y,
                                       rect.size.width*CC_CONTENT_SCALE_FACTOR(),
                                       rect.size.height*CC_CONTENT_SCALE_FACTOR())];
    } else {
        [self setContentSize:untrimmedSize];
        [self setVertexRect:rect];
    }
#else
    [self setContentSize:untrimmedSize];
    [self setVertexRect:rect];
#endif
	
	[self setTextureCoords:rect];
    
	CGPoint relativeOffset = unflippedOffsetPositionFromCenter_;
    
	// issue #732
	if( flipX_ )
		relativeOffset.x = -relativeOffset.x;
	if( flipY_ )
		relativeOffset.y = -relativeOffset.y;
    
    
	offsetPosition_.x = relativeOffset.x + (contentSize_.width - rect_.size.width) / 2;
	offsetPosition_.y = relativeOffset.y + (contentSize_.height - rect_.size.height) / 2;
    
    
	// rendering using batch node
	if( batchNode_ ) {
		// update dirty_, don't update recursiveDirty_
		dirty_ = YES;
	}
    
	// self rendering
	else
	{
		// Atlas: Vertex
		float x1 = offsetPosition_.x;
		float y1 = offsetPosition_.y;
		float x2 = x1 + rect_.size.width;
		float y2 = y1 + rect_.size.height;
        
		// Don't update Z.
		quad_.bl.vertices = (ccVertex3F) { x1, y1, 0 };
		quad_.br.vertices = (ccVertex3F) { x2, y1, 0 };
		quad_.tl.vertices = (ccVertex3F) { x1, y2, 0 };
		quad_.tr.vertices = (ccVertex3F) { x2, y2, 0 };
	}
}

@end
