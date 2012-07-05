//
//  UIVIew+CSS.m
//  CSSSample
//
//  Created by Jonathan Dalrymple on 16/07/2011.
//  Copyright 2011 Float:Right Ltd. All rights reserved.

#import <Foundation/Foundation.h>
#import "UIView+CSS.h"
#import "NSObject+CSS.h"

@implementation UIView (CSS)

- (void)applyProperties:(NSDictionary*)props 
{
    NSArray *keys = [props allKeys];
    for (NSString *key in keys) 
    {
        @try
        {
            [self setValue:[[props objectForKey:key] objectAtIndex:0] forKey:key];
        }
        @catch (NSException *exception) 
        {
            NSLog(@"Key does not exist when trying to set from css: %@", [exception reason]);
        }
    }
}

- (void)applyStylesToChildren:(CSSSelectorTree *)treeNode 
       withInheirtedStyleDict:(NSDictionary *)mdict
                      recurse:(BOOL)doRecurse
{    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:mdict];
    
    for (CSSSelectorTree *node in treeNode.nodes) 
    {
        //first level is always most specific, do we match?
        if ([node.selector doesMatchIntoSelector:self.CSSSelector]) 
        {            
            if (node.rules) 
            {
                // will replace inherited (as expected)
                [dict addEntriesFromDictionary:node.rules];
            }
            
            // if it has nodes, we need to match upwards in the tree.
            if (node.nodes && node.nodes.count > 0) 
            {
                // we need to check if we match all the way up the tree
                // we always go all the way to the root bc we do descendant matching not just child matching but descendant
                
                BOOL doesMatch = YES;
                //move through nodes as we move up
                NSEnumerator *node_iter = [node.nodes objectEnumerator];
                CSSSelectorTree *subtree = nil;
                UIView *parent = nil;
                while ((subtree = [node_iter nextObject]) && doesMatch) 
                {
                    // try to find the appropriate match up the tree
                    doesMatch = NO;
                    while ((parent = [self CSSParent])) 
                    {
                        if ([parent.CSSSelector doesMatchIntoSelector:subtree.selector]) 
                        {
                            doesMatch = YES;
                            //parent will be left where it is on purpose. We don't want rematch a parent.
                            break;
                        }
                    }
                }
                if (doesMatch) 
                {
                    //we can now use the style
                    CSSSelectorTree *tree = [node.nodes objectAtIndex:0];
                    if (tree.rules) 
                    {
                        [dict addEntriesFromDictionary:tree.rules];
                    }
                }
                
            }
            
        }
    }
    if (dict.count > 0) [self applyProperties:dict];
    
    if (doRecurse) 
    {
        //tell all the children to do the rule merging
        //also we pass our styles down for inheritance.
        for (int i = 0; i < self.subviews.count; i++) {
            [[self.subviews objectAtIndex:i] applyStylesToChildren:treeNode withInheirtedStyleDict:dict recurse:YES];
        }
    }
}

#pragma mark Actual application methods
//** Applies styles only to this node and doesn't recurse.*/
- (void)apply:(CSSStyleSheet*)sheet 
{
    [self applyStylesToChildren:[sheet root] withInheirtedStyleDict:[NSDictionary dictionary] recurse:NO];
    
}

- (void)applyAll:(CSSStyleSheet *)sheet 
{
    [self applyStylesToChildren:[sheet root] withInheirtedStyleDict:[NSDictionary dictionary] recurse:YES];
}

#pragma mark Searching though the "DOM"
/** Searches through the "DOM" for a specific set of subviews specified
 by the selector.*/
- (NSArray*)find:(CSSSelector*)selector 
{
    return nil;
}

- (NSArray*)findAll:(CSSSelector*)selector 
{
    return nil;
}

-(id) CSSParent
{
	return [self superview];
}

@end
