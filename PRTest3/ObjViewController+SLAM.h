/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#define HAS_LIBCXX

#import "ObjViewController.h"
#import <Structure/Structure.h>
#import <Structure/StructureSLAM.h>

#import "ObjMeshViewController.h"

@interface ObjViewController (SLAM)

- (void)setupSLAM;
- (void)resetSLAM;
- (void)clearSLAM;
- (void)processDepthFrame:(STDepthFrame *)depthFrame
          colorFrameOrNil:(STColorFrame *)colorFrame;

@end
