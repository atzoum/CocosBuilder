/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBAnimationManager.h"
#import "CCBSequence.h"
#import "CCBSequenceProperty.h"
#import "CCBReader.h"
#import "CCBKeyframe.h"
#import "CCNode+CCBRelativePositioning.h"

@interface CCBAnimationManager()

@end

@implementation CCBAnimationManager

@synthesize sequences;
@synthesize autoPlaySequenceId;
@synthesize rootNode;
@synthesize rootContainerSize;
@synthesize delegate;
@synthesize documentOutletNames;
@synthesize documentOutletNodes;
@synthesize documentCallbackNames;
@synthesize documentCallbackNodes;
@synthesize documentControllerName;
@synthesize lastCompletedSequenceName;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    sequences = [[NSMutableArray alloc] init];
    nodeSequences = [[NSMutableDictionary alloc] init];
    baseValues = [[NSMutableDictionary alloc] init];
    
    documentOutletNames = [[NSMutableArray alloc] init];
    documentOutletNodes = [[NSMutableArray alloc] init];
    documentCallbackNames = [[NSMutableArray alloc] init];
    documentCallbackNodes = [[NSMutableArray alloc] init];
    
    return self;
}

- (CGSize) containerSize:(CCNode*)node
{
    if (node) return node.contentSize;
    else return rootContainerSize;
}

- (void) addNode:(CCNode*)node andSequences:(NSDictionary*)seq
{
    [node retain];
    
    NSValue* nodePtr = [NSValue valueWithPointer:node];
    [nodeSequences setObject:seq forKey:nodePtr];
}

- (void) moveAnimationsFromNode:(CCNode*)fromNode toNode:(CCNode*)toNode
{
    NSValue* fromNodePtr = [NSValue valueWithPointer:fromNode];
    NSValue* toNodePtr = [NSValue valueWithPointer:toNode];
    
    // Move base values
    id baseValue = [baseValues objectForKey:fromNodePtr];
    if (baseValue)
    {
        [baseValues setObject:baseValue forKey:toNodePtr];
        [baseValues removeObjectForKey:fromNodePtr];
        
        [fromNode release];
        [toNode retain];
    }
    
    // Move keyframes
    NSDictionary* seqs = [nodeSequences objectForKey:fromNodePtr];
    if (seqs)
    {
        [nodeSequences setObject:seqs forKey:toNodePtr];
        [nodeSequences removeObjectForKey:fromNodePtr];
        
        [fromNode release];
        [toNode retain];
    }
}

- (void) setBaseValue:(CCBBaseValueTypePair*) value forNode:(CCNode*)node propertyName:(NSString*)propName
{
    NSValue* nodePtr = [NSValue valueWithPointer:node];
    
    NSMutableDictionary* props = [baseValues objectForKey:nodePtr];
    if (!props)
    {
        props = [NSMutableDictionary dictionary];
        [baseValues setObject:props forKey:nodePtr];
        [node retain];
    }
    
    [props setObject:value forKey:propName];
}

- (CCBBaseValueTypePair*) baseValueForNode:(CCNode*) node propertyName:(NSString*) propName
{
    NSValue* nodePtr = [NSValue valueWithPointer:node];
    
    NSMutableDictionary* props = [baseValues objectForKey:nodePtr];
    return [props objectForKey:propName];
}

- (int) sequenceIdForSequenceNamed:(NSString*)name
{
    for (CCBSequence* seq in sequences)
    {
        if ([seq.name isEqualToString:name])
        {
            return seq.sequenceId;
        }
    }
    return -1;
}

- (CCBSequence*) sequenceFromSequenceId:(int)seqId
{
    for (CCBSequence* seq in sequences)
    {
        if (seq.sequenceId == seqId) return seq;
    }
    return NULL;
}

- (CCActionInterval*) actionFromKeyframe0:(CCBKeyframe*)kf0 andKeyframe1:(CCBKeyframe*)kf1 propertyName:(NSString*)name node:(CCNode*)node
{
    float duration = kf1.time - kf0.time;
    
    if ([name isEqualToString:@"rotation"])
    {
        return [CCBRotateTo actionWithDuration:duration angle:[kf1.value floatValue]];
    }
    else if ([name isEqualToString:@"opacity"] || kf0.type == kCCBPropTypeByte )
    {
        return [CCBTweenByteTo actionWithProperty:name duration:duration value:[kf1.value intValue]];
    }
    else if ([name isEqualToString:@"color"])
    {
        ccColor3B c;
        [kf1.value getValue:&c];
        
        return [CCTintTo actionWithDuration:duration red:c.r green:c.g blue:c.b];
    }
    else if ([name isEqualToString:@"visible"] || kf0.type == kCCBPropTypeCheck)
    {
        return [CCSequence actionOne:[CCDelayTime actionWithDuration:duration] two:[CCBSetProperty actionWithPropertyName:name value:kf1.value]];
    }
    else if ([name isEqualToString:@"displayFrame"])
    {
        return [CCSequence actionOne:[CCDelayTime actionWithDuration:duration] two:[CCBSetProperty actionWithPropertyName:name value:kf1.value]];
    }
    else if ([name isEqualToString:@"position"])
    {
        // Get position type
        CCBBaseValueTypePair *valueTypePair = [self baseValueForNode:node propertyName:name];
        int type = [[valueTypePair.value objectAtIndex:2] intValue];
        
        id value = kf1.value;
        
        // Get relative position
        float x = [[value objectAtIndex:0] floatValue];
        float y = [[value objectAtIndex:1] floatValue];
        
        CGSize containerSize = [self containerSize:node.parent];
        
        CGPoint absPos = [node absolutePositionFromRelative:ccp(x,y) type:type parentSize:containerSize propertyName:name];
        
        return [CCMoveTo actionWithDuration:duration position:absPos];
    }
    else if ([name isEqualToString:@"scale"])
    {
        // Get position type
        CCBBaseValueTypePair *valueTypePair = [self baseValueForNode:node propertyName:name];
        int type = [[valueTypePair.value objectAtIndex:2] intValue];
        
        id value = kf1.value;
        
        // Get relative scale
        float x = [[value objectAtIndex:0] floatValue];
        float y = [[value objectAtIndex:1] floatValue];
        
        if (type == kCCBScaleTypeMultiplyResolution)
        {
            float resolutionScale = [node resolutionScale];
            x *= resolutionScale;
            y *= resolutionScale;
        }
        
        return [CCScaleTo actionWithDuration:duration scaleX:x scaleY:y];
    }
    else
    {
        NSLog(@"CCBReader: Failed to create animation for property: %@", name);
    }
    return NULL;
}

- (void) setAnimatedProperty:(NSString*)name forNode:(CCNode*)node toValue:(id)value tweenDuration:(float) tweenDuration type:(int) propType
{
    [self setAnimatedProperty:name forNode:node toValue:value tweenDuration:tweenDuration type:propType tDiff:0];
}
- (void) setAnimatedProperty:(NSString*)name forNode:(CCNode*)node toValue:(id)value tweenDuration:(float) tweenDuration type:(int) propType tDiff:(float) tDiff
{
    if (tweenDuration > 0)
    {
        // Create a fake keyframe to generate the action from
        CCBKeyframe* kf1 = [[[CCBKeyframe alloc] init] autorelease];
        kf1.value = value;
        kf1.time = tweenDuration;
        kf1.type = propType;
        kf1.easingType = kCCBKeyframeEasingLinear;
        
        
        // Animate
        CCActionInterval* tweenAction = [self actionFromKeyframe0:NULL andKeyframe1:kf1 propertyName:name node:node];
        [node runAction:tweenAction];
        if (tDiff>0) {
            [tweenAction step:0];
            [tweenAction step:tDiff];
        }
    }
    else
    {
        // Just set the value
    
        if ([name isEqualToString:@"position"])
        {
            // Get position type
            CCBBaseValueTypePair *valueTypePair = [self baseValueForNode:node propertyName:name];
            int type = [[valueTypePair.value objectAtIndex:2] intValue];
            
            // Get relative position
            float x = [[value objectAtIndex:0] floatValue];
            float y = [[value objectAtIndex:1] floatValue];
            
            [node setRelativePosition:ccp(x,y) type:type parentSize:[self containerSize:node.parent] propertyName:name];
        }
        else if ([name isEqualToString:@"scale"])
        {
            // Get scale type
            CCBBaseValueTypePair *valueTypePair = [self baseValueForNode:node propertyName:name];
            int type = [[valueTypePair.value objectAtIndex:2] intValue];
            
            // Get relative scale
            float x = [[value objectAtIndex:0] floatValue];
            float y = [[value objectAtIndex:1] floatValue];
            
            [node setRelativeScaleX:x Y:y type:type propertyName:name];
        }
        else
        {
            [node setValue:value forKey:name];
        }
    }  
}

- (void) setFirstFrameForNode:(CCNode*)node sequenceProperty:(CCBSequenceProperty*)seqProp tweenDuration:(float)tweenDuration
{
    NSArray* keyframes = [seqProp keyframes];
    
    if (keyframes.count == 0)
    {
        // Use base value (no animation)
        CCBBaseValueTypePair *valueTypePair = [self baseValueForNode:node propertyName:seqProp.name];
        id baseValue = valueTypePair.value;
        NSAssert1(baseValue, @"No baseValue found for property (%@)", seqProp.name);
        [self setAnimatedProperty:seqProp.name forNode:node toValue:baseValue tweenDuration:tweenDuration type:valueTypePair.type];
    }
    else
    {
        // Use first keyframe
        CCBKeyframe* keyframe = [keyframes objectAtIndex:0];
        [self setAnimatedProperty:seqProp.name forNode:node toValue:keyframe.value tweenDuration:tweenDuration type:seqProp.type];
    }
}

- (CCActionInterval*) easeAction:(CCActionInterval*) action easingType:(int)easingType easingOpt:(float) easingOpt
{
    if ([action isKindOfClass:[CCSequence class]]) return action;
    
    if (easingType == kCCBKeyframeEasingLinear)
    {
        return action;
    }
    else if (easingType == kCCBKeyframeEasingInstant)
    {
        return [CCEaseInstant actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingCubicIn)
    {
        return [CCEaseIn actionWithAction:action rate:easingOpt];
    }
    else if (easingType == kCCBKeyframeEasingCubicOut)
    {
        return [CCEaseOut actionWithAction:action rate:easingOpt];
    }
    else if (easingType == kCCBKeyframeEasingCubicInOut)
    {
        return [CCEaseInOut actionWithAction:action rate:easingOpt];
    }
    else if (easingType == kCCBKeyframeEasingBackIn)
    {
        return [CCEaseBackIn actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingBackOut)
    {
        return [CCEaseBackOut actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingBackInOut)
    {
        return [CCEaseBackInOut actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingBounceIn)
    {
        return [CCEaseBounceIn actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingBounceOut)
    {
        return [CCEaseBounceOut actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingBounceInOut)
    {
        return [CCEaseBounceInOut actionWithAction:action];
    }
    else if (easingType == kCCBKeyframeEasingElasticIn)
    {
        return [CCEaseElasticIn actionWithAction:action period:easingOpt];
    }
    else if (easingType == kCCBKeyframeEasingElasticOut)
    {
        return [CCEaseElasticOut actionWithAction:action period:easingOpt];
    }
    else if (easingType == kCCBKeyframeEasingElasticInOut)
    {
        return [CCEaseElasticInOut actionWithAction:action period:easingOpt];
    }
    else
    {
        NSLog(@"CCBReader: Unkown easing type %d", easingType);
        return action;
    }
}

- (void) runActionsForNode:(CCNode*)node sequenceProperty:(CCBSequenceProperty*)seqProp tweenDuration:(float)tweenDuration
{
    [self runActionsForNode:node sequenceProperty:seqProp tweenDuration:tweenDuration tDiff:0];
}
- (void) runActionsForNode:(CCNode*)node sequenceProperty:(CCBSequenceProperty*)seqProp tweenDuration:(float)tweenDuration tDiff:(float) tDiff
{
    NSArray* keyframes = [seqProp keyframes];
    int numKeyframes = (int)keyframes.count;
    
    if (numKeyframes > 1)
    {
        // Make an animation!
        NSMutableArray* actions = [NSMutableArray array];
            
        CCBKeyframe* keyframeFirst = [keyframes objectAtIndex:0];
        float timeFirst = keyframeFirst.time + tweenDuration;
        
        if (timeFirst > 0)
        {
            [actions addObject:[CCDelayTime actionWithDuration:timeFirst]];
        }
        
        for (int i = 0; i < numKeyframes - 1; i++)
        {
            CCBKeyframe* kf0 = [keyframes objectAtIndex:i];
            CCBKeyframe* kf1 = [keyframes objectAtIndex:i+1];
            
            CCActionInterval* action = [self actionFromKeyframe0:kf0 andKeyframe1:kf1 propertyName:seqProp.name node:node];
            if (action)
            {
                // Apply easing
                action = [self easeAction:action easingType:kf0.easingType easingOpt:kf0.easingOpt];
                
                [actions addObject:action];
            }
        }
        
        CCSequence* seq = [CCSequence actionWithArray:actions];
        [node runAction:seq];
        if (tDiff>0) {
            [seq step:0];
            [seq step:tDiff];
        }
    }
}

- (void) runAnimationsForSequenceId:(int)seqId tweenDuration:(float) tweenDuration
{
    [self runAnimationsForSequenceId:seqId tweenDuration:tweenDuration tDiff:0];
}
- (void) runAnimationsForSequenceId:(int)seqId tweenDuration:(float) tweenDuration tDiff:(float) tDiff
{
    NSAssert(seqId != -1, @"Sequence id %d couldn't be found",seqId);
    
    [rootNode stopAllActions];
    
    for (NSValue* nodePtr in nodeSequences)
    {
        CCNode* node = [nodePtr pointerValue];
        [node stopAllActions];
        
        NSDictionary* seqs = [nodeSequences objectForKey:nodePtr];
        NSDictionary* seqNodeProps = [seqs objectForKey:[NSNumber numberWithInt:seqId]];
        
        NSMutableSet* seqNodePropNames = [NSMutableSet set];
        
        // Reset nodes that have sequence node properties, and run actions on them
        for (NSString* propName in seqNodeProps)
        {
            CCBSequenceProperty* seqProp = [seqNodeProps objectForKey:propName];
            [seqNodePropNames addObject:propName];
            
            [self setFirstFrameForNode:node sequenceProperty:seqProp tweenDuration:tweenDuration];
            [self runActionsForNode:node sequenceProperty:seqProp tweenDuration:tweenDuration];
        }
        
        // Reset the nodes that may have been changed by other timelines
        NSDictionary* nodeBaseValues = [baseValues objectForKey:nodePtr];
        for (NSString* propName in nodeBaseValues)
        {
            if (![seqNodePropNames containsObject:propName])
            {
                CCBBaseValueTypePair *valueTypePair = [nodeBaseValues objectForKey:propName];
                if (valueTypePair) {
                    id value = valueTypePair.value;
                
                    if (value)
                    {
                        [self setAnimatedProperty:propName forNode:node toValue:value tweenDuration:tweenDuration type:valueTypePair.type];
                    }
                }
            }
        }
    }
    
    // Make callback at end of sequence
    CCBSequence* seq = [self sequenceFromSequenceId:seqId];
    float totalTime = seq.duration+tweenDuration;
    
//    CCAction* completeAction = [CCSequence actionOne:[CCDelayTime actionWithDuration:totalTime] two:[CCCallFunc actionWithTarget:self selector:@selector(sequenceCompleted:)]];
    CCAction* completeAction = [CCCallFuncWithDelay actionWithDelay:totalTime target:self selector:@selector(sequenceCompleted:)];
    [rootNode runAction:completeAction];
    if (tDiff>0) {
        [completeAction step:0];
        [completeAction step:tDiff];
    }
    // Set the running scene
    runningSequence = [self sequenceFromSequenceId:seqId];
}

- (void) runAnimationsForSequenceNamed:(NSString*)name tweenDuration:(float)tweenDuration
{
    int seqId = [self sequenceIdForSequenceNamed:name];
    [self runAnimationsForSequenceId:seqId tweenDuration:tweenDuration];
}

- (void) runAnimationsForSequenceNamed:(NSString*)name
{
    [self runAnimationsForSequenceNamed:name tweenDuration:0];
}

- (void) sequenceCompleted:(NSNumber*) diff
{
    //NSLog(@"diffTime: %f", [diff floatValue]);
    // Save last completed sequence
    if (lastCompletedSequenceName != runningSequence.name)
    {
        [lastCompletedSequenceName release];
        lastCompletedSequenceName = [runningSequence.name copy];
    }
    
    // Callbacks
    [delegate completedAnimationSequenceNamed:runningSequence.name];
    if (block) block(self);
    
    // Play next sequence
    int nextSeqId = runningSequence.chainedSequenceId;
    runningSequence = NULL;
    
    if (nextSeqId != -1)
    {
        [self runAnimationsForSequenceId:nextSeqId tweenDuration:0 tDiff:[diff floatValue]];
    }
    
}

- (NSString*) runningSequenceName
{
    return runningSequence.name;
}

-(void) setCompletedAnimationCallbackBlock:(void(^)(id sender))b
{
    [block release];
    block = [b copy];
}

- (void) dealloc
{
    for (NSValue* nodePtr in nodeSequences)
    {
        CCNode* node = [nodePtr pointerValue];
        [node release];
    }
    
    for (NSValue* nodePtr in baseValues)
    {
        CCNode* node = [nodePtr pointerValue];
        [node release];
    }
    
    [baseValues release];
    [sequences release];
    [nodeSequences release];
    self.rootNode = NULL;
    self.delegate = NULL;
    self.documentControllerName = NULL;
    
    [documentOutletNames release];
    [documentOutletNodes release];
    [documentCallbackNames release];
    [documentCallbackNodes release];
    
    [lastCompletedSequenceName release];
    
    [block release];
    
    [super dealloc];
}

- (void) debug
{
    //NSLog(@"baseValues: %@", baseValues);
    //NSLog(@"nodeSequences: %@", nodeSequences);
}

@end



@implementation CCBBaseValueTypePair

@synthesize value = value_;
@synthesize type = type_;

+ (id) baseValue:(id) value ofType:(int) type
{
    return [[[CCBBaseValueTypePair alloc] initWithValue:value ofType:type] autorelease];
}

- (id) initWithValue:(id) value ofType:(int) type
{
    if ( (self = [super init]) ) {
        self.value = value;
        self.type = type;
    }
    return self;
}

-(void) dealloc
{
    [value_ release];
    [super dealloc];
}

@end
#pragma mark Custom Actions



@implementation CCBRotateTo

+(id) actionWithDuration:(ccTime)duration angle:(float)angle
{
    return [[[CCBRotateTo alloc] initWithDuration:duration angle:angle] autorelease];
}

-(id) initWithDuration:(ccTime)duration angle:(float)angle
{
    self = [super initWithDuration:duration];
    if (!self) return NULL;
    
    dstAngle_ = angle;
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    CCAction *copy = [[[self class] allocWithZone: zone] initWithDuration:[self duration] angle:dstAngle_];
	return copy;
}

-(void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
    startAngle_ = [target_ rotation];
    diffAngle_ = dstAngle_ - startAngle_;
}

-(void) update: (ccTime) t
{
	[target_ setRotation: startAngle_ + diffAngle_ * t];
}

@end


@implementation CCEaseInstant
-(void) update: (ccTime) t
{
    if (t < 0)
    {
        [other update:0];
    }
    else
    {
        [other update:1];
    }
}
@end

@implementation CCBSetProperty
+(id) actionWithPropertyName: (NSString*) propertyName value:(id) value
{
	return [[[self alloc]initWithPropertyName:propertyName value:value] autorelease];
}

-(id) initWithPropertyName: (NSString*) propertyName value:(id) value
{
	if( (self=[super init]) ) {
		propertyName_ = [propertyName retain];
        value_ = [value retain];
    }
	return self;
}

- (void) dealloc
{
    [propertyName_ release];
    [value_ release];
    [super dealloc];
}

-(id) copyWithZone: (NSZone*) zone
{
    CCActionInstant *copy = [[[self class] allocWithZone: zone] initWithPropertyName:propertyName_ value:value_];
	return copy;
}

-(void) update:(ccTime)time
{
	[target_ setValue:value_ forKey:propertyName_];
}

@end

@implementation CCBTweenByteTo

+(id) actionWithProperty:(NSString*) propertyName duration:(ccTime)duration value:(GLubyte)val
{
    return [[[ self alloc] initWithProperty: propertyName duration:duration value:val] autorelease];
}

/** initializes the action with duration and value */
-(id) initWithProperty:(NSString*) propertyName duration:(ccTime)duration value:(GLubyte)val
{
    if ( (self = [super initWithDuration:duration])) {
        toValue_ = val;
        propertyName_= [propertyName retain];
    }
    return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone: zone] initWithProperty:propertyName_ duration:[self duration] value:toValue_];
	return copy;
}

-(void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
	fromValue_ = [[target_ valueForKey:propertyName_] charValue];
}

-(void) update: (ccTime) t
{
    [target_ setValue:[NSNumber numberWithChar:fromValue_ + ( toValue_ - fromValue_ ) * t] forKey:propertyName_];
}



@end

@implementation CCCallFuncWithDelay

@synthesize targetCallback = targetCallback_;

+(id) actionWithDelay:(ccTime) d target: (id) t selector:(SEL) s
{
	return [[[self alloc] initWithDelay: d target: t selector: s] autorelease];
}

-(id) initWithDelay:(ccTime) d target: (id) t selector:(SEL) s
{
	if( (self=[super initWithDuration:d]) ) {
		self.targetCallback = t;
		selector_ = s;
	}
	return self;
}

-(NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %p | Tag = %ld | selector = %@>",
			[self class],
			self,
			(long)tag_,
			NSStringFromSelector(selector_)
			];
}

-(void) dealloc
{
	[targetCallback_ release];
	[super dealloc];
}

-(id) copyWithZone: (NSZone*) zone
{
	CCActionInterval *copy = [[[self class] allocWithZone: zone] initWithDelay:duration_ target:targetCallback_ selector:selector_];
	return copy;
}

-(void) update:(ccTime)time
{
    if (time==1) {
        [self execute];
    }
}

-(void) execute
{
    NSNumber *diff = [NSNumber numberWithFloat:elapsed_- duration_];
    //NSLog(@"diff: %f",[diff floatValue]);
	[targetCallback_ performSelector:selector_ withObject:diff];
}
@end
