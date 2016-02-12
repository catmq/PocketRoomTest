//
//  ViewController.m
//  GLModelExample
//
//  Created by Nick Lockwood on 20/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. 
//

#import "LoadViewController.h"


@implementation LoadViewController

- (void)setModel:(NSInteger)index
{
    switch (index)
    {
        case 0:
        {
            //set title
            self.LoadNavBar.topItem.title = @"capsule.obj";
            
            //set model
            //[glMaterialf(<#GLenum face#>, <#GLenum pname#>, <#GLfloat param#>)]
        
            self.LoadModelView.texture = nil;//[GLImage imageNamed:@"capsule.mtl"];
            self.LoadModelView.blendColor = [UIColor whiteColor];
            self.LoadModelView.model = [GLModel modelWithContentsOfFile:@"capsule.obj"];
            
            //set default transform
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -2.0f);
//            transform = CATransform3DScale(transform, 1.0f, 1.0f, 1.0f);
 //           transform = CATransform3DRotate(transform, 0.2f, 1.0f, 0.0f, 0.0f);
            self.LoadModelView.modelTransform = transform;
            
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
            CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -2.0f);
            transform = CATransform3DScale(transform, 0.01f, 0.01f, 0.01f);
            transform = CATransform3DRotate(transform, 0.2f, 1.0f, 0.0f, 0.0f);
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
    }
}

- (void)setNewModel:(NSInteger)index
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *appDataDirectoryPath1 = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    NSString *appDataPath = [appDataDirectoryPath1 stringByAppendingPathComponent:objFiles[index]];//   appDataDirectoryPath1 + @"/" +;
    
    
    self.LoadNavBar.topItem.title = objFiles[index];
    self.LoadModelView.texture = nil;
    self.LoadModelView.blendColor = [UIColor whiteColor];
    self.LoadModelView.model = [GLModel modelWithContentsOfFile:appDataPath];
    
    NSLog(@"===> appDataPath :%@",appDataPath);
    
    //set default transform
    /*
     CATransform3D transform = CATransform3DMakeTranslation(0.0f, 0.0f, -2.0f);
    transform = CATransform3DScale(transform, 0.01f, 0.01f, 0.01f);
    //transform = CATransform3DRotate(transform, 0.2f, 1.0f, 0.0f, 0.0f);
    self.LoadModelView.modelTransform = transform;
    */
    
    CATransform3D transform = CATransform3DMakeTranslation(-0.5f, -0.5f, -1.0f);
    transform = CATransform3DScale(transform, 0.175f, 0.175f, 0.175f);
    //transform = CATransform3DRotate(transform, (CGFloat)M_PI_4, 1.0f, 1.0f, 0.0f);
    self.LoadModelView.modelTransform = transform;

    
}

- (void)selectLoadModel
{
    /*
    [[[UIActionSheet alloc] initWithTitle:nil
                                 delegate:self
                        cancelButtonTitle:nil
                   destructiveButtonTitle:nil
                        otherButtonTitles:@"Demon", @"Quad", @"Chair", @"Diamond", @"Cube", @"Ship", nil] showInView:self.view];
    */
    
    ///
    // check file in folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *appDataDirectoryPath1 = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *bundleDirectory = [fileManager contentsOfDirectoryAtPath:appDataDirectoryPath1 error:nil];
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.obj'"];
    objFiles = [bundleDirectory filteredArrayUsingPredicate:filter];
    
    NSLog(@"====> set Obj files %d: %@", [objFiles count], objFiles);
    
    
    UIActionSheet* sheet = [[UIActionSheet alloc] init] ;
    //sheet.title = @"Illustrations";
    sheet.delegate = self;
    
    
    for(int i =0; i < [objFiles count]; i++)
    {
        [sheet addButtonWithTitle:objFiles[i]];
        NSLog(@"====> %@", objFiles[i]);
    }
    
    [sheet showInView:self.view];
    
//    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
}

- (void)actionSheet:(__unused UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"====> open action sheet");
    
    /*
    if (buttonIndex >= 0)
    {
        [self setModel:buttonIndex];
    }
     */

    if (buttonIndex >= 0)
    {
        [self setNewModel:buttonIndex];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setModel:0];
    
    
    // check file in folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *appDataDirectoryPath1 = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    
    
    NSLog(@"=====> the folder is: %@", appDataDirectoryPath1);
    
   // NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *bundleDirectory = [fileManager contentsOfDirectoryAtPath:appDataDirectoryPath1 error:nil];
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.obj'"];
    objFiles = [bundleDirectory filteredArrayUsingPredicate:filter];
    
    NSLog(@"====> Obj files %d: %@", [objFiles count], objFiles);
    
    
    

}

@end
