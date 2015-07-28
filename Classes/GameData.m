//
//  GameData.m
//  SproutMarble
//
//  Created by Brandon Smith on 1/4/10.
//  Copyright 2010 SproutWorks. All rights reserved.
//

#import "GameData.h"



@implementation GameData

@synthesize cameraX;
@synthesize cameraY;

static GameData *sharedGameData;

// Initialize the singleton instance if needed and return
+(GameData *)sharedGameData
{
	//	@synchronized(self)	        
	{
		if (!sharedGameData)
			sharedGameData = [[GameData alloc] init];
		
		return sharedGameData;
	}
}
+(id)alloc
{
	//	@synchronized(self)
	{
		NSAssert(sharedGameData == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedGameData = [super alloc];
		return sharedGameData;
	}
}
+(id)copy
{
	//  @synchronized(self)
	{
		NSAssert(sharedGameData == nil, @"Attempted to copy the singleton.");
		return sharedGameData;
	}
}

@end

