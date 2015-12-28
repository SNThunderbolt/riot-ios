/*
 Copyright 2015 OpenMarket Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "UIViewController+VectorSearch.h"

#import <objc/runtime.h>

/**
 `UIViewController_VectorSearch` is the internal single point storage for the search feature.
 
 It hosts all required data so that only one associated object can be used in the category.
 */
@interface UIViewController_VectorSearch : NSObject

// The search bar
@property (nonatomic) UISearchBar *searchBar;

// Backup of view when displaying search
@property (nonatomic) UIView *backupTitleView;
@property (nonatomic) UIBarButtonItem *backupLeftBarButtonItem;
@property (nonatomic) UIBarButtonItem *backupRightBarButtonItem;

@end

@implementation UIViewController_VectorSearch
@end


#pragma mark - UIViewController+VectorSearch
#pragma mark -

@interface UIViewController ()

// The single associated object hosting all data.
@property(nonatomic) UIViewController_VectorSearch *searchInternals;

@end

@implementation UIViewController (VectorSearch)

- (UISearchBar *)searchBar
{
    return self.searchInternals.searchBar;
}

- (void)showSearch:(BOOL)animated
{
    // Backup screen header before displaying the search bar in it
    self.searchInternals.backupTitleView = self.navigationItem.titleView;
    self.searchInternals.backupLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
    self.searchInternals.backupRightBarButtonItem = self.navigationItem.rightBarButtonItem;

    // Reset searches
    self.searchBar.text = @"";

    // Remove navigation buttons
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;

    // Add the search bar and
    self.navigationItem.titleView = self.searchBar;
    [self.searchBar becomeFirstResponder];
}

- (void)hideSearch:(BOOL)animated
{
    // Restore the screen header
    if (self.searchInternals.backupLeftBarButtonItem)
    {
        self.navigationItem.hidesBackButton = NO;
        self.navigationItem.titleView = self.searchInternals.backupTitleView;
        self.navigationItem.leftBarButtonItem = self.searchInternals.backupLeftBarButtonItem;
        self.navigationItem.rightBarButtonItem = self.searchInternals.backupRightBarButtonItem;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar2
{
    // "Search" key has been pressed
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar2
{
    [self hideSearch:YES];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar2
{
    // Keep the search bar cancel button enabled even if the keyboard is not displayed
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subView in self.searchBar.subviews)
        {
            for (UIView *view in subView.subviews)
            {
                if ([view isKindOfClass:[UIButton class]])
                {
                    [(UIButton *)view setEnabled:YES];
                }
            }
        }
    });
    return YES;
}

#pragma mark - Internal associated object

- (void)setSearchInternals:(UIViewController_VectorSearch *)searchInternals
{
    objc_setAssociatedObject(self, @selector(searchInternals), searchInternals, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController_VectorSearch *)searchInternals
{
    UIViewController_VectorSearch *searchInternals = objc_getAssociatedObject(self, @selector(searchInternals));
    if (!searchInternals)
    {
        // Initialise internal data at the first call
        searchInternals = [[UIViewController_VectorSearch alloc] init];

        UISearchBar *searchBar = [[UISearchBar alloc] init];
        searchBar.showsCancelButton = YES;
        searchBar.delegate = self;
        searchInternals.searchBar = searchBar;

        self.searchInternals = searchInternals;
    }
    return searchInternals;
}

@end
