//
//  EAGLView.h
//  GameOne
//
//  Created by Brandon Smith on 12/30/08.
//  Copyright SproutWorks 2008. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "GridObject.h"
#import "Marble.h"

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/
@interface EAGLView : UIView {
    
@private
    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
	/* OpenGL name for the sprite texture */
	GLuint spriteTexture;
	
	GLuint *spriteTextures;
	
	int numTextures;
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
	NSString *textureNames;
	
    NSTimer *animationTimer;
    NSTimeInterval animationInterval;
	
	
	BOOL colliding;
	BOOL forward;
	
	CGPoint firstPoint;
	CGPoint curPoint;
	
	float curX;
	float curY;
	
	float speedX;
	float speedY;
	
	float ballSize;
	
	float rotateAngle;
	
	int numMarbles;
	
	GridObject *gridObject;
	Marble *marble;
	Marble **marbles;
}

@property NSTimeInterval animationInterval;

- (void)startAnimation;
- (void)stopAnimation;
- (void)loadTextures;
- (void)loadObjects;
- (void)setupView;
- (void)drawView;
- (void)drawBall;

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;

@end
