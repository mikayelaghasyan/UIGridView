//
//  UIGridView.h
//  UIGridView
//
//  Created by Mikayel Aghasyan on 6/18/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSIndexPath (UIGridView)

+ (NSIndexPath *)indexPathForCellIndex:(NSUInteger)cellIndex inSection:(NSUInteger)section;

@property(nonatomic, readonly) NSUInteger section;
@property(nonatomic, readonly) NSUInteger cellIndex;

@end

typedef enum {
	UIGridViewCellHorizontalAlignmentLeft,
	UIGridViewCellHorizontalAlignmentCenter,
	UIGridViewCellHorizontalAlignmentRight
} UIGridViewCellHorizontalAlignment;

typedef enum {
	UIGridViewCellVerticalAlignmentTop,
	UIGridViewCellVerticalAlignmentCenter,
	UIGridViewCellVerticalAlignmentBottom
} UIGridViewCellVerticalAlignment;

@class UIGridView;

@protocol UIGridViewDelegate <NSObject, UIScrollViewDelegate>

@optional

- (CGSize)gridView:(UIGridView *)gridView sizeForCellAtIndexPath:(NSIndexPath *)indexPath;
- (UIEdgeInsets)gridView:(UIGridView *)gridView preferredInsetsForCellAtIndexPath:(NSIndexPath *)indexPath;

// Horizontal alignment of cell within available space. Default is UIGridViewCellHorizontalAlignmentCenter.
- (UIGridViewCellHorizontalAlignment)gridView:(UIGridView *)gridView horizontalAlignmentForCellAtIndexPath:(NSIndexPath *)indexPath;

// Vertical alignment of cell within available space. Default is UIGridViewCellVerticalAlignmentCenter.
- (UIGridViewCellVerticalAlignment)gridView:(UIGridView *)gridView verticalAlignmentForCellAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)gridView:(UIGridView *)gridView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)gridView:(UIGridView *)gridView heightForFooterInSection:(NSUInteger)section;

- (UIView *)gridView:(UIGridView *)gridView viewForHeaderInSection:(NSUInteger)section;
- (UIView *)gridView:(UIGridView *)gridView viewForFooterInSection:(NSUInteger)section;

@end

@class UIGridViewCell;
@protocol UIGridViewDataSource;

@interface UIGridView : UIScrollView

@property (weak, nonatomic) id<UIGridViewDataSource> dataSource;
@property (weak, nonatomic) id<UIGridViewDelegate> delegate;

@property (assign, nonatomic) CGSize cellSize;
@property (assign, nonatomic) UIEdgeInsets cellInsets;

- (UIGridViewCell *)dequeReusableCellWithIdentifier:(NSString *)identifier;

@end

@interface UIGridViewCell : UIView

@property (copy, nonatomic, readonly) NSString *reuseIdentifier;

- (id)initWithReuseIdentifier:(NSString *)identifier;

@end

@protocol UIGridViewDataSource <NSObject>

@optional

// Number of sections in grid view. Default is 1.
- (NSUInteger)numberOfSectionsInGridView:(UIGridView *)gridView;

// Number of columns in section. Return 0 to dynamically calculate number of columns to fill available width. Default is 0.
- (NSUInteger)gridView:(UIGridView *)gridView numberOfColumnsInSection:(NSUInteger)section;

- (NSString *)gridView:(UIGridView *)gridView titleForHeaderInSection:(NSUInteger)section;
- (NSString *)gridView:(UIGridView *)gridView titleForFooterInSection:(NSUInteger)section;

@required

// Number of cells in section.
- (NSUInteger)gridView:(UIGridView *)gridView numberOfCellsInSection:(NSUInteger)section;

- (UIGridViewCell *)gridView:(UIGridView *)gridView cellAtIndexPath:(NSIndexPath *)indexPath;

@end
