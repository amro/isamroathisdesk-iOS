//
//  OBViewController.h
//  OfficeBeacon
//
//  Created by Amro Mousa on 6/11/14.
//  Copyright (c) 2014 Amro Mousa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *beaconStatusTextView;
@property (strong, nonatomic) IBOutlet UITextView *httpStatusTextView;

@end
