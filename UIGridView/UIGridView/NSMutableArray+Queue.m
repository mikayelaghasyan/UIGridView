//
//  NSMutableArray+Queue.m
//  UIGridView
//
//  Created by Mikayel Aghasyan on 7/11/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (id)deque {
	id result = nil;
	if ([self count] > 0) {
		result = [self objectAtIndex:0];
		[self removeObjectAtIndex:0];
	}
	return result;
}

- (void)enque:(id)obj {
	[self addObject:obj];
}

@end
