//
//  COATLine.h
//  COAT-iOS-Client
//
//  Created by Brennan Jones on 11/8/2013.
//  Copyright (c) 2013 Brennan Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface COATLine : NSObject
@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint endPoint;
@property (nonatomic) UIColor *color;
@property (nonatomic) int width;
@property (nonatomic) UIBezierPath *path;
@end
