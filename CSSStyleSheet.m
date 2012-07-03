//
//  CSSStyleSheet.m
//  CSSSample
//
//  Created by Sam Stewart on 7/16/11.
//  Copyright 2011 Float:Right Ltd. All rights reserved.
//

#import "CSSStyleSheet.h"
#import "CSSParser.h"

@interface CSSStyleSheet ()
- (void)buildTree:(NSDictionary*)rules;
@end

@implementation CSSStyleSheet
@synthesize root = _root;
#pragma mark Loader Methods

+ (CSSStyleSheet*)styleSheetFromURL:(NSURL *)url 
{
    CSSStyleSheet *sheet = [[CSSStyleSheet alloc] init];
    [sheet loadFromURL:url];
    return sheet;
}

+ (CSSStyleSheet*)styleSheetFromString:(NSString *)css_code 
{
    //TODO: load and parse from string
    return nil;
}

- (void)loadFromURL:(NSURL*)url 
{
    parser = [[CSSParser alloc] init];
    
    // grab the entire file and load the rule dictionary.
    NSDictionary *rules = [parser parseFilename:[url path]];
    
    // build the tree from the parsed rules
    [self buildTree:rules];
    
    // sort the tree so that the least-specific node is at the top.
    [_root sortNodes];
}

- (void)loadFromString:(NSString *)css_code {
    //TODO: load from string (need it in the parser class.)
}

#pragma mark Tree Parsing methods
- (void)buildTree:(NSDictionary *)rules 
{    
    // create the root node for the selector tree
    _root = [[CSSSelectorTree alloc] init];
    
    NSArray *selectors = [rules allKeys];
    
    for (NSString *selector in selectors) {
        
        NSDictionary *ruleset = [rules objectForKey:selector];
        
        //grab subtrees (really horizontal list since they are sublevels.)
        // ul, ul, li, sam.red#hello
        NSArray *subtrees = [CSSSelectorTree subtreesFromSelector:selector];
        
        if ([subtrees count] < 1)
            return;
        
        //ruleset belongs to most specific (or first)
        CSSSelectorTree *most_specific = [subtrees objectAtIndex:0];
        most_specific.rules = ruleset;
        
        //now we convert into tree
        CSSSelectorTree *root_subtree = [CSSSelectorTree chainSubtrees:subtrees];
        [_root.nodes addObject:root_subtree];
    }
}

- (void)dealloc 
{
    parser = nil;
    _root = nil;
}

@end
