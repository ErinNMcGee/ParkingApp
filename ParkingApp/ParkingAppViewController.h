//
//  ParkingAppViewController.h
//  ParkingApp
//
//  Created by Erin McGee on 3/9/14.
//  Copyright (c) 2014 Erin McGee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

@interface ParkingAppViewController : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextView *steps;
@property (strong, nonatomic) AVAudioPlayer *playerBG;
@property (strong, nonatomic) NSString *allSteps;
@end
