//
//  CSSParser.m
//  CSSSample
//
//  Created by Sam Stewart on 7/16/11.
//  Copyright 2011 Float:Right Ltd. All rights reserved.
//

#import "CSSTokens.h"
#import "css.h"
#import "CSSParser.h"

typedef enum 
{
    None,    
} ParserStates;


// Damn you, flex. Due to the nature of the global methods and whatnot, we can only have one
// parser at any given time.
CSSParser* gActiveParser = nil;

@interface CSSParser()

- (void)consumeToken:(int)token text:(char*)text;
- (UIColor *)colorWithHexString:(NSString *)stringToConvert;

@end


int cssConsume(char* text, int token) 
{
    [gActiveParser consumeToken:token text:text];
    return 0;
}


@implementation CSSParser

- (id)init 
{
    if (self = [super init]) 
    {
        _ruleSets           = [[NSMutableDictionary alloc] init];
        _activeCssSelectors = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)dealloc 
{
    _ruleSets=nil;
    _activeCssSelectors=nil;
    _activeRuleSet=nil;
    _activePropertyName=nil;
    _lastTokenText=nil;    
}


- (void)consumeToken:(int)token text:(char*)text 
{
    // ignroe whitespace
    NSString* string = [[NSString stringWithCString: text encoding: NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"current: %d, %@. previous: %d, %@", token, string, _lastToken, _lastTokenText);
    switch (token) 
    {
        case CSSHASH:
        case CSSIDENT: 
        {
            if (_state.Flags.InsideDefinition) 
            {                
                // If we're inside a definition then we ignore hashes.
                if (CSSHASH != token && !_state.Flags.InsideProperty) 
                {
                    _activePropertyName = string;
                    
                    NSMutableArray* values = [[NSMutableArray alloc] init];
                    [_activeRuleSet setObject:values forKey:_activePropertyName];               
                } 
                else 
                {
                    // This is a value, so add it to the active property.
                    //TTDASSERT(nil != _activePropertyName);                    
                    if (nil != _activePropertyName) 
                    {
                        NSMutableArray* values = [_activeRuleSet objectForKey:_activePropertyName];
                        
                        // detect and convert colors
                        if ((token == CSSHASH) && (string.length == 7 || string.length == 9)) {
                            // strip the hash
                            [values addObject:[self colorWithHexString:[string substringFromIndex:1]]];
                        }
                        else {
                            [values addObject:string];
                        }
                    }
                }
            } 
            else 
            {
                if ((_lastToken != CSSUNKNOWN) && (_lastTokenText != nil))
                {
                    string = [_lastTokenText stringByAppendingString:string];
                }
                // don't add the string yet. it will only be recognized as a selector when the left curly-brace,
                //  is encountered in order to recognize complex inheritance, e.g. UILabel.someClass#someID
                _activePropertyName=nil;
            }
            break;
        }            
        case CSSFUNCTION: 
        {
            if (_state.Flags.InsideProperty) 
            {
                _state.Flags.InsideFunction = YES;
                
                if (nil != _activePropertyName) 
                {
                    NSMutableArray* values = [_activeRuleSet objectForKey:_activePropertyName];
                    [values addObject:string];
                }
            }
            break;
        }
            
        case CSSSTRING:
        case CSSEMS:
        case CSSEXS:
        case CSSLENGTH:
        case CSSANGLE:
        case CSSTIME:
        case CSSFREQ:
        case CSSDIMEN:
        case CSSPERCENTAGE:
        case CSSNUMBER:
        case CSSURI: 
        {
            if (nil != _activePropertyName)
            {
                NSMutableArray* values = [_activeRuleSet objectForKey:_activePropertyName];
                [values addObject:string];
            }
            break;
        }
        case CSSUNKNOWN:
        {
            switch (text[0])
            {
                case '{':
                {
                    // wait until here (the beginning of the definition) before recognizing a selector.
                    if ((_lastToken != CSSUNKNOWN) && (_lastTokenText != nil))
                    {
                        [_activeCssSelectors addObject:_lastTokenText];
                        _activePropertyName=nil;
                    }
                    
                    _state.Flags.InsideDefinition = YES;
                    _state.Flags.InsideFunction = NO;
                    _activeRuleSet=nil;
                    _activeRuleSet = [[NSMutableDictionary alloc] init];
                    break;
                }                    
                case '}': 
                {
                    for (NSString* name in _activeCssSelectors) 
                    {
                        NSMutableDictionary* existingProperties = [_ruleSets objectForKey:name];
                        if (nil != existingProperties) 
                        {
                            // Overwrite the properties, instead!                            
                            NSDictionary* iteratorProperties = [_activeRuleSet copy];
                            for (NSString* key in iteratorProperties) 
                            {
                                [existingProperties setObject:[_activeRuleSet objectForKey:key] forKey:key];
                            }                            
                        } 
                        else 
                        {
                            NSMutableDictionary* ruleSet = [_activeRuleSet mutableCopy];
                            [_ruleSets setObject:ruleSet forKey:name];
                        }
                    }
                    _activeRuleSet=nil;
                    [_activeCssSelectors removeAllObjects];
                    _state.Flags.InsideDefinition = NO;
                    _state.Flags.InsideProperty = NO;
                    _state.Flags.InsideFunction = NO;
                    break;
                }                    
                case ':': 
                {
                    if (_state.Flags.InsideDefinition) 
                    {
                        _state.Flags.InsideProperty = YES;
                    }
                    break;
                }                    
                case ')': 
                {
                    if (_state.Flags.InsideFunction && nil != _activePropertyName) 
                    {
                        NSMutableArray* values = [_activeRuleSet objectForKey:_activePropertyName];
                        [values addObject:string];
                    }
                    _state.Flags.InsideFunction = NO;
                    break;
                }                    
                case ';': 
                {
                    if (_state.Flags.InsideDefinition) 
                    {
                        _state.Flags.InsideProperty = NO;
                    }
                    break;
                }
            }
            break;
        }
    }
    
    _lastTokenText = string;
    _lastToken = token;
}

// taken from http://arstechnica.com/apple/2009/02/iphone-development-accessing-uicolor-components/
- (UIColor *) colorWithHexString: (NSString *) stringToConvert
{
	NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
	
	// String should be 6 or 8 characters
	if ([cString length] < 6) return [UIColor clearColor];
	
	// strip 0X if it appears
	if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
	
	if ([cString length] != 6) return [UIColor clearColor];
    
	// Separate into r, g, b substrings
	NSRange range;
	range.location = 0;
	range.length = 2;
	NSString *rString = [cString substringWithRange:range];
	
	range.location = 2;
	NSString *gString = [cString substringWithRange:range];
	
	range.location = 4;
	NSString *bString = [cString substringWithRange:range];
	
	// Scan values
	unsigned int r, g, b;
	[[NSScanner scannerWithString:rString] scanHexInt:&r];
	[[NSScanner scannerWithString:gString] scanHexInt:&g];
	[[NSScanner scannerWithString:bString] scanHexInt:&b];
	
	return [UIColor colorWithRed:((float) r / 255.0f)
						   green:((float) g / 255.0f)
							blue:((float) b / 255.0f)
						   alpha:1.0f];
}

#pragma mark -
#pragma mark Public



- (NSDictionary*)parseFilename:(NSString*)filename 
{
    gActiveParser = self;
    
    [_ruleSets removeAllObjects];
    [_activeCssSelectors removeAllObjects];
    _activeRuleSet=nil;
    _activePropertyName=nil;
    _lastTokenText=nil;
    
    cssin = fopen([filename UTF8String], "r");
    
    csslex();
    
    fclose(cssin);
    
    NSDictionary* result = [_ruleSets copy];
    _ruleSets=nil;
    return result;
}

@end
