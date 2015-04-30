//
//  MBXCompositeTileOverlay.m
//  Pods
//
//  Created by Andrea Cremaschi on 04/11/14.
//
//

#import "MBXCompositeTileOverlay.h"

@interface MBXCompositeTileOverlay ()
@property (nonatomic, strong) NSArray *tileOverlays;
@end

@implementation MBXCompositeTileOverlay

-(id)initWithTileOverlays:(NSArray *)tileOverlays {
    self = [super init];
    if (self==nil) return nil;
    
    BOOL valid = YES;
    for (id overlay in tileOverlays) {
        valid &= [overlay isKindOfClass:[MKTileOverlay class]];
    }
    
    if (!valid){
        self = nil;
        return nil;
    }
    
    self.tileSize = [tileOverlays.firstObject tileSize];
    self.minimumZ = [[tileOverlays valueForKeyPath:@"@min.minimumZ"] integerValue];
    self.maximumZ = [[tileOverlays valueForKeyPath:@"@max.maximumZ"] integerValue];
    _tileOverlays = [tileOverlays copy];
    
    return self;
}

- (MKMapRect)boundingMapRect
{
    // Note: If you're wondering why this doesn't return a MapRect calculated from the TileJSON's bounds, it's been
    // tried and it doesn't work, possibly due to an MKMapKit bug. The main symptom is unpredictable visual glitching.
    //
    MKMapRect mapRect = MKMapRectNull;
    for (MKTileOverlay *overlay in self.tileOverlays)
    {
        mapRect = MKMapRectUnion(mapRect, overlay.boundingMapRect);
    }
    return mapRect;
}

-(BOOL)canReplaceMapContent {
    for (MKTileOverlay *overlay in self.tileOverlays) {
        if (overlay.canReplaceMapContent)
            return YES;
    }
    return NO;
}

- (void)loadTileAtPath:(MKTileOverlayPath)path tileOverlayAtIndex:(NSInteger)tileIndex result:(void (^)(NSData *tileData, NSError *error))result {
    
    NSInteger __block blockTileIndex = tileIndex;
    [self.tileOverlays[tileIndex] loadTileAtPath:path result:^(NSData *tileData, NSError *error) {
        if (error) {
            blockTileIndex--;
            if (blockTileIndex>=0) {
                [self loadTileAtPath:path tileOverlayAtIndex:blockTileIndex result:result];
            } else {
                result(nil, error);
            }
        } else {
            result(tileData, error);
        }
    }];
}
- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *, NSError *))result {
    NSInteger tileIndex = self.tileOverlays.count-1;
    
    [self loadTileAtPath:path tileOverlayAtIndex:tileIndex result:result];
}

@end
