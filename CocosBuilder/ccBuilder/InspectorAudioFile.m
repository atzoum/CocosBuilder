//
//  InspectorAudioFile.m
//  CocosBuilder
//
//  Created by Aris Tzoumas on 18/10/12.
//
//

#import "InspectorAudioFile.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "CCBGlobals.h"
#import "CocosBuilderAppDelegate.h"
#import "CCBDocument.h"
#import "CCBReaderInternal.h"
#import "NodeGraphPropertySetter.h"
#import "PositionPropertySetter.h"
#import "CCNode+NodeInfo.h"
#import "TexturePropertySetter.h"


@implementation InspectorAudioFile

- (void) willBeAdded
{
    // Setup menu
    NSString* sf = [selection extraPropForKey:propertyName];
    
    [ResourceManagerUtil populateResourcePopup:popup resType:kCCBResTypeAudio allowSpriteFrames:NO selectedFile:sf selectedSheet:NULL target:self];
}

- (void) selectedResource:(id)sender
{
    [[CocosBuilderAppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    id item = [sender representedObject];
    
    NSString* sf = nil;

    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        
        if (res.type == kCCBResTypeAudio)
        {
            sf = [ResourceManagerUtil relativePathFromAbsolutePath:res.filePath];
            [ResourceManagerUtil setTitle:sf forPopup:popup];
        }
    }
    
    // Set the properties and sprite frames
    if (sf)
    {
        [selection setExtraProp:sf forKey:propertyName];
        [TexturePropertySetter setAudioForNode:selection andProperty:propertyName withFile:sf];
    }
    
    [self updateAffectedProperties];
}

@end
