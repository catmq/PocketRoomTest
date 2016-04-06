/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import "ObjViewController.h"
#import "ObjViewController+OpenGL.h"

#include <cmath>
#include <limits>

@implementation ObjViewController (OpenGL)

GLubyte* mpixels;
GLubyte* cpixels;

#pragma mark -  OpenGL

- (void)setupGL
{
    // Create an EAGLContext for our EAGLView.
    _objdisplay.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_objdisplay.context) { NSLog(@"Failed to create ES context"); }
    
    [EAGLContext setCurrentContext:_objdisplay.context];
    [(EAGLView*)self.view setContext:_objdisplay.context];
    [(EAGLView*)self.view setFramebuffer];
    
    _objdisplay.yCbCrTextureShader = [[STGLTextureShaderYCbCr alloc] init];
    _objdisplay.rgbaTextureShader = [[STGLTextureShaderRGBA alloc] init];
    
    // Set up a textureCache for images output by the color camera.
    CVReturn texError0 = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _objdisplay.context, NULL, &_objdisplay.videoTextureCache);
    if (texError0) { NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", texError0); return; }
    
    // Scanning volume feedback.
    {
        // We configured the sensor for QVGA depth.
        const int w = 320, h = 240;
        
        // Create the RGBA buffer to store the feedback pixels.
        _objdisplay.scanningVolumeFeedbackBuffer.resize (w*h*4, 0);
        
        // Create the GL texture to display the feedback.
        glGenTextures(1, &_objdisplay.scanningVolumeFeedbackTexture);
        glBindTexture(GL_TEXTURE_2D, _objdisplay.scanningVolumeFeedbackTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        
        // Jack
        // combine view
        CGSize FrameBuffersize = [(EAGLView*)self.view getFramebufferSize];
        _objdisplay.combineviewBuffer.resize (FrameBuffersize.width*FrameBuffersize.height*4, 0);
        
        // Create the GL texture to display the feedback.
        glGenTextures(1, &_objdisplay.combineviewTexture);
        glBindTexture(GL_TEXTURE_2D, _objdisplay.combineviewTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FrameBuffersize.width, FrameBuffersize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

        
        // camera view
        glGenTextures(1, &_objdisplay.cameraviewTexture);
        glBindTexture(GL_TEXTURE_2D, _objdisplay.cameraviewTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FrameBuffersize.width, FrameBuffersize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        
        
        glGenFramebuffers(1, &_objdisplay.cameraFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _objdisplay.cameraFrameBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _objdisplay.cameraviewTexture, 0);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER_OES);
        if(status != GL_FRAMEBUFFER_COMPLETE_OES) {
            printf("failed to make complete framebuffer object %x", status);
        }
        
        //meshview
        _objdisplay.meshviewBuffer.resize (FrameBuffersize.width*FrameBuffersize.height*4, 0);
        glGenTextures(1, &_objdisplay.meshviewTexture);
        glBindTexture(GL_TEXTURE_2D, _objdisplay.meshviewTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FrameBuffersize.width, FrameBuffersize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        
        
        glGenFramebuffers(1, &_objdisplay.meshFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _objdisplay.meshFrameBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _objdisplay.meshviewTexture, 0);
        
        status = glCheckFramebufferStatus(GL_FRAMEBUFFER_OES);
        if(status != GL_FRAMEBUFFER_COMPLETE_OES) {
            printf("failed to make complete framebuffer object %x", status);
        }
        
    }

    /*
    // Set up texture and textureCache for images output by the color camera.
    CVReturn texError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _objdisplay.context, NULL, &_objdisplay.videoTextureCache);
    if (texError) { NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", texError); }
    */
    
    glGenTextures(1, &_objdisplay.depthAsRgbaTexture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _objdisplay.depthAsRgbaTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)setupGLViewport
{
    const float vgaAspectRatio = 640.0f/480.0f;
    
    // Helper function to handle float precision issues.
    auto nearlyEqual = [] (float a, float b) { return std::abs(a-b) < std::numeric_limits<float>::epsilon(); };
    
    CGSize frameBufferSize = [(EAGLView*)self.view getFramebufferSize];
    
    float imageAspectRatio = 1.0f;
    
    float framebufferAspectRatio = frameBufferSize.width/frameBufferSize.height;
    
    // The iPad's diplay conveniently has a 4:3 aspect ratio just like our video feed.
    // Some iOS devices need to render to only a portion of the screen so that we don't distort
    // our RGB image. Alternatively, you could enlarge the viewport (losing visual information),
    // but fill the whole screen.
    if (!nearlyEqual (framebufferAspectRatio, vgaAspectRatio))
        imageAspectRatio = 480.f/640.0f;
    
    _objdisplay.viewport[0] = 0;
    _objdisplay.viewport[1] = 0;
    _objdisplay.viewport[2] = frameBufferSize.width*imageAspectRatio;
    _objdisplay.viewport[3] = frameBufferSize.height;
    
    
    //Jack
    CGSize FrameBuffersize = [(EAGLView*)self.view getFramebufferSize];
    mpixels = (GLubyte*) malloc(FrameBuffersize.width * FrameBuffersize.height * sizeof(GLubyte) * 4);
    cpixels = (GLubyte*) malloc(FrameBuffersize.width * FrameBuffersize.height * sizeof(GLubyte) * 4);
}

- (void)uploadGLColorTexture:(STColorFrame*)colorFrame
{
    GLenum err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"******** Part -3 --- Here: glError is = %x", err0);
    
    if (!_objdisplay.videoTextureCache)
    {
        NSLog(@"Cannot upload color texture: No texture cache is present.");
        return;
    }
    
    // Clear the previous color texture.
    if (_objdisplay.lumaTexture)
    {
        //NSLog(@"1");
        CFRelease (_objdisplay.lumaTexture);
        _objdisplay.lumaTexture = NULL;
    }
    
    // Clear the previous color texture
    if (_objdisplay.chromaTexture)
    {
        //NSLog(@"2");
        CFRelease (_objdisplay.chromaTexture);
        _objdisplay.chromaTexture = NULL;
    }
    
    // Displaying image with width over 1280 is an overkill. Downsample it to save bandwidth.
    while( colorFrame.width > 2560 )
        colorFrame = colorFrame.halfResolutionColorFrame;
    
    
    //NSLog(@"colorframe.width: %d", colorFrame.width);
    
    
    // Jack add
    /*
    // Clear the previous color texture
    if (_objdisplay.videoTextureCache)
    {
        //NSLog(@"2");
        CFRelease (_objdisplay.videoTextureCache);
        _objdisplay.videoTextureCache = NULL;
    }
    
    EAGLContext *context = [EAGLContext currentContext];//_objdisplay.context; //
    assert (context != nil);
    
    if(!context)
        NSLog(@"[EAGLContext currentContext] = NULL");
    
    //if (_objdisplay.videoTextureCache == NULL)
    {
        NSLog(@"HHHHHHHHHHHHHEEEEEEEEEEERRRRRRRRRRREEEEEEEEEEEEE");
        CVReturn texError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_objdisplay.videoTextureCache);
        if (texError) { NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", texError); }
    }
     */
    //Jack
    
    
    CVReturn err;
    
    // Allow the texture cache to do internal cleanup.
    CVOpenGLESTextureCacheFlush(_objdisplay.videoTextureCache, 0);
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(colorFrame.sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    OSType pixelFormat = CVPixelBufferGetPixelFormatType (pixelBuffer);
    NSAssert(pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, @"YCbCr is expected!");
    
    glActiveTexture (GL_TEXTURE0);
    
    err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"******** Part 1 --- Here: glError is = %x", err0);
    
    // Create an new Y texture from the video texture cache.
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _objdisplay.videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       (int)width,
                                                       (int)height,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_objdisplay.lumaTexture);
    
    if (err)
    {
        NSLog(@"Error with CVOpenGLESTextureCacheCreateTextureFromImage: %d", err);
        return;
    }
    
    // Set good rendering properties for the new texture.
    glBindTexture(CVOpenGLESTextureGetTarget(_objdisplay.lumaTexture), CVOpenGLESTextureGetName(_objdisplay.lumaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"******** Part 2 --- Here: glError is = %x", err0);
    
    //NSLog(@"5 w:%d, h:%d",(int)width, (int)height);
    
    // Activate the default texture unit.
    glActiveTexture (GL_TEXTURE1);
    
    
    // Check for OpenGL errors
    err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"******** Part 3 --- Here: glError is = %x", err0);

    
    // Create an new CbCr texture from the video texture cache.
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _objdisplay.videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       (int)width/2,
                                                       (int)height/2,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_objdisplay.chromaTexture);
    
    if (err)
    {
        NSLog(@"Error with CVOpenGLESTextureCacheCreateTextureFromImage: %d", err);
        return;
    }
    
    // Set rendering properties for the new texture.
    glBindTexture(CVOpenGLESTextureGetTarget(_objdisplay.chromaTexture), CVOpenGLESTextureGetName(_objdisplay.chromaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    // Check for OpenGL errors
    err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"******** Part 4 --- Here: glError is = %x", err0);
    
    //glBindTexture(GL_TEXTURE_2D, 0);
    
    
}

- (void)uploadGLColorTextureFromDepth:(STDepthFrame*)depthFrame
{
    
    [_depthAsRgbaVisualizer convertDepthFrameToRgba:depthFrame];
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, _objdisplay.depthAsRgbaTexture);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _depthAsRgbaVisualizer.width, _depthAsRgbaVisualizer.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _depthAsRgbaVisualizer.rgbaBuffer);
    
}


- (void)renderSceneForDepthFrame:(STDepthFrame*)depthFrame colorFrameOrNil:(STColorFrame*)colorFrame
{
    NSLog(@"renderSceneForDepthFrame");
    //return;
    // Activate our view framebuffer.
    [(EAGLView *)self.view setFramebuffer];
    
    
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClear(GL_DEPTH_BUFFER_BIT);
    
    glViewport (_objdisplay.viewport[0], _objdisplay.viewport[1], _objdisplay.viewport[2], _objdisplay.viewport[3]);
    
    switch (_objslamState.objscannerState)
    {
        case ObjScannerStateCubePlacement:
        {
            // Render the background image from the color camera.
            [self renderCameraImage];
            
            if (_objslamState.cameraPoseInitializer.hasValidPose)
            {
                GLKMatrix4 depthCameraPose = _objslamState.cameraPoseInitializer.cameraPose;
                
                GLKMatrix4 cameraViewpoint;
                float alpha;
                if (_useColorCamera)
                {
                    // Make sure the viewpoint is always to color camera one, even if not using registered depth.
                    
                    GLKMatrix4 colorCameraPoseInStreamCoordinateSpace;
                    [depthFrame colorCameraPoseInDepthCoordinateFrame:colorCameraPoseInStreamCoordinateSpace.m];
                    
                    // colorCameraPoseInWorld
                    cameraViewpoint = GLKMatrix4Multiply(depthCameraPose, colorCameraPoseInStreamCoordinateSpace);
                    alpha = 0.5;
                }
                else
                {
                    cameraViewpoint = depthCameraPose;
                    alpha = 1.0;
                }
                
                // Highlighted depth values inside the current volume area.
                [_objdisplay.cubeRenderer renderHighlightedDepthWithCameraPose:cameraViewpoint alpha:alpha];
                
                // Render the wireframe cube corresponding to the current scanning volume.
                [_objdisplay.cubeRenderer renderCubeOutlineWithCameraPose:cameraViewpoint
                                                      depthTestEnabled:false
                                                  occlusionTestEnabled:true];
                
            }
            
            break;
        }
            
        case ObjScannerStateScanning:
        {
            // Enable GL blending to show the mesh with some transparency.
            glEnable (GL_BLEND);
            
            // Render the background image from the color camera.
            [self renderCameraImage];   // render to texture2
            
            
            ///Jack---render the camera view to cameraview texture, get data
            CGSize FrameBuffersize = [(EAGLView*)self.view getFramebufferSize];
            
            
            glBindFramebuffer(GL_FRAMEBUFFER, _objdisplay.cameraFrameBuffer);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _objdisplay.cameraviewTexture, 0);
            // set the viewport as the FBO won't be the same dimension as the screen
             
            glClearColor(0.0, 0.0, 0.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            glClear(GL_DEPTH_BUFFER_BIT);
            
            glViewport(0, 0, FrameBuffersize.width, FrameBuffersize.height);
            
            [self renderCameraImage];   // render to new texture
            
            //GLubyte* cpixels = (GLubyte*) malloc(FrameBuffersize.width * FrameBuffersize.height * sizeof(GLubyte) * 4);
            glReadPixels(0, 0, FrameBuffersize.width, FrameBuffersize.height, GL_RGBA, GL_UNSIGNED_BYTE, cpixels);
            [(EAGLView *)self.view setFramebuffer];
            glViewport (_objdisplay.viewport[0], _objdisplay.viewport[1], _objdisplay.viewport[2], _objdisplay.viewport[3]);
            NSLog(@"viewport: %f, %f, %f, %f",_objdisplay.viewport[0], _objdisplay.viewport[1], _objdisplay.viewport[2], _objdisplay.viewport[3]);

            ///---Jack
            
            
            
            // Render the current mesh reconstruction using the last estimated camera pose.
            
            GLKMatrix4 depthCameraPose = [_objslamState.tracker lastFrameCameraPose];
            
            NSLog(@"depthCameraPose0: %f, %f, %f, %f",depthCameraPose.m00, depthCameraPose.m01, depthCameraPose.m02, depthCameraPose.m03);
            NSLog(@"depthCameraPose1: %f, %f, %f, %f",depthCameraPose.m10, depthCameraPose.m11, depthCameraPose.m12, depthCameraPose.m13);
            NSLog(@"depthCameraPose2: %f, %f, %f, %f",depthCameraPose.m20, depthCameraPose.m21, depthCameraPose.m22, depthCameraPose.m23);
            NSLog(@"depthCameraPose3: %f, %f, %f, %f",depthCameraPose.m30, depthCameraPose.m31, depthCameraPose.m32, depthCameraPose.m33);
            
            GLKMatrix4 cameraGLProjection;
            if (_useColorCamera)
            {
                NSLog(@"use colorcamera");
                cameraGLProjection = colorFrame.glProjectionMatrix;
            }
            else
            {
                cameraGLProjection = depthFrame.glProjectionMatrix;
            }
            
            NSLog(@"cameraGLProjection0: %f, %f, %f, %f",cameraGLProjection.m00, cameraGLProjection.m01, cameraGLProjection.m02, cameraGLProjection.m03);
            NSLog(@"cameraGLProjection1: %f, %f, %f, %f",cameraGLProjection.m10, cameraGLProjection.m11, cameraGLProjection.m12, cameraGLProjection.m13);
            NSLog(@"cameraGLProjection2: %f, %f, %f, %f",cameraGLProjection.m20, cameraGLProjection.m21, cameraGLProjection.m22, cameraGLProjection.m23);
            NSLog(@"cameraGLProjection3: %f, %f, %f, %f",cameraGLProjection.m30, cameraGLProjection.m31, cameraGLProjection.m32, cameraGLProjection.m33);
            
            GLKMatrix4 cameraViewpoint;
            if (_useColorCamera && !_objoptions.useHardwareRegisteredDepth)
            {
                // If we want to use the color camera viewpoint, and are not using registered depth, then
                // we need to deduce the color camera pose from the depth camera pose.
                
                GLKMatrix4 colorCameraPoseInDepthCoordinateSpace;
                [depthFrame colorCameraPoseInDepthCoordinateFrame:colorCameraPoseInDepthCoordinateSpace.m];
                
                // colorCameraPoseInWorld
                cameraViewpoint = GLKMatrix4Multiply(depthCameraPose, colorCameraPoseInDepthCoordinateSpace);
            }
            else
            {
                cameraViewpoint = depthCameraPose;
            }
            
            NSLog(@"cameraViewpoint0: %f, %f, %f, %f",cameraViewpoint.m00, cameraViewpoint.m01, cameraViewpoint.m02, cameraViewpoint.m03);
            NSLog(@"cameraViewpoint1: %f, %f, %f, %f",cameraViewpoint.m10, cameraViewpoint.m11, cameraViewpoint.m12, cameraViewpoint.m13);
            NSLog(@"cameraViewpoint2: %f, %f, %f, %f",cameraViewpoint.m20, cameraViewpoint.m21, cameraViewpoint.m22, cameraViewpoint.m23);
            NSLog(@"cameraViewpoint3: %f, %f, %f, %f",cameraViewpoint.m30, cameraViewpoint.m31, cameraViewpoint.m32, cameraViewpoint.m33);
            
            //update camera in room model
            if(self.LVcontroller != nil)
            {
                bool invertible;
                
                GLKMatrix4 invModelView = GLKMatrix4Invert(cameraViewpoint, &invertible);
                NSLog(@"invModelView0: %f, %f, %f, %f",invModelView.m00, invModelView.m01, invModelView.m02, invModelView.m03);
                NSLog(@"invModelView1: %f, %f, %f, %f",invModelView.m10, invModelView.m11, invModelView.m12, invModelView.m13);
                NSLog(@"invModelView2: %f, %f, %f, %f",invModelView.m20, invModelView.m21, invModelView.m22, invModelView.m23);
                NSLog(@"invModelView3: %f, %f, %f, %f",invModelView.m30, invModelView.m31, invModelView.m32, invModelView.m33);
                
                
                //[self.LVcontroller updateTransformProjectMatrix:cameraGLProjection ModelMatrix:invModelView];
            }
            ///Jack---render the mesh in the volumne to meshtexture, get data
            glBindFramebuffer(GL_FRAMEBUFFER, _objdisplay.meshFrameBuffer);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _objdisplay.meshviewTexture, 0);
            glClearColor(0.0, 0.0, 0.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            glClear(GL_DEPTH_BUFFER_BIT);
            // set the viewport as the FBO won't be the same dimension as the screen
            glViewport(0, 0, FrameBuffersize.width, FrameBuffersize.height);
            
            [_objslamState.scene renderMeshFromViewpoint:cameraViewpoint
                                   cameraGLProjection:cameraGLProjection
                                                alpha:1.0
                             highlightOutOfRangeDepth:true
                                            wireframe:false];   // render to new texture
            
            //GLubyte* mpixels = (GLubyte*) malloc(FrameBuffersize.width * FrameBuffersize.height * sizeof(GLubyte) * 4);
            glReadPixels(0, 0, FrameBuffersize.width, FrameBuffersize.height, GL_RGBA, GL_UNSIGNED_BYTE, mpixels);
            
            
            [(EAGLView *)self.view setFramebuffer];
            glClearColor(0.0, 0.0, 0.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            glClear(GL_DEPTH_BUFFER_BIT);
            glViewport (_objdisplay.viewport[0], _objdisplay.viewport[1], _objdisplay.viewport[2], _objdisplay.viewport[3]);
            NSLog(@"viewport: %f, %f, %f, %f",_objdisplay.viewport[0], _objdisplay.viewport[1], _objdisplay.viewport[2], _objdisplay.viewport[3]);
            

            
            
            // Compare the mesh and cameraview data to get the mesh shape filled with camera view
            [self renderMeshwithCameraviewdata:cpixels Meshviewdata:mpixels framebuffersize:FrameBuffersize];
            
            glDisable (GL_BLEND);
            
            
            // Render the wireframe cube corresponding to the scanning volume.
            // Here we don't enable occlusions to avoid performance hit.
            //[_objdisplay.cubeRenderer renderCubeOutlineWithCameraPose:cameraViewpoint
             //                                    depthTestEnabled:true
             //                                 occlusionTestEnabled:false];
            
            
            
           // Life Camera Feed Culling
           // [self renderScanningVolumeFeedbackOverlayWithDepthFrame:depthFrame colorFrame:colorFrame cameraViewPoint:cameraViewpoint];
            
            break;
            
            
        }
            
            // MeshViewerController handles this.
        case ObjScannerStateViewing:
        default: {}
    };
    
    
    // Check for OpenGL errors
    GLenum err = glGetError ();
    if (err != GL_NO_ERROR)
        NSLog(@"glError is = %x", err);
    
    // Display the rendered framebuffer.
    //NSLog(@"ObjviewController presentFramebuffer");
    [(EAGLView *)self.view presentFramebuffer];
}

// Jack
- (void)renderMeshwithCameraviewdata:(GLubyte*)cpixels Meshviewdata:(GLubyte*)mpixels framebuffersize:(CGSize)FrameBuffersize
{
    
    glActiveTexture(GL_TEXTURE2);
    
    glBindTexture(GL_TEXTURE_2D, _objdisplay.combineviewTexture);
    
    int cols = FrameBuffersize.width, rows = FrameBuffersize.height;
    NSLog(@"renderMeshwithCameraviewdata FrameBuffer: %d, %d", cols, rows);
    
    // Fill the feedback RGBA buffer.
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < cols; ++c)
        {
            const int pixelIndex = r*cols + c;
            const int tIndex = (rows-1-r)*cols + c;
            
            if(mpixels[4*tIndex])
            {
                _objdisplay.combineviewBuffer[4*pixelIndex] = cpixels[4*tIndex];
                _objdisplay.combineviewBuffer[4*pixelIndex+1] = cpixels[4*tIndex+1];
                _objdisplay.combineviewBuffer[4*pixelIndex+2] = cpixels[4*tIndex+2];
                _objdisplay.combineviewBuffer[4*pixelIndex+3] = cpixels[4*tIndex+3];
            }
            else{
                _objdisplay.combineviewBuffer[4*pixelIndex] = 0;
                _objdisplay.combineviewBuffer[4*pixelIndex+1] = 0;
                _objdisplay.combineviewBuffer[4*pixelIndex+2] = 0;
                _objdisplay.combineviewBuffer[4*pixelIndex+3] = 0;
            }
        }
    
    // Upload the texture to the GPU.
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, cols, rows, GL_RGBA, GL_UNSIGNED_BYTE, _objdisplay.combineviewBuffer.data());
    
    
    // Rendering it with blending enabled to apply the overlay on the previously rendered buffer.
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ZERO); //src: combineviewBuffer   dst:rgbaTextureShader ??
    
    [_objdisplay.rgbaTextureShader useShaderProgram];
    [_objdisplay.rgbaTextureShader renderTexture:GL_TEXTURE2];
    
    
    glActiveTexture(GL_TEXTURE2);
    glDisable(GL_TEXTURE_2D);
}



- (void)renderOnlyfromGeoWithDepthFrame:(STDepthFrame*)depthFrame colorFrame:(STColorFrame*)colorFrame cameraViewPoint:(GLKMatrix4)cameraViewPoint cameraviewdata:(GLubyte*)pixels framebuffersize:(CGSize)FrameBuffersize
{
    
    glActiveTexture(GL_TEXTURE2);
    
    
    
    glBindTexture(GL_TEXTURE_2D, _objdisplay.scanningVolumeFeedbackTexture);
    
    int cols = colorFrame.width, rows = colorFrame.height;
    NSLog(@"colorFrame: %d, %d", cols, rows);
    

    cols = depthFrame.width, rows = depthFrame.height;
    NSLog(@"depthFrame: %d, %d", cols, rows);

    cols = FrameBuffersize.width, rows = FrameBuffersize.height;
    NSLog(@"FrameBuffer: %d, %d", cols, rows);
    
    // Get the list of depth pixels which lie within the scanning volume boundaries.
    //std::vector<uint8_t> mask (rows*cols);
    //[_slamState.cameraPoseInitializer detectInnerPixelsWithDepthFrame:depthFrame mask:&mask[0]];
    
    // Fill the feedback RGBA buffer.
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < cols; ++c)
        {
            const int pixelIndex = r*cols + c;
            const int tIndex = (rows-1-r)*cols + c;

            
            //pixels[4*pixelIndex] = 255;//A
            //pixels[4*pixelIndex+1] = 0;//G
            //pixels[4*pixelIndex+2] = 0;//B
            //pixels[4*pixelIndex+3] = 255;//R
            _objdisplay.scanningVolumeFeedbackBuffer[4*pixelIndex] = pixels[4*tIndex];//pixels[4*pixelIndex];
            _objdisplay.scanningVolumeFeedbackBuffer[4*pixelIndex+1] = pixels[4*tIndex+1];
            _objdisplay.scanningVolumeFeedbackBuffer[4*pixelIndex+2] = pixels[4*tIndex+2];
            _objdisplay.scanningVolumeFeedbackBuffer[4*pixelIndex+3] = pixels[4*tIndex+3];
        }
    
    // Upload the texture to the GPU.
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, cols, rows, GL_RGBA, GL_UNSIGNED_BYTE, _objdisplay.scanningVolumeFeedbackBuffer.data());
    
    
    // Rendering it with blending enabled to apply the overlay on the previously rendered buffer.
    glEnable(GL_BLEND);
    //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFunc(GL_ZERO, GL_ONE); //src: GL_TEXTURE2   dst:rgbaTextureShader ??

    [_objdisplay.rgbaTextureShader useShaderProgram];
    [_objdisplay.rgbaTextureShader renderTexture:GL_TEXTURE2];
    
    //NSLog(@"Depth: %f", *depthFrame.depthInMillimeters);
}

// If we are outside of the scanning volume we make the pixels very dark.
- (void)renderScanningVolumeFeedbackOverlayWithDepthFrame:(STDepthFrame*)depthFrame colorFrame:(STColorFrame*)colorFrame cameraViewPoint:(GLKMatrix4)cameraViewPoint
{
    glActiveTexture(GL_TEXTURE2);
    
    
    
    glBindTexture(GL_TEXTURE_2D, _objdisplay.scanningVolumeFeedbackTexture);
    int cols = depthFrame.width, rows = depthFrame.height;
    
    // Get the list of depth pixels which lie within the scanning volume boundaries.
    std::vector<uint8_t> mask (rows*cols);
    [_objslamState.cameraPoseInitializer detectInnerPixelsWithDepthFrame:depthFrame mask:&mask[0]];
    
    // Fill the feedback RGBA buffer.
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < cols; ++c)
        {
            const int pixelIndex = r*cols + c;
            
            bool insideVolume=mask[pixelIndex];
            
            if (insideVolume)
            {
                // Set the alpha to 0, leaving the pixels already in the render buffer unchanged.
                _objdisplay.scanningVolumeFeedbackBuffer[4*pixelIndex+3] = 0;
            }
            else
            {
                // Set the alpha to a higher value, making the pixel in the render buffer darker.
                _objdisplay.scanningVolumeFeedbackBuffer[4*pixelIndex+3] = 500;
            }
        }
    
    // Upload the texture to the GPU.
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, cols, rows, GL_RGBA, GL_UNSIGNED_BYTE, _objdisplay.scanningVolumeFeedbackBuffer.data());
    
    // Rendering it with blending enabled to apply the overlay on the previously rendered buffer.
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [_objdisplay.rgbaTextureShader useShaderProgram];
    [_objdisplay.rgbaTextureShader renderTexture:GL_TEXTURE2];

    //NSLog(@"Depth: %f", *depthFrame.depthInMillimeters);
}


- (void)renderCameraImage
{
    NSLog(@"Obj renderCameraImage");
    if (_useColorCamera)
    {
        if (!_objdisplay.lumaTexture || !_objdisplay.chromaTexture)
            return;
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(_objdisplay.lumaTexture),
                      CVOpenGLESTextureGetName(_objdisplay.lumaTexture));
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(_objdisplay.chromaTexture),
                      CVOpenGLESTextureGetName(_objdisplay.chromaTexture));
        
        glDisable(GL_BLEND);
        [_objdisplay.yCbCrTextureShader useShaderProgram];
        [_objdisplay.yCbCrTextureShader renderWithLumaTexture:GL_TEXTURE0 chromaTexture:GL_TEXTURE1];
        
        GLint progid;
        glGetIntegerv(GL_CURRENT_PROGRAM,&progid);
        
        NSLog(@"========= scan =========current gl program: %d", progid);
        
        GLenum err0 = glGetError ();
        if (err0 != GL_NO_ERROR)
            NSLog(@"=========== Part -8 --- Here: glError is = %x", err0);
        
        glActiveTexture(GL_TEXTURE0);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE1);
        glDisable(GL_TEXTURE_2D);

    }
    else
    {
        if(_objdisplay.depthAsRgbaTexture == 0)
            return;
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _objdisplay.depthAsRgbaTexture);
        [_objdisplay.rgbaTextureShader useShaderProgram];
        [_objdisplay.rgbaTextureShader renderTexture:GL_TEXTURE0];
    }
    glUseProgram (0);
    
}


@end