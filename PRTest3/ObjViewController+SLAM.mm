/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import "ObjViewController.h"
#import "ObjViewController+OpenGL.h"

#import <Structure/Structure.h>
#import <Structure/StructureSLAM.h>


#pragma mark - Utilities

namespace // anonymous namespace for local functions
{
    float deltaRotationAngleBetweenPosesInDegrees (const GLKMatrix4& previousPose, const GLKMatrix4& newPose)
    {
        GLKMatrix4 deltaPose = GLKMatrix4Multiply(newPose,
                                                  // Transpose is equivalent to inverse since we will only use the rotation part.
                                                  GLKMatrix4Transpose(previousPose));
        
        // Get the rotation component of the delta pose
        GLKQuaternion deltaRotationAsQuaternion = GLKQuaternionMakeWithMatrix4(deltaPose);
        
        // Get the angle of the rotation
        const float angleInDegree = GLKQuaternionAngle(deltaRotationAsQuaternion)/M_PI*180;
        
        return angleInDegree;
    }
}

@implementation ObjViewController (SLAM)

#pragma mark - SLAM

// Set up SLAM related objects.
- (void)setupSLAM
{
    NSLog(@"setupSLAM....");
    if (_objslamState.initialized)
        return;
    
    NSLog(@"setupSLAM....start.......................");
    
    // Initialize the scene.
    _objslamState.scene = [[STScene alloc] initWithContext:_objdisplay.context
                                      freeGLTextureUnit:GL_TEXTURE2];
    
    // Initialize the camera pose tracker.
    NSDictionary* trackerOptions = @{
                                     kSTTrackerTypeKey: self.enableNewTrackerSwitch.on ? @(STTrackerDepthAndColorBased) : @(STTrackerDepthBased),
                                     kSTTrackerTrackAgainstModelKey: @TRUE, // tracking against the model is much better for close range scanning.
                                     kSTTrackerQualityKey: @(STTrackerQualityAccurate),
                                     kSTTrackerBackgroundProcessingEnabledKey: @TRUE
                                     };
    
    NSError* trackerInitError = nil;
    
    // Initialize the camera pose tracker.
    _objslamState.tracker = [[STTracker alloc] initWithScene:_objslamState.scene options:trackerOptions error:&trackerInitError];
    
    if (trackerInitError != nil)
    {
        NSLog(@"Error during STTracker initialization: `%@'.", [trackerInitError localizedDescription]);
    }
    
    NSAssert (_objslamState.tracker != nil, @"Could not create a tracker.");
    
    // Initialize the mapper.
    NSDictionary* mapperOptions =
    @{
      kSTMapperVolumeResolutionKey: @[@(round(_objoptions.initialVolumeSizeInMeters.x / _objoptions.initialVolumeResolutionInMeters)),
                                      @(round(_objoptions.initialVolumeSizeInMeters.y / _objoptions.initialVolumeResolutionInMeters)),
                                      @(round(_objoptions.initialVolumeSizeInMeters.z / _objoptions.initialVolumeResolutionInMeters))]
      };
    
    _objslamState.mapper = [[STMapper alloc] initWithScene:_objslamState.scene
                                                options:mapperOptions];
    
    // We need it for the TrackAgainstModel tracker, and for live rendering.
    _objslamState.mapper.liveTriangleMeshEnabled = true;
    
    // Default volume size set in options struct
    _objslamState.mapper.volumeSizeInMeters = _objoptions.initialVolumeSizeInMeters;
    
    // Setup the cube placement initializer.
    NSError* cameraPoseInitializerError = nil;
    _objslamState.cameraPoseInitializer = [[STCameraPoseInitializer alloc]
                                        initWithVolumeSizeInMeters:_objslamState.mapper.volumeSizeInMeters
                                        options:@{kSTCameraPoseInitializerStrategyKey: @(STCameraPoseInitializerStrategyTableTopCube)}
                                        error:&cameraPoseInitializerError];
    NSAssert (cameraPoseInitializerError == nil, @"Could not initialize STCameraPoseInitializer: %@", [cameraPoseInitializerError localizedDescription]);
    
    // Set up the cube renderer with the current volume size.
    _objdisplay.cubeRenderer = [[STCubeRenderer alloc] initWithContext:_objdisplay.context];
    
    // Set up the initial volume size.
    [self adjustVolumeSize:_objslamState.mapper.volumeSizeInMeters];
    
    // Start with cube placement mode
    [self enterCubePlacementState];
    
    NSDictionary* keyframeManagerOptions = @{
                                             kSTKeyFrameManagerMaxSizeKey: @(_objoptions.maxNumKeyFrames),
                                             kSTKeyFrameManagerMaxDeltaTranslationKey: @(_objoptions.maxKeyFrameTranslation),
                                             kSTKeyFrameManagerMaxDeltaRotationKey: @(_objoptions.maxKeyFrameRotation), // 20 degrees.
                                             };
    
    NSError* keyFrameManagerInitError = nil;
    _objslamState.keyFrameManager = [[STKeyFrameManager alloc] initWithOptions:keyframeManagerOptions error:&keyFrameManagerInitError];
    
    NSAssert (keyFrameManagerInitError == nil, @"Could not initialize STKeyFrameManger: %@", [keyFrameManagerInitError localizedDescription]);
    
    _depthAsRgbaVisualizer = [[STDepthToRgba alloc] initWithOptions:@{kSTDepthToRgbaStrategyKey: @(STDepthToRgbaStrategyGray)}
                                                              error:nil];
    
    _objslamState.initialized = true;
}

- (void)resetSLAM
{
    _objslamState.prevFrameTimeStamp = -1.0;
    [_objslamState.mapper reset];
    [_objslamState.tracker reset];
    [_objslamState.scene clear];
    [_objslamState.keyFrameManager clear];
    
    [self enterCubePlacementState];
}

- (void)clearSLAM
{
    _objslamState.initialized = false;
    _objslamState.scene = nil;
    _objslamState.tracker = nil;
    _objslamState.mapper = nil;
    _objslamState.keyFrameManager = nil;
}

- (void)processDepthFrame:(STDepthFrame *)depthFrame
          colorFrameOrNil:(STColorFrame*)colorFrame
{
    NSLog(@"processDepthFrame");
    // Upload the new color image for next rendering.
    if (_useColorCamera && colorFrame != nil)
    {
        NSLog(@"processDepthFrame 1");
        [self uploadGLColorTexture: colorFrame];
    }
    else if(!_useColorCamera)
    {
        NSLog(@"processDepthFrame 2");
        [self uploadGLColorTextureFromDepth:depthFrame];
    }
    
    // Update the projection matrices since we updated the frames.
    {
        NSLog(@"processDepthFrame 3");
        _objdisplay.depthCameraGLProjectionMatrix = [depthFrame glProjectionMatrix];
        if (colorFrame)
        {
            _objdisplay.colorCameraGLProjectionMatrix = [colorFrame glProjectionMatrix];
            NSLog(@"processDepthFrame 4");
        }
    }

    //return;
    
    switch (_objslamState.objscannerState)
    {
        case ObjScannerStateCubePlacement:
        {
            NSLog(@"ObjScannerStateCubePlacement begin");
            // Provide the new depth frame to the cube renderer for ROI highlighting.
            //[_objdisplay.cubeRenderer setDepthFrame:_useColorCamera?[depthFrame registeredToColorFrame:colorFrame]:depthFrame];
            if(_useColorCamera)
            {
                NSLog(@"_useColorCamera 1");
                
                STDepthFrame* newdepth = nil;
                newdepth = [depthFrame registeredToColorFrame:colorFrame];
                
                NSLog(@"_useColorCamera 2");
                
                if(newdepth == nil)
                    NSLog(@"-->newdepth = nil");
                else
                 [_objdisplay.cubeRenderer setDepthFrame:newdepth];
                
                NSLog(@"_useColorCamera 3");
            }
            else
            {
                [_objdisplay.cubeRenderer setDepthFrame:depthFrame];
            }
            
            NSLog(@"ObjScannerStateCubePlacement 1");
            
            // Estimate the new scanning volume position.
            if (GLKVector3Length(_lastGravity) > 1e-5f)
            {
                bool success = [_objslamState.cameraPoseInitializer updateCameraPoseWithGravity:_lastGravity depthFrame:depthFrame error:nil];
                NSAssert (success, @"Camera pose initializer error.");
            }
            
            NSLog(@"ObjScannerStateCubePlacement 2");
            
            // Tell the cube renderer whether there is a support plane or not.
            [_objdisplay.cubeRenderer setCubeHasSupportPlane:_objslamState.cameraPoseInitializer.hasSupportPlane];
            
            NSLog(@"ObjScannerStateCubePlacement 3");
            
            // Enable the scan button if the pose initializer could estimate a pose.
            self.scanButton.enabled = _objslamState.cameraPoseInitializer.hasValidPose;
            
            NSLog(@"ObjScannerStateCubePlacement end");
            break;
        }
            
        case ObjScannerStateScanning:
        {
             //NSLog(@"ObjScannerStateScanning");
            // First try to estimate the 3D pose of the new frame.
            NSError* trackingError = nil;
            
            GLKMatrix4 depthCameraPoseBeforeTracking = [_objslamState.tracker lastFrameCameraPose];
            
            BOOL trackingOk = [_objslamState.tracker updateCameraPoseWithDepthFrame:depthFrame colorFrame:colorFrame error:&trackingError];
            
            // Integrate it into the current mesh estimate if tracking was successful.
            if (trackingOk)
            {
                GLKMatrix4 depthCameraPoseAfterTracking = [_objslamState.tracker lastFrameCameraPose];
                /*
                NSLog(@"depthCameraPoseAfterTracking0: %f, %f, %f, %f",depthCameraPoseAfterTracking.m00, depthCameraPoseAfterTracking.m01, depthCameraPoseAfterTracking.m02, depthCameraPoseAfterTracking.m03);
                NSLog(@"depthCameraPoseAfterTracking1: %f, %f, %f, %f",depthCameraPoseAfterTracking.m10, depthCameraPoseAfterTracking.m11, depthCameraPoseAfterTracking.m12, depthCameraPoseAfterTracking.m13);
                NSLog(@"depthCameraPoseAfterTracking2: %f, %f, %f, %f",depthCameraPoseAfterTracking.m20, depthCameraPoseAfterTracking.m21, depthCameraPoseAfterTracking.m22, depthCameraPoseAfterTracking.m23);
                NSLog(@"depthCameraPoseAfterTracking3: %f, %f, %f, %f",depthCameraPoseAfterTracking.m30, depthCameraPoseAfterTracking.m31, depthCameraPoseAfterTracking.m32, depthCameraPoseAfterTracking.m33);
                */
                // Jack
                bool invertible;
                GLKMatrix4 invBeforeMat = GLKMatrix4Invert(depthCameraPoseBeforeTracking, &invertible);
                GLKMatrix4 cameraMoveMatrix = GLKMatrix4Multiply(depthCameraPoseAfterTracking, invBeforeMat);
                if(self.LVcontroller != nil)
                {
                    NSLog(@"update camera");
                    
                    [self.LVcontroller updateCameraMovementMatrix:cameraMoveMatrix];
                }
                
                
                [_objslamState.mapper integrateDepthFrame:depthFrame cameraPose:depthCameraPoseAfterTracking];
                
                if (colorFrame)
                {
                    // Make sure the pose is in color camera coordinates in case we are not using registered depth.
                    GLKMatrix4 colorCameraPoseInDepthCoordinateSpace;
                    [depthFrame colorCameraPoseInDepthCoordinateFrame:colorCameraPoseInDepthCoordinateSpace.m];
                    GLKMatrix4 colorCameraPoseAfterTracking = GLKMatrix4Multiply(depthCameraPoseAfterTracking,
                                                                                 colorCameraPoseInDepthCoordinateSpace);
                    

                    bool showHoldDeviceStill = false;
                    
                    // Check if the viewpoint has moved enough to add a new keyframe
                    if ([_objslamState.keyFrameManager wouldBeNewKeyframeWithColorCameraPose:colorCameraPoseAfterTracking])
                    {
                        const bool isFirstFrame = (_objslamState.prevFrameTimeStamp < 0.);
                        bool canAddKeyframe = false;
                        
                        if (isFirstFrame) // always add the first frame.
                        {
                            canAddKeyframe = true;
                        }
                        else // for others, check the speed.
                        {
                            float deltaAngularSpeedInDegreesPerSecond = FLT_MAX;
                            NSTimeInterval deltaSeconds = depthFrame.timestamp - _objslamState.prevFrameTimeStamp;
                            
                            // If deltaSeconds is 2x longer than the frame duration of the active video device, do not use it either
                            CMTime frameDuration = self.videoDevice.activeVideoMaxFrameDuration;
                            if (deltaSeconds < (float)frameDuration.value/frameDuration.timescale*2.f)
                            {
                                // Compute angular speed
                                deltaAngularSpeedInDegreesPerSecond = deltaRotationAngleBetweenPosesInDegrees (depthCameraPoseBeforeTracking, depthCameraPoseAfterTracking)/deltaSeconds;
                            }
                            
                            // If the camera moved too much since the last frame, we will likely end up
                            // with motion blur and rolling shutter, especially in case of rotation. This
                            // checks aims at not grabbing keyframes in that case.
                            if (deltaAngularSpeedInDegreesPerSecond < _objoptions.maxKeyframeRotationSpeedInDegreesPerSecond)
                            {
                                canAddKeyframe = true;
                            }
                        }
                        
                        if (canAddKeyframe)
                        {
                            [_objslamState.keyFrameManager processKeyFrameCandidateWithColorCameraPose:colorCameraPoseAfterTracking
                                                                                         colorFrame:colorFrame
                                                                                         depthFrame:nil];
                        }
                        else
                        {
                            // Moving too fast. Hint the user to slow down to capture a keyframe
                            // without rolling shutter and motion blur.
                            showHoldDeviceStill = true;
                        }
                    }
                    
                    if (showHoldDeviceStill)
                        [self showTrackingMessage:@"Please hold still so we can capture a keyframe..."];
                    else
                        [self hideTrackingErrorMessage];
                }
                else
                {
                    [self hideTrackingErrorMessage];
                }
            }
            else if (trackingError.code == STErrorTrackerLostTrack)
            {
                [self showTrackingMessage:@"Tracking Lost! Please Realign or Press Reset."];
            }
            else if (trackingError.code == STErrorTrackerPoorQuality)
            {
                switch ([_objslamState.tracker status])
                {
                    case STTrackerStatusDodgyForUnknownReason:
                    {
                        NSLog(@"STTracker Tracker quality is bad, but we don't know why.");
                        // Don't show anything on screen since this can happen often.
                        break;
                    }
                        
                    case STTrackerStatusFastMotion:
                    {
                        NSLog(@"STTracker Camera moving too fast.");
                        // Don't show anything on screen since this can happen often.
                        break;
                    }
                        
                    case STTrackerStatusTooClose:
                    {
                        NSLog(@"STTracker Too close to the model.");
                        [self showTrackingMessage:@"Too close to the scene! Please step back."];
                        break;
                    }
                        
                    case STTrackerStatusTooFar:
                    {
                        NSLog(@"STTracker Too far from the model.");
                        [self showTrackingMessage:@"Please get closer to the model."];
                        break;
                    }
                        
                    case STTrackerStatusRecovering:
                    {
                        NSLog(@"STTracker Recovering.");
                        [self showTrackingMessage:@"Recovering, please move gently."];
                        break;
                    }
                        
                    case STTrackerStatusModelLost:
                    {
                        NSLog(@"STTracker model not in view.");
                        [self showTrackingMessage:@"Please put the model back in view."];
                        break;
                    }
                    default:
                        NSLog(@"STTracker unknown quality.");
                }
            }
            else
            {
                NSLog(@"[Structure] STTracker Error: %@.", [trackingError localizedDescription]);
            }
            
            _objslamState.prevFrameTimeStamp = depthFrame.timestamp;
            
            break;
        }
            
        case ObjScannerStateViewing:
        default:
        {} // Do nothing, the MeshViewController will take care of this.
    }
}

@end