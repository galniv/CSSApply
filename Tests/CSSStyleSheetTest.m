//
//  CSSViewSelectorTest.h
//  CSSSample
//
//  Created by Alexander Brausch on 03/07/2012.
//  Copyright 2012 Alexander Brausch. All rights reserved.
//


#import "CSSStyleSheetTest.h"

#import "CSSStyleSheet.h"
#import "CSSSelector.h"
#import "CSSSelectorTree.h"

@implementation CSSStyleSheetTest

- (void) testLoadFromString {
    CSSStyleSheet* sheet = [CSSStyleSheet styleSheetFromString: @".foo.bar{background-color:black}"];
    
    NSUInteger count = [sheet.root.nodes count];
    GHAssertTrue( count == 1, @"Invalid count %d",count);
}

@end
