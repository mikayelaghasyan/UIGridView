//
//  UIGridView.m
//  UIGridView
//
//  Created by Mikayel Aghasyan on 6/18/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import "UIGridView.h"
#import "NSMutableArray+Queue.h"
#import <QuartzCore/QuartzCore.h>

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
@property (retain, nonatomic) UIGridViewCell *cellView;

@end

@implementation UIGridViewCellInfo

@synthesize cellIndex = _cellIndex;
@synthesize preferredInsets = _preferredInsets;
@synthesize horizontalAlignment = _horizontalAlignment;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize frame = _frame;

- (void)dealloc {
	[_cellView release];
	[super dealloc];
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

@property (assign, nonatomic) NSUInteger sectionIndex;
@property (retain, nonatomic) NSMutableArray *cellsInfo;
@property (assign, nonatomic) CGFloat headerHeight;
@property (assign, nonatomic) CGFloat footerHeight;
@property (assign, nonatomic) NSUInteger numberOfColumns;
@property (assign, nonatomic) NSUInteger actualNumberOfColumns;
@property (assign, nonatomic) CGFloat sectionColumnWidth;
@property (assign, nonatomic) CGFloat sectionRowHeight;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) CGPoint origin;
@property (assign, nonatomic) CGSize size;
@property (retain, nonatomic) UIView *headerView;
@property (retain, nonatomic) UIView *footerView;

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

- (void)dealloc {
	[_cellsInfo release];
	[_headerView release];
	[_footerView release];
	[super dealloc];
}

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

@interface UIGridViewCell ()

@property (copy, nonatomic) NSString *reuseIdentifier;
@property (retain, nonatomic) UIView *contentView;
@property (retain, nonatomic) UIButton *deleteButton;
@property (assign, nonatomic) BOOL canDelete;

- (void)startShake;
- (void)endShake;
- (void)zoomIn;
- (void)zoomOut;

@end

@interface UIGridView ()

@property (retain, nonatomic) NSMutableDictionary *cellQueueDictionary;
@property (retain, nonatomic) NSMutableArray *sectionsInfo;
@property (assign, nonatomic) NSInteger firstVisibleSection;
@property (assign, nonatomic) NSInteger lastVisibleSection;
@property (retain, nonatomic) NSIndexPath *firstVisibleCellIndexPath;
@property (retain, nonatomic) NSIndexPath *lastVisibleCellIndexPath;
@property (assign, nonatomic) BOOL needsUpdateCellsInfo;
@property (assign, nonatomic) CGSize lastSize;

@property (retain, nonatomic) UIGestureRecognizer *tapGesture;
@property (retain, nonatomic) UIGestureRecognizer *longPressGesture;

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

- (void)handleTap:(UIGestureRecognizer *)sender;
- (void)handleLongPress:(UIGestureRecognizer *)sender;

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

@synthesize editing = _editing;

@synthesize cellQueueDictionary = _cellQueueDictionary;
@synthesize sectionsInfo = _sectionsInfo;
@synthesize firstVisibleSection = _firstVisibleSection;
@synthesize lastVisibleSection = _lastVisibleSection;
@synthesize firstVisibleCellIndexPath = _firstVisibleCellIndexPath;
@synthesize lastVisibleCellIndexPath = _lastVisibleCellIndexPath;
@synthesize needsUpdateCellsInfo = _needsUpdateCellsInfo;
@synthesize lastSize = _lastSize;

@synthesize tapGesture = _tapGesture;
@synthesize longPressGesture = _longPressGesture;

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
	self.directionalLockEnabled = YES;
	self.delaysContentTouches = NO;

	self.needsUpdateCellsInfo = YES;
	self.firstVisibleSection = -1;
	self.lastVisibleSection = -1;

	self.tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
	self.tapGesture.delegate = self;
	self.longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
	self.longPressGesture.delegate = self;
	[self.tapGesture requireGestureRecognizerToFail:self.longPressGesture];
	[self addGestureRecognizer:self.tapGesture];
	[self addGestureRecognizer:self.longPressGesture];
}

- (void)dealloc {
	[_gridHeaderView release];
	[_gridFooterView release];
	[_cellQueueDictionary release];
	[_sectionsInfo release];
	[_firstVisibleCellIndexPath release];
	[_lastVisibleCellIndexPath release];
	[_tapGesture release];
	[_longPressGesture release];
	[super dealloc];
}

- (void)layoutSubviews {
	BOOL sizeChanged = !CGSizeEqualToSize(self.bounds.size, self.lastSize);
	if (sizeChanged || self.needsUpdateCellsInfo) {
		[self cleanGridView];
	}
	if (self.needsUpdateCellsInfo) {
		self.needsUpdateCellsInfo = NO;
		[self updateCellsInfo];
	}
	if (sizeChanged || self.needsUpdateCellsInfo) {
		[self calculateFrames];
		self.lastSize = self.bounds.size;
	}
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
			[cellInfo release];
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
		[sectionInfo release];
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
	while (sectionInfo.origin.y > self.contentOffset.y || sectionInfo.origin.y + sectionInfo.size.height <= self.contentOffset.y) {
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
	while (sectionInfo.origin.y >= self.contentOffset.y + self.bounds.size.height ||
		   sectionInfo.origin.y + sectionInfo.size.height < self.contentOffset.y + self.bounds.size.height) {
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
	NSInteger row = MAX((self.contentOffset.y - sectionInfo.origin.y - sectionInfo.headerHeight) / sectionInfo.sectionRowHeight, 0);
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
	CGFloat columnWidth = 0;
	for (NSIndexPath *indexPath = startIndexPath; indexPath && [indexPath compare:endIndexPath] != NSOrderedDescending; indexPath = [self nextIndexPath:indexPath]) {
		if (!sectionInfo || sectionInfo.sectionIndex != indexPath.section) {
			sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
			if (sectionInfo.actualNumberOfColumns * sectionInfo.sectionColumnWidth < self.bounds.size.width) {
				columnWidth = self.bounds.size.width / sectionInfo.actualNumberOfColumns;
			} else {
				columnWidth = sectionInfo.sectionColumnWidth;
			}
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
				cellInfo.cellView = [self.dataSource gridView:self cellAtIndexPath:indexPath];
				NSInteger row = indexPath.cellIndex / sectionInfo.actualNumberOfColumns;
				NSInteger column = indexPath.cellIndex % sectionInfo.actualNumberOfColumns;
				cellInfo.cellView.frame = CGRectMake(sectionInfo.origin.x + column * columnWidth + (columnWidth - sectionInfo.sectionColumnWidth) / 2 + cellInfo.origin.x,
										sectionInfo.origin.y + sectionInfo.headerHeight + row * sectionInfo.sectionRowHeight + cellInfo.origin.y,
										cellInfo.size.width, cellInfo.size.height);
				[self addSubview:cellInfo.cellView];
			}
		}
	}
	self.firstVisibleCellIndexPath = firstVisibleCellIndexPath;
	self.lastVisibleCellIndexPath = lastVisibleCellIndexPath;
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

- (NSIndexPath *)indexPathOfCellAtLocation:(CGPoint)location {
	NSIndexPath *result = nil;
	UIGridViewSectionInfo *sectionInfo = nil;
	for (sectionInfo in self.sectionsInfo) {
		if (CGRectContainsPoint(sectionInfo.frame, location)) {
			NSInteger column = (location.x - sectionInfo.origin.x) / sectionInfo.sectionColumnWidth;
			NSInteger row = (location.y - sectionInfo.origin.y - sectionInfo.headerHeight) / sectionInfo.sectionRowHeight;
			NSInteger cellIndex = row * sectionInfo.actualNumberOfColumns + column;
			if (cellIndex < [sectionInfo.cellsInfo count]) {
				result = [NSIndexPath indexPathForCellIndex:cellIndex inSection:sectionInfo.sectionIndex];
			}
			break;
		}
	}
	return result;
}

- (UIGridViewCell *)cellAtLocation:(CGPoint)location {
	UIGridViewCell *result = nil;
	NSIndexPath *indexPath = [self indexPathOfCellAtLocation:location];
	if (indexPath) {
		UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
		UIGridViewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:indexPath.cellIndex];
		result = cellInfo.cellView;
	}
	return result;
}

- (UIGridViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath {
	UIGridViewCell *result = nil;
	if (indexPath) {
		UIGridViewSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
		UIGridViewCellInfo *cellInfo = [sectionInfo.cellsInfo objectAtIndex:indexPath.cellIndex];
		result = cellInfo.cellView;
	}
	return result;
}

- (NSArray *)indexPathsForVisibleCells {
	NSMutableArray *indexPaths = [[[NSMutableArray alloc] init] autorelease];
	if (self.firstVisibleCellIndexPath) {
		for (NSIndexPath *indexPath = self.firstVisibleCellIndexPath; indexPath && [indexPath compare:self.lastVisibleCellIndexPath] != NSOrderedDescending;
			 indexPath = [self nextIndexPath:indexPath]) {
			[indexPaths addObject:indexPath];
		}
	}
	return [[indexPaths copy] autorelease];
}

- (NSArray *)visibleCells {
	NSMutableArray *visibleCells = [[[NSMutableArray alloc] init] autorelease];
	if (self.firstVisibleCellIndexPath) {
		for (NSIndexPath *indexPath = self.firstVisibleCellIndexPath; indexPath && [indexPath compare:self.lastVisibleCellIndexPath] != NSOrderedDescending;
			 indexPath = [self nextIndexPath:indexPath]) {
			UIGridViewCell *cell = [self cellAtIndexPath:indexPath];
			if (cell) {
				[visibleCells addObject:cell];
			}
		}
	}
	return [[visibleCells copy] autorelease];
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
		queue = [[[NSMutableArray alloc] init] autorelease];
		[self.cellQueueDictionary setObject:queue forKey:cell.reuseIdentifier];
	}
	[queue enque:cell];
}

- (UIGridViewCell *)dequeReusableCellWithIdentifier:(NSString *)identifier {
	UIGridViewCell *cell = nil;
	NSMutableArray *queue = [self.cellQueueDictionary objectForKey:identifier];
	if (queue) {
		cell = [queue deque];
	}
	return cell;
}

- (void)reloadData {
	self.needsUpdateCellsInfo = YES;
	[self setNeedsLayout];
}

- (void)setEditing:(BOOL)editing {
	if (_editing != editing) {
		_editing = editing;
		NSArray *visibleCellsIndexPaths = [self indexPathsForVisibleCells];
		for (NSIndexPath *indexPath in visibleCellsIndexPaths) {
			UIGridViewCell *cell = [self cellAtIndexPath:indexPath];
			if (cell) {
				BOOL canDelete = YES;
				if ([self.dataSource respondsToSelector:@selector(gridView:canDeleteCellAtIndexPath:)]) {
					canDelete = [self.dataSource gridView:self canDeleteCellAtIndexPath:indexPath];
				}
				[cell setCanDelete:canDelete];

				BOOL canEdit = YES;
				if ([self.dataSource respondsToSelector:@selector(gridView:canEditCellAtIndexPath:)]) {
					canEdit = [self.dataSource gridView:self canEditCellAtIndexPath:indexPath];
				}
				if (canEdit) {
					[cell setEditing:editing];
				}
			}
		}
	}
}

- (void)handleTap:(UIGestureRecognizer *)sender {
	CGPoint location = [sender locationInView:self];
	NSIndexPath *indexPath = [self indexPathOfCellAtLocation:location];
	UIGridViewCell *cell = [self cellAtIndexPath:indexPath];
	if (!self.editing && cell && CGRectContainsPoint(cell.frame, location)) {
		if ([self.delegate respondsToSelector:@selector(gridView:didSelectCellAtIndexPath:)]) {
			[self.delegate gridView:self didSelectCellAtIndexPath:indexPath];
		}
	}
}

- (void)handleLongPress:(UIGestureRecognizer *)sender {
	CGPoint location = [sender locationInView:self];
	NSIndexPath *indexPath = [self indexPathOfCellAtLocation:location];
	UIGridViewCell *cell = [self cellAtIndexPath:indexPath];
	if (cell && CGRectContainsPoint(cell.frame, location)) {
		NSLog(@"Gesture state: %d", sender.state);
		if (sender.state == UIGestureRecognizerStateBegan) {
			[cell zoomIn];
		} else if (sender.state == UIGestureRecognizerStateEnded ||
				   sender.state == UIGestureRecognizerStateFailed ||
				   sender.state == UIGestureRecognizerStateCancelled) {
			[cell zoomOut];
		}
		if (!self.editing) {
			[self setEditing:YES];
		}
	}
}

#pragma mark - UIGestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	CGPoint location = [touch locationInView:self];
	NSIndexPath *indexPath = [self indexPathOfCellAtLocation:location];
	UIGridViewCell *cell = [self cellAtIndexPath:indexPath];
	if (gestureRecognizer == self.tapGesture) {
		return (cell && CGRectContainsPoint(cell.frame, location));
	} else if (gestureRecognizer == self.longPressGesture) {
		if (cell && CGRectContainsPoint(cell.frame, location)) {
			BOOL canEdit = YES;
			if ([self.dataSource respondsToSelector:@selector(gridView:canEditCellAtIndexPath:)]) {
				canEdit = [self.dataSource gridView:self canEditCellAtIndexPath:indexPath];
			}
			return canEdit;
		}
		return NO;
	}
	return YES;
}

#pragma mark - Touch handling
/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	UIGridViewCell *cell = [self cellAtLocation:location];
	if (!self.editing && cell && CGRectContainsPoint(cell.frame, location)) {
		[cell setHighlighted:YES];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	UIGridViewCell *cell = [self cellAtLocation:location];
	if (cell && CGRectContainsPoint(cell.frame, location)) {
		[cell setHighlighted:NO];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	UIGridViewCell *cell = [self cellAtLocation:location];
	if (cell && CGRectContainsPoint(cell.frame, location)) {
		[cell setHighlighted:NO];
	}
}
*/
@end

@implementation UIGridViewCell

@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize contentView = _contentView;
@synthesize deleteButton = _deleteButton;
@synthesize editing = _editing;
@synthesize canDelete = _canDelete;

- (id)initWithReuseIdentifier:(NSString *)identifier {
	self = [super init];
	if (self) {
		self.reuseIdentifier = identifier;

		self.contentView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:self.contentView];

		self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		self.deleteButton.frame = CGRectMake(-10.0, -10.0, 40.0, 40.0);
		[self.deleteButton setImage:[UIImage imageNamed:@"delete_default.png"] forState:UIControlStateNormal];
		self.deleteButton.adjustsImageWhenHighlighted = YES;
		[self.deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		self.deleteButton.hidden = YES;
		[self addSubview:self.deleteButton];
	}
	return self;
}

- (void)dealloc {
	[_reuseIdentifier release];
	[_contentView release];
	[_deleteButton release];
	[super dealloc];
}
- (void)setEditing:(BOOL)editing {
	if (_editing != editing) {
		_editing = editing;
		self.deleteButton.hidden = !editing || !self.canDelete;
		if (editing) {
			[self startShake];
		} else {
			[self endShake];
		}
	}
}

- (void)startShake {
	CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	[anim setToValue:[NSNumber numberWithFloat:0.0f]];
	[anim setFromValue:[NSNumber numberWithDouble:M_PI/64]];
	[anim setDuration:0.1];
	[anim setRepeatCount:NSUIntegerMax];
	[anim setAutoreverses:YES];
	[self.layer addAnimation:anim forKey:@"shake"];
}

- (void)endShake {
	[self.layer removeAnimationForKey:@"shake"];
}

- (void)zoomIn {
	NSLog(@"Zoom in");
	CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	[anim setToValue:[NSNumber numberWithFloat:1.5f]];
	[anim setFromValue:[NSNumber numberWithDouble:1.0f]];
	[anim setDuration:0.1];
	[anim setRemovedOnCompletion:NO];
	[anim setFillMode:kCAFillModeForwards];
	[self.layer addAnimation:anim forKey:@"zoomIn"];
}

- (void)zoomOut {
	NSLog(@"Zoom out");
	CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	[anim setToValue:[NSNumber numberWithFloat:1.0f]];
	[anim setFromValue:[NSNumber numberWithDouble:1.5f]];
	[anim setDuration:0.1];
	[anim setRemovedOnCompletion:NO];
	[anim setFillMode:kCAFillModeForwards];
	[self.layer addAnimation:anim forKey:@"zoomOut"];
}

@end