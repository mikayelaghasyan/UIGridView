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

@interface UIGridViewCellInfo : NSObject

@property (assign, nonatomic) NSUInteger cellIndex;
@property (assign, nonatomic) UIEdgeInsets preferredInsets;
@property (assign, nonatomic) UIGridViewCellHorizontalAlignment horizontalAlignment;
@property (assign, nonatomic) UIGridViewCellVerticalAlignment verticalAlignment;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) CGPoint origin;
@property (assign, nonatomic) CGSize size;
@property (strong, nonatomic) UIGridViewCell *cellView;

@end

@implementation UIGridViewCellInfo

@synthesize cellIndex = _cellIndex;
@synthesize preferredInsets = _preferredInsets;
@synthesize horizontalAlignment = _horizontalAlignment;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize frame = _frame;

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

@property (assign, nonatomic) NSUInteger sectionIndex;
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
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *footerView;

@end

@implementation UIGridViewSectionInfo

@synthesize sectionIndex = _sectionIndex;
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
@property (assign, nonatomic) NSInteger firstVisibleSection;
@property (assign, nonatomic) NSInteger lastVisibleSection;
@property (strong, nonatomic) NSIndexPath *firstVisibleCellIndexPath;
@property (strong, nonatomic) NSIndexPath *lastVisibleCellIndexPath;
@property (assign, nonatomic) BOOL needsUpdateCellsInfo;

- (void)initGridView;
- (void)enqueReusableCell:(UIGridViewCell *)cell;
- (void)updateCellsInfo;
- (void)calculateFrames;
- (void)layoutGridView;
- (void)cleanGridView;


- (NSIndexPath *)firstIndexPath;
- (NSIndexPath *)lastIndexPath;
- (NSIndexPath *)nextIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)previousIndexPath:(NSIndexPath *)indexPath;

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
@synthesize firstVisibleSection = _firstVisibleSection;
@synthesize lastVisibleSection = _lastVisibleSection;
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
	self.firstVisibleSection = -1;
	self.lastVisibleSection = -1;
}

- (void)layoutSubviews {
	if (self.needsUpdateCellsInfo) {
		self.needsUpdateCellsInfo = NO;
		[self cleanGridView];
		[self updateCellsInfo];
	}
	[self calculateFrames];
	[self layoutGridView];
}

- (void)updateCellsInfo {
	self.sectionsInfo = nil;
	NSUInteger numberOfSections = 1;
	if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)]) {
		numberOfSections = [self.dataSource numberOfSectionsInGridView:self];
	}
	for (NSUInteger i = 0; i < numberOfSections; i++) {
		UIGridViewSectionInfo *sectionInfo = [[UIGridViewSectionInfo alloc] init];
		sectionInfo.sectionIndex = i;
		[self.sectionsInfo addObject:sectionInfo];
		NSUInteger numberOfCells = [self.dataSource gridView:self numberOfCellsInSection:i];
		for (NSUInteger j = 0; j < numberOfCells; j++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForCellIndex:j inSection:i];
			UIGridViewCellInfo *cellInfo = [[UIGridViewCellInfo alloc] init];
			cellInfo.cellIndex = j;
			[sectionInfo.cellsInfo addObject:cellInfo];
			if ([self.delegate respondsToSelector:@selector(gridView:sizeForCellAtIndexPath:)]) {
				[cellInfo setSize:[self.delegate gridView:self sizeForCellAtIndexPath:indexPath]];
			} else {
				[cellInfo setSize:self.cellSize];
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
			sectionInfo.sectionColumnWidth = MAX(sectionInfo.sectionColumnWidth, cellInfo.preferredInsets.left + cellInfo.preferredInsets.right + cellInfo.size.width);
			sectionInfo.sectionRowHeight = MAX(sectionInfo.sectionRowHeight, cellInfo.preferredInsets.top + cellInfo.preferredInsets.bottom + cellInfo.size.height);
		}
		for (NSUInteger j = 0; j < [sectionInfo.cellsInfo count]; j++) {
			UIGridViewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:j];
			CGFloat x, y;
			switch (cellInfo.horizontalAlignment) {
				case UIGridViewCellHorizontalAlignmentLeft:
					x = cellInfo.preferredInsets.left;
					break;
				case UIGridViewCellHorizontalAlignmentCenter:
					x = cellInfo.preferredInsets.left + ((sectionInfo.sectionColumnWidth - cellInfo.preferredInsets.left - cellInfo.preferredInsets.right) - cellInfo.size.width) / 2;
					break;
				case UIGridViewCellHorizontalAlignmentRight:
					x = cellInfo.preferredInsets.left + (sectionInfo.sectionColumnWidth - cellInfo.preferredInsets.left - cellInfo.preferredInsets.right) - cellInfo.size.width;
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
					y = cellInfo.preferredInsets.top + ((sectionInfo.sectionRowHeight - cellInfo.preferredInsets.top - cellInfo.preferredInsets.bottom) - cellInfo.size.height) / 2;
					break;
				case UIGridViewCellVerticalAlignmentBottom:
					y = cellInfo.preferredInsets.top + (sectionInfo.sectionRowHeight - cellInfo.preferredInsets.top - cellInfo.preferredInsets.bottom) - cellInfo.size.height;
					break;
				default:
					y = 0;
					break;
			}
			[cellInfo setOrigin:CGPointMake(x, y)];
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
	}

	if (self.gridFooterView) {
		currentSize.height += self.gridFooterView.bounds.size.height;
	}

	self.contentSize = currentSize;
}

- (void)layoutGridView {
	if ([self.sectionsInfo count] == 0) {
		return;
	}

	NSInteger firstVisibleSection = (self.firstVisibleSection > -1) ? self.firstVisibleSection : 0;
	UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:firstVisibleSection];
	while (sectionInfo.origin.y <= self.contentOffset.y && sectionInfo.origin.y + sectionInfo.size.height > self.contentOffset.y) {
		if (sectionInfo.origin.y > self.contentOffset.y) {
			if (firstVisibleSection > 0) {
				firstVisibleSection--;
			} else {
				break;
			}
		} else {
			if (firstVisibleSection < [self.sectionsInfo count] - 1) {
				firstVisibleSection++;
			} else {
				break;
			}
		}
		sectionInfo = [self.sectionsInfo objectAtIndex:firstVisibleSection];
	}
	NSInteger lastVisibleSection = (self.lastVisibleSection > -1) ? self.lastVisibleSection : firstVisibleSection;
	sectionInfo = [self.sectionsInfo objectAtIndex:lastVisibleSection];
	while (sectionInfo.origin.y < self.contentOffset.y + self.bounds.size.height &&
		   sectionInfo.origin.y + sectionInfo.size.height >= self.contentOffset.y + self.bounds.size.height) {
		if (sectionInfo.origin.y >= self.contentOffset.y + self.bounds.size.height) {
			if (lastVisibleSection > firstVisibleSection) {
				lastVisibleSection--;
			} else {
				break;
			}
		} else {
			if (lastVisibleSection < [self.sectionsInfo count] - 1) {
				lastVisibleSection++;
			} else {
				break;
			}
		}
		sectionInfo = [self.sectionsInfo objectAtIndex:lastVisibleSection];
	}
	NSInteger start = (self.firstVisibleSection > -1) ? MIN(self.firstVisibleSection, firstVisibleSection) : firstVisibleSection;
	NSInteger end = (self.lastVisibleSection > -1) ? MAX(self.lastVisibleSection, lastVisibleSection) : lastVisibleSection;
	for (NSInteger i = start; i <= end; i++) {
		sectionInfo = [self.sectionsInfo objectAtIndex:i];
		if (i < firstVisibleSection || i > lastVisibleSection) {
			if (sectionInfo.headerView && sectionInfo.headerView.superview == self) {
				[sectionInfo.headerView removeFromSuperview];
			}
			if (sectionInfo.footerView && sectionInfo.footerView.superview == self) {
				[sectionInfo.footerView removeFromSuperview];
			}
		} else {
			if (sectionInfo.headerView && sectionInfo.headerView.superview != self) {
				sectionInfo.headerView.frame = CGRectMake(sectionInfo.origin.x, sectionInfo.origin.y, sectionInfo.size.width, sectionInfo.headerHeight);
				[self addSubview:sectionInfo.headerView];
			}
			if (sectionInfo.footerView && sectionInfo.footerView.superview != self) {
				sectionInfo.footerView.frame = CGRectMake(sectionInfo.origin.x, sectionInfo.origin.y + sectionInfo.size.height - sectionInfo.headerHeight,
														  sectionInfo.size.width, sectionInfo.headerHeight);
			}
		}
	}
	self.firstVisibleSection = firstVisibleSection;
	self.lastVisibleSection = lastVisibleSection;

	sectionInfo = [self.sectionsInfo objectAtIndex:self.firstVisibleSection];
	NSInteger row = (self.contentOffset.y - sectionInfo.origin.y - sectionInfo.headerHeight) / sectionInfo.sectionRowHeight;
	NSInteger cellIndex = row * sectionInfo.actualNumberOfColumns;
	NSIndexPath *firstVisibleCellIndexPath = [NSIndexPath indexPathForCellIndex:cellIndex inSection:self.firstVisibleSection];
	if (cellIndex >= [sectionInfo.cellsInfo count]) {
		firstVisibleCellIndexPath = [self nextIndexPath:firstVisibleCellIndexPath];
	}

	sectionInfo = [self.sectionsInfo objectAtIndex:self.lastVisibleSection];
	row = (self.contentOffset.y + self.bounds.size.height - sectionInfo.origin.y - sectionInfo.headerHeight) / sectionInfo.sectionRowHeight;
	cellIndex = (row + 1) * sectionInfo.actualNumberOfColumns - 1;
	NSIndexPath *lastVisibleCellIndexPath = [NSIndexPath indexPathForCellIndex:cellIndex inSection:self.lastVisibleSection];
	if (cellIndex >= [sectionInfo.cellsInfo count]) {
		lastVisibleCellIndexPath = [self previousIndexPath:lastVisibleCellIndexPath];
	}

	NSIndexPath *startIndexPath = firstVisibleCellIndexPath;
	if (self.firstVisibleCellIndexPath && [self.firstVisibleCellIndexPath compare:firstVisibleCellIndexPath] == NSOrderedAscending) {
		startIndexPath = self.firstVisibleCellIndexPath;
	}
	NSIndexPath *endIndexPath = lastVisibleCellIndexPath;
	if (self.lastVisibleCellIndexPath && [self.lastVisibleCellIndexPath compare:lastVisibleCellIndexPath] == NSOrderedDescending) {
		endIndexPath = self.lastVisibleCellIndexPath;
	}
	sectionInfo = nil;
	for (NSIndexPath *indexPath = startIndexPath; indexPath && [indexPath compare:endIndexPath] != NSOrderedDescending; indexPath = [self nextIndexPath:indexPath]) {
		if (!sectionInfo || sectionInfo.sectionIndex != indexPath.section) {
			sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
		}
		UIGridViewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:indexPath.cellIndex];
		if ([indexPath compare:firstVisibleCellIndexPath] == NSOrderedAscending || [indexPath compare:lastVisibleCellIndexPath] == NSOrderedDescending) {
			if (cellInfo.cellView) {
				[cellInfo.cellView removeFromSuperview];
				[self enqueReusableCell:cellInfo.cellView];
				cellInfo.cellView = nil;
			}
		} else {
			if (!cellInfo.cellView) {
				UIGridViewCell *cell = [self.dataSource gridView:self cellAtIndexPath:indexPath];
				NSInteger row = indexPath.cellIndex / sectionInfo.actualNumberOfColumns;
				NSInteger column = indexPath.cellIndex % sectionInfo.actualNumberOfColumns;
				cell.frame = CGRectMake(sectionInfo.origin.x + column * sectionInfo.sectionColumnWidth + cellInfo.origin.x,
										sectionInfo.origin.y + sectionInfo.headerHeight + row * sectionInfo.sectionRowHeight + cellInfo.origin.y,
										cellInfo.size.width, cellInfo.size.height);
				[self addSubview:cell];
			}
		}
	}
}

- (void)cleanGridView {
	for (UIGridViewSectionInfo *sectionInfo in self.sectionsInfo) {
		if (sectionInfo.headerView) {
			if (sectionInfo.headerView.superview == self) {
				[sectionInfo.headerView removeFromSuperview];
			}
			sectionInfo.headerView = nil;
		}
		if (sectionInfo.footerView) {
			if (sectionInfo.footerView.superview == self) {
				[sectionInfo.footerView removeFromSuperview];
			}
			sectionInfo.footerView = nil;
		}
	}
	self.firstVisibleSection = -1;
	self.lastVisibleSection = -1;

	if (self.firstVisibleCellIndexPath) {
		UIGridViewSectionInfo *sectionInfo = nil;
		for (NSIndexPath *indexPath = self.firstVisibleCellIndexPath; indexPath && [indexPath compare:self.lastVisibleCellIndexPath] != NSOrderedDescending;
			 indexPath = [self nextIndexPath:indexPath]) {
			if (!sectionInfo || sectionInfo.sectionIndex != indexPath.section) {
				sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
			}
			UIGridViewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:indexPath.cellIndex];
			if (cellInfo.cellView) {
				[cellInfo.cellView removeFromSuperview];
				[self enqueReusableCell:cellInfo.cellView];
				cellInfo.cellView = nil;
			}
		}
	}
	self.firstVisibleCellIndexPath = nil;
	self.lastVisibleCellIndexPath = nil;
}

- (NSIndexPath *)firstIndexPath {
	NSIndexPath *result = nil;
	NSInteger section = 0;
	while (section < [self.sectionsInfo count]) {
		UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:section];
		if ([sectionInfo.cellsInfo count] > 0) {
			result = [NSIndexPath indexPathForCellIndex:0 inSection:section];
			break;
		} else {
			section++;
		}
	}
	return result;
}

- (NSIndexPath *)lastIndexPath {
	NSIndexPath *result = nil;
	NSInteger section = [self.sectionsInfo count] - 1;
	while (section >= 0) {
		UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:section];
		if ([sectionInfo.cellsInfo count] > 0) {
			result = [NSIndexPath indexPathForCellIndex:([sectionInfo.cellsInfo count] - 1) inSection:section];
			break;
		} else {
			section--;
		}
	}
	return result;
}

- (NSIndexPath *)nextIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *result = nil;
	if (indexPath) {
		NSInteger section = [indexPath section];
		NSInteger cellIndex = [indexPath cellIndex] + 1;
		UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:section];
		if (cellIndex > [sectionInfo.cellsInfo count] - 1) {
			section++;
			while (section < [self.sectionsInfo count]) {
				sectionInfo = [self.sectionsInfo objectAtIndex:section];
				if ([sectionInfo.cellsInfo count] > 0) {
					result = [NSIndexPath indexPathForCellIndex:0 inSection:section];
					break;
				} else {
					section++;
				}
			}
		} else {
			result = [NSIndexPath indexPathForCellIndex:cellIndex inSection:section];
		}
	}
	return result;
}

- (NSIndexPath *)previousIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *result = nil;
	if (indexPath) {
		NSInteger section = [indexPath section];
		NSInteger cellIndex = [indexPath cellIndex] - 1;
		if (cellIndex < 0) {
			section--;
			while (section >= 0) {
				UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:section];
				if ([sectionInfo.cellsInfo count] > 0) {
					result = [NSIndexPath indexPathForCellIndex:([sectionInfo.cellsInfo count] - 1) inSection:section];
					break;
				} else {
					section--;
				}
			}
		} else {
			result = [NSIndexPath indexPathForCellIndex:cellIndex inSection:section];
		}
	}
	return result;
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
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:self.contentView];
	}
	return self;
}

@end