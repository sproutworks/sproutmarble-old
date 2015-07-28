//
//  GameOneAppDelegate.m
//  GameOne
//
//  Created by Brandon Smith on 12/30/08.
//  Copyright SproutWorks 2008. All rights reserved.
//

#import "GameOneAppDelegate.h"
#import "EAGLView.h"

@implementation GameOneAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	glView.animationInterval = 1.0 / 60.0;
	[glView startAnimation];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 5.0;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 60.0;
}


- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
