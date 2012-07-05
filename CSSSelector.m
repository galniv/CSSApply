//
//  CSSSelector.m
//  CSSSample
//
//  Created by Sam Stewart on 7/16/11.
//  Copyright 2011 Float:Right Ltd. All rights reserved.
//

#import "CSSSelector.h"
@interface CSSSelector ()
- (void)parseSelector;
@end

@implementation CSSSelector
@synthesize cssID = _cssID;
@synthesize classes = _classes;
@synthesize className = _className;
@synthesize selector = _selector;
//@dynamic score;

- (id)initWithSelectorStr:(NSString*)selector_arg 
{
    if (self = [super init]) 
    {
        _selector = selector_arg;
        [self parseSelector];
    }
    return self;
}

- (id)initWithClassName:(NSString*)aClassName classNames:(NSArray*)classNames classID:(NSString*)aCssID 
{
    if (self = [super init])
    {
        _className = aClassName;
        _classes = [NSMutableArray arrayWithArray:classNames];
        _cssID = aCssID;
    }
    return self;
}

- (void)dealloc 
{
    _classes = nil;
    _cssID = nil;
    _className = nil;
    _selector = nil;
}
+ (NSArray*)subSelectorsFromString:(NSString *)main_selector 
{
    NSArray *sels = [main_selector componentsSeparatedByString:@" "];
    
    NSMutableArray *parsed_sels = [NSMutableArray arrayWithCapacity:30];
    for (NSString *sel in sels) 
    {
        CSSSelector *parsed_sel = [[CSSSelector alloc] initWithSelectorStr:sel];
        [parsed_sels addObject:parsed_sel];
    }
    return parsed_sels;
}
#pragma mark accessor methods
/** Parses selector string into levels, classes, etc.*/
- (void)parseSelector 
{
    NSArray *levels = [self.selector componentsSeparatedByString:@" "];
    
    if ([levels count]) 
    {
        NSString *slug = [levels lastObject];
        
        NSString *class_slug = nil;
        NSString *id_slug = nil;
        
        // split and try to find ids
        NSArray *id_comps = [slug componentsSeparatedByString:@"#"];
        if ([id_comps count] == 2) 
        {
            id_slug = [id_comps lastObject];
            _cssID = id_slug;
            
            class_slug = [id_comps objectAtIndex:0];
            //might just be id slug
            if ([class_slug isEqualToString:@""]) class_slug = nil;
            
        } 
        else 
        {
            class_slug = slug;
        }
        
        //now we parse class slug
        if (class_slug) 
        {
            NSArray *classes_comps = [class_slug componentsSeparatedByString:@"."];
            NSAssert([classes_comps count], @"Could not parse class slug: %@", class_slug);
            
            //check to see if first one is class type tag (not css class)
            // first entry will not be blank if it's a class tag
            // sam.green = "sam", "green"
            // .red.green = "", "red", "green"
            if (![[classes_comps objectAtIndex:0] isEqualToString:@""]) 
            {
                _className = [classes_comps objectAtIndex:0];
            } 
            
            _classes = [NSMutableArray arrayWithCapacity:20];
            [self.classes addObjectsFromArray:[classes_comps subarrayWithRange:NSMakeRange(1, [classes_comps count] - 1)]];
        }
    }
}

- (NSArray*)selectorComponents 
{
    // just split on spaces..
    return [[self description] componentsSeparatedByString:@" "];
}

- (BOOL)doesMatchIntoSelector:(CSSSelector *)other_selector 
{
//    NSLog(@"ID: %@, className: %@, classes: %@", self.cssID, self.className, self.classes);
//    NSLog(@"comapring to: ID: %@, className: %@, classes: %@", other_selector.cssID, other_selector.className, other_selector.classes);
    if (self.classes)
    {
        NSArray *other_classes = other_selector.classes;
        for (NSString *class in self.classes) 
        {
            if (![other_classes containsObject:class])
            {
                return NO;
            }
        }
    }
    
    // see if the class name doens't match
    if (self.className)
    {
        if (other_selector.className == nil) return NO;
        if (![self.className isEqualToString:other_selector.className]) return NO;
    }
    
    // finally see if the id matches (might not...)
    if (self.cssID) 
    {
        if (other_selector.cssID == nil) return NO;
        if (![self.cssID isEqualToString:other_selector.cssID]) return NO;
    }
    
    return YES;
}

- (NSString*)description 
{
    if (_selector) return _selector;
    
    return [NSString stringWithFormat:@"Class: %@, classes: %@, ID: %@", _className, _classes, _cssID];
}

/** calculates precedence score based on number of classes, ids, etc.
 The score is based on the following:
 ID are always worth 100
 Class are always worth 10
 HTML tags (class type tags) are always worth 1.
 
 Since the score is so simple to calculate, we simply re-run everytime and don't
 cache.*/
- (NSInteger) score 
{
    NSInteger score = 0;
    score += self.cssID ? 100 : 0;
    score += self.classes.count ? self.classes.count * 10 : 0;
    score += self.className ? 1 : 0;
    return score;
}

@end
