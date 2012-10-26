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

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class CCBSequence;

#pragma mark Delegate

@protocol CCBAnimationManagerDelegate <NSObject>

- (void) completedAnimationSequenceNamed:(NSString*)name;

@end

@interface CCBBaseValueTypePair : NSObject
{
    id value_;
    int type_;
}
@property (nonatomic,retain) id value;
@property (nonatomic,assign) int type;
+ (id) baseValue:(id) value ofType:(int) type;
- (id) initWithValue:(id) value ofType:(int) type;

@end


#pragma mark Action Manager

@interface CCBAnimationManager : NSObject
{
    NSMutableArray* sequences;
    NSMutableDictionary* nodeSequences;
    NSMutableDictionary* baseValues;
    int autoPlaySequenceId;
    
    CCNode* rootNode;
    CGSize rootContainerSize;
    
    NSObject<CCBAnimationManagerDelegate>* delegate;
    CCBSequence* runningSequence;
    
    // Used by javascript bindings
    NSMutableArray* documentOutletNames;
    NSMutableArray* documentOutletNodes;
    NSMutableArray* documentCallbackNames;
    NSMutableArray* documentCallbackNodes;
    NSString* documentControllerName;
    NSString* lastCompletedSequenceName;
    
    void (^block)(id sender);
}
@property (nonatomic,readonly) NSMutableArray* sequences;
@property (nonatomic,assign) int autoPlaySequenceId;
@property (nonatomic,retain) CCNode* rootNode;
@property (nonatomic,assign) CGSize rootContainerSize;
@property (nonatomic,retain) NSObject<CCBAnimationManagerDelegate>* delegate;
@property (nonatomic,readonly) NSString* runningSequenceName;
@property (nonatomic,readonly) NSMutableArray* documentOutletNames;
@property (nonatomic,readonly) NSMutableArray* documentOutletNodes;
@property (nonatomic,readonly) NSMutableArray* documentCallbackNames;
@property (nonatomic,readonly) NSMutableArray* documentCallbackNodes;
@property (nonatomic,copy) NSString* documentControllerName;
@property (nonatomic,readonly) NSString* lastCompletedSequenceName;

- (CGSize) containerSize:(CCNode*)node;

- (void) addNode:(CCNode*)node andSequences:(NSDictionary*)seq;
- (void) moveAnimationsFromNode:(CCNode*)fromNode toNode:(CCNode*)toNode;

- (void) setBaseValue:(CCBBaseValueTypePair*) value forNode:(CCNode*)node propertyName:(NSString*)propName;

- (void) runAnimationsForSequenceNamed:(NSString*)name tweenDuration:(float)tweenDuration;
- (void) runAnimationsForSequenceNamed:(NSString*)name;
- (void) runAnimationsForSequenceId:(int)seqId tweenDuration:(float) tweenDuration;

-(void) setCompletedAnimationCallbackBlock:(void(^)(id sender))b;

- (void) debug;

@end

#pragma mark Custom Animation Actions

@interface CCBRotateTo : CCActionInterval <NSCopying>
{
    float startAngle_;
    float dstAngle_;
    float diffAngle_;
}
+(id) actionWithDuration:(ccTime)duration angle:(float)angle;
-(id) initWithDuration:(ccTime)duration angle:(float)angle;
@end

//
// EeseInstant
//
@interface CCEaseInstant : CCActionEase <NSCopying>
{}
@end

@interface CCBSetProperty : CCActionInstant
{
    NSString *propertyName_;
    id value_;
}
/** creates a Place action with a position */
+(id) actionWithPropertyName: (NSString*) propertyName value:(id) value;
/** Initializes a Place action with a position */
-(id) initWithPropertyName: (NSString*) propertyName value:(id) value;

// XXX Needed for BridgeSupport
-(void) update:(ccTime)time;
@end

/** Fades an object that implements the CCRGBAProtocol protocol. It modifies the opacity from the current value to a custom one.
 @warning This action doesn't support "reverse"
 */
@interface CCBTweenByteTo : CCActionInterval <NSCopying>
{
    GLubyte toValue_;
	GLubyte fromValue_;
    NSString *propertyName_;
}
/** creates an action with duration and value */
+(id) actionWithProperty:(NSString*) propertyName duration:(ccTime)duration value:(GLubyte)val;
/** initializes the action with duration and value */
-(id) initWithProperty:(NSString*) propertyName duration:(ccTime)duration value:(GLubyte)val;
@end

