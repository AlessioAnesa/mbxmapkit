//
//  MBXOfflineMapDescriptor.m
//  OrobieOutdoor
//
//  Created by Andrea Cremaschi on 25/08/14.
//  Copyright (c) 2014 moma comunicazione. All rights reserved.
//

#import "MBXSparseMapDescriptor.h"

@interface MBXSparseMapDescriptor ()
@property (strong) NSDictionary *regionsDictionary;
// Properties
@property NSInteger minimumZ;
@property NSInteger maximumZ;

@end

@implementation MBXSparseMapDescriptor

-(id)initWithMinimumZ: (NSInteger) minimumZ maximumZ: (NSInteger) maximumZ {

    self = [super init];
    if (!self) return nil;
    
    _minimumZ = minimumZ;
    _maximumZ = maximumZ;
    
    _regionsDictionary = [NSDictionary dictionary];

    return self;
}

-(void)addRegion: (MKCoordinateRegion) region identifier: (NSString *)identifier {
    
    // region to NSValue
    NSValue *centerValue = [NSValue valueWithMKCoordinate:region.center];
    NSValue *spanValue = [NSValue valueWithMKCoordinateSpan:region.span];
    
    NSMutableDictionary *dict = [self.regionsDictionary mutableCopy];
    [dict setObject:@[ centerValue, spanValue ] forKey: identifier];
    self.regionsDictionary = dict;
}

-(MKCoordinateRegion)regionForKey:(NSString*)identifier
{
    NSArray *data = self.regionsDictionary[identifier];
    return MKCoordinateRegionMake([data[0] MKCoordinateValue], [data[1] MKCoordinateSpanValue]);
}

-(int)regionsCount {
    return self.regionsDictionary.count;
}

-(NSArray*)regionsIdentifiers {
    return self.regionsDictionary.allKeys;
}


-(void)enumerateTiles:(void (^)(RMTile))block
{
    NSInteger minimumZ = self.minimumZ;
    NSInteger maximumZ = self.maximumZ;
    
    for (NSString *mapRegionIdentifier in self.regionsDictionary.allKeys)
    {
        MKCoordinateRegion mapRegion = [self regionForKey: mapRegionIdentifier];
        CLLocationDegrees minLat = mapRegion.center.latitude - (mapRegion.span.latitudeDelta / 2.0);
        CLLocationDegrees maxLat = minLat + mapRegion.span.latitudeDelta;
        CLLocationDegrees minLon = mapRegion.center.longitude - (mapRegion.span.longitudeDelta / 2.0);
        CLLocationDegrees maxLon = minLon + mapRegion.span.longitudeDelta;
        NSUInteger minX;
        NSUInteger maxX;
        NSUInteger minY;
        NSUInteger maxY;
        NSUInteger tilesPerSide;
        for(NSUInteger zoom = minimumZ; zoom <= maximumZ; zoom++)
        {
            tilesPerSide = pow(2.0, zoom);
            minX = floor(((minLon + 180.0) / 360.0) * tilesPerSide);
            maxX = floor(((maxLon + 180.0) / 360.0) * tilesPerSide);
            minY = floor((1.0 - (logf(tanf(maxLat * M_PI / 180.0) + 1.0 / cosf(maxLat * M_PI / 180.0)) / M_PI)) / 2.0 * tilesPerSide);
            maxY = floor((1.0 - (logf(tanf(minLat * M_PI / 180.0) + 1.0 / cosf(minLat * M_PI / 180.0)) / M_PI)) / 2.0 * tilesPerSide);
            for(uint32_t x=minX; x<=maxX; x++)
            {
                for(uint32_t y=minY; y<=maxY; y++)
                {
                    RMTile tile = RMTileMake(x, y, zoom);
                    block(tile);
                }
            }
        }
    }
}

#pragma mark - MBXMapDescriptorDelegate

-(MKCoordinateRegion)mapRegion {
    MKMapRect globalMaprect = MKMapRectNull;
    for (NSString *key in self.regionsDictionary.allKeys) {
        MKCoordinateRegion region = [self regionForKey:key];
        MKMapRect maprect = [self mapRectForCoordinateRegion:region];
        globalMaprect =MKMapRectUnion(maprect, globalMaprect);
    }
    return MKCoordinateRegionForMapRect(globalMaprect);
}

- (MKMapRect)mapRectForCoordinateRegion:(MKCoordinateRegion)coordinateRegion
{
    CLLocationCoordinate2D topLeftCoordinate =
    CLLocationCoordinate2DMake(coordinateRegion.center.latitude
                               + (coordinateRegion.span.latitudeDelta/2.0),
                               coordinateRegion.center.longitude
                               - (coordinateRegion.span.longitudeDelta/2.0));
    
    MKMapPoint topLeftMapPoint = MKMapPointForCoordinate(topLeftCoordinate);
    
    CLLocationCoordinate2D bottomRightCoordinate =
    CLLocationCoordinate2DMake(coordinateRegion.center.latitude
                               - (coordinateRegion.span.latitudeDelta/2.0),
                               coordinateRegion.center.longitude
                               + (coordinateRegion.span.longitudeDelta/2.0));
    
    MKMapPoint bottomRightMapPoint = MKMapPointForCoordinate(bottomRightCoordinate);
    
    MKMapRect mapRect = MKMapRectMake(topLeftMapPoint.x,
                                      topLeftMapPoint.y,
                                      fabs(bottomRightMapPoint.x-topLeftMapPoint.x),
                                      fabs(bottomRightMapPoint.y-topLeftMapPoint.y));
    
    return mapRect;
}

-(NSString *)uniqueID
{
    if (!_uniqueID)
        _uniqueID = [[NSUUID UUID] UUIDString];
    
    return _uniqueID;
}

@end
