//
//  RotateGradientView.m
//  PRTest3
//
//  Created by Qing Mao on 4/4/16.
//  Copyright © 2016 Tsung-Yu Tsai. All rights reserved.
//

#import "RotateGradientView.h"

@implementation RotateGradientView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

CGPoint RGV_lastTranslation = CGPointMake(0.0f, 0.0f);

- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    //    if ([gestureRecognizer numberOfTouches] != 2)
    //        return;
    CGPoint translation = [gestureRecognizer translationInView:self];
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
        RGV_lastTranslation = translation;
    else if ( [gestureRecognizer state] == UIGestureRecognizerStateChanged)
        RGV_lastTranslation = translation;
}

@end
