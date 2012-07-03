//
//  CSSSelectorTree.m
//  CSSSample
//
//  Created by Sam Stewart on 7/16/11.
//  Copyright 2011 Float:Right Ltd. All rights reserved.
//
/**
 @class CSSSelectorTree 
 This custom data structure represents our css tree we inflate after parsing. In fact, it's not really a tree but more of a list of matching "paths".
 
 An example will hopefully clarify this:
 */
#import "CSSSelectorTree.h"
#import "CSSSelector.h"

@implementation CSSSelectorTree
//@dynamic score;
@synthesize nodes = _nodes;
@synthesize rules = _rules;
@synthesize selector = _selector;

- (id)initWithSelector:(CSSSelector *)selector_arg 
{    
    if (self = [super init]) 
    {
        _selector = selector_arg;
    }
    return self;
}

- (void)dealloc 
{
    _rules = nil;
    _nodes = nil;
    _selector = nil;
}

/** Convenience method for breaking up multi level selector
 into multiple smaller selectors wrapped in subtrees. Builds the subtrees in reverse order of specificity.*/
+ (NSArray*)subtreesFromSelector:(NSString *)selector 
{
    NSArray *comps = [selector componentsSeparatedByString:@" "];
    
    NSMutableArray *subtrees = [NSMutableArray arrayWithCapacity:20];
    for (NSString *comp in comps) 
    {
        CSSSelector *selector = [[CSSSelector alloc] initWithSelectorStr:comp];
        CSSSelectorTree *subtree = [[CSSSelectorTree alloc] initWithSelector:selector];
        
        // make sure it's in reverse order.
        [subtrees insertObject:subtree atIndex:0];
    }
    return subtrees;
}

+ (CSSSelectorTree*)chainSubtrees:(NSArray *)subtrees 
{
    if (![subtrees count]) return nil;
    
    //start with most specific and begin chaining
    CSSSelectorTree *cur_parent = [subtrees objectAtIndex:0];
    CSSSelectorTree *top_parent = cur_parent;
    
    for (CSSSelectorTree *subtree in subtrees) 
    {
        if (subtree != cur_parent) 
        {
            [cur_parent.nodes addObject:subtree];
            cur_parent = subtree; //move into subtree
        }
    }
    return top_parent;
}

#pragma mark Accessors

/* 
 * Sort nodes so that the least-specific selector is at the top.
 */
- (void)sortNodes 
{
    [self.nodes sortUsingComparator:(NSComparator)^(CSSSelectorTree *a_sel, CSSSelectorTree *b_sel) 
    {
        [a_sel sortNodes];
        [b_sel sortNodes];
        
        NSInteger a_score = [a_sel score];
        NSInteger b_score = [b_sel score];
        
        if (a_score < b_score)
            return NSOrderedAscending;
        else if(a_score > b_score)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
}
/** Searches subnodes for partial matches for the selector you pass in.
 Remember, only a few properties have to match for the entire selector to match.
 @return Array of CSSSelectorTree nodes.
 */
- (NSArray*)find:(CSSSelector *)selector_arg 
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:20];
    for (CSSSelectorTree *node in self.nodes) 
    {
        if ([node.selector doesMatchIntoSelector:selector_arg]) 
        {
            [results addObject:node];
        }
    }
    return results;
}

- (BOOL)isLeaf
{
    return (self.nodes.count == 0);
}
- (NSString*)name 
{
    // grab our selector entire selector string..
    return self.selector.selector;
}
/** Takes the biggest child score to ensure we reflect the child nodes accurately.
 Note: this may not be quite right. How do we know we "own" the biggest node?*/
- (NSInteger)score 
{
    if ([self isLeaf]) return _selector.score;
    
    NSInteger max_score = 0;
    for (CSSSelectorTree* node in self.nodes) 
    {
        //NSInteger score = [node score];
        max_score =  MAX(max_score, node.score);  //(score > max_score ? score : max_score);
    }
    return max_score;
}

- (NSMutableArray*) nodes 
{    
    if (!_nodes) 
    {
        _nodes = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return _nodes;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"CSSSelectorTree [%@]", _selector];
}

@end
