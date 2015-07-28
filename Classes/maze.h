//
//  maze.h
//  SproutMarble
//
//  Created by Brandon Smith on 5/17/09.
//  Copyright 2009 SproutWorks. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Maze : NSObject {
	int wallsX;
	int wallsY;
	BOOL* hWalls;
	BOOL* vWalls;
	
}

//@property (nonatomic, retain) BOOL *hWalls;
//@property (nonatomic, retain) BOOL * Walls;

-(Maze*)initDefault;
-(Maze*)initWithSize:(int)x andY:(int)y;
-(void)create;
-(void)processCell:(int)curX andY:(int)curY;
-(BOOL*)getHWalls;
-(BOOL*)getVWalls;

@end
