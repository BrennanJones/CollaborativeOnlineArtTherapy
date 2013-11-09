//
//  COATViewController.m
//  COAT-iOS-Client
//
//  Created by Brennan Jones on 11/8/2013.
//  Copyright (c) 2013 Brennan Jones. All rights reserved.
//

#import "COATViewController.h"
#import "COATCustomView.h"
#import "COATLine.h"
#import "SocketIOPacket.h"

@interface COATViewController ()
{
    COATCustomView *customView;
}

@end

@implementation COATViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.socketIO = [[SocketIO alloc]initWithDelegate:self];
    [self.socketIO connectToHost:@"10.11.126.177" onPort:12345];
    
    customView = (COATCustomView *)self.view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    NSLog(@"onError() %@", error);
}

- (void) socketIODidDisconnect:(SocketIO *) socket disconnectedWithError:(NSError *)error
{
    NSLog(@"socket.io disconnected. did error occur> %@", error);
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveEvent()");
    
    NSArray* args = packet.args;
    NSDictionary* arg = args[0];
    
    if([packet.name isEqualToString:@"AllowToDraw"])
    {
        self.myClientId = (NSString *)arg[@"clientId"];
        
        // initialization of variables
        self.currentColor = [UIColor purpleColor];
        self.currentWidth = 6;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;
        [customView addGestureRecognizer:pan];
        
        [self addClient:self.myClientId];
    }
    
    else if ([packet.name isEqualToString:@"NewClient"])
    {
        [self addClient:(NSString *)arg[@"clientId"]];
    }
    
    else if([packet.name isEqualToString:@"Pan"])
    {
        NSString *clientId = (NSString *)arg[@"clientId"];
        NSString *x = (NSString *)arg[@"x"];
        NSString *y = (NSString *)arg[@"y"];
        NSString *prevX = (NSString *)arg[@"prevX"];
        NSString *prevY = (NSString *)arg[@"prevY"];
        NSString *state = (NSString *)arg[@"state"];
        NSString *color = (NSString *)arg[@"color"];
        NSInteger width = [(NSString *)arg[@"width"] intValue];
        
        CGPoint current = CGPointMake([x floatValue], [y floatValue]);
        CGPoint previous = CGPointMake([prevX floatValue], [prevY floatValue]);
        CGPoint midPoint = midpoint(previous, current);
        
        if ([state isEqualToString:@"began"]) {
            
            // create new path and new line
            UIBezierPath *newPath = [UIBezierPath bezierPath];
            
            
            ////// --- CLIENT SENDS THIS INFO WITH FLAG (new array element)
            // tells the other clients this is a new line
            
            
            // start point for path
            [newPath moveToPoint:current];
            
            // create new line in the array
            COATLine *newLine = [[COATLine alloc] init];
            
            // style the line with current client settings
            if ([color isEqualToString:@"purple"])
            {
                newLine.color = [UIColor purpleColor];
            }
            else if ([color isEqualToString:@"blue"])
            {
                newLine.color = [UIColor blueColor];
            }
            else if ([color isEqualToString:@"green"])
            {
                newLine.color = [UIColor greenColor];
            }
            newLine.width = width;
            
            ////// --- SEND ALL DATA ABOVE TO CLIENT
            // when received, the client adds line to the appropriate array
            // this needs to have a client id, which would map to an index
            // in the array of arrays
            //
            // start point, color, and width are all sent
            // may need to track current and previous points as well, for
            // midline/control point calculation
            //
            // then -- basically rebuild as above
            
            // add the line to the line array
            newLine.path = newPath;
            [(NSMutableArray *)(customView.lineArrays[clientId]) addObject:newLine];
            
        } else if ([state isEqualToString:@"changed"]) {
            
            // add the point to the latest line in the array
            // send this with a different flag to the client
            [((COATLine *) [(NSMutableArray *)(customView.lineArrays[clientId]) lastObject]).path addQuadCurveToPoint:midPoint controlPoint:previous];
        }
        
        [customView setNeedsDisplay];
    }
}

-(void) addClient:(NSString *)clientId
{
    [customView.lineArrays setObject:[[NSMutableArray alloc] init] forKey:clientId];
}

- (void)pan:(UIPanGestureRecognizer *)pan{
    
    // get current touchpoint
    self.current = [pan locationInView:customView];
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:self.myClientId forKey:@"clientId"];
    [json setObject:[NSString stringWithFormat:@"%.2f", self.current.x] forKey:@"x"];
    [json setObject:[NSString stringWithFormat:@"%.2f", self.current.y] forKey:@"y"];
    [json setObject:[NSString stringWithFormat:@"%.2f", self.previous.x] forKey:@"prevX"];
    [json setObject:[NSString stringWithFormat:@"%.2f", self.previous.y] forKey:@"prevY"];
    [json setObject:[NSString stringWithFormat:@"%d", self.currentWidth] forKey:@"width"];
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        [json setObject:@"began" forKey:@"state"];
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        [json setObject:@"changed" forKey:@"state"];
    }
    
    if (self.currentColor == [UIColor purpleColor])
    {
        [json setObject:@"purple" forKey:@"color"];
    }
    else if (self.currentColor == [UIColor blueColor])
    {
        [json setObject:@"blue" forKey:@"color"];
    }
    else if (self.currentColor == [UIColor greenColor])
    {
        [json setObject:@"green" forKey:@"color"];
    }
    
    [self.socketIO sendEvent:@"Pan" withData:json];
    
    CGPoint midPoint = midpoint(self.previous, self.current);
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        
        // create new path and new line
        UIBezierPath *newPath = [UIBezierPath bezierPath];
        
        
        ////// --- CLIENT SENDS THIS INFO WITH FLAG (new array element)
        // tells the other clients this is a new line
        
        
        // start point for path
        [newPath moveToPoint:self.current];
        
        // create new line in the array
        COATLine *newLine = [[COATLine alloc] init];
        
        // style the line with current client settings
        newLine.color = self.currentColor;
        newLine.width = self.currentWidth;
        
        ////// --- SEND ALL DATA ABOVE TO CLIENT
        // when received, the client adds line to the appropriate array
        // this needs to have a client id, which would map to an index
        // in the array of arrays
        //
        // start point, color, and width are all sent
        // may need to track current and previous points as well, for
        // midline/control point calculation
        //
        // then -- basically rebuild as above
        
        // add the line to the line array
        newLine.path = newPath;
        [customView.lineArrays[self.myClientId] addObject:newLine];
        
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        
        // add the point to the latest line in the array
        // send this with a different flag to the client
        [((COATLine *) [(NSMutableArray *)(customView.lineArrays[self.myClientId]) lastObject]).path addQuadCurveToPoint:midPoint controlPoint:self.previous];
    }
    
    self.previous = self.current;
    
    [customView setNeedsDisplay];
}

// Midpoint Formula
static CGPoint midpoint(CGPoint p0, CGPoint p1) {
    return (CGPoint) {
        (p0.x + p1.x) / 2.0,
        (p0.y + p1.y) / 2.0
    };
}

- (IBAction)purplePress:(UIButton *)sender {
    self.currentColor = [UIColor purpleColor];
}

- (IBAction)bluePress:(UIButton *)sender {
    self.currentColor = [UIColor blueColor];
}

- (IBAction)greenPress:(UIButton *)sender {
    self.currentColor = [UIColor greenColor];
}

- (IBAction)bigPress:(UIButton *)sender {
    self.currentWidth = 10;
}

- (IBAction)smallPress:(UIButton *)sender {
    self.currentWidth = 2;
}

@end
