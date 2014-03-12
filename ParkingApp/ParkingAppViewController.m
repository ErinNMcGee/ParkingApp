//
//  ParkingAppViewController.m
//  ParkingApp
//
//  Created by Erin McGee on 3/9/14.
//  Copyright (c) 2014 Erin McGee. All rights reserved.
//

#import "ParkingAppViewController.h"

@interface ParkingAppViewController ()

@end

@implementation ParkingAppViewController

@synthesize mapView;

CLPlacemark *thePlacemark;
MKRoute *routeDetails;
id<MKOverlay> routeRemoveId;
CLLocationCoordinate2D parkingSpot;
CLLocationCoordinate2D currentLocation;


- (void)viewDidLoad
{
    [super viewDidLoad];
    //Intialize Audio Player
    AVAudioPlayer *pp1 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"batmobile" ofType:@"wav"]] error:nil];
    self.playerBG = pp1;
    [pp1 prepareToPlay];
    self.mapView.delegate = self;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    //Zoom map to user location and set currentLocation variable for later use
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    currentLocation=userLocation.coordinate;
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];

}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *identifier = @"identifier";
    MKPinAnnotationView *pinView =
    (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!pinView)
    {
        if ([[annotation title] isEqualToString:@"I parked here!"])
        {
         MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        
        UIImage *flagImage = [UIImage imageNamed:@"batmobile.png"];
        annotationView.image = flagImage;
        return annotationView;
        }
    }
    else
    {
        pinView.annotation = annotation;
    }
    return pinView;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        routeRenderer.strokeColor = [UIColor blueColor];
        routeRemoveId=overlay;
        return routeRenderer;
    }
    else return nil;
}

- (IBAction)parkedButtonPressed:(UIBarButtonItem *)sender {
        for (int i =0; i < [mapView.annotations count]; i++) {
            if ([[mapView.annotations objectAtIndex:i] isKindOfClass:[MKPointAnnotation class]])
                {
                [mapView removeAnnotation:[mapView.annotations objectAtIndex:i]];
            }
        }
        [self.mapView removeOverlay:routeRemoveId];
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = currentLocation;
        point.title = @"I parked here!";
        parkingSpot=point.coordinate;
        [self.mapView addAnnotation:point];
}

- (IBAction)routeButtonPressed:(UIBarButtonItem *)sender {
    [self.playerBG play];
    for (int i =0; i < [mapView.annotations count]; i++) {
        if ([[mapView.annotations objectAtIndex:i] isKindOfClass:[MKPointAnnotation class]])
        {
            if(![[[mapView.annotations objectAtIndex:i] title] isEqualToString:@"I parked here!"])
            {
                [mapView removeAnnotation:[mapView.annotations objectAtIndex:i]];
            }
        }
    }
    if (routeRemoveId != (id)[NSNull null])
    {
        [self.mapView removeOverlay:routeRemoveId];
    }
    MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
    MKPlacemark *placemark = [[MKPlacemark alloc]initWithCoordinate:parkingSpot addressDictionary:nil];
    [directionsRequest setSource:[MKMapItem mapItemForCurrentLocation]];
    [directionsRequest setDestination:[[MKMapItem alloc] initWithPlacemark:placemark]];
    directionsRequest.transportType = MKDirectionsTransportTypeWalking;
    directionsRequest.requestsAlternateRoutes = YES;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:[error localizedDescription]
                                  message:[error localizedRecoverySuggestion]
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                                  otherButtonTitles:nil];
            
            [alert show];
        }
        else {
            routeDetails = response.routes.lastObject;
            self.distanceLabel.text = [NSString stringWithFormat:@"%0.0001f Miles", routeDetails.distance/1609.344];
            self.allSteps = @"";
            for (int i = 0; i < routeDetails.steps.count; i++) {
                MKRouteStep *step = [routeDetails.steps objectAtIndex:i];
                NSString *stepNumber = [NSString stringWithFormat:@"%d. ", (i+1)];
                NSString *newStep = [stepNumber stringByAppendingString:step.instructions];
                self.allSteps = [self.allSteps stringByAppendingString:newStep];
                self.allSteps = [self.allSteps stringByAppendingString:@"\n\n"];
            }
            self.steps.text = self.allSteps;
            [self showDirections:response]; //response is provided by the CompletionHandler
        }
    }];

}
- (IBAction)clearRoute:(id)sender {
    
    for (int i =0; i < [mapView.annotations count]; i++) {
        if ([[mapView.annotations objectAtIndex:i] isKindOfClass:[MKPointAnnotation class]])
        {
                [mapView removeAnnotation:[mapView.annotations objectAtIndex:i]];
        }
    }
    if (routeRemoveId != (id)[NSNull null])
    {
        [self.mapView removeOverlay:routeRemoveId];
    }
}

- (void)showDirections:(MKDirectionsResponse *)response
{
    for (MKRoute *route in response.routes) {
        [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
    }
    
    double minLatitude=0;
    double maxLatitude=0;
    double minLongitude=0;
    double maxLongitude=0;
    
    if(parkingSpot.latitude<currentLocation.latitude)
    {
        minLatitude=parkingSpot.latitude;
        maxLatitude=currentLocation.latitude;
    }
    else
    {
        minLatitude=currentLocation.latitude;
        maxLatitude=parkingSpot.latitude;
    }
    
    if(parkingSpot.longitude<currentLocation.longitude)
    {
        minLongitude=parkingSpot.longitude;
        maxLongitude=currentLocation.longitude;
    }
    else
    {
        minLongitude=currentLocation.longitude;
        maxLongitude=parkingSpot.longitude;
    }
    
    #define MAP_PADDING 1.1

    
    #define MINIMUM_VISIBLE_LATITUDE 0.01
    
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    
    region.span.latitudeDelta = (maxLatitude - minLatitude) * MAP_PADDING;
    
    region.span.latitudeDelta = (region.span.latitudeDelta < MINIMUM_VISIBLE_LATITUDE)? MINIMUM_VISIBLE_LATITUDE
    : region.span.latitudeDelta;
    
    region.span.longitudeDelta = (maxLongitude - minLongitude) * MAP_PADDING;
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

@end
