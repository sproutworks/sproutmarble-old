//
//  Marble.m
//  GameOne
//
//  Created by Brandon Smith on 1/30/09.
//  Copyright 2009 SproutWorks. All rights reserved.
//

#import "Marble.h"



@implementation Marble


@synthesize posX;
@synthesize posY;

-(id)initMarble {
	
	textureNum = 0;
	intSpeed = 4000;
	if (1) {
		
        speedX = (float)(rand() % 100) / intSpeed;
        speedY =  (float)(rand() % 100) / intSpeed;
        size = (float)(rand() % 100)/250;
        posX = (float)(rand() % 100);
        posY = (float)(rand() % 100);
	
	}
	else {
		speedX = 1.0;
		speedY = 1.0;
		size =  0.5;
		posX = 0;
		posY = 0;
		prevX = 0;
		prevY = 0;
	}
	
	mass = size*10;
	
	c = false;
	return self;
}


-(float) posX {
	return posX;
}

-(float)posY {
	return posY;
}

-(void)move {
	prevX = posX;
	prevY = posY;
	
	posX += speedX;
	posY += speedY;
	
	int grid = 50;
	float gridSize = 0.1;
	float edge = (float)(grid)*(gridSize) -size/2 ;
	
	if (posX > edge) {
		posX = edge;
		speedX = -speedX;
	}
	else if (posX < -edge) {
		posX = -(float)edge;
		speedX = -speedX;
	}
	
	if (posY > edge) {
		posY = edge;
		speedY = -speedY;
	}
	else if (posY < -edge) {
		posY = -(float)edge;
		speedY = -speedY;
	}
	
}

-(bool) collide: (float)x withY: (float)y andRadius: (float)radius otherSpeedX: (float)oSpeedX otherSpeedY: (float)oSpeedY outX: (float*)ox outY: (float*)oy {
	
	float dx = posX - x;
	float dy = posY - y;
	

	float distance = sqrt(dx*dx + dy*dy);
	
	//float otherRadius = sin(3.14/4)*size/2;
	//float thisRadius = sin(3.14/4)*radius/2;
	
	float otherRadius = size/2;
	float thisRadius = radius/2;
	
	if (distance < (otherRadius + thisRadius)) {
		
		if (c) return false;
		
		float actionAng = atan(dy/dx);
		
		float sinAng = sin(actionAng);
		float cosAng = cos(actionAng);
		
		float vParallel = cosAng*speedX;
		float vNormal = -sinAng*speedX;
		
		float ovParallel = cosAng*oSpeedX;
		float ovNormal = sinAng*oSpeedX;
		
		float e = 1;
		float otherMass = 4.0;
		
		float pvParallel = (mass - e*otherMass)/(mass + otherMass)*vParallel;
		float opvParallel = (1.0 + e)*mass/(mass + otherMass)*vParallel;
		
		speedX = pvParallel*cosAng - sinAng*vNormal;
		speedY = pvParallel*sinAng + vNormal*cosAng;
		
		*ox = -(opvParallel*cosAng - ovNormal*sinAng);
		*oy = -(opvParallel*sinAng + ovNormal*cosAng);
		
		textureNum = 3;
		
		c = true;
		
		//*ox = aspeed*sin(a);
		
		posX = prevX;
		posY = prevY;
		
		return true;
	}
	c = false;
	return false;
}


-(void)draw:(GLuint **)textures{
	int row;
	
	GLfloat *testVerts;
	
	GLfloat *testTex;
	
	testVerts = malloc(sizeof(GLfloat)*8);
	testTex = malloc(sizeof(GLfloat)*8);
	
	glPushMatrix();
	//glLoadIdentity();
	glTranslatef( posX, posY, 0);
	
	//float xOffset = (float)posX + 1.0;
	//float yOffset = (float)posY + 1.0;
	
	float xOffset =0;
	float yOffset = -size/2;
	
	for (row=0; row < 2; row++) {
		testVerts[row*4 + 3]	= (float)row*size  + yOffset;
		testVerts[row*4 + 2]	= size/2 + xOffset;
		testVerts[row*4 + 1]	= (float)row*size  + yOffset;
		testVerts[row*4]	= -size/2 + xOffset;
		testTex[row*4 + 3]	= 0;
		testTex[row*4 + 2]	= (float)row/1;
		testTex[row*4 + 1]	= 1;
		testTex[row*4]	= (float)row/1;
	}
	
	glBindTexture(GL_TEXTURE_2D, textures[textureNum]);
	glVertexPointer(2, GL_FLOAT, 0, testVerts);
	glTexCoordPointer(2, GL_FLOAT, 0, testTex);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glPopMatrix();
	
	
	free(testVerts);
	free(testTex);
	
}


@end
