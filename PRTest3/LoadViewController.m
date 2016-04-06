//
//  ViewController.m
//  GLModelExample
//
//  Created by Nick Lockwood on 20/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. 
//

#import "LoadViewController.h"



@implementation LoadViewController

float scalex = 1.122454f;
float scaley = -1.008032f;
float scalez = -1.496606f;

float lastRotation = 0.0f;
float rotationFactor = 0.01f;
float translationFactor = 0.01f;
bool rotateControl = false;

CGPoint lastTranslation = CGPointMake(0.0f, 0.0f);
GLKMatrix4 projectmatrix = GLKMatrix4Identity, modelmatrix = GLKMatrix4Identity, rendermatrix;
GLImage* newtexture = nil;
NSString *texturestr;
bool bReload = false;

CATransform3D latesttransform;

- (void)setModel:(NSInteger)index
{
    switch (index)
    {
        case 0:
        {
            //set title
            self.LoadNavBar.topItem.title = @"Model.obj";
            texturestr = @"Model.jpg";
            
            UIImage *image = [UIImage imageNamed:texturestr];
            image = [GLImage imageWithOriginalImage:image.CGImage flip:NO]; // flip vertically
            image = [GLImage imageWithImage:image scaledToSize:CGSizeMake(2048, 2048)]; // resize to power of 2
            newtexture = [GLImage imageWithUIImage:image];
            
            
            self.LoadModelView.texture = newtexture;
            self.LoadModelView.blendColor = [UIColor whiteColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"Model.obj"];
            
            //set default transform
            
            CATransform3D transform = CATransform3DIdentity;
            
            projectmatrix.m00 = -2.506634f;
            projectmatrix.m11 = -3.342179f;
            projectmatrix.m22 = -1.008032f;
            projectmatrix.m32 = -0.200803f;
            projectmatrix.m23 = 1.0f;
            
            modelmatrix.m30 = -4.5f;
            modelmatrix.m31 = -3.0f;
            modelmatrix.m32 = 4.5f;
            
            rendermatrix = GLKMatrix4Multiply(projectmatrix, modelmatrix);
            
            transform = [self matrixFromGLKMatrix:rendermatrix];

            scalex = transform.m11;
            scaley = transform.m22;
            scalez = transform.m33;
            
            
            self.LoadModelView.modelTransform = transform;
            
            
            NSLog(@"transform1: %f, %f, %f, %f",transform.m11,transform.m12,transform.m13,transform.m14);
            NSLog(@"transform2: %f, %f, %f, %f",transform.m21,transform.m22,transform.m23,transform.m24);
            NSLog(@"transform3: %f, %f, %f, %f",transform.m31,transform.m32,transform.m33,transform.m34);
            NSLog(@"transform4: %f, %f, %f, %f",transform.m41,transform.m42,transform.m43,transform.m44);
            
            break;

            /*
             //set title
            self.LoadNavBar.topItem.title = @"demon.model";
            
            //set model
            self.LoadModelView.texture = [GLImage imageNamed:@"demon.png"];
            self.LoadModelView.blendColor = nil;
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"demon.model"];
            
            //set default transform
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -2.0f);
            transform = CATransform3DScale(transform, 0.01f, 0.01f, 0.01f);
            transform = CATransform3DRotate(transform, (CGFloat)-M_PI_2, 1.0f, 0.0f, 0.0f);
            self.LoadModelView.modelTransform = transform;
            
            break;
             */
        }
        case 1:
        {
            //set title
            self.LoadNavBar.topItem.title = @"quad";
            
            //set model
            self.LoadModelView.texture = nil;
            self.LoadModelView.blendColor = [UIColor redColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"quad.obj"];
            
            //set default transform
            self.LoadModelView.modelTransform = CATransform3DMakeTranslation(0.0f, 0.0f, -2.0f);
            
            break;
        }
        case 2:
        {
            //set title
            self.LoadNavBar.topItem.title = @"chair.obj";
            
            //set model
            self.LoadModelView.texture = [GLImage imageNamed:@"chair.tga"];
            self.LoadModelView.blendColor = nil;
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"chair.obj"];
            
            //set default transform
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -20.0f);
            transform = CATransform3DRotate(transform, 0.0f, 1.0f, 1.0f, 0.0f);
            transform = CATransform3DScale(transform, 0.01f, 0.01f, 0.01f);
            self.LoadModelView.modelTransform = transform;
            
            break;
        }
        case 3:
        {
            //set title
            self.LoadNavBar.topItem.title = @"diamond.obj";
            
            //set model
            self.LoadModelView.texture = nil;
            self.LoadModelView.blendColor = [UIColor greenColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"diamond.obj"];
            
            //set default transform
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -1.0f);
            transform = CATransform3DScale(transform, 0.01f, 0.01f, 0.01f);
            transform = CATransform3DRotate(transform, (CGFloat)M_PI_2, 1.0f, 0.0f, 0.0f);
            self.LoadModelView.modelTransform = transform;
            
            break;
        }
        case 4:
        {
            //set title
            self.LoadNavBar.topItem.title = @"cube.obj";
            
            //set model
            self.LoadModelView.texture = nil;
            self.LoadModelView.blendColor = [UIColor whiteColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"cube.obj"];
            
            //set default transform
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -1.0f);
            transform = CATransform3DRotate(transform, (CGFloat)M_PI_4, 1.0f, 1.0f, 0.0f);
            self.LoadModelView.modelTransform = transform;
            
            break;
        }
        case 5:
        {
            //set title
            self.LoadNavBar.topItem.title = @"ship.obj";
            
            //set model
            self.LoadModelView.texture = nil;
            self.LoadModelView.blendColor = [UIColor grayColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"ship.obj"];
            
            //set default transform
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -15.0f);
            transform = CATransform3DRotate(transform, (CGFloat)M_PI + 0.4f, 0.0f, 0.0f, 1.0f);
            transform = CATransform3DRotate(transform, (CGFloat)M_PI_4, 1.0f, 0.0f, 0.0f);
            transform = CATransform3DRotate(transform, -0.4f, 0.0f, 1.0f, 0.0f);
            transform = CATransform3DScale(transform, 3.0f, 3.0f, 3.0f);
            self.LoadModelView.modelTransform = transform;
            
            break;
        }
        case 6:
        {
            //set title
            self.LoadNavBar.topItem.title = @"RoomModel.obj";
            texturestr = @"RoomModel.jpg";
            
            UIImage *image = [UIImage imageNamed:texturestr];
            image = [GLImage imageWithOriginalImage:image.CGImage flip:NO]; // flip vertically
            image = [GLImage imageWithImage:image scaledToSize:CGSizeMake(2048, 2048)]; // resize to power of 2
            newtexture = [GLImage imageWithUIImage:image];
            
            
            self.LoadModelView.texture = newtexture;
            self.LoadModelView.blendColor = [UIColor whiteColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"RoomModel.obj"];
            
            //set default transform
            
            CATransform3D transform = CATransform3DIdentity;
            
            projectmatrix.m00 = -2.506634f;
            projectmatrix.m11 = -3.342179f;
            projectmatrix.m22 = -1.008032f;
            projectmatrix.m32 = -0.200803f;
            projectmatrix.m23 = 1.0f;
            
            modelmatrix.m30 = -4.5f;
            modelmatrix.m31 = -3.0f;
            modelmatrix.m32 = 4.5f;
            
            rendermatrix = GLKMatrix4Multiply(projectmatrix, modelmatrix);
            
            transform = [self matrixFromGLKMatrix:rendermatrix];
            
            transform = CATransform3DScale(transform, 1.0f, 1.0f, 1.0f);
            
            scalex = transform.m11;
            scaley = transform.m22;
            scalez = transform.m33;
            
            
            self.LoadModelView.modelTransform = transform;
            
            
            NSLog(@"transform1: %f, %f, %f, %f",transform.m11,transform.m12,transform.m13,transform.m14);
            NSLog(@"transform2: %f, %f, %f, %f",transform.m21,transform.m22,transform.m23,transform.m24);
            NSLog(@"transform3: %f, %f, %f, %f",transform.m31,transform.m32,transform.m33,transform.m34);
            NSLog(@"transform4: %f, %f, %f, %f",transform.m41,transform.m42,transform.m43,transform.m44);
            
            break;
        }
    }
}

- (GLKMatrix4)matrixFrom3DTransformation:(CATransform3D)transform
{
    GLKMatrix4 matrix = GLKMatrix4Make(transform.m11, transform.m12, transform.m13, transform.m14,
                                       transform.m21, transform.m22, transform.m23, transform.m24,
                                       transform.m31, transform.m32, transform.m33, transform.m34,
                                       transform.m41, transform.m42, transform.m43, transform.m44);
    
    return matrix;
}

- (CATransform3D)matrixFromGLKMatrix:(GLKMatrix4)transform
{
    CATransform3D output;
    
    GLfloat glMatrix[16];
    CGFloat caMatrix[16];
    
    memcpy(glMatrix, &transform, sizeof(glMatrix)); //insert GL matrix data to the buffer
    for(int i=0; i<16; i++) caMatrix[i] = glMatrix[i]; //this will do the typecast if needed
    
    output = *((CATransform3D *)caMatrix);
    return output;
}

- (IBAction)updateModelMatrix:(id)sender
{
    //NSLog(@"--->ROOM MODEL!!! 2 updateModelMatrix");
    //self.LoadModelView.texture = newtexture;
    //self.LoadModelView.modelTransform = latesttransform;
    
    
    //NSLog(@"--->ROOM MODEL!!! 2 updateModelMatrix");
    //NSLog(@"latesttransform0: %f, %f, %f, %f",self.LoadModelView.modelTransform.m11, self.LoadModelView.modelTransform.m12, self.LoadModelView.modelTransform.m13, self.LoadModelView.modelTransform.m14);
    //NSLog(@"latesttransform1: %f, %f, %f, %f",self.LoadModelView.modelTransform.m21, self.LoadModelView.modelTransform.m22, self.LoadModelView.modelTransform.m23, self.LoadModelView.modelTransform.m24);
    //NSLog(@"latesttransform2: %f, %f, %f, %f",self.LoadModelView.modelTransform.m31, self.LoadModelView.modelTransform.m32, self.LoadModelView.modelTransform.m33, self.LoadModelView.modelTransform.m34);
    //NSLog(@"latesttransform3: %f, %f, %f, %f",self.LoadModelView.modelTransform.m41, self.LoadModelView.modelTransform.m42, self.LoadModelView.modelTransform.m43, self.LoadModelView.modelTransform.m44);

}

- (void)updateCameraMovementMatrix:(GLKMatrix4)movematrix
{
    
    NSLog(@"--->ROOM MODEL!!! 3 updateCameraMoveMatrix");
    
    
    latesttransform = self.LoadModelView.modelTransform;
    modelmatrix.m30 = modelmatrix.m30 +4.5f;
    modelmatrix.m31 = modelmatrix.m31 +3.0f;
    modelmatrix.m32 = modelmatrix.m32 -4.5f;
    
    GLKMatrix4 rendermat = [self matrixFrom3DTransformation:latesttransform];
    rendermat = GLKMatrix4Multiply(movematrix, rendermat);
    
    
    latesttransform = [self matrixFromGLKMatrix:rendermat];
    
    modelmatrix.m30 = modelmatrix.m30 -4.5f;
    modelmatrix.m31 = modelmatrix.m31 -3.0f;
    modelmatrix.m32 = modelmatrix.m32 +4.5f;
    
    //NSLog(@"latesttransform0: %f, %f, %f, %f",latesttransform.m11, latesttransform.m12, latesttransform.m13, latesttransform.m14);
    //NSLog(@"latesttransform1: %f, %f, %f, %f",latesttransform.m21, latesttransform.m22, latesttransform.m23, latesttransform.m24);
    //NSLog(@"latesttransform2: %f, %f, %f, %f",latesttransform.m31, latesttransform.m32, latesttransform.m33, latesttransform.m34);
    //NSLog(@"latesttransform3: %f, %f, %f, %f",latesttransform.m41, latesttransform.m42, latesttransform.m43, latesttransform.m44);
    
    //[self performSelector: @selector(updateModelMatrix:) withObject:self afterDelay: 0.0];
    [self updateModelMatrix:self];
}

- (void)updateTransformProjectMatrix:(GLKMatrix4)projectmatrix ModelMatrix:(GLKMatrix4)modelmatrix
{
    
    //NSLog(@"--->ROOM MODEL!!! 1 updateTransformProjectMatrix");
    
    
    float fscale = 1.29424f;//1.3932277f;
    GLKMatrix4 newmat = GLKMatrix4Identity;
    newmat.m00 = -fscale;
    newmat.m11 = fscale;
    newmat.m22 = -fscale;
    
    GLKMatrix4 newProj = GLKMatrix4Multiply(projectmatrix, newmat);
    

    //NSLog(@"newProj0: %f, %f, %f, %f",projectmatrix.m00, projectmatrix.m01, projectmatrix.m02, projectmatrix.m03);
    //NSLog(@"newProj1: %f, %f, %f, %f",projectmatrix.m10, projectmatrix.m11, projectmatrix.m12, projectmatrix.m13);
    //NSLog(@"newProj2: %f, %f, %f, %f",projectmatrix.m20, projectmatrix.m21, projectmatrix.m22, projectmatrix.m23);
    //NSLog(@"newProj3: %f, %f, %f, %f",projectmatrix.m30, projectmatrix.m31, projectmatrix.m32, projectmatrix.m33);

    
    modelmatrix.m30 = modelmatrix.m30 -4.5f;
    modelmatrix.m31 = modelmatrix.m31 -3.0f;
    modelmatrix.m32 = modelmatrix.m32 +4.5f;
    //modelmatrix.m33 = 1.0f;
/*
 
 projectmatrix.m00 = 2.506634f;
 projectmatrix.m11 = -3.342179f;
 projectmatrix.m22 = 1.008032f;
 projectmatrix.m32 = -0.200803f;
 projectmatrix.m23 = 1.0f;
 
 modelmatrix.m30 = -4.5f;
 modelmatrix.m31 = -3.0f;
 modelmatrix.m32 = -4.5f;
 
 */
    GLKMatrix4 rendermat = GLKMatrix4Multiply(newProj, modelmatrix);
    
    latesttransform = [self matrixFromGLKMatrix:rendermat];
    
    
    //NSLog(@"latesttransform0: %f, %f, %f, %f",latesttransform.m11, latesttransform.m12, latesttransform.m13, latesttransform.m14);
    //NSLog(@"latesttransform1: %f, %f, %f, %f",latesttransform.m21, latesttransform.m22, latesttransform.m23, latesttransform.m24);
    //NSLog(@"latesttransform2: %f, %f, %f, %f",latesttransform.m31, latesttransform.m32, latesttransform.m33, latesttransform.m34);
    //NSLog(@"latesttransform3: %f, %f, %f, %f",latesttransform.m41, latesttransform.m42, latesttransform.m43, latesttransform.m44);
    
    latesttransform.m41 = latesttransform.m41 -1.0f;
    latesttransform.m42 = latesttransform.m42 -1.0f;
    latesttransform.m43 = latesttransform.m43 +3.0f;
    latesttransform.m44 = 5.5f;


    
    //[self performSelector: @selector(updateModelMatrix:) withObject:self afterDelay: 0.0];
    [self updateModelMatrix:self];
}

- (void)setNewModel:(NSInteger)index
{
    //NSLog(@"--->setNewModel");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *appDataDirectoryPath1 = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    NSString *appDataPath = [appDataDirectoryPath1 stringByAppendingPathComponent:objFiles[index]];
    
    
    self.LoadNavBar.topItem.title = objFiles[index];
    
    
    //NSString *texturestr;
    NSRange replaceRange = [appDataPath rangeOfString:@".obj"];
    if (replaceRange.location != NSNotFound){
        texturestr = [appDataPath stringByReplacingCharactersInRange:replaceRange withString:@".jpg"];
    }
    //NSLog(@"--->texture: %@", texturestr);  // get texture path
    
    /////////
    UIImage *image = [UIImage imageNamed:texturestr];
    image = [GLImage imageWithOriginalImage:image.CGImage flip:NO]; // flip vertically
    image = [GLImage imageWithImage:image scaledToSize:CGSizeMake(2048, 2048)]; // resize to power of 2
    newtexture = [GLImage imageWithUIImage:image];
    
    self.LoadModelView.texture = newtexture;//[GLImage imageNamed:texturestr];//nil;
    self.LoadModelView.blendColor = [UIColor whiteColor];
    self.LoadModelView.model = [GLModel modelWithContentsOfFile:appDataPath];
    
    //NSLog(@"===> appDataPath :%@",appDataPath);
    
    //set default transform
    CATransform3D transform = CATransform3DIdentity;

    // Recover the projection matrix and the initial position of camera
    projectmatrix.m00 = 2.506634f;
    projectmatrix.m11 = -3.342179f;
    projectmatrix.m22 = 1.008032f;
    projectmatrix.m32 = -0.200803f;
    projectmatrix.m23 = 1.0f;
    
    modelmatrix.m30 = -4.5f;
    modelmatrix.m31 = -3.0f;
    modelmatrix.m32 = -4.5f;
    
    rendermatrix = GLKMatrix4Multiply(projectmatrix, modelmatrix);
    
    transform = [self matrixFromGLKMatrix:rendermatrix];
    
    scalex = transform.m11;
    scaley = transform.m22;
    scalez = transform.m33;
    
    
    self.LoadModelView.modelTransform = transform;
    
}


//int testcount = 0;

- (void)selectLoadModel
{
    //[self.appStatusLabel setText: [NSString stringWithFormat:@"testcount: %d",testcount]];
    //testcount++;
    // check file in folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *appDataDirectoryPath1 = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *bundleDirectory = [fileManager contentsOfDirectoryAtPath:appDataDirectoryPath1 error:nil];
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.obj'"];
    objFiles = [bundleDirectory filteredArrayUsingPredicate:filter];
    
    //NSLog(@"====> set Obj files %d: %@", [objFiles count], objFiles);
    
    filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"];
    jpgFiles = [bundleDirectory filteredArrayUsingPredicate:filter];
    
    //NSLog(@"====> set JPG files %d: %@", [jpgFiles count], jpgFiles);
    
    UIActionSheet* sheet = [[UIActionSheet alloc] init] ;
    //sheet.title = @"Illustrations";
    sheet.delegate = self;
    
    
    for(int i =0; i < [objFiles count]; i++)
    {
        [sheet addButtonWithTitle:objFiles[i]];
        //NSLog(@"====> %@", objFiles[i]);
    }
    
    [sheet showInView:self.view];
    
//    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
}

- (void)actionSheet:(__unused UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //NSLog(@"====> open action sheet");
    
    //[self showAppStatus: self.appStatusLabel msg:@"Loading..."];
    //[self.appStatusLabel setText: [NSString stringWithFormat:@"sheet: %d",testcount]];
    //testcount++;

    
    if (buttonIndex >= 0)
    {
        [self setNewModel:buttonIndex];
    }
    
    //[self hideAppStatus: self.appStatusLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self setModel:0];
    [self setModel:6]; // chair
    
    // check file in folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *appDataDirectoryPath1 = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *bundleDirectory = [fileManager contentsOfDirectoryAtPath:appDataDirectoryPath1 error:nil];
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.obj'"];
    objFiles = [bundleDirectory filteredArrayUsingPredicate:filter];
    
    //NSLog(@"Loading Obj files %d: %@", [objFiles count], objFiles);
    
    [self setupGestureRecognizer];
    
}

- (void) hideAppStatus:(UILabel*)label
{
    //NSLog(@"hide msg");
    [label setText:@""];
    
    /*
    [UIView animateWithDuration:0.5f animations:^{
        label.alpha = 0.0f;
    } completion:^(BOOL finished){
        [label setHidden:YES];
    }];
    */
}

- (void)showAppStatus:(UILabel*)label msg:(NSString *)msg
{
    //NSLog(@"show msg");
    [label setText:msg];
    /*
    if (label.hidden == YES)
    {
        [label setHidden:NO];
        NSLog(@"setHidden:No");
        
        label.alpha = 0.0f;
        [UIView animateWithDuration:0.5f animations:^{
            label.alpha = 1.0f;
        }];
        
    }
    */
}
/*
- (void)showAppStatusMessage:(NSString *)msg
{
    //_appStatus.needsDisplayOfStatusMessage = true;
    //[self.view.layer removeAllAnimations];
    
    [self.appStatusLabel setText:msg];
    [self.appStatusLabel setHidden:NO];
    
    
}

- (void)hideAppStatusMessage
{
    //_appStatus.needsDisplayOfStatusMessage = true;
    //[self.view.layer removeAllAnimations];
    
    
   
    
    [self.appStatusLabel setHidden:YES];
    
    [UIView animateWithDuration:0.5f animations:^{
        label.alpha = 0.0f;
    } completion:^(BOOL finished){
        [label setHidden:YES];
    }];
    
}
*/

- (void)setupGestureRecognizer
{
    
//    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc]
//                                                    initWithTarget:self
//                                                    action:@selector(rotationGesture:)];
//    [rotationGesture setDelegate:self];
//    [self.view addGestureRecognizer:rotationGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(panGesture:)];
    [panGesture setDelegate:self];
    [self.view addGestureRecognizer:panGesture];
    //UIView *controlView = [self.view viewWithTag:1];
    //[panGesture addTarget:controlView action:@selector(panGesture:)];
    //[controlView addGestureRecognizer:panGesture];
    
}
                                          
- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
//    if ([gestureRecognizer numberOfTouches] != 2)
//        return;
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        CGPoint tapPosition = [gestureRecognizer locationInView:self.view];
        UIView *hitView = [self.view hitTest:tapPosition withEvent:nil];
        NSLog(@"HitView is %i",hitView.tag);
        if (hitView.tag == 1)
            rotateControl = true;
        else
            rotateControl = false;
        lastTranslation = [gestureRecognizer translationInView:self.view];
    }
    else if ( [gestureRecognizer state] == UIGestureRecognizerStateChanged)
        [self onPanGestureChanged:[gestureRecognizer translationInView:self.view]];
}

- (void)rotationGesture:(UIRotationGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
        [self onRotationGestureBegan:[gestureRecognizer rotation]];
    else if ( [gestureRecognizer state] == UIGestureRecognizerStateChanged)
        [self onRotationGestureChanged:[gestureRecognizer rotation]];
}

- (void) onPanGestureChanged:(CGPoint)translation
{
    //NSLog(@"translation:(%f,%f)",translation.x, translation.y);
    CATransform3D transform = self.LoadModelView.modelTransform;
    
    if (rotateControl)
    {
        transform = CATransform3DRotate(transform, (translation.x-lastTranslation.x)*rotationFactor, 0.0f, 1.0f, 0.0f);
        
        lastTranslation = translation;
        
        self.LoadModelView.modelTransform = transform;
    }
    else
    {
//        transform = CATransform3DTranslate(transform, -translation.x+lastTranslation.x, 0.0f, translation.y - lastTranslation.y);
        
        transform.m41 += -(translation.x - lastTranslation.x) * translationFactor;
        transform.m43 += (translation.y - lastTranslation.y) * translationFactor;
        
        lastTranslation = translation;
        
        self.LoadModelView.modelTransform = transform;
    }

}

- (void) onRotationGestureBegan:(float)rotation
{
    NSLog(@"Rotating");
    CATransform3D transform = self.LoadModelView.modelTransform;
    
    transform = CATransform3DRotate(transform, rotation, 0.0f, 1.0f, 0.0f);
    
    lastRotation = rotation;
    
    self.LoadModelView.modelTransform = transform;
}

- (void) onRotationGestureChanged:(float)rotation
{
    CATransform3D transform = self.LoadModelView.modelTransform;
    
    transform = CATransform3DRotate(transform, rotation-lastRotation, 0.0f, 1.0f, 0.0f);
    
    lastRotation = rotation;
    
    self.LoadModelView.modelTransform = transform;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (IBAction)ModelXSliderValueChanged:(id)sender
{
    GLenum err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"=========== Part -4 --- Here: glError is = %x", err0);
    
    float val = self.modelXSlider.value;
    
    CATransform3D transform = self.LoadModelView.modelTransform;
    transform.m41 = val;
    //rendermatrix = GLKMatrix4Multiply(projectmatrix, modelmatrix);
    //transform = [self matrixFromGLKMatrix:rendermatrix];
    
    /*if(!bReload)
    {
        NSLog(@"reload texture again");
        UIImage *image = [UIImage imageNamed:texturestr];
        image = [GLImage imageWithOriginalImage:image.CGImage flip:NO]; // flip vertically
        image = [GLImage imageWithImage:image scaledToSize:CGSizeMake(2048, 2048)]; // resize to power of 2
        newtexture = [GLImage imageWithUIImage:image];
        
        bReload = true;
    }
    */
    //self.LoadModelView.texture = newtexture;
    self.LoadModelView.modelTransform = transform;
    
    err0 = glGetError ();
    if (err0 != GL_NO_ERROR)
        NSLog(@"=========== Part -5 --- Here: glError is = %x", err0);

    
    //NSLog(@"X: %f",val);
    //NSLog(@"Xtransform1: %f, %f, %f, %f",transform.m11,transform.m12,transform.m13,transform.m14);
    //NSLog(@"Xtransform2: %f, %f, %f, %f",transform.m21,transform.m22,transform.m23,transform.m24);
    //NSLog(@"Xtransform3: %f, %f, %f, %f",transform.m31,transform.m32,transform.m33,transform.m34);
    //NSLog(@"Xtransform4: %f, %f, %f, %f",transform.m41,transform.m42,transform.m43,transform.m44);
}
- (IBAction)ModelYSliderValueChanged:(id)sender
{
    float val = self.modelYSlider.value;
    
    CATransform3D transform = self.LoadModelView.modelTransform;
    transform.m42 = val;
    //rendermatrix = GLKMatrix4Multiply(projectmatrix, modelmatrix);
    //transform = [self matrixFromGLKMatrix:rendermatrix];
    
    //self.LoadModelView.texture = newtexture;
    self.LoadModelView.modelTransform = transform;
    /*
     NSLog(@"Y: %f",val);
    NSLog(@"Ytransform1: %f, %f, %f, %f",transform.m11,transform.m12,transform.m13,transform.m14);
    NSLog(@"Ytransform2: %f, %f, %f, %f",transform.m21,transform.m22,transform.m23,transform.m24);
    NSLog(@"Ytransform3: %f, %f, %f, %f",transform.m31,transform.m32,transform.m33,transform.m34);
    NSLog(@"Ytransform4: %f, %f, %f, %f",transform.m41,transform.m42,transform.m43,transform.m44);
     */
    
}
- (IBAction)ModelZSliderValueChanged:(id)sender
{
    float val = self.modelZSlider.value;
    
    CATransform3D transform = self.LoadModelView.modelTransform;
    transform.m43 = val;
    //rendermatrix = GLKMatrix4Multiply(projectmatrix, modelmatrix);
    //transform = [self matrixFromGLKMatrix:rendermatrix];
    
    
    //self.LoadModelView.texture = newtexture;
    self.LoadModelView.modelTransform = transform;
    /*
     NSLog(@"Z: %f",val);
    NSLog(@"Ztransform1: %f, %f, %f, %f",transform.m11,transform.m12,transform.m13,transform.m14);
    NSLog(@"Ztransform2: %f, %f, %f, %f",transform.m21,transform.m22,transform.m23,transform.m24);
    NSLog(@"Ztransform3: %f, %f, %f, %f",transform.m31,transform.m32,transform.m33,transform.m34);
    NSLog(@"Ztransform4: %f, %f, %f, %f",transform.m41,transform.m42,transform.m43,transform.m44);
     */
}
- (IBAction)ScaleSliderValueChanged:(id)sender
{
    float val = self.ScaleSlider.value;
    
    CATransform3D transform = self.LoadModelView.modelTransform;
//    float posx = transform.m41;
//    float posy = transform.m42;
//    float posz = transform.m43;
//    transform.m44 = -3.5f;
//    transform = CATransform3DMakeTranslation(-posx,-posy,-posz);
//    
//    transform.m11 = scalex*val;
//    transform.m22 = scaley*val;
//    transform.m33 = scalez*val;
//    
//    transform.m41 =posx;
//    transform.m42 =posy;
//    transform.m43 =posz;
    
    transform = CATransform3DRotate(transform, val-lastRotation, 0.0f, 1.0f, 0.0f);
    
    lastRotation = val;
    
    self.LoadModelView.modelTransform = transform;
    //NSLog(@"Scale: %f",val);
    
    //NSLog(@"Stransform1: %f, %f, %f, %f",transform.m11,transform.m12,transform.m13,transform.m14);
    //NSLog(@"Stransform2: %f, %f, %f, %f",transform.m21,transform.m22,transform.m23,transform.m24);
    //NSLog(@"Stransform3: %f, %f, %f, %f",transform.m31,transform.m32,transform.m33,transform.m34);
    //NSLog(@"Stransform4: %f, %f, %f, %f",transform.m41,transform.m42,transform.m43,transform.m44);
}

- (IBAction)gotoLoadRoomView:(id)sender
{
    //NSLog(@"gotoLoadRoomView");
    self.LoadModelView.hidden = false;
    self.ScanObjView.hidden = true;
}

- (IBAction)gotoScanObjView:(id)sender
{
    /*
    NSLog(@"gotoScanObjView");
    self.LoadModelView.hidden = true;
    self.ScanObjView.hidden = false;
     */
}

@end
