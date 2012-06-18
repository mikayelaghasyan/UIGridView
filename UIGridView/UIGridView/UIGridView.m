//
//  UIGridView.m
//  UIGridView
//
//  Created by Mikayel Aghasyan on 6/18/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import "UIGridView.h"

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

@implementation UIGridView

@synthesize dataSource = _gvDataSource;
@synthesize delegate = _gvDelegate;
@synthesize cellSize = _cellSize;
@synthesize cellInsets = _cellInsets;

- (UIGridViewCell *)dequeReusableCellWithIdentifier:(NSString *)identifier {
	return nil;
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