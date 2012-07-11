//
//  UIGridView.m
//  UIGridView
//
//  Created by Mikayel Aghasyan on 6/18/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import "UIGridView.h"
#import "NSMutableArray+Queue.h"

static NSUInteger const kIndexPathIndexesCount = 2;

@implementation NSIndexPath (UIGridView)

+ (NSIndexPath *)indexPathForCellIndex:(NSUInteger)cellIndex inSection:(NSUInteger)section {
	NSUInteger indexes[kIndexPathIndexesCount] = {section, cellIndex};
	return [NSIndexPath indexPathWithIndexes:indexes length:kIndexPathIndexesCount];
}

- (NSUInteger)section {
	return [self indexAtPosition:0];
}

- (NSUInteger)cellIndex {
	return [self indexAtPosition:1];
}

@end

@interface UIGridView ()

@property (strong, nonatomic) NSMutableDictionary *cellQueueDictionary;

- (void)enqueReusableCell:(UIGridViewCell *)cell;

@end

@implementation UIGridView

@synthesize dataSource = _gvDataSource;
@synthesize delegate = _gvDelegate;
@synthesize cellSize = _cellSize;
@synthesize cellInsets = _cellInsets;

@synthesize cellQueueDictionary = _cellQueueDictionary;

- (NSMutableDictionary *)cellQueueDictionary {
	if (!_cellQueueDictionary) {
		_cellQueueDictionary = [[NSMutableDictionary alloc] init];
	}
	return _cellQueueDictionary;
}

- (void)enqueReusableCell:(UIGridViewCell *)cell {
	NSMutableArray *queue = [self.cellQueueDictionary objectForKey:cell.reuseIdentifier];
	if (!queue) {
		queue = [[NSMutableArray alloc] init];
		[self.cellQueueDictionary setObject:queue forKey:cell.reuseIdentifier];
	}
	[queue enque:cell];
}

- (UIGridViewCell *)dequeReusableCellWithIdentifier:(NSString *)identifier {
	UIGridViewCell *cell = nil;
	NSMutableArray *queue = [self.cellQueueDictionary objectForKey:cell.reuseIdentifier];
	if (queue) {
		cell = [queue deque];
	}
	return cell;
}

- (void)reloadData {
}

@end

@interface UIGridViewCell ()

@property (copy, nonatomic) NSString *reuseIdentifier;

@end

@implementation UIGridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;

- (id)initWithReuseIdentifier:(NSString *)identifier {
	self = [super init];
	if (self) {
		self.reuseIdentifier = identifier;
	}
	return self;
}

@end