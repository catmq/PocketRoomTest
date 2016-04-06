//
//  GLModelView.h
//
//  GLView Project
//  Version 1.6.1
//
//  Created by Nick Lockwood on 10/07/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/GLView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "GLModelView.h"


#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wgnu"


@implementation GLModelView

- (void)setUp
{
	[super setUp];
    
    // should put Yfov
	self.fov = (CGFloat)(44.419998f/180.f * M_PI) * 0.75f; // 44.41998 is the fov of the camera of the device (from AVCaptureDevice)
    //(CGFloat)M_PI_2; // default
    
    /*
    GLLight *light = [[GLLight alloc] init];
    light.transform = CATransform3DMakeTranslation(-0.5f, 1.0f, 0.5f);
    self.lights = @[light];
    */
    
    _modelTransform = CATransform3DIdentity;
}

- (void)setLights:(NSArray *)lights
{
    if (_lights != lights)
    {
        _lights = lights;
        [self setNeedsDisplay];
    }
}

- (void)setModel:(GLModel *)model
{
    if (_model != model)
    {
        _model = model;
        [self setNeedsDisplay];
    }
}

- (void)setBlendColor:(UIColor *)blendColor
{
    if (_blendColor != blendColor)
    {
        _blendColor = blendColor;
        [self setNeedsDisplay];
    }
}

- (void)setTexture:(GLImage *)texture
{
    NSLog(@"********************************************setTexture 0");
    if (_texture != texture)
    {
        NSLog(@"===============================> setTexture 1");
        _texture = texture;
        [self setNeedsDisplay];
    }
}

- (void)setModelTransform:(CATransform3D)modelTransform
{
    _modelTransform = modelTransform;
    [self setNeedsDisplay];
}

float fval = 1.0f;
int count = 0;
- (void)drawRect:(__unused CGRect)rect
{
    //apply lights
    if ([self.lights count])
    {
        //normalize normals
        glEnable(GL_NORMALIZE);
        
        for (GLuint i = 0; i < GL_MAX_LIGHTS; i++)
        {
            if (i < [self.lights count])
            {
                [self.lights[i] bind:GL_LIGHT0 + i];
            }
            else
            {
                glDisable(GL_LIGHT0 + i);
            }
        }
    }
    else
    {
        glDisable(GL_LIGHTING);
    }
    
    //apply model transform
    GLLoadCATransform3D(self.modelTransform);
    
    NSLog(@"self.texture = %@", self.texture);
    
    
    //set texture
    
    [self.blendColor ?: [UIColor whiteColor] bindGLColor];
    if (self.texture)
    {
        [self.texture bindTexture];
    }
    else
    {
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
    
    /*
     // test
    if(fval<0)
        fval = 1.0f;
    
    //[UIColor blueColor];//
    self.blendColor = [UIColor colorWithRed:fval green:0 blue:0 alpha:1.0f];
    //fval = fval - 0.1f;
    
    [self.blendColor bindGLColor];
    count++;
    NSLog(@"count= %d, color:%f",count,fval);
    
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    */
    /*
    //test2
    if (btest)
    {
        self.blendColor = [UIColor blueColor];
    }
    else
    {
        self.blendColor = [UIColor redColor];
    }
    btest = !btest;
    [self.blendColor bindGLColor];
    
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
     */
    ////////
    
    
    NSLog(@"************************start self.model drawinggggg.......");
    //render the model
    [self.model draw];
    NSLog(@"************************finished self.model drawinggggg.......");
    
    GLint progid;
    glGetIntegerv(GL_CURRENT_PROGRAM,&progid);
    
    NSLog(@"========= ModelView =========current gl program: %d", progid);
    
    //GLint progid;
    //glGetIntegerv(GL_CURRENT_PROGRAM,&progid);
    
    //NSLog(@"***************** modelview **************current gl program: %d", progid);
    
    GLenum err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"=========== Part -6 --- Here: glError is = %x", err0);
    
    
    glDisable(GL_TEXTURE_2D);
    

        //glUseProgram(0);
}

@end
