//
//  NSMutableArray+Queue.h
//  UIGridView
//
//  Created by Mikayel Aghasyan on 7/11/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queue)

- (id)deque;
- (void)enque:(id)obj;

@end
