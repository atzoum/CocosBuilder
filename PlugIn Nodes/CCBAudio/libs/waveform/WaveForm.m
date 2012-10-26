//
//  WaveForm.m
//  CoreAudioTest
//
//  Created by Gyetván András on 6/25/12.
//  Copyright (c) 2012 DroidZONE. All rights reserved.
//

#import "WaveForm.h"

@interface WaveForm (Private)

- (void) initView;
- (void) drawRoundRect:(NSRect)bounds fillColor:(NSColor *)fillColor strokeColor:(NSColor *)strokeColor radius:(CGFloat)radius lineWidht:(CGFloat)lineWidth;
- (NSRect) fullRect;
- (NSRect) waveRect;
- (NSRect) clipWaveRect;
- (void) setSampleData:(float *)theSampleData length:(int)length;

@end

@implementation WaveForm

@synthesize drawDuration,currentPath,interpolRect;

#pragma mark -
#pragma mark Chrome
- (id)init
{
    self = [super init];
    if (self) {
		[self initView];
    }
    return self;
}

- (void) initView
{
	orange = [[NSColor colorWithSRGBRed:247.0/255.0 green:200.0/255.0 blue:239.0/255.0 alpha:1.0]retain];
	darkgray = [[NSColor colorWithSRGBRed:47.0/255.0 green:47.0/255.0 blue:47.0/255.0 alpha:1.0]retain];

    trackDuration = -1.0f;
    drawDuration = -1.0f;
    
}


- (void) dealloc
{
	if(sampleData != nil) {
		free(sampleData);
		sampleData = nil;
		sampleLength = 0;
	}
	[orange release];
	[darkgray release];
    [currentPath release];
	[super dealloc];
}




- (void) openAudioURL:(NSURL *)url
{
    self.currentPath = [url path];
	sampleLength = 0;
    wsp = [[WaveSampleCache sharedCache] providerForURL:url];
    if(wsp.status == LOADED) {
		int sdl = 0;
        trackDuration = wsp.trackDuration;
        int resolution = (int) 50*trackDuration;
		float *sd = [wsp dataForResolution:resolution lenght:&sdl];
		[self setSampleData:sd length:sdl];
        
	}
}



- (NSRect) waveRect
{
    if (drawDuration<0) {
        return NSMakeRect(self.interpolRect.origin.x,self.interpolRect.origin.y, self.interpolRect.size.width,self.interpolRect.size.height);
    } else {
        float xPercent = drawDuration/trackDuration;
        return NSMakeRect(self.interpolRect.origin.x,self.interpolRect.origin.y, self.interpolRect.size.width/xPercent,self.interpolRect.size.height);
    }
    
}

- (NSRect) clipWaveRect
{
    if (drawDuration<0) {
        return NSMakeRect(self.interpolRect.origin.x,self.interpolRect.origin.y, self.interpolRect.size.width,self.interpolRect.size.height);
    } else {
        float xPercent = drawDuration/trackDuration;
        return NSMakeRect(self.interpolRect.origin.x,self.interpolRect.origin.y, self.interpolRect.size.width*xPercent,self.interpolRect.size.height);
    }
    
}



- (NSRect) fullRect
{
    return NSMakeRect(self.interpolRect.origin.x,self.interpolRect.origin.y, self.interpolRect.size.width,self.interpolRect.size.height);
}

- (void) drawRoundRect:(NSRect)bounds fillColor:(NSColor *)fillColor strokeColor:(NSColor *)strokeColor radius:(CGFloat)radius lineWidht:(CGFloat)lineWidth
{
	CGRect frame = NSMakeRect(bounds.origin.x+(lineWidth/2), bounds.origin.y+(lineWidth/2), bounds.size.width - lineWidth, bounds.size.height - lineWidth);
	
	NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:radius yRadius:radius];
	
	path.lineWidth = lineWidth;
	path.flatness = 0.0;
	
	[fillColor setFill];
	[path fill];
	
	[strokeColor set];
	[path stroke];
	
}


- (void)drawInRect:(NSRect)dirtyRect
{
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	NSRect waveRect = [self waveRect];
    
	[self drawRoundRect:[self fullRect] fillColor:orange strokeColor:darkgray radius:0.0 lineWidht:1.0];
	
	
	if(sampleLength > 0) {
		CGMutablePathRef halfPath = CGPathCreateMutable();
		CGPathAddLines( halfPath, NULL,sampleData, sampleLength); // magic!
		
		CGMutablePathRef path = CGPathCreateMutable();

		double xscale = (NSWidth(waveRect)-4.0) / (float)sampleLength;
		// Transform to fit the waveform ([0,1] range) into the vertical space 
		// ([halfHeight,height] range)
		double halfHeight = floor( NSHeight( waveRect ) / 2.0 );//waveRect.size.height / 2.0;
		CGAffineTransform xf = CGAffineTransformIdentity;
		xf = CGAffineTransformTranslate( xf, waveRect.origin.x+2, halfHeight + waveRect.origin.y);
		xf = CGAffineTransformScale( xf, xscale, halfHeight-2 );
		CGPathAddPath( path, &xf, halfPath );
		
		// Transform to fit the waveform ([0,1] range) into the vertical space
		// ([0,halfHeight] range), flipping the Y axis
		xf = CGAffineTransformIdentity;
		xf = CGAffineTransformTranslate( xf, waveRect.origin.x+2, halfHeight + waveRect.origin.y);
		xf = CGAffineTransformScale( xf, xscale, -(halfHeight-2));
		CGPathAddPath( path, &xf, halfPath );
		
		CGPathRelease( halfPath ); // clean up!
		// Now, path contains the full waveform path.
        NSRect clipWaveRect = [self fullRect];
        NSRectClip(clipWaveRect);
		NSGraphicsContext * nsGraphicsContext = [NSGraphicsContext currentContext];

		CGContextRef cr = (CGContextRef) [nsGraphicsContext graphicsPort];
        CGContextSetLineWidth(cr,0.5f);
		[darkgray set];
		CGContextAddPath(cr, path);
		CGContextStrokePath(cr);

		// gauge draw
		NSRect clipRect = waveRect;
        clipRect.size.width = (clipRect.size.width - 4) * 1.0f;
        clipRect.origin.x = clipRect.origin.x + 2;
        NSRectClip(clipRect);
        
        [darkgray setFill];
        CGContextAddPath(cr, path);
        CGContextFillPath(cr);
        NSRectClip(waveRect);
        [darkgray set];
        CGContextAddPath(cr, path);
        CGContextStrokePath(cr);
				
		CGPathRelease(path); // clean up!
        
        
	}
	[[NSColor clearColor] setFill];
	[self drawRoundRect:[self fullRect] fillColor:[NSColor clearColor] strokeColor:darkgray radius:0.0 lineWidht:1.0];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
	
}

- (void) setSampleData:(float *)theSampleData length:(int)length
{
	sampleLength = 0;
	
	length += 2;
	CGPoint *tempData = (CGPoint *)calloc(sizeof(CGPoint),length);
	tempData[0] = CGPointMake(0.0,0.0);
	tempData[length-1] = CGPointMake(length-1,0.0);
	for(int i = 1; i < length-1;i++) {
		tempData[i] = CGPointMake(i, theSampleData[i]);
	}
	
	CGPoint *oldData = sampleData;
	
	sampleData = tempData;
	sampleLength = length;

	if(oldData != nil) {
		free(oldData);
	}
	
	free(theSampleData);
}

@end
