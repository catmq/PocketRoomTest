/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import "ObjViewController.h"
#import "ObjViewController+Camera.h"
#import "ObjViewController+Sensor.h"
#import "ObjViewController+SLAM.h"
#import "ObjViewController+OpenGL.h"

#include <cmath>

// Needed to determine platform string
#include <sys/types.h>
#include <sys/sysctl.h>

#pragma mark - Utilities

namespace // anonymous namespace for local functions.
{
    BOOL isIpadAir2()
    {
        const char* kernelStringName = "hw.machine";
        NSString* deviceModel;
        {
            size_t size;
            sysctlbyname(kernelStringName, NULL, &size, NULL, 0); // Get the size first
            
            char *stringNullTerminated = (char*)malloc(size);
            sysctlbyname(kernelStringName, stringNullTerminated, &size, NULL, 0); // Now, get the string itself
            
            deviceModel = [NSString stringWithUTF8String:stringNullTerminated];
            free(stringNullTerminated);
        }
        
        if ([deviceModel isEqualToString:@"iPad5,3"]) return YES; // Wi-Fi
        if ([deviceModel isEqualToString:@"iPad5,4"]) return YES; // Wi-Fi + LTE
        return NO;
    }
    
    BOOL getDefaultHighResolutionSettingForCurrentDevice()
    {
        // iPad Air 2 can handle 30 FPS high-resolution, so enable it by default.
        if (isIpadAir2())
            return TRUE;
        
        // Older devices can only handle 15 FPS high-resolution, so keep it disabled by default
        // to avoid showing a low framerate.
        return FALSE;
    }
} // anonymous

#pragma mark - ViewController Setup

@implementation ObjViewController

- (void)dealloc
{
    NSLog(@"ObjViewcontroller dealloc");
    [self.avCaptureSession stopRunning];
    
    
    if ([EAGLContext currentContext] == _objdisplay.context)
    {
        NSLog(@"currentContext == _objdisplay.context");
        [EAGLContext setCurrentContext:nil];
    }
    
        NSLog(@"ObjViewcontroller dealloc 2");
}

- (void)viewDidLoad
{
    NSLog(@"ObjViewController view Did Load");
    [super viewDidLoad];
    
    _calibrationOverlay = nil;
    
    //self.LVcontroller = nil;
    //self.LVcontroller = //[self.storyboard instantiateViewControllerWithIdentifier:@"LoadViewController"];

    [self setupGL];
    
    [self setupUserInterface];
    
    //[self setupObjMeshViewController];
    
    [self setupGestures];
    
    [self setupIMU];
    
    [self setupStructureSensor];
    
    // Later, we’ll set this true if we have a device-specific calibration
    _useColorCamera = [STSensorController approximateCalibrationGuaranteedForDevice];
    
    // Make sure we get notified when the app becomes active to start/restore the sensor state if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    NSLog(@"ObjViewController viewDidLoad end");
    
    // Try to connect to the Structure Sensor and stream if necessary.
    if ([self currentStateNeedsSensor])
        [self connectToStructureSensorAndStartStreaming];
    
    // Abort the current scan if we were still scanning before going into background since we
    // are not likely to recover well.
    if (_objslamState.objscannerState == ObjScannerStateScanning)
    {
        [self resetButtonPressed:self];
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    
    NSLog(@"ObjViewController viewDidAppear");
    [super viewDidAppear:animated];
    
    // The framebuffer will only be really ready with its final size after the view appears.
    [(EAGLView *)self.view setFramebuffer];
    
    [self setupGLViewport];

    [self updateAppStatusMessage];
    
    // We will connect to the sensor when we receive appDidBecomeActive.
    
    NSLog(@"ObjViewController viewDidAppear end");
}

- (void)appDidBecomeActive
{
    NSLog(@"ObjViewController appDidBecomeActive");
    
    if ([self currentStateNeedsSensor])
        [self connectToStructureSensorAndStartStreaming];
    
    // Abort the current scan if we were still scanning before going into background since we
    // are not likely to recover well.
    if (_objslamState.objscannerState == ObjScannerStateScanning)
    {
        [self resetButtonPressed:self];
    }
    
    
    NSLog(@"ObjViewController appDidBecomeActive end");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self respondToMemoryWarning];
}

- (void)setupUserInterface
{
    // Make sure the status bar is hidden.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    // Fully transparent message label, initially.
    self.appStatusMessageLabel.alpha = 0;
    
    // Make sure the label is on top of everything else.
    self.appStatusMessageLabel.layer.zPosition = 100;
    
    // Set the default value for the high resolution switch. If set, will use 2592x1968 as color input.
    self.enableHighResolutionColorSwitch.on = getDefaultHighResolutionSettingForCurrentDevice();
}

// Make sure the status bar is disabled (iOS 7+)
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupGestures
{
    // Register pinch gesture for volume scale adjustment.
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [pinchGesture setDelegate:self];
    [self.view addGestureRecognizer:pinchGesture];
}

- (void)setupObjMeshViewController
{/*
    // The mesh viewer will be used after scanning.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //_meshViewController = [[ObjMeshViewController alloc] initWithNibName:@"MeshView_iPhone" bundle:nil];
        
        _objmeshViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ObjMeshViewController"];
    } else {
        //_meshViewController = [[ObjMeshViewController alloc]  initWithNibName:@"MeshView_iPad" bundle:nil];
        
        _objmeshViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ObjMeshViewController"];
    }
    _objmeshViewController.delegate = self;
    _objmeshViewNavigationController = [[UINavigationController alloc] initWithRootViewController:_objmeshViewController];
    */
    ///
    // The mesh viewer will be used after scanning.
    //_meshViewController = [[MeshViewController alloc] initWithNibName:@"MeshView" bundle:nil];
    NSLog(@"setupObjMeshViewController");
    
    _objmeshViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ObjMeshViewController"];
    
    _objmeshViewController.delegate = self;
    _objmeshViewNavigationController = [[UINavigationController alloc] initWithRootViewController:_objmeshViewController];
    
    if(_objmeshViewController)
    {
        NSLog(@"got _objmeshViewController and  initial");
        
        [_objmeshViewController initMeshView];
    }
    if(_objmeshViewNavigationController)
        NSLog(@"got _meshViewNavigationController");
}

- (void)presentMeshViewer:(STMesh *)mesh
{
    [_objmeshViewController setupGL:_objdisplay.context];
    
    _objmeshViewController.colorEnabled = _useColorCamera;
    _objmeshViewController.mesh = mesh;
    [_objmeshViewController setCameraProjectionMatrix:_objdisplay.depthCameraGLProjectionMatrix];
    
    GLKVector3 volumeCenter = GLKVector3MultiplyScalar([_objslamState.mapper volumeSizeInMeters], 0.5);
    [_objmeshViewController resetMeshCenter:volumeCenter];
    
    [self presentViewController:_objmeshViewNavigationController animated:YES completion:^{}];
}

- (void)enterCubePlacementState
{
    NSLog(@"enterCubePlacementState");
    // Switch to the Scan button.
    self.scanButton.hidden = NO;
    self.doneButton.hidden = YES;
    self.resetButton.hidden = YES;
    
    // We'll enable the button only after we get some initial pose.
    self.scanButton.enabled = NO;
    
    //Jack
    //self.view.userInteractionEnabled = YES;  // recover interactionenable
   // self.view.hidden = YES;/////testttttt
    
    // Cannot be lost in cube placement mode.
    _trackingLostLabel.hidden = YES;
    
    [self setColorCameraParametersForInit];
    
    _objslamState.objscannerState = ObjScannerStateCubePlacement;
    
    [self updateIdleTimer];
}

- (void)enterScanningState
{
    // Switch to the Done button.
    self.scanButton.hidden = YES;
    
    //self.doneButton.hidden = NO;
    self.doneButton.hidden = YES;   // dont need to show the done button to finish scanning and save the obj
    self.view.userInteractionEnabled = NO; //Jack: add this for user can do action on Scanned Room View (which is behind of the front view)
    
    self.resetButton.hidden = NO;
    
    // Tell the mapper if we have a support plane so that it can optimize for it.
    [_objslamState.mapper setHasSupportPlane:_objslamState.cameraPoseInitializer.hasSupportPlane];
    
    _objslamState.tracker.initialCameraPose = _objslamState.cameraPoseInitializer.cameraPose;
    
    // We will lock exposure during scanning to ensure better coloring.
    [self setColorCameraParametersForScanning];
    
    _objslamState.objscannerState = ObjScannerStateScanning;
}

- (void)enterViewingState
{
    // Cannot be lost in view mode.
    [self hideTrackingErrorMessage];
    
    _objappStatus.statusMessageDisabled = true;
    [self updateAppStatusMessage];
    
    // Hide the Scan/Done/Reset button.
    self.scanButton.hidden = YES;
    self.doneButton.hidden = YES;
    self.resetButton.hidden = YES;
    
    [_sensorController stopStreaming];

    if (_useColorCamera)
        [self stopColorCamera];
    
    [_objslamState.mapper finalizeTriangleMeshWithSubsampling:1];
    
    STMesh *mesh = [_objslamState.scene lockAndGetSceneMesh];
    [self presentMeshViewer:mesh];
    
    [_objslamState.scene unlockSceneMesh];
    
    _objslamState.objscannerState = ObjScannerStateViewing;
    
    [self updateIdleTimer];
}

namespace { // anonymous namespace for utility function.
    
    float keepInRange(float value, float minValue, float maxValue)
    {
        if (isnan (value))
            return minValue;
        
        if (value > maxValue)
            return maxValue;
        
        if (value < minValue)
            return minValue;
        
        return value;
    }
    
}

- (void)adjustVolumeSize:(GLKVector3)volumeSize
{
    // Make sure the volume size remains between 10 centimeters and 10 meters.
    volumeSize.x = keepInRange (volumeSize.x, 0.1, 10.f);
    volumeSize.y = keepInRange (volumeSize.y, 0.1, 10.f);
    volumeSize.z = keepInRange (volumeSize.z, 0.1, 10.f);
    
    _objslamState.mapper.volumeSizeInMeters = volumeSize;
    
    _objslamState.cameraPoseInitializer.volumeSizeInMeters = volumeSize;
    [_objdisplay.cubeRenderer adjustCubeSize:_objslamState.mapper.volumeSizeInMeters
                         volumeResolution:_objslamState.mapper.volumeResolution];
    

}

#pragma mark -  Structure Sensor Management

-(BOOL)currentStateNeedsSensor
{
    switch (_objslamState.objscannerState)
    {
        // Initialization and scanning need the sensor.
        case ObjScannerStateCubePlacement:
        case ObjScannerStateScanning:
            return TRUE;
            
        // Other states don't need the sensor.
        default:
            return FALSE;
    }
}

#pragma mark - IMU

- (void)setupIMU
{
    _lastGravity = GLKVector3Make (0,0,0);
    
    // 60 FPS is responsive enough for motion events.
    const float fps = 60.0;
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.accelerometerUpdateInterval = 1.0/fps;
    _motionManager.gyroUpdateInterval = 1.0/fps;
    
    // Limiting the concurrent ops to 1 is a simple way to force serial execution
    _imuQueue = [[NSOperationQueue alloc] init];
    [_imuQueue setMaxConcurrentOperationCount:1];
    
    __weak ObjViewController *weakSelf = self;
    CMDeviceMotionHandler dmHandler = ^(CMDeviceMotion *motion, NSError *error)
    {
        // Could be nil if the self is released before the callback happens.
        if (weakSelf) {
            [weakSelf processDeviceMotion:motion withError:error];
        }
    };
    
    [_motionManager startDeviceMotionUpdatesToQueue:_imuQueue withHandler:dmHandler];
}

- (void)processDeviceMotion:(CMDeviceMotion *)motion withError:(NSError *)error
{
    if (_objslamState.objscannerState == ObjScannerStateCubePlacement)
    {
        // Update our gravity vector, it will be used by the cube placement initializer.
        _lastGravity = GLKVector3Make (motion.gravity.x, motion.gravity.y, motion.gravity.z);
    }
    
    if (_objslamState.objscannerState == ObjScannerStateCubePlacement || _objslamState.objscannerState == ObjScannerStateScanning)
    {
        // The tracker is more robust to fast moves if we feed it with motion data.
        [_objslamState.tracker updateCameraPoseWithMotion:motion];
    }
}

#pragma mark - UI Callbacks

- (IBAction)enableNewTrackerSwitchChanged:(id)sender
{
    // Save the volume size.
    GLKVector3 previousVolumeSize = _objoptions.initialVolumeSizeInMeters;
    if (_objslamState.initialized)
        previousVolumeSize = _objslamState.mapper.volumeSizeInMeters;
    
    // Simulate a full reset to force a creation of a new tracker.
    [self resetButtonPressed:self.resetButton];
    [self clearSLAM];
    [self setupSLAM];
    
    // Restore the volume size cleared by the full reset.
    _objslamState.mapper.volumeSizeInMeters = previousVolumeSize;
    [self adjustVolumeSize:_objslamState.mapper.volumeSizeInMeters];
}

- (IBAction)enableHighResolutionColorSwitchChanged:(id)sender
{
    if (self.avCaptureSession)
    {
        [self stopColorCamera];
        if (_useColorCamera)
            [self startColorCamera];
    }
    
    // Force a scan reset since we cannot changing the image resolution during the scan is not
    // supported by STColorizer.
    [self resetButtonPressed:self.resetButton];
}

- (IBAction)scanButtonPressed:(id)sender
{
    //This is where we will perform our function
    [self enterScanningState];
    
}

- (IBAction)resetButtonPressed:(id)sender
{
    [self resetSLAM];
}

- (IBAction)doneButtonPressed:(id)sender
{
    [self enterViewingState];
    
}

// Manages whether we can let the application sleep.
-(void)updateIdleTimer
{
    if ([self isStructureConnectedAndCharged] && [self currentStateNeedsSensor])
    {
        // Do not let the application sleep if we are currently using the sensor data.
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    else
    {
        // Let the application sleep if we are only viewing the mesh or if no sensors are connected.
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

- (void)showTrackingMessage:(NSString*)message
{
    self.trackingLostLabel.text = message;
    self.trackingLostLabel.hidden = NO;
}

- (void)hideTrackingErrorMessage
{
    self.trackingLostLabel.hidden = YES;
}

- (void)showAppStatusMessage:(NSString *)msg
{
    _objappStatus.needsDisplayOfStatusMessage = true;
    [self.view.layer removeAllAnimations];
    
    [self.appStatusMessageLabel setText:msg];
    [self.appStatusMessageLabel setHidden:NO];
    
    // Progressively show the message label.
    [self.view setUserInteractionEnabled:false];
    [UIView animateWithDuration:0.5f animations:^{
        self.appStatusMessageLabel.alpha = 1.0f;
    }completion:nil];
}

- (void)hideAppStatusMessage
{
    if (!_objappStatus.needsDisplayOfStatusMessage)
        return;
    
    _objappStatus.needsDisplayOfStatusMessage = false;
    [self.view.layer removeAllAnimations];
    
    __weak ObjViewController *weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         weakSelf.appStatusMessageLabel.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         // If nobody called showAppStatusMessage before the end of the animation, do not hide it.
                         if (!_objappStatus.needsDisplayOfStatusMessage)
                         {
                             // Could be nil if the self is released before the callback happens.
                             if (weakSelf) {
                                 [weakSelf.appStatusMessageLabel setHidden:YES];
                                 [weakSelf.view setUserInteractionEnabled:true];
                             }
                         }
     }];
}

-(void)updateAppStatusMessage
{
    // Skip everything if we should not show app status messages (e.g. in viewing state).
    if (_objappStatus.statusMessageDisabled)
    {
        [self hideAppStatusMessage];
        return;
    }
    
    // First show sensor issues, if any.
    switch (_objappStatus.sensorStatus)
    {
        case ObjAppStatus::SensorStatusOk:
        {
            break;
        }
            
        case ObjAppStatus::SensorStatusNeedsUserToConnect:
        {
            [self showAppStatusMessage:_objappStatus.pleaseConnectSensorMessage];
            return;
        }
            
        case ObjAppStatus::SensorStatusNeedsUserToCharge:
        {
            [self showAppStatusMessage:_objappStatus.pleaseChargeSensorMessage];
            return;
        }
    }
    
    // Then show color camera permission issues, if any.
    if (!_objappStatus.colorCameraIsAuthorized)
    {
        [self showAppStatusMessage:_objappStatus.needColorCameraAccessMessage];
        return;
    }

    // If we reach this point, no status to show.
    [self hideAppStatusMessage];
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        if (_objslamState.objscannerState == ObjScannerStateCubePlacement)
        {
            _volumeScale.initialPinchScale = _volumeScale.currentScale / [gestureRecognizer scale];
        }
    }
    else if ([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        if(_objslamState.objscannerState == ObjScannerStateCubePlacement)
        {
            // In some special conditions the gesture recognizer can send a zero initial scale.
            if (!isnan (_volumeScale.initialPinchScale))
            {
                _volumeScale.currentScale = [gestureRecognizer scale] * _volumeScale.initialPinchScale;
                
                // Don't let our scale multiplier become absurd
                _volumeScale.currentScale = keepInRange(_volumeScale.currentScale, 0.01, 1000.f);
                
                GLKVector3 newVolumeSize = GLKVector3MultiplyScalar(_objoptions.initialVolumeSizeInMeters, _volumeScale.currentScale);
                
                [self adjustVolumeSize:newVolumeSize];
            }
        }
    }
}

#pragma mark - MeshViewController delegates

- (void)meshViewWillDismiss
{
    // If we are running colorize work, we should cancel it.
    if (_naiveColorizeTask)
    {
        [_naiveColorizeTask cancel];
        _naiveColorizeTask = nil;
    }
    if (_enhancedColorizeTask)
    {
        [_enhancedColorizeTask cancel];
        _enhancedColorizeTask = nil;
    }
    
    [_objmeshViewController hideMeshViewerMessage];
}

- (void)meshViewDidDismiss
{
    _objappStatus.statusMessageDisabled = false;
    [self updateAppStatusMessage];
    
    [self connectToStructureSensorAndStartStreaming];
    [self resetSLAM];
}

- (void)backgroundTask:(STBackgroundTask *)sender didUpdateProgress:(double)progress
{
    if (sender == _naiveColorizeTask)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_objmeshViewController showMeshViewerMessage:[NSString stringWithFormat:@"Processing: % 3d%%", int(progress*20)]];
        });
    }
    else if (sender == _enhancedColorizeTask)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_objmeshViewController showMeshViewerMessage:[NSString stringWithFormat:@"Processing: % 3d%%", int(progress*80)+20]];
        });
    }
}

- (BOOL)meshViewDidRequestColorizing:(STMesh*)mesh previewCompletionHandler:(void (^)())previewCompletionHandler enhancedCompletionHandler:(void (^)())enhancedCompletionHandler
{
    if (_naiveColorizeTask) // already one running?
    {
        NSLog(@"Already one colorizing task running!");
        return FALSE;
    }

    _naiveColorizeTask = [STColorizer
                     newColorizeTaskWithMesh:mesh
                     scene:_objslamState.scene
                     keyframes:[_objslamState.keyFrameManager getKeyFrames]
                     completionHandler: ^(NSError *error)
                     {
                         if (error != nil) {
                             NSLog(@"Error during colorizing: %@", [error localizedDescription]);
                         }
                         else
                         {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 previewCompletionHandler();
                                 _objmeshViewController.mesh = mesh;
                                 [self performEnhancedColorize:(STMesh*)mesh enhancedCompletionHandler:enhancedCompletionHandler];
                             });
                             _naiveColorizeTask = nil;
                         }
                     }
                     options:@{kSTColorizerTypeKey: @(STColorizerPerVertex),
                               kSTColorizerPrioritizeFirstFrameColorKey: @(_objoptions.prioritizeFirstFrameColor)}
                     error:nil];
    
    if (_naiveColorizeTask)
    {
        _naiveColorizeTask.delegate = self;
        [_naiveColorizeTask start];
        return TRUE;
    }
    
    return FALSE;
}

- (void)performEnhancedColorize:(STMesh*)mesh enhancedCompletionHandler:(void (^)())enhancedCompletionHandler
{
    _enhancedColorizeTask =[STColorizer
       newColorizeTaskWithMesh:mesh
       scene:_objslamState.scene
       keyframes:[_objslamState.keyFrameManager getKeyFrames]
       completionHandler: ^(NSError *error)
       {
           if (error != nil) {
               NSLog(@"Error during colorizing: %@", [error localizedDescription]);
           }
           else
           {
               dispatch_async(dispatch_get_main_queue(), ^{
                   enhancedCompletionHandler();
                   _objmeshViewController.mesh = mesh;
               });
               _enhancedColorizeTask = nil;
           }
       }
       options:@{kSTColorizerTypeKey: @(STColorizerTextureMapForObject),
                 kSTColorizerPrioritizeFirstFrameColorKey: @(_objoptions.prioritizeFirstFrameColor),
                 kSTColorizerQualityKey: @(_objoptions.colorizerQuality),
                 kSTColorizerTargetNumberOfFacesKey: @(_objoptions.colorizerTargetNumFaces)} // 20k faces is enough for most objects.
       error:nil];
    
    if (_enhancedColorizeTask)
    {
        // We don't need the keyframes anymore now that the final colorizing task was started.
        // Clearing it now gives a chance to early release the keyframe memory when the colorizer
        // stops needing them.
        [_objslamState.keyFrameManager clear];
        
        _enhancedColorizeTask.delegate = self;
        [_enhancedColorizeTask start];
    }
}


- (void) respondToMemoryWarning
{
    switch( _objslamState.objscannerState )
    {
        case ObjScannerStateViewing:
        {
            // If we are running a colorizing task, abort it
            if( _enhancedColorizeTask != nil && !_objslamState.showingMemoryWarning )
            {
                _objslamState.showingMemoryWarning = true;
                
                // stop the task
                [_enhancedColorizeTask cancel];
                _enhancedColorizeTask = nil;
                
                // hide progress bar
                [_objmeshViewController hideMeshViewerMessage];
                
                UIAlertController *alertCtrl= [UIAlertController alertControllerWithTitle:@"Memory Low"
                                                                                  message:@"Colorizing was canceled."
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                           {
                                               _objslamState.showingMemoryWarning = false;
                                           }];
                
                [alertCtrl addAction:okAction];
                
                // show the alert in the meshViewController
                [_objmeshViewController presentViewController:alertCtrl animated:YES completion:nil];
            }
            
            break;
        }
        case ObjScannerStateScanning:
        {
            if( !_objslamState.showingMemoryWarning )
            {
                _objslamState.showingMemoryWarning = true;
                
                UIAlertController *alertCtrl= [UIAlertController alertControllerWithTitle:@"Memory Low"
                                                                                  message:@"Scanning will be stopped to avoid loss."
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                           {
                                               _objslamState.showingMemoryWarning = false;
                                               [self enterViewingState];
                                           }];
                
                
                [alertCtrl addAction:okAction];
                
                // show the alert
                [self presentViewController:alertCtrl animated:YES completion:nil];
            }
            
            break;
        }
        default:
        {
            // not much we can do here
        }
    }
}
@end
