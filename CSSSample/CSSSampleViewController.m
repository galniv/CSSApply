//
//  CSSSampleViewController.m
//  CSSSample
//
//  Created by Jonathan Dalrymple on 16/07/2011.
//  Copyright 2011 Float:Right Ltd. All rights reserved.
//

#import "CSSSampleViewController.h"
#import "UIView+CSS.h"
#import "NSObject+CSS.h"
@implementation CSSSampleViewController
@synthesize sampleView;

- (void)dealloc
{
    sampleView = nil;
	//[sampleView release];
    //[super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(10, 10, 100, 100);
    button.CSSID = @"magicButton";
    [button setTitle:@"#magicbutton" forState:UIControlStateNormal];
    [[self view] addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button2.frame = CGRectMake(115, 10, 100, 100);
    [button2 setTitle:@"normal" forState:UIControlStateNormal];
    [[self view] addSubview:button2];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button3.frame = CGRectMake(220, 10, 100, 100);
    [button3 addCSSClassName:@"someClass"];
    [button3 setTitle:@".class" forState:UIControlStateNormal];
    [[self view] addSubview:button3];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button4.frame = CGRectMake(10, 300, 100, 100);
    [button4 addCSSClassName:@"someClass"];
    button4.CSSID = @"abc";
    [button4 setTitle:@"class#id" forState:UIControlStateNormal];
    [[self view] addSubview:button4];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
    
	NSURL *cssURL;
	
	cssURL = [[NSBundle mainBundle] URLForResource:@"maintest"
									 withExtension:@"css"
			  ];

	[[self view] applyAll:[CSSStyleSheet styleSheetFromURL:cssURL]];
    
}


- (void)viewDidUnload
{
	[self setSampleView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
