//
//  GridDemoViewController.m
//  UIGridViewDemo
//
//  Created by Mikayel Aghasyan on 8/20/12.
//  Copyright (c) 2012 AtTask. All rights reserved.
//

#import "GridDemoViewController.h"

@interface GridDemoViewController ()

@property (strong, nonatomic) IBOutlet UIGridView *gridView;

@end

@implementation GridDemoViewController

@synthesize gridView = _gridView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.gridView.dataSource = self;
	self.gridView.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	self.gridView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UIGridView data source

// Number of sections in grid view. Default is 1.
- (NSUInteger)numberOfSectionsInGridView:(UIGridView *)gridView {
	return 2;
}

// Number of columns in section. Return 0 to dynamically calculate number of columns to fill available width. Default is 0.
- (NSUInteger)gridView:(UIGridView *)gridView numberOfColumnsInSection:(NSUInteger)section {
	NSUInteger result = 0;
	switch (section) {
		case 1:
			result = 10;
			break;
		default:
			break;
	}
	return result;
}

// Number of cells in section.
- (NSUInteger)gridView:(UIGridView *)gridView numberOfCellsInSection:(NSUInteger)section {
	NSUInteger result = 0;
	switch (section) {
		case 0:
			result = 50;
			break;
		case 1:
			result = 100;
			break;
		default:
			break;
	}
	return result;
}

- (UIGridViewCell *)gridView:(UIGridView *)gridView cellAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellID = @"CellID";
	UIGridViewCell *cell = [gridView dequeReusableCellWithIdentifier:CellID];
	UIImageView *imageView = nil;
	if (!cell) {
		cell = [[UIGridViewCell alloc] initWithReuseIdentifier:CellID];
		imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		imageView.tag = 1;
		[cell.contentView addSubview:imageView];
	}

	UIImage *image = nil;
	switch (indexPath.section) {
		case 0:
			image = [UIImage imageNamed:@"ferrari.png"];
			break;
		case 1:
			image = [UIImage imageNamed:@"porsche.jpg"];
			break;
		default:
			break;
	}
	imageView = (UIImageView *)[cell.contentView viewWithTag:1];
	imageView.image = image;
	return cell;
}

- (BOOL)gridView:(UIGridView *)gridView canEditCellAtIndexPath:(NSIndexPath *)indexPath {
	BOOL canEdit = YES;
	switch (indexPath.section) {
		case 0:
			if (indexPath.cellIndex == 0) {
				canEdit = NO;
			}
			break;
		default:
			break;
	}
	return canEdit;
}

#pragma mark - UIGridView delegate

- (CGSize)gridView:(UIGridView *)gridView sizeForCellAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake(100, 100);
}

- (UIEdgeInsets)gridView:(UIGridView *)gridView preferredInsetsForCellAtIndexPath:(NSIndexPath *)indexPath {
	return UIEdgeInsetsMake(20, 20, 20, 20);
}

// Horizontal alignment of cell within available space. Default is UIGridViewCellHorizontalAlignmentCenter.
- (UIGridViewCellHorizontalAlignment)gridView:(UIGridView *)gridView horizontalAlignmentForCellAtIndexPath:(NSIndexPath *)indexPath {
	return UIGridViewCellHorizontalAlignmentCenter;
}

// Vertical alignment of cell within available space. Default is UIGridViewCellVerticalAlignmentCenter.
- (UIGridViewCellVerticalAlignment)gridView:(UIGridView *)gridView verticalAlignmentForCellAtIndexPath:(NSIndexPath *)indexPath {
	return UIGridViewCellVerticalAlignmentCenter;
}

- (CGFloat)gridView:(UIGridView *)gridView heightForHeaderInSection:(NSUInteger)section {
	return 0;
}

- (CGFloat)gridView:(UIGridView *)gridView heightForFooterInSection:(NSUInteger)section {
	return 0;
}

- (void)gridView:(UIGridView *)gridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Did select cell at index path: %@", indexPath);
}

@end
