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
#import	"GameData.h"

#define USE_DEPTH_BUFFER 0
#define kUpdateFrequency 30  // Hz
#define kMaxSpeed		 0.05

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

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
	
	//UITouch *touch = [touches anyObject];
	
}


- (void)setupChipmunk {
	cpInitChipmunk();
	
	space = cpSpaceNew();
	
	space->gravity = cpv(-1.44, -1.05);
	
	cpBody *ballBody = cpBodyNew(100, 5.0);
	
	ballBody->p = cpv(0.0, 0.0);
	
	cpSpaceAddBody(space, ballBody);
	
	cpShape *ballShape = cpCircleShapeNew(ballBody, ballSize/2, cpvzero);
	
	ballShape->e = 0.989;
	ballShape->collision_type = 1;
	ballShape->data = (void*)1;
	
	cpSpaceAddShape(space, ballShape);
	
	
}

-(void)setupWalls {
	int drawX;
	int drawY;
	float wallThickness = 0.0001;
	cpVect *wallVerts = malloc(4*sizeof(cpVect));
	cpBody *wallBody = cpBodyNew(INFINITY, INFINITY);
	wallBody->p = cpv(0, 0);
	cpShape *floorShape;
	
	cpVect center = cpv(-(float)gridSize*numTilesX/2, -(float)gridSize*numTilesY/2);
	
	int cX,cY;
	
	BOOL *hWalls = [theMaze getHWalls];
	BOOL *vWalls = [theMaze getVWalls];
	
	
	for (drawX=0; drawX < numTilesX; drawX++) {
		cX = drawX;
		for (drawY=0; drawY < numTilesY; drawY++) {
			cY = drawY;
			if (vWalls[drawY*numTilesX + drawX]) {
				
				wallVerts[0] = cpv(cX*gridSize + wallThickness, cY*gridSize);
				wallVerts[1] = cpv(cX*gridSize, (cY)*gridSize);
				wallVerts[2] = cpv(cX*gridSize, (cY+1)*gridSize);
				wallVerts[3] = cpv(cX*gridSize + wallThickness, (cY+1)*gridSize);
				floorShape = cpPolyShapeNew(wallBody, 4, wallVerts, center);		// delete this later
				floorShape->e = 0.999;
				floorShape->u = 0.8;
				floorShape->collision_type = 1;
				floorShape->data = (void*)1;
				cpSpaceAddStaticShape(space, floorShape);
			}
			
			
			if (hWalls[drawY*numTilesX + drawX]) {
				wallVerts[0] = cpv((cX+1)*gridSize, cY*gridSize);
				wallVerts[1] = cpv(cX*gridSize, cY*gridSize);
				wallVerts[2] = cpv(cX*gridSize, cY*gridSize + wallThickness);
				wallVerts[3] = cpv((cX+1)*gridSize, cY*gridSize + wallThickness);
				floorShape = cpPolyShapeNew(wallBody, 4, wallVerts, center);		// delete this later
				floorShape->e = 0.999;
				floorShape->u = 0.8;
				floorShape->collision_type = 1;
				floorShape->data = (void*)1;
				cpSpaceAddStaticShape(space, floorShape);
			}
			
		}
		
	}
	
	
	 
	// left
	/*
	wallVerts[0] = cpv(-numTilesX*gridSize/2, -numTilesY*gridSize/2);
	wallVerts[1] = cpv(-numTilesX*gridSize/2, numTilesY*gridSize/2);
	wallVerts[2] = cpv(-numTilesX*gridSize/2 + wallThickness, numTilesY*gridSize/2);
	wallVerts[3] = cpv(-numTilesX*gridSize/2 + wallThickness, -numTilesY*gridSize/2);
	floorShape = cpPolyShapeNew(wallBody, 4, wallVerts, cpvzero);		// delete this later
	floorShape->e = 0.999;
	floorShape->u = 0.8;
	floorShape->collision_type = 1;
	floorShape->data = (void*)1;
	cpSpaceAddStaticShape(space, floorShape);
	*/
	 
	// right
	wallVerts[0] = cpv(numTilesX*gridSize/2, -numTilesY*20*gridSize/2);
	wallVerts[1] = cpv(numTilesX*gridSize/2, numTilesY*20*gridSize/2);
	wallVerts[2] = cpv(numTilesX*gridSize/2 + wallThickness, numTilesY*gridSize/2);
	wallVerts[3] = cpv(numTilesX*gridSize/2 + wallThickness, -numTilesY*gridSize/2);
	floorShape = cpPolyShapeNew(wallBody, 4, wallVerts, cpv(numTilesX*gridSize,0));		// delete this later
	floorShape->e = 0.999;
	floorShape->u = 0.8;
	floorShape->collision_type = 1;
	floorShape->data = (void*)1;
	cpSpaceAddStaticShape(space, floorShape);
	
	// bottom
	/*
	wallVerts[0] = cpv(-numTilesX*gridSize/2, -numTilesY*gridSize/2);
	wallVerts[1] = cpv(-numTilesX*gridSize/2, -numTilesY*gridSize/2 + wallThickness);
	wallVerts[2] = cpv(numTilesX*gridSize/2, -numTilesY*gridSize/2 + wallThickness);
	wallVerts[3] = cpv(numTilesX*gridSize/2, -numTilesY*gridSize/2);
	floorShape = cpPolyShapeNew(wallBody, 4, wallVerts, cpvzero);		// delete this later
	floorShape->e = 0.999;
	floorShape->u = 0.8;
	floorShape->collision_type = 1;
	floorShape->data = (void*)1;
	cpSpaceAddStaticShape(space, floorShape);
	 
	 
	 
	// top
	wallVerts[0] = cpv(-numTilesX*gridSize/2, numTilesY*gridSize/2);
	wallVerts[1] = cpv(-numTilesX*gridSize/2, numTilesY*gridSize/2 + wallThickness);
	wallVerts[2] = cpv(numTilesX*gridSize/2, numTilesY*gridSize/2 + wallThickness);
	wallVerts[3] = cpv(numTilesX*gridSize/2, numTilesY*gridSize/2);
	floorShape = cpPolyShapeNew(wallBody, 4, wallVerts, cpvzero);		// delete this later
	floorShape->e = 0.999;
	floorShape->u = 0.8;
	floorShape->collision_type = 1;
	floorShape->data = (void*)1;
	cpSpaceAddStaticShape(space, floorShape);
	 */
	
	
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
		
		textureNames = [[NSArray alloc] initWithObjects: @"marble", @"green-square-hole", @"red-wall", @"blue_marble", @"red_marble", @"green_marble", @"grass-tile",@"bluegear",@"greengear", nil];
		
		forward = true;
		rotateAngle = 0;
		
		curX = 0;
		curY = 0;
		speedX = 0.002;
		speedY = 0.002;
		numMarbles = 1;
		colliding = false;
		ballSize = 0.10;
		gridSize = 0.2;
		numTilesX = 25;
		numTilesY = 25;
		//gridObject = [[GridObject alloc] init];
		
		[self loadObjects];
		
		marble = [[Marble alloc] initMarble];
		
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kUpdateFrequency)];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
		//calibrationOffset = 0.0;
		//firstCalibrationReading = kNoReadingValue;
		
		theMaze = [[Maze alloc] initWithSize: numTilesX andY: numTilesY];
		
		
		[self loadTextures];
		[self setupView];
		
		[self setupChipmunk];
		[self setupWalls];
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

- (void)updateShape:(void*)ptr unused:(void*)unused {
	cpShape *shape = (cpShape*)ptr;
	
	if(shape == nil || shape->body == nil || shape->data == nil) {  
   
		NSLog(@"Unexpected shape please debug here...");  
   
		return;  
   }
	
}

- (void)drawView; {
    
	if (!colliding) {
		//curX += speedX;
		//curY -= speedY;
	}
	
	cpSpaceStep(space, animationInterval);
	
	cpSpaceHashEach(space->activeShapes, updateShape, nil);  
	
	GameData *data = [GameData sharedGameData];
	
	curX = -data.cameraX;
	curY = data.cameraY;
	
	int curMarble;
	

	int numSquares = 1;
	int numShapes = numTilesY;
	int numRows = numTilesX;
	int curSquare = 0;
	int curVert = 0;
	int numVerts = numSquares*2 + 2;
	
	float size = 0.1f;
	float halfSize = size/2;
	
	
	
	GLfloat *wallVerts;
	GLfloat *wallTex;
	
	wallVerts = malloc(sizeof(GLfloat)*8*3);
	wallTex = malloc(sizeof(GLfloat)*8*3);
	
	int offset;
	
	int row;
	int drawX, drawY;
	
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
	
	//glTranslatef((curPoint.x - firstPoint.x)/100.0f, 0, 0);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
	//CGRect rect = view.bounds; 
	GLfloat ssize = .1 * tanf(DEGREES_TO_RADIANS(45.0) / 2.0); 
	
	glFrustumf(-ssize,                                           // Left
			   ssize,                                           // Right
			   -ssize,											// Bottom
			   ssize,											// Top
			   .02,												// Near
			   1000.0);   
	
	
    glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 2.0f);
	glViewport(0, 0,320, 480); 
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(curX, -curY, 0);
	
	
	glPushMatrix();
	//glLoadIdentity();
	
	
	float xView = 32;
	float yView = 20;

	
	float floor = 0.01;
	float wallHeight = -0.03;
	float wallThickness = 0.1;
	
	float center = gridSize*numTilesX/2.0;
	
	float relX = (-curX + center);
	float relY = (curY + center);
	
	float centerX = relX/center;
	float centerY = relY/center;
	float centerXPix = centerX*numTilesX/2.0;
	float centerYPix = centerY*numTilesY/2.0;
	
	int startX = (int)(centerXPix - xView);
	int endX = ceil(centerXPix + xView);
	
	int startY = (int)(centerYPix - yView);
	int endY = ceil(centerYPix + yView);
	
	//int startX = floor(shiftX/gridSize - off) - view;
	//int endX = ceil(shiftX/gridSize - off) + view;
	
	//startX = 0;
	
	//float gridSize = 0.11;
	
	//int startY = 0;
	//int endY = numShapes;
	
	if (startX < 0) {
		startX = 0;
		//endX = view;
	}
	if (startY < 0) startY = 0;
	if (startX > numRows-1) startX = numRows-1;
	if (startY > numShapes-1) startY = numShapes-1;
	if (endX > numRows-1) endX = numRows-1;
	if (endY > numShapes-1) endY = numShapes-1;
	
	glTranslatef(-numTilesX*gridSize/2 /*- startX*gridSize*/, -numTilesY*gridSize/2/* - startY*gridSize*/, 0.2);
	
	float tileLevel = floor + wallHeight;
	
	// draw floor
	for (drawX=startX; drawX < endX; drawX++) {
		for (drawY=startY; drawY < endY; drawY++) {
			curSquare = 0;
			
			for (curVert=0; curVert < numVerts; curVert += 2, curSquare++) {
				offset = curVert*3;
				
				wallVerts[offset+5] = tileLevel;
				wallVerts[offset+4]	=  (drawY+1)*gridSize;
				wallVerts[offset+3]	= (float)curSquare * gridSize + drawX*gridSize;
				//
				wallVerts[offset+2] = tileLevel/2;
				wallVerts[offset+1]	= drawY*gridSize;
				wallVerts[offset]	= (float)curSquare * gridSize + drawX*gridSize;
				wallTex[offset+5] = 0;
				wallTex[offset+4] = 0;
				wallTex[offset+3] = (float)curVert/(numVerts-2);
				wallTex[offset+2] = 1;
				wallTex[offset+1] = 1;
				wallTex[offset] = (float)curVert/(numVerts-2);
			}
			
			float m = numShapes*numRows;
				
			//float s = sin((drawY*drawX)/m);
				
			//int tex = (int)(s * 20) % numTextures;
				
			//tex = ((drawY + drawX)%2 == 1) ? 1 : 2;
			int tex = 2;
			
			glBindTexture(GL_TEXTURE_2D, spriteTextures[tex]);
			
			glVertexPointer(3, GL_FLOAT, 0, wallVerts);
			
			glTexCoordPointer(3, GL_FLOAT, 0, wallTex);
			
			//glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
		}		
	}
	
#pragma mark draw maze
	// draw maze
	
	BOOL *hWalls = [theMaze getHWalls];
	BOOL *vWalls = [theMaze getVWalls];
	
	int curWall;
	float wallOffset;
	float wallTop = floor + wallHeight;
	float localFloor = wallTop;
	
	colliding = false;
	
	for (drawX=startX; drawX < endX; drawX++) {
		for (drawY=startY; drawY < endY; drawY++) {
			
			if (hWalls[drawY*numTilesX + drawX]) {
				
				for (curWall=0; curWall < 1; curWall++) {
				
					wallOffset = (float)curWall*wallThickness;

					
					// horz wall, lower left corner
					wallVerts[0] = drawX*gridSize;	// x
					wallVerts[1] = drawY*gridSize + wallOffset;	// y
					wallVerts[2] = floor;			// z
					
					wallTex[0] = 0;
					wallTex[1] = 1;
					wallTex[2] = 0;
					
					// horz wall, upper left corner
					wallVerts[3] = drawX*gridSize;	// x
					wallVerts[4] = (drawY)*gridSize + wallOffset;	// y
					wallVerts[5] = wallTop;			// z
					
					wallTex[3] = 0;
					wallTex[4] = 0;
					wallTex[5] = 1;
					
					// horz wall, upper right corner
					wallVerts[6] = (drawX+1)*gridSize;	// x
					wallVerts[7] = (drawY)*gridSize + wallOffset;	// y
					wallVerts[8] = wallTop;			// z
					
					wallTex[6] = 1;
					wallTex[7] = 0;
					wallTex[8] = 1;
					
					// horz wall, lower right corner
					wallVerts[9] = (drawX+1)*gridSize;	// x
					wallVerts[10] = (drawY)*gridSize + wallOffset;	// y
					wallVerts[11] = floor;			// z
					
					wallTex[9] = 1;
					wallTex[10] = 1;
					wallTex[11] = 0;
					
					
					glBindTexture(GL_TEXTURE_2D, spriteTextures[6]);
					glVertexPointer(3, GL_FLOAT, 0, wallVerts);
					glTexCoordPointer(3, GL_FLOAT, 0, wallTex);
					
					
					glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
				}
				
			}
			
						
			// vert walls
			if (vWalls[drawY*numTilesX + drawX]) {
				
				for (curWall=0; curWall < 1; curWall++) {
					wallOffset = (float)curWall*wallThickness;
					
					// left wall, lower right corner
					wallVerts[0] = drawX*gridSize + wallOffset;	// x
					wallVerts[1] = drawY*gridSize;	// y
					wallVerts[2] = floor;		// z
					
					wallTex[0] = 0;
					wallTex[1] = 0;
					wallTex[2] = 0;
					
					// left wall, lower left corner
					wallVerts[3] = drawX*gridSize + wallOffset;	// x
					wallVerts[4] = (drawY+1)*gridSize;	// y
					wallVerts[5] = floor;			// z
					
					wallTex[3] = 1;
					wallTex[4] = 0;
					wallTex[5] = 0;
					
					// left wall, upper left corner
					wallVerts[6] = drawX*gridSize + wallOffset;	// x
					wallVerts[7] = (drawY+1)*gridSize;	// y
					wallVerts[8] = wallTop;			// z
					
					wallTex[6] = 1;
					wallTex[7] = 1;
					wallTex[8] = 1;
					
					// left wall, upper right corner
					wallVerts[9] = drawX*gridSize + wallOffset;	// x
					wallVerts[10] = (drawY)*gridSize;	// y
					wallVerts[11] = wallTop;			// z
					
					wallTex[9] = 0;
					wallTex[10] = 1;
					wallTex[11] = 1;
					
					
					glBindTexture(GL_TEXTURE_2D, spriteTextures[6]);
					glVertexPointer(3, GL_FLOAT, 0, wallVerts);
					glTexCoordPointer(3, GL_FLOAT, 0, wallTex);
					
					glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
					
					// draw top
					
					if (curWall == 0) {
					
						// lower right corner
						wallVerts[0] = drawX*gridSize;	// x
						wallVerts[1] = drawY*gridSize;	// y
						wallVerts[2] = localFloor;		// z
						
						wallTex[0] = 0;
						wallTex[1] = 0;
						wallTex[2] = 0;
						
						// upper left corner
						wallVerts[3] = drawX*gridSize;	// x
						wallVerts[4] = (drawY+1)*gridSize;	// y
						wallVerts[5] = localFloor;			// z
						
						wallTex[3] = 0;
						wallTex[4] = 1;
						wallTex[5] = 0;
						
						// upper right corner
						wallVerts[6] = drawX*gridSize + wallThickness;	// x
						wallVerts[7] = (drawY+1)*gridSize;	// y
						wallVerts[8] = localFloor;			// z
						
						wallTex[6] = 1;
						wallTex[7] = 1;
						wallTex[8] = 1;
						
						// lower right corner
						wallVerts[9] = drawX*gridSize + wallThickness;	// x
						wallVerts[10] = drawY*gridSize;	// y
						wallVerts[11] = localFloor;			// z
						
						wallTex[9] = 1;
						wallTex[10] = 0;
						wallTex[11] = 1;
						
						glBindTexture(GL_TEXTURE_2D, spriteTextures[7]);
						glVertexPointer(3, GL_FLOAT, 0, wallVerts);
						glTexCoordPointer(3, GL_FLOAT, 0, wallTex);
						
						//glDrawArrays(GL_TRIANGLE_FAN, 0, 4);	// draw top of vert wall
					}
				}
				
			}
			
		}
		
	}

	glPopMatrix();

	
	float xx;
	float yy;
	
	//colliding = false;
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
	
	free(wallVerts);
	free(wallTex);
	
	
}

- (bool)collideWithBall:(CGRect *) wall; {
	
	CGRect ball = CGRectMake(-ballSize/2 - speedX, -ballSize/2 - speedY, ballSize, ballSize);
	
	//NSLog(@"wall %f", test);
	
	CGRect intersect = CGRectIntersection(*wall, ball);
	
	return (!CGRectIsNull(intersect));
	
}

-(void)drawBall {
	
	int row;
	int memOffset;
	
	GLfloat *ballVerts;
	GLfloat *ballTex;
	
	ballVerts = malloc(sizeof(GLfloat)*12);
	ballTex = malloc(sizeof(GLfloat)*12);
	
	
	glPushMatrix();
	//glLoadIdentity();
	glTranslatef( -curX, curY, 0);
	
	float xOffset = (float)curX + 1.0;
	float yOffset = (float)curY + 1.0;
	
	float floor = 0.3;
	
	xOffset =0;
	yOffset = -ballSize/2;
	//yOffset = 0;
	
	for (row=0; row < 2; row++) {
		memOffset = row*6;
		ballVerts[memOffset + 5]	= floor;
		ballVerts[memOffset + 4]	= (float)row*ballSize  + yOffset;
		ballVerts[memOffset + 3]	= ballSize/2 + xOffset;
		ballVerts[memOffset + 2]	= floor;
		ballVerts[memOffset + 1]	= (float)row*ballSize  + yOffset;
		ballVerts[memOffset]		= -ballSize/2 + xOffset;
		
		ballTex[memOffset]		= 1;	// x
		ballTex[memOffset + 1]	= (float)row/1;	// y
		ballTex[memOffset + 2]	= 0;	// z
		ballTex[memOffset + 3]	= 0;		// x
		ballTex[memOffset + 4]	= (float)row/1;		// y
		ballTex[memOffset + 5]	= 0;		// z
	}
	
	glBindTexture(GL_TEXTURE_2D, spriteTextures[2]);
	glVertexPointer(3, GL_FLOAT, 0, ballVerts);
	glTexCoordPointer(3, GL_FLOAT, 0, ballTex);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glPopMatrix();
		 
	free(ballVerts);
	free(ballTex);
	
	
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
    
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
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
	[theMaze release];
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
	
	/*
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
	*/
	
    // keep the raw reading, to use during calibrations
   //currentRawReading = atan2(accelerationY, accelerationX);
    
    //float calibratedAngle = [self calibratedAngleFromAngle:currentRawReading];
    
    //[levelView updateToInclinationInRadians:calibratedAngle];
}

@end

void updateShape(void *ptr, void* unused) {
	
	cpShape *shape = (cpShape*)ptr;
	
	if (shape == nil || shape->body == nil || shape->data == nil) {
		NSLog(@"Unexpected shape");
		return;
	}
	
	
	GameData *data = [GameData sharedGameData];
	
	data.cameraX = shape->body->p.x;
	data.cameraY = shape->body->p.y;
	
	//glView.ballSize = 10;
}