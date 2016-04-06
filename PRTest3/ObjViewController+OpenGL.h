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

@interface ObjViewController (OpenGL)

- (void)setupGL;
- (void)setupGLViewport;
- (void)uploadGLColorTexture:(STColorFrame*)colorFrame;
- (void)uploadGLColorTextureFromDepth:(STDepthFrame*)depthFrame;
- (void)renderSceneForDepthFrame:(STDepthFrame*)depthFrame colorFrameOrNil:(STColorFrame*)colorFrame;

@end
