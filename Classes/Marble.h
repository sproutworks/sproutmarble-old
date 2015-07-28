//
//  Marble.h
//  GameOne
//
//  Created by Brandon Smith on 1/30/09.
//  Copyright 2009 SproutWorks. All rights reserved.
//

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface Marble : NSObject {
	float posX, posY, posZ;
	float prevX, prevY, prevZ;
	float speedX, speedY, speedZ;
	float size;
	float mass;
	bool c;
	int intSpeed;
	int textureNum;
}

-(id)initMarble;
-(void)move;
-(bool) collide: (float)x withY: (float)y andRadius: (float)radius otherSpeedX: (float)oSpeedX otherSpeedY: (float)oSpeedY outX: (float*)ox outY: (float*)oy;
-(void)draw:(GLuint **) textures;




@property (nonatomic, readwrite) float posX;
@property (nonatomic, readwrite) float posY;

@end
