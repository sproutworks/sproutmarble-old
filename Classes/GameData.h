//
//  GameData.h
//  SproutMarble
//
//  Created by Brandon Smith on 1/4/10.
//  Copyright 2010 SproutWorks. All rights reserved.
//




@interface GameData : NSObject {

	float cameraX;
	float cameraY;
}

@property (nonatomic) float cameraX;
@property (nonatomic) float cameraY;

+ (GameData *)sharedGameData;



@end
