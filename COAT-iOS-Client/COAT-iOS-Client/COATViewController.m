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
    
    self.prevXs = [[NSMutableDictionary alloc] init];
    self.prevYs = [[NSMutableDictionary alloc] init];
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
    
    else if ([packet.name isEqualToString:@"BeginDraw"])
    {
        NSString *clientId = (NSString *)arg[@"clientId"];
        NSString *x = (NSString *)arg[@"x"];
        NSString *y = (NSString *)arg[@"y"];
        NSInteger width = [(NSString *)arg[@"width"] intValue];
        NSString *colorR = (NSString *)arg[@"colorR"];
        NSString *colorG = (NSString *)arg[@"colorG"];
        NSString *colorB = (NSString *)arg[@"colorB"];
        NSString *colorA = (NSString *)arg[@"colorA"];
        
        UIColor *color = [UIColor colorWithRed:[colorR floatValue] green:[colorG floatValue] blue:[colorB floatValue] alpha:[colorA floatValue]];
        
        [self clientBeginDraw:clientId fromX:[x floatValue] fromY:[y floatValue] withWidth:width withColor:color];
        
        [customView setNeedsDisplay];
    }
    
    else if ([packet.name isEqualToString:@"ContinueDraw"])
    {
        NSString *clientId = (NSString *)arg[@"clientId"];
        NSString *x = (NSString *)arg[@"x"];
        NSString *y = (NSString *)arg[@"y"];
        
        [self clientContinueDraw:clientId atX:[x floatValue] atY:[y floatValue]];
        
        [customView setNeedsDisplay];
    }
}

-(void) addClient:(NSString *)clientId
{
    [customView.lineArrays setObject:[[NSMutableArray alloc] init] forKey:clientId];
    [self.prevXs setObject:@"0.0" forKey:clientId];
    [self.prevYs setObject:@"0.0" forKey:clientId];
}

- (void)pan:(UIPanGestureRecognizer *)pan{
    // get current touchpoint
    self.current = [pan locationInView:customView];
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:self.myClientId forKey:@"clientId"];
    [json setObject:[NSString stringWithFormat:@"%.2f", self.current.x] forKey:@"x"];
    [json setObject:[NSString stringWithFormat:@"%.2f", self.current.y] forKey:@"y"];
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        [json setObject:[NSString stringWithFormat:@"%d", self.currentWidth] forKey:@"width"];
        
        CGFloat *redComponent = malloc(sizeof(CGFloat));
        CGFloat *greenComponent = malloc(sizeof(CGFloat));
        CGFloat *blueComponent = malloc(sizeof(CGFloat));
        CGFloat *alphaComponent = malloc(sizeof(CGFloat));
        
        [self.currentColor getRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent];
        
        [json setObject:[NSString stringWithFormat:@"%.2f", *redComponent] forKey:@"colorR"];
        [json setObject:[NSString stringWithFormat:@"%.2f", *greenComponent] forKey:@"colorG"];
        [json setObject:[NSString stringWithFormat:@"%.2f", *blueComponent] forKey:@"colorB"];
        [json setObject:[NSString stringWithFormat:@"%.2f", *alphaComponent] forKey:@"colorA"];
        
        [self.socketIO sendEvent:@"BeginDraw" withData:json];
        
        [self clientBeginDraw:self.myClientId fromX:self.current.x fromY:self.current.y withWidth:self.currentWidth withColor:self.currentColor];
        
        [customView setNeedsDisplay];
    }
    
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        [self.socketIO sendEvent:@"ContinueDraw" withData:json];
        
        [self clientContinueDraw:self.myClientId atX:self.current.x atY:self.current.y];
        
        [customView setNeedsDisplay];
    }
}

- (void) clientBeginDraw:(NSString *)clientId fromX:(CGFloat)x fromY:(CGFloat)y withWidth:(NSInteger)width withColor:(UIColor *)color
{
    // create new path and new line
    UIBezierPath *newPath = [UIBezierPath bezierPath];
    
    // start point for path
    [newPath moveToPoint:CGPointMake(x, y)];
    
    // create new line in the array
    COATLine *newLine = [[COATLine alloc] init];
    
    // style the line with current client settings
    newLine.color = color;
    newLine.width = width;
    
    // add the line to the line array
    newLine.path = newPath;
    [customView.lineArrays[clientId] addObject:newLine];
    
    [self.prevXs setObject:[NSString stringWithFormat:@"%.2f", x] forKey:clientId];
    [self.prevYs setObject:[NSString stringWithFormat:@"%.2f", y] forKey:clientId];
}

-(void) clientContinueDraw:(NSString *)clientId atX:(CGFloat)x atY:(CGFloat)y
{
    CGPoint previous = CGPointMake([self.prevXs[clientId] floatValue], [self.prevYs[clientId] floatValue]);
    CGPoint current = CGPointMake(x, y);
    CGPoint midPoint = midpoint(previous, current);
    
    // add the point to the latest line in the array
    [((COATLine *) [(NSMutableArray *)(customView.lineArrays[clientId]) lastObject]).path addQuadCurveToPoint:midPoint controlPoint:previous];
    
    [self.prevXs setObject:[NSString stringWithFormat:@"%.2f", x] forKey:clientId];
    [self.prevYs setObject:[NSString stringWithFormat:@"%.2f", y] forKey:clientId];
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
