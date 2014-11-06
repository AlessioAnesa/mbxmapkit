//
//  MBXCompositeTileOverlay.h
//  Pods
//
//  Created by Andrea Cremaschi on 04/11/14.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "MBXConstantsAndTypes.h"

@interface MBXCompositeTileOverlay : MKTileOverlay

- (id)initWithTileOverlays:(NSArray *)tileOverlays;
- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *tileData, NSError *error))result;

@property (nonatomic, strong, readonly) NSArray *tileOverlays;

@end
