#import "MultiViewController.h"


@implementation MultiViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.root = [self.storyboard instantiateViewControllerWithIdentifier:@"LoadViewController"];
    self.root.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    //[self.root.view setBackgroundColor:[UIColor yellowColor]];
    
    [self addChildViewController:self.root];
    [self.root didMoveToParentViewController:self];
    [self.view addSubview:self.root.view];
    
    
    [self.view bringSubviewToFront:self.backbutton];
    [self.view bringSubviewToFront:self.nextbutton];
}

#pragma mark - Event
-(void)pop:(id)sender {
    if (self.overlap == nil ) {
        // Open(Show)
        //self.overlap = [self.storyboard instantiateViewControllerWithIdentifier:@"ObjViewController"];
        
        self.overlap = [[UIViewController alloc] init];
        [self.overlap.view setBackgroundColor:[UIColor redColor]];
        
        
        //self.overlap.view.frame = CGRectMake(500, 500, 1024, 768);
        
        
        [self addChildViewController:self.overlap];
        ///
        [self.overlap didMoveToParentViewController:self];
        [self.view addSubview:self.overlap.view];
        
        //[self.button setTitle:@"Hide" forState:UIControlStateNormal];
        /*
        // Start line
        CGRect startFrame = self.view.frame;
        startFrame.origin.y = startFrame.size.height;
        self.overlap.view.frame = startFrame;

        // Move half
        [self transitionFromViewController:self.root
                          toViewController:self.overlap
                                  duration:1.0
                                   options:0
                                animations:^{
                                    CGRect original = self.root.view.frame;
                                    self.overlap.view.frame = CGRectMake(70, original.origin.y, original.size.width, original.size.height);
                                }
                                completion:^(BOOL finished) {
                                    [self.overlap didMoveToParentViewController:self];
                                    [self.button setTitle:@"Hide" forState:UIControlStateNormal];
                                }];
         */
    }
    else {
        // Hide
        [self.overlap willMoveToParentViewController:nil];
        
        //
        [self.overlap.view.superview bringSubviewToFront:self.overlap.view];
        [self.overlap removeFromParentViewController];
        self.overlap = nil;
        //[self.button setTitle:@"Show" forState:UIControlStateNormal];
        
        /*
        // Good-bye
        [self transitionFromViewController:self.overlap
                          toViewController:self.root
                                  duration:1.0
                                   options:0
                                animations:^{
                                    CGRect original = self.root.view.frame;
                                    self.overlap.view.frame = CGRectMake(70, original.size.height, original.size.width, original.size.height);
                                    [self.overlap.view.superview bringSubviewToFront:self.overlap.view];
                                    
                                }
                                completion:^(BOOL finished) {
                                    [self.overlap removeFromParentViewController];
                                    self.overlap = nil;
                                    [self.button setTitle:@"Show" forState:UIControlStateNormal];
                                }];
         */
        
    }
}


- (IBAction)gotoBackView:(id)sender
{
    NSLog(@"gotoBackView");
    if (self.overlap == nil ) {  // in Loadview
        //back to startview
        NSLog(@"Back (in LoadView)");
        
        [self performSegueWithIdentifier:@"segueToStart" sender:self];
    }
    else{// in ObjView
        NSLog(@"Back (in ObjView)");
        /*
        [self.overlap willMoveToParentViewController:nil];
        
        [self.overlap.view.superview bringSubviewToFront:self.overlap.view];
        [self.overlap removeFromParentViewController];
        self.overlap = nil;
        */
        //ObjViewController *vc = [self.childViewControllers lastObject];
        [self.overlap willMoveToParentViewController:nil];
        [self.overlap.view.superview bringSubviewToFront:self.overlap.view];
        [self.overlap.view removeFromSuperview];
        [self.overlap removeFromParentViewController];
        self.overlap.LVcontroller = nil;
        self.overlap = nil;
        
        NSLog(@"Back (in ObjView) end");
        [self.view bringSubviewToFront:self.backbutton];
        [self.view bringSubviewToFront:self.nextbutton];
    }
}

- (IBAction)gotoNextView:(id)sender
{
    NSLog(@"gotoNextView");
    if (self.overlap == nil ) {  // in Loadview
        
        NSLog(@"Next (in LoadView)");
        // Open(Show)
        self.overlap = [self.storyboard instantiateViewControllerWithIdentifier:@"ObjViewController"];
        self.overlap.LVcontroller = self.root;//[self.storyboard instantiateViewControllerWithIdentifier:@"LoadViewController"];
        
        // self.overlap = [[UIViewController alloc] init];
        //[self.overlap.view setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.5]];
        //self.overlap.view.userInteractionEnabled = NO;
        
        //self.overlap.view.frame = CGRectMake(200, 100, 1024, 768);
        //self.overlap.view.hidden = YES;
        
        
        
        [self addChildViewController:self.overlap];
        [self.view addSubview:self.overlap.view];
        [self.overlap didMoveToParentViewController:self];
        
        [self.view bringSubviewToFront:self.backbutton];
        [self.view bringSubviewToFront:self.nextbutton];
        
    }
    else{// in ObjView
        NSLog(@"Next (in ObjView)");
        
    }
}


@end