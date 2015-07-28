//
//  GameOneAppDelegate.h
//  GameOne
//
//  Created by Brandon Smith on 12/30/08.
//  Copyright SproutWorks 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface GameOneAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

