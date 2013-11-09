//
//  COATCustomView.m
//  COAT-iOS-Client
//
//  Created by Brennan Jones on 11/8/2013.
//  Copyright (c) 2013 Brennan Jones. All rights reserved.
//

#import "COATCustomView.h"
#import "COATLine.h"

@implementation COATCustomView

- (void)commonInit {
    // initialization of dictionaries
    self.lineArrays = [[NSMutableDictionary alloc] init];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) [self commonInit];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // draw all lines to the canvas
    for (NSString *key in [self.lineArrays allKeys])
    {
        for (COATLine *line in (NSMutableArray *)(self.lineArrays[key])) {
            UIBezierPath *path = line.path;
            
            path.lineWidth = line.width;
            [line.color setStroke];
            [path stroke];
        }
    }
}

@end
