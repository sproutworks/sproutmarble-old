//
//  maze.m
//  SproutMarble
//
//  Created by Brandon Smith on 5/17/09.
//  Copyright 2009 SproutWorks. All rights reserved.
//

#import "maze.h"


@implementation Maze

//@synthesize hWalls;
//@synthesize vWalls;

-(Maze*)initDefault {
	
	wallsX = 50;
	wallsY = 50;
	
	srand(time(0));
	[self create];
	return self;
}

-(Maze*)initWithSize:(int)x andY:(int)y {
	wallsX = x;
	wallsY = y;
	
	srand(time(0));
	[self create];
	return self;
	
}

-(void)create {
	hWalls = malloc((wallsY+1)*(wallsX+1)*sizeof(float));
	vWalls = malloc((wallsX+1)*(wallsY+1)*sizeof(float));
	
	int wallX;
	int wallY;
	
	// build all the walls
	for (wallX=0; wallX < wallsX*wallsY; wallX++) {
		vWalls[wallX] = true;
	}
	
	for (wallY=0; wallY < wallsY*wallsX; wallY++) {
		hWalls[wallY] = true;
	}
	
	[self processCell: 0 andY:0];
	
}


-(BOOL)allWalls:(int)curX andY:(int)curY {
	return(hWalls[curY*wallsX + curX] && hWalls[(curY+1)*wallsX + curX] && vWalls[curY*wallsX + curX] && vWalls[curY*wallsX + curX + 1]);
}
	
-(BOOL*)getHWalls {
	return hWalls;
}

-(BOOL*)getVWalls {
	return vWalls;
}

-(void)processCell:(int)curX andY:(int)curY {
	
	//int direction = rand() % 4;
	
	//NSLog(@"process");
	
	int numChoices = 0;
	int curChoice = 0;
	
	BOOL up,down,left,right;
	up = down = left = right = false;
	
	if (curX > 0 && [self allWalls: curX-1 andY: curY]) {
		numChoices++;
		left = true;
	}
	if (curX < wallsX && [self allWalls: curX+1 andY: curY]) {
		numChoices++;
		right = true;
	}
	if (curY > 0 && [self allWalls: curX andY: curY-1]) {
		numChoices++;
		up = true;
	}
	if (curY < wallsY && [self allWalls: curX andY: curY+1]) {
		numChoices++;
		down = true;
	}

	int choice = (numChoices) ? rand() % numChoices : 5;
	
	int r = rand() % 3;
	if (rand() % 2 == 1) {
	// go left
	if (curX > 0 && [self allWalls: curX-1 andY: curY]) {
		//if (curChoice++ == choice) {
			//NSLog(@"remove left");
			vWalls[curY*wallsX + curX] = false;
			[self processCell:curX-1 andY: curY];
		//}
	}
		// go down
		if (curY < wallsY && [self allWalls: curX andY: curY+1]) {
			//if (curChoice++ == choice) {
			//NSLog(@"remove down");
			hWalls[(curY+1)*wallsX + curX] = false;
			[self processCell:curX andY:curY+1];
			//}
		}
	// go right
	if (curX < wallsX && [self allWalls: curX+1 andY: curY]) {
		//if (curChoice++ == choice) {
			//NSLog(@"remove right");
		vWalls[curY*wallsX + curX + 1] = false;
		[self processCell:curX+1 andY:curY];
		//}
	}
	// go up
	if (curY > 0 && [self allWalls: curX andY: curY-1]) {
		//if (curChoice++ == choice) {
			//NSLog(@"remove up");
			hWalls[(curY)*wallsX + curX] = false;
			[self processCell:curX andY:curY-1];
		//}
	}
	
	} else {
		
		// go right
		if (curX < wallsX && [self allWalls: curX+1 andY: curY]) {
			//if (curChoice++ == choice) {
			//NSLog(@"remove right");
			vWalls[curY*wallsX + curX + 1] = false;
			[self processCell:curX+1 andY:curY];
			//}
		}
		
		// go up
		if (curY > 0 && [self allWalls: curX andY: curY-1]) {
			//if (curChoice++ == choice) {
			//NSLog(@"remove up");
			hWalls[(curY)*wallsX + curX] = false;
			[self processCell:curX andY:curY-1];
			//}
		}
		
		
		// go down
		if (curY < wallsY && [self allWalls: curX andY: curY+1]) {
			//if (curChoice++ == choice) {
			//NSLog(@"remove down");
			hWalls[(curY+1)*wallsX + curX] = false;
			[self processCell:curX andY:curY+1];
			//}
		}
		
		
		// go left
		if (curX > 0 && [self allWalls: curX-1 andY: curY]) {
			//if (curChoice++ == choice) {
			//NSLog(@"remove left");
			vWalls[curY*wallsX + curX] = false;
			[self processCell:curX-1 andY: curY];
			//}
		}
		
		
		
		
				
		
			}
}

@end
