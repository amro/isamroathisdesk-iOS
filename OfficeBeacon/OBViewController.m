//
//  OBViewController.m
//  OfficeBeacon
//
//  Created by Amro Mousa on 6/11/14.
//  Copyright (c) 2014 Amro Mousa. All rights reserved.
//

#import "OBViewController.h"
#import <CoreLocation/CoreLocation.h>

typedef void (^URLResponseCallback)(NSDictionary *response, NSError *error);

#define kOfficeUDID         @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"

@interface OBViewController() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLBeaconRegion *region;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSDate *lastStatusUpdate;
@property (assign, nonatomic) BOOL lastStatus;
@end

@implementation OBViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    NSLog(@"Starting up...");
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        NSLog(@"Unmonitoring region: %@", region);
        [self.locationManager stopMonitoringForRegion:region];
    }

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kOfficeUDID];
    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"com.office.amro"];
    [self.locationManager startMonitoringForRegion:self.region];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    self.beaconStatusTextView.text = [NSString stringWithFormat:@"Entered region \"%@\"", region.identifier];
    NSLog(@"%@", self.beaconStatusTextView.text);

    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:self.region];
    }

    if ([region isEqual:self.region]) {
        [self updateStatus:YES];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    self.beaconStatusTextView.text = [NSString stringWithFormat:@"Left region \"%@\"", region.identifier];
    NSLog(@"%@", self.beaconStatusTextView.text);

    [self.locationManager stopRangingBeaconsInRegion:self.region];
    
    if ([region isEqual:self.region]) {
        [self updateStatus:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    CLBeacon *beacon = [beacons firstObject];
    if (beacon && ([region isEqual:self.region])) {
        NSString *uuid = beacon.proximityUUID.UUIDString;
        if ([kOfficeUDID isEqualToString:uuid] && [beacon.major isEqual:@4] && [beacon.minor isEqual:@2]) {
            NSString *proximity;
            
            BOOL available = YES;
            
            switch (beacon.proximity) {
                case CLProximityImmediate:
                    proximity = @"immediate";
                    break;
                case CLProximityNear:
                    proximity = @"near";
                    break;
                case CLProximityFar:
                    proximity = @"far";
                    break;
                default:
                    available = NO;
                    proximity = @"unknown";
                    break;
            }

            self.beaconStatusTextView.text = [NSString stringWithFormat:@"In region \"%@\" (%@)", region.identifier, proximity];
            NSLog(@"%@", self.beaconStatusTextView.text);
            
            BOOL shouldUpdateStatus = (self.lastStatusUpdate == nil) || (available != self.lastStatus) || ([self.lastStatusUpdate timeIntervalSinceNow] > 30);
            
            if (shouldUpdateStatus) {
                [self updateStatus:available];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"Did determine state called - %@", @(state));

    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:self.region];
    }

//This doesn't seem to work reliably
    
//    switch (state) {
//        case CLRegionStateInside:
//            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
//                [self.locationManager startRangingBeaconsInRegion:self.region];
//            }
//            break;
//        case CLRegionStateOutside:
//        case CLRegionStateUnknown:
//        default:
//            break;
//    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    self.beaconStatusTextView.text = [NSString stringWithFormat:@"Started monitoring region \"%@\"", region.identifier];
    NSLog(@"%@", self.beaconStatusTextView.text);
    
    [self.locationManager requestStateForRegion:self.region];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region  withError:(NSError *)error {
    self.beaconStatusTextView.text = [NSString stringWithFormat:@"Failed to monitor region \"%@\" with error: %@", region.identifier, error];
    NSLog(@"%@", self.beaconStatusTextView.text);
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.locationManager startMonitoringForRegion:self.region];
    });
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    self.beaconStatusTextView.text = [NSString stringWithFormat:@"Ranging beacons failed for region \"%@\" with error: %@", region.identifier, error];
    NSLog(@"%@", self.beaconStatusTextView.text);
}

#pragma mark - Helpers

- (void)updateStatus:(BOOL)available {
    self.lastStatus = available;
    self.lastStatusUpdate = [NSDate date];
    
    __weak typeof (self) weakSelf = self;
    
    NSURLRequest *request = [self URLRequestForAvailabilityStatus:self.lastStatus];
    [[self URLSessionTaskWithRequest:request completion:^(NSDictionary *response, NSError *error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        
        NSLog(@"Response: %@, Error: %@", response, error);
        
        strongSelf.httpStatusTextView.text = [NSString stringWithFormat:@"Updated status on server: %@, error: %@", response, error];
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:3];
        localNotification.alertBody = [NSString stringWithFormat:@"Updated status to: %@", @(available)];
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [@(available) integerValue];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }] resume];
}

#pragma mark - HTTP

- (NSURLRequest *)URLRequestForAvailabilityStatus:(BOOL)status {
    NSString *URLString = @"https://isamroathisdesk.herokuapp.com/statuses.json";

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *payload = @{@"key": @"<my_secret>", @"status": @{@"available": status ? @"available" : @"unavailable"}};
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    
    return request;
}

- (NSURLSessionTask *)URLSessionTaskWithRequest:(NSURLRequest *)request completion:(URLResponseCallback)completion {
    return [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(parsedResponse, error);
            });
        }
    }];
}


@end
