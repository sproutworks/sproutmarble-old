//
//  EAGLView.m
//  GameOne
//
//  Created by Brandon Smith on 12/30/08.
//  Copyright SproutWorks 2008. All rights reserved.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <math.h>

#import "EAGLView.h"

#import "AccelerometerSimulation.h"

#define USE_DEPTH_BUFFER 0
#define kUpdateFrequency 20  // Hz
#define kMaxSpeed		 0.05

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;
@property (nonatomic, retain) GridObject *gridObject;
@property (nonatomic, retain) Marble *marble;
@property (nonatomic, retain) Marble *marbles;


- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;
@synthesize gridObject;
@synthesize marble;

// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// We only support single touches, so anyObject retrieves just that touch from touches
	UITouch *touch = [touches anyObject];
	
	// Only move the placard view if the touch was in the placard view
	
	// Animate the first touch
	firstPoint = [touch locationInView:self];
	
	forward = !forward;
	
	//[self animateFirstTouchAtPoint:touchPoint];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [touches anyObject];
	
	curPoint = [touch locationInView:self];
	
	curX += (float)(curPoint.x - firstPoint.x)/100.0f;
	curY += (float)(curPoint.y - firstPoint.y)/100.0f;
	
	firstPoint = curPoint;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [touches anyObject];
	
			
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
    
    if ((self = [super initWithCoder:coder])) {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }
        
        animationInterval = 1.0 / 60.0;
		
		textureNames = [[NSArray alloc] initWithObjects: @"marble", @"Sprite", @"blue_marble", @"red_marble", @"green_marble",@"redgear",@"bluegear",@"greengear", nil];
		
		forward = true;
		rotateAngle = 0;
		
		curX = 0;
		curY = 0;
		speedX = 0.005;
		speedY = 0.005;
		numMarbles = 1;
		colliding = false;
		ballSize = 0.4;
		
		//gridObject = [[GridObject alloc] init];
		
		[self loadObjects];
		
		marble = [[Marble alloc] initMarble];
		
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kUpdateFrequency)];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
		//calibrationOffset = 0.0;
		//firstCalibrationReading = kNoReadingValue;
		
		
		[self loadTextures];
		[self setupView];
    }
    return self;
}

-(void)loadObjects {
	
	int i;
	
	marbles = malloc(numMarbles * sizeof(Marble *));
	for (i=0; i < numMarbles; i++) {
		marbles[i] = [[Marble alloc] initMarble];
		
	}
}

-(void)loadTextures {
	CGImageRef spriteImage;
	CGContextRef spriteContext;
	int  curTexture = 0;
	GLubyte *spriteData;
	size_t	width, height;
	
	numTextures = [textureNames count];
	NSString *curName;
	NSString *fileName;
	
	spriteTextures = malloc(sizeof(GLuint)*numTextures);
	
	for (int texture=0; texture < numTextures; texture++) {
		curName = [textureNames objectAtIndex:texture];
		fileName = [NSString stringWithFormat:@"%@.png", curName];
		spriteImage = [UIImage imageNamed:fileName].CGImage;
		
		if(spriteImage) {
			
			width = CGImageGetWidth(spriteImage);
			height = CGImageGetHeight(spriteImage);
			
			// Allocated memory needed for the bitmap context
			spriteData = (GLubyte *) malloc(width * height * 4);
			// Uses the bitmatp creation function provided by the Core Graphics framework. 
			spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
			// After you create the context, you can draw the sprite image to the context.
			CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), spriteImage);
			// You don't need the context at this point, so you need to release it to avoid memory leaks.
			CGContextRelease(spriteContext);
			
			// Use OpenGL ES to generate a name for the texture.
			glGenTextures(1, &spriteTextures[curTexture]);
			// Bind the texture name. 
			glBindTexture(GL_TEXTURE_2D, spriteTextures[curTexture]);
			
			
			// Speidfy a 2D texture image, provideing the a pointer to the image data in memory
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
			glBindTexture(GL_TEXTURE_2D, spriteTextures[curTexture]);
			// Release the image data
			free(spriteData);
			
			// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			
			
			curTexture++;
		}
		
	}
	
	/*
	CGColorSpaceRef    colorSpace = CGColorSpaceCreateDeviceGray();
	int sizeInBytes = height*width;
	void* data = malloc(sizeInBytes);
	memset(data, 0, sizeInBytes);
	CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width, colorSpace, kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);
	CGGloat gray = 0.5;
	CGContextSetGrayFillColor(context, grayColor, 1.0);
	CGContextTranslateCTM(context, 0.0, height);
	CGContextScaleCTM(context, 1.0, -1.0);
	UIGraphicsPushContext(context);
    [txt drawInRect:CGRectMake(0, 20, 100, 100) withFont:font
	  lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
	UIGraphicsPopContext();
	*/
	
	
	// Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	// Enable blending
	glEnable(GL_BLEND);
	
	
}

-(void)setupView {

}

- (void)drawView {
    
    // Replace the implementation of this method to do your own custom drawing
    
	if (!colliding) {
		curX += speedX;
		curY -= speedY;
	}
	float bounce = 0.9;
	int grid = 15;
	float gridSize = 0.1;
	float edge = (float)(grid)*(gridSize) -ballSize/2 ;
	
	if (curX > edge) {
		curX = edge;
		speedX = -speedX*bounce;
	}
	else if (curX < -edge) {
		curX = -(float)edge;
		speedX = -speedX*bounce;
	}
	
	if (curY > edge) {
		curY = edge;
		speedY = -speedY*bounce;
	}
	else if (curY < -edge) {
		curY = -(float)edge;
		speedY = -speedY*bounce;
	}
	
	int curMarble;
	

	int numSquares = 1;
	int numShapes = grid;
	int numRows = grid;
	int curSquare = 0;
	int curVert = 0;
	int numVerts = numSquares*2 + 2;
	
	float size = 0.2f;
	float halfSize = size/2;
	
	GLfloat **testVerts;
	GLubyte *testColors;
	GLfloat *testTex;
	
	testVerts = malloc(sizeof(GLfloat*)*numShapes);
	testTex = malloc(sizeof(GLfloat)*(numVerts*2));
	testColors = malloc(sizeof(GLubyte)*(numVerts*4));
	
	//testVerts = malloc(1000);
	//testColors = malloc(1000);
	
	int color = 0;
	int rgb;
	int offset;
	int curShape;
	int row;
	
	[EAGLContext setCurrentContext:context];
    
	//glLoadIdentity();
	
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
	
	float offsetC = -(float)numShapes*size/2;
	//offsetC = 0;
	
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	//int rotateAngle = (forward) ? 1.0f : -1.0f;
	//glRotatef(rotateAngle, 0.0f, 0.0f, 1.0f);
	
	//glRotatef(rotateAngle, 0.0f, 0.0f, 1.0f);
	//glTranslatef(offsetC, offsetC, 0);

	//rotateAngle += 0.1;
	
	
	for (curShape=0; curShape < numShapes; curShape++) {
		testVerts[curShape] = malloc(sizeof(GLfloat)*(numVerts*2));
	}
	
	//glTranslatef((curPoint.x - firstPoint.x)/100.0f, 0, 0);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
    glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f);
	
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(curX, -curY, 0);
	
	
	glPushMatrix();
	//glLoadIdentity();
	glTranslatef(-numShapes*size/2, -numShapes*size/2, 0);
	
	
	float view = 3;
	float yView = 30;
	
	float gridOff = gridSize*grid;
	float shiftX = -curX + gridSize*(grid);
	float off = gridSize*0.0;
	float yOff = gridSize*7.5;
	int startX = floor(shiftX/gridSize - off) - view;
	int endX = ceil(shiftX/gridSize - off) + view;
	int startY = floor((curY + gridOff)/gridSize + yOff - yView) + grid/2;
	int endY = ceil((curY + gridOff)/gridSize + yOff + yView) + grid/2;
	
	if (startX < 0) {
		startX = 0;
		//endX = view;
	}
	if (startY < 0) startY = 0;
	if (startX > numRows-1) startX = numRows-1;
	if (startY > numShapes-1) startY = numShapes-1;
	if (endX > numRows-1) endX = numRows-1;
	if (endY > numShapes-1) endY = numShapes-1;
	
	
	for (row=startX; row < endX; row++) {
			for (curShape=startY; curShape < endY; curShape++) {
			curSquare = 0;
			
			for (curVert=0; curVert < numVerts; curVert += 2, curSquare++) {
				offset = curVert*2;
				testVerts[curShape][offset+3]	=  (curShape+1)*size;
				testVerts[curShape][offset+2]	= (float)curSquare * size + row*size;
				testVerts[curShape][offset+1]	= curShape*size;
				testVerts[curShape][offset]	= (float)curSquare * size + row*size;
				testTex[offset+3] = 0;
				testTex[offset+2] = (float)curVert/(numVerts-2);
				testTex[offset+1] = 1;
				testTex[offset] = (float)curVert/(numVerts-2);
			}
			
		
			//GLenum err;
		
			//int tex = (random() % numTextures);
			//int tex = curShape % numTextures;
			
			float m = numShapes*numRows;
				
			float s = sin((curShape*row)/m);
				
			int tex = (int)(s * 20) % numTextures;

			
			
			glBindTexture(GL_TEXTURE_2D, spriteTextures[tex]);
			
					
			glVertexPointer(2, GL_FLOAT, 0, testVerts[curShape]);
			
			glTexCoordPointer(2, GL_FLOAT, 0, testTex);
			
			
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		
		}
		
	}
	glPopMatrix();
   
	float dx;
	float dy;
	
	float xx;
	float yy;
	
	colliding = false;
	[self drawBall];
	
#pragma mark move/draw marbles
	for (curMarble=0; curMarble < numMarbles; curMarble++) {
		if ([marbles[curMarble] collide:-curX withY:curY andRadius:ballSize otherSpeedX:speedX otherSpeedY:speedY outX:&xx outY:&yy]) {
			colliding = true;
			speedX = xx;
			speedY = yy;
			//curX = 4;
			//curY = 4;
		} else {
			//for (curMarble=0; curMarble < numMarbles; curMarble++) {
				[marbles[curMarble] move];
			//}
		}
		[marbles[curMarble] draw:spriteTextures];
			
	}
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	for (curShape=0; curShape < numShapes; curShape++) {
		free(testVerts[curShape]);
	}
	
	free(testVerts);
	free(testTex);
	free(testColors);
	
	
}

-(void)drawBall {
	
	int row;
	
	GLfloat *testVerts;
	
	GLfloat *testTex;
	
	testVerts = malloc(sizeof(GLfloat)*8);
	testTex = malloc(sizeof(GLfloat)*8);
	
	
	glPushMatrix();
	//glLoadIdentity();
	glTranslatef( -curX, curY, 0);
	
	float xOffset = (float)curX + 1.0;
	float yOffset = (float)curY + 1.0;
	
	xOffset =0;
	yOffset = -ballSize/2;
	//yOffset = 0;
	
	for (row=0; row < 2; row++) {
		testVerts[row*4 + 3]	= (float)row*ballSize  + yOffset;
		testVerts[row*4 + 2]	= ballSize/2 + xOffset;
		testVerts[row*4 + 1]	= (float)row*ballSize  + yOffset;
		testVerts[row*4]	= -ballSize/2 + xOffset;
		testTex[row*4 + 3]	= 0;
		testTex[row*4 + 2]	= (float)row/1;
		testTex[row*4 + 1]	= 1;
		testTex[row*4]	= (float)row/1;
	}
	
	glBindTexture(GL_TEXTURE_2D, spriteTextures[3]);
	glVertexPointer(2, GL_FLOAT, 0, testVerts);
	glTexCoordPointer(2, GL_FLOAT, 0, testTex);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glPopMatrix();
		 
	free(testVerts);
	free(testTex);
	
	
}


- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    //[self drawView];
	//[self drawBall];
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation {
    self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
    [animationTimer invalidate];
    animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
    
    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
        [self startAnimation];
    }
}


- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
	[textureNames release];
    [context release];  
    [super dealloc];
}




- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    // Use a basic low-pass filter to only keep the gravity in the accelerometer values for the X and Y axes
    float accelerationX, accelerationY, currentRawReading;
	
	float kFilteringFactor = 1;
	
	
	accelerationX = acceleration.x * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
    accelerationY = acceleration.y * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);
    float f = 0.02;
	speedX -= (float)accelerationX*f;
	speedY -= (float)accelerationY*f;
	
	if (speedX > kMaxSpeed) speedX = kMaxSpeed;
	else if (speedX < -kMaxSpeed) speedX = -kMaxSpeed;
	if (speedY > kMaxSpeed) speedY = kMaxSpeed;
	else if (speedY < -kMaxSpeed) speedY = -kMaxSpeed;
	
	int grid = 100;
	float gridSize = 0.1;
	float edge = (float)(grid)*(gridSize) -ballSize/2 ;
	
	if (curX > edge) {
		curX = edge;
		speedX = -speedX;
	}
	else if (curX < -edge) {
		curX = -(float)edge;
		speedX = -speedX;
	}
	
	if (curY > edge) {
		curY = edge;
		speedY = -speedY;
	}
	else if (curY < -edge) {
		curY = -(float)edge;
		speedY = -speedY;
	}
	
    // keep the raw reading, to use during calibrations
   //currentRawReading = atan2(accelerationY, accelerationX);
    
    //float calibratedAngle = [self calibratedAngleFromAngle:currentRawReading];
    
    //[levelView updateToInclinationInRadians:calibratedAngle];
}

@end