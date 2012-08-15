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

@interface UIGridVIewCellInfo : NSObject

@property (assign, nonatomic) UIEdgeInsets preferredInsets;
@property (assign, nonatomic) UIGridViewCellHorizontalAlignment horizontalAlignment;
@property (assign, nonatomic) UIGridViewCellVerticalAlignment verticalAlignment;
@property (assign, nonatomic) CGRect contentFrame;
@property (assign, nonatomic) CGPoint contentOrigin;
@property (assign, nonatomic) CGSize contentSize;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) CGPoint origin;
@property (assign, nonatomic) CGSize size;

@end

@implementation UIGridVIewCellInfo

@synthesize preferredInsets = _preferredInsets;
@synthesize horizontalAlignment = _horizontalAlignment;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize contentFrame = _contentFrame;
@synthesize frame = _frame;

- (CGPoint)contentOrigin {
	return self.contentFrame.origin;
}

- (void)setContentOrigin:(CGPoint)origin {
	CGRect frame = self.contentFrame;
	frame.origin = origin;
	self.contentFrame = frame;
}

- (CGSize)contentSize {
	return self.contentFrame.size;
}

- (void)setContentSize:(CGSize)size {
	CGRect frame = self.contentFrame;
	frame.size = size;
	self.contentFrame = frame;
}

- (CGPoint)origin {
	return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
	CGRect frame = self.frame;
	frame.origin = origin;
	self.frame = frame;
}

- (CGSize)size {
	return self.frame.size;
}

- (void)setSize:(CGSize)size {
	CGRect frame = self.frame;
	frame.size = size;
	self.frame = frame;
}

@end

@interface UIGridViewSectionInfo : NSObject

@property (strong, nonatomic) NSMutableArray *cellsInfo;
@property (assign, nonatomic) CGFloat headerHeight;
@property (assign, nonatomic) CGFloat footerHeight;
@property (assign, nonatomic) NSUInteger numberOfColumns;
@property (assign, nonatomic) NSUInteger actualNumberOfColumns;
@property (assign, nonatomic) CGFloat sectionColumnWidth;
@property (assign, nonatomic) CGFloat sectionRowHeight;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) CGPoint origin;
@property (assign, nonatomic) CGSize size;

@end

@implementation UIGridViewSectionInfo

@synthesize cellsInfo = _cellsInfo;
@synthesize headerHeight = _headerHeight;
@synthesize footerHeight = _footerHeight;
@synthesize numberOfColumns = _numberOfColumns;
@synthesize actualNumberOfColumns = _actualNumberOfColumns;
@synthesize sectionColumnWidth = _sectionColumnWidth;
@synthesize sectionRowHeight = _sectionRowHeight;
@synthesize frame = _frame;

- (NSMutableArray *)cellsInfo {
	if (!_cellsInfo) {
		_cellsInfo = [[NSMutableArray alloc] init];
	}
	return _cellsInfo;
}

- (CGPoint)origin {
	return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
	CGRect frame = self.frame;
	frame.origin = origin;
	self.frame = frame;
}

- (CGSize)size {
	return self.frame.size;
}

- (void)setSize:(CGSize)size {
	CGRect frame = self.frame;
	frame.size = size;
	self.frame = frame;
}

@end

@interface UIGridView ()

@property (strong, nonatomic) NSMutableDictionary *cellQueueDictionary;
@property (strong, nonatomic) NSMutableArray *sectionsInfo;
@property (strong, nonatomic) NSIndexPath *firstVisibleCellIndexPath;
@property (strong, nonatomic) NSIndexPath *lastVisibleCellIndexPath;
@property (assign, nonatomic) BOOL needsUpdateCellsInfo;

- (void)initGridView;
- (void)enqueReusableCell:(UIGridViewCell *)cell;
- (void)updateCellsInfo;
- (void)calculateFrames;
- (void)layoutVisibleCells;

@end

@implementation UIGridView

@synthesize dataSource = _gvDataSource;
@synthesize delegate = _gvDelegate;
@synthesize cellSize = _cellSize;
@synthesize cellPreferredInsets = _cellPreferredInsets;
@synthesize cellHorizontalAlignment = _cellHorizontalAlignment;
@synthesize cellVerticalAlignment = _cellVerticalAlignment;
@synthesize sectionHeaderHeight = _sectionHeaderHeight;
@synthesize sectionFooterHeight = _sectionFooterHeight;
@synthesize gridHeaderView = _gridHeaderView;
@synthesize gridFooterView = _gridFooterView;

@synthesize cellQueueDictionary = _cellQueueDictionary;
@synthesize sectionsInfo = _sectionsInfo;
@synthesize firstVisibleCellIndexPath = _firstVisibleCellIndexPath;
@synthesize lastVisibleCellIndexPath = _lastVisibleCellIndexPath;
@synthesize needsUpdateCellsInfo = _needsUpdateCellsInfo;

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initGridView];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initGridView];
	}
	return self;
}

- (void)initGridView {
	self.needsUpdateCellsInfo = YES;
}

- (void)layoutSubviews {
	if (self.needsUpdateCellsInfo) {
		self.needsUpdateCellsInfo = NO;
		[self updateCellsInfo];
	}
	[self layoutVisibleCells];
}

- (void)updateCellsInfo {
	self.sectionsInfo = nil;
	NSUInteger numberOfSections = 1;
	if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)]) {
		numberOfSections = [self.dataSource numberOfSectionsInGridView:self];
	}
	for (NSUInteger i = 0; i < numberOfSections; i++) {
		UIGridViewSectionInfo *sectionInfo = [[UIGridViewSectionInfo alloc] init];
		[self.sectionsInfo addObject:sectionInfo];
		NSUInteger numberOfCells = [self.dataSource gridView:self numberOfCellsInSection:i];
		for (NSUInteger j = 0; j < numberOfCells; j++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForCellIndex:j inSection:i];
			UIGridVIewCellInfo *cellInfo = [[UIGridVIewCellInfo alloc] init];
			[sectionInfo.cellsInfo addObject:cellInfo];
			if ([self.delegate respondsToSelector:@selector(gridView:sizeForCellAtIndexPath:)]) {
				[cellInfo setContentSize:[self.delegate gridView:self sizeForCellAtIndexPath:indexPath]];
			} else {
				[cellInfo setContentSize:self.cellSize];
			}
			if ([self.delegate respondsToSelector:@selector(gridView:preferredInsetsForCellAtIndexPath:)]) {
				[cellInfo setPreferredInsets:[self.delegate gridView:self preferredInsetsForCellAtIndexPath:indexPath]];
			} else {
				[cellInfo setPreferredInsets:self.cellPreferredInsets];
			}
			if ([self.delegate respondsToSelector:@selector(gridView:horizontalAlignmentForCellAtIndexPath:)]) {
				[cellInfo setHorizontalAlignment:[self.delegate gridView:self horizontalAlignmentForCellAtIndexPath:indexPath]];
			} else {
				[cellInfo setHorizontalAlignment:self.cellHorizontalAlignment];
			}
			if ([self.delegate respondsToSelector:@selector(gridView:verticalAlignmentForCellAtIndexPath:)]) {
				[cellInfo setHorizontalAlignment:[self.delegate gridView:self verticalAlignmentForCellAtIndexPath:indexPath]];
			} else {
				[cellInfo setHorizontalAlignment:self.cellVerticalAlignment];
			}
			sectionInfo.sectionColumnWidth = MAX(sectionInfo.sectionColumnWidth, cellInfo.preferredInsets.left + cellInfo.preferredInsets.right + cellInfo.contentSize.width);
			sectionInfo.sectionRowHeight = MAX(sectionInfo.sectionRowHeight, cellInfo.preferredInsets.top + cellInfo.preferredInsets.bottom + cellInfo.contentSize.height);
		}
		for (NSUInteger j = 0; j < [sectionInfo.cellsInfo count]; j++) {
			UIGridVIewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:j];
			CGFloat x, y;
			switch (cellInfo.horizontalAlignment) {
				case UIGridViewCellHorizontalAlignmentLeft:
					x = cellInfo.preferredInsets.left;
					break;
				case UIGridViewCellHorizontalAlignmentCenter:
					x = cellInfo.preferredInsets.left + ((sectionInfo.sectionColumnWidth - cellInfo.preferredInsets.left - cellInfo.preferredInsets.right) - cellInfo.contentSize.width) / 2;
					break;
				case UIGridViewCellHorizontalAlignmentRight:
					x = cellInfo.preferredInsets.left + (sectionInfo.sectionColumnWidth - cellInfo.preferredInsets.left - cellInfo.preferredInsets.right) - cellInfo.contentSize.width;
					break;
				default:
					x = 0;
					break;
			}
			switch (cellInfo.verticalAlignment) {
				case UIGridViewCellVerticalAlignmentTop:
					y = cellInfo.preferredInsets.top;
					break;
				case UIGridViewCellVerticalAlignmentCenter:
					y = cellInfo.preferredInsets.top + ((sectionInfo.sectionRowHeight - cellInfo.preferredInsets.top - cellInfo.preferredInsets.bottom) - cellInfo.contentSize.height) / 2;
					break;
				case UIGridViewCellVerticalAlignmentBottom:
					y = cellInfo.preferredInsets.top + (sectionInfo.sectionRowHeight - cellInfo.preferredInsets.top - cellInfo.preferredInsets.bottom) - cellInfo.contentSize.height;
					break;
				default:
					y = 0;
					break;
			}
			[cellInfo setContentOrigin:CGPointMake(x, y)];
		}
		if ([self.delegate respondsToSelector:@selector(gridView:heightForHeaderInSection:)]) {
			sectionInfo.headerHeight = [self.delegate gridView:self heightForHeaderInSection:i];
		} else {
			sectionInfo.headerHeight = self.sectionHeaderHeight;
		}
		if ([self.delegate respondsToSelector:@selector(gridView:heightForFooterInSection:)]) {
			sectionInfo.footerHeight = [self.delegate gridView:self heightForFooterInSection:i];
		} else {
			sectionInfo.footerHeight = self.sectionFooterHeight;
		}
		if ([self.dataSource respondsToSelector:@selector(gridView:numberOfColumnsInSection:)]) {
			sectionInfo.numberOfColumns = [self.dataSource gridView:self numberOfColumnsInSection:i];
		} else {
			sectionInfo.numberOfColumns = 0;
		}
	}
}

- (void)calculateFrames {
	CGPoint currentOrigin = CGPointZero;
	CGSize currentSize = CGSizeMake(self.bounds.size.width, 0);

	if (self.gridHeaderView) {
		currentSize.height += self.gridHeaderView.bounds.size.height;
		currentOrigin.y = currentSize.height;
	}

	for (UIGridViewSectionInfo *sectionInfo in self.sectionsInfo) {
		[sectionInfo setOrigin:currentOrigin];
		sectionInfo.actualNumberOfColumns = (sectionInfo.numberOfColumns > 0) ? sectionInfo.numberOfColumns : (self.bounds.size.width / sectionInfo.sectionColumnWidth);
		CGFloat width = MAX(self.bounds.size.width, sectionInfo.sectionColumnWidth * sectionInfo.actualNumberOfColumns);
		CGFloat height = sectionInfo.headerHeight + sectionInfo.footerHeight + sectionInfo.sectionRowHeight *
				(([sectionInfo.cellsInfo count] / sectionInfo.actualNumberOfColumns) +
				 ([sectionInfo.cellsInfo count] % sectionInfo.actualNumberOfColumns > 0));
		[sectionInfo setSize:CGSizeMake(width, height)];
		currentSize.width = MAX(currentSize.width, width);
		currentSize.height += height;
		currentOrigin.y = currentSize.height;

		CGFloat columnWidth = width / sectionInfo.actualNumberOfColumns;
		for (NSUInteger j = 0; j < [sectionInfo.cellsInfo count]; j++) {
			UIGridVIewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:j];
			NSUInteger row = j / sectionInfo.actualNumberOfColumns;
			NSUInteger column = j % sectionInfo.actualNumberOfColumns;
			[cellInfo setOrigin:CGPointMake(column * columnWidth + (columnWidth - sectionInfo.sectionColumnWidth) / 2,
											row * sectionInfo.sectionRowHeight)];
			[cellInfo setSize:CGSizeMake(sectionInfo.sectionColumnWidth, sectionInfo.sectionRowHeight)];
		}
	}

	if (self.gridFooterView) {
		currentSize.height += self.gridFooterView.bounds.size.height;
	}

	self.contentSize = currentSize;
}

- (void)layoutVisibleCells {
//	self.contentOffset
}

- (NSMutableDictionary *)cellQueueDictionary {
	if (!_cellQueueDictionary) {
		_cellQueueDictionary = [[NSMutableDictionary alloc] init];
	}
	return _cellQueueDictionary;
}

- (NSMutableArray *)sectionsInfo {
	if (!_sectionsInfo) {
		_sectionsInfo = [[NSMutableArray alloc] init];
	}
	return _sectionsInfo;
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
@property (strong, nonatomic) UIView *contentView;

@end

@implementation UIGridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize contentView = _contentView;

- (id)initWithReuseIdentifier:(NSString *)identifier {
	self = [super init];
	if (self) {
		self.reuseIdentifier = identifier;
		self.contentView = [[UIView alloc] initWithFrame:self.bounds];
		[self addSubview:self.contentView];
	}
	return self;
}

@end