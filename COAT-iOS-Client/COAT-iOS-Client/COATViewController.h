//
//  COATViewController.h
//  COAT-iOS-Client
//
//  Created by Brennan Jones on 11/8/2013.
//  Copyright (c) 2013 Brennan Jones. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocketIO.h"

@interface COATViewController : UIViewController

@property (nonatomic, strong) SocketIO *socketIO;
@property (nonatomic) NSString *myClientId;

@property (nonatomic) CGPoint current;
@property (nonatomic) CGPoint previous;
@property (nonatomic) UIColor *lineColor;
@property (nonatomic) UIColor *currentColor;
@property (nonatomic) int currentWidth;

- (IBAction)purplePress:(UIButton *)sender;
- (IBAction)bluePress:(UIButton *)sender;
- (IBAction)greenPress:(UIButton *)sender;
- (IBAction)bigPress:(UIButton *)sender;
- (IBAction)smallPress:(UIButton *)sender;

@end
