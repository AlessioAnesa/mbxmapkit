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

- (NSInteger)minimumZ
{
    return [[self.tileOverlays valueForKeyPath:@"@min.minimumZ"] integerValue];
}

- (NSInteger)maximumZ
{
    return [[self.tileOverlays valueForKeyPath:@"@min.maximumZ"] integerValue];
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
//- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *tileData, NSError *error))result {
    NSInteger tileIndex = self.tileOverlays.count-1;

    [self loadTileAtPath:path tileOverlayAtIndex:tileIndex result:result];
}

@end
