//
//	Copyright 2011 James Addyman (JamSoft). All rights reserved.
//	
//	Redistribution and use in source and binary forms, with or without modification, are
//	permitted provided that the following conditions are met:
//	
//		1. Redistributions of source code must retain the above copyright notice, this list of
//			conditions and the following disclaimer.
//
//		2. Redistributions in binary form must reproduce the above copyright notice, this list
//			of conditions and the following disclaimer in the documentation and/or other materials
//			provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY JAMES ADDYMAN (JAMSOFT) ``AS IS'' AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JAMES ADDYMAN (JAMSOFT) OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//	The views and conclusions contained in the software and documentation are those of the
//	authors and should not be interpreted as representing official policies, either expressed
//	or implied, of James Addyman (JamSoft).
//

#import "JSTokenButton.h"
#import "JSTokenField.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+EYEAdditions.h"

@import EYELibrary;
@import EYEWidgets;

@implementation JSTokenButton

@synthesize toggled = _toggled;
@synthesize normalBg = _normalBg;
@synthesize highlightedBg = _highlightedBg;
@synthesize representedObject = _representedObject;
@synthesize parentField = _parentField;

+ (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj
{
	JSTokenButton *button = (JSTokenButton *)[self buttonWithType:UIButtonTypeCustom];
	
	[button setNormalBg:[UIImage eye_filledImageWithSize:CGSizeMake(1, 1) color:[UIColor colorWithWhite:1.0 alpha:0.2]]];
	[button setHighlightedBg:[UIImage eye_filledImageWithSize:CGSizeMake(1, 1) color:[UIColor colorWithWhite:1.0 alpha:0.4]]];
	[button setAdjustsImageWhenHighlighted:NO];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[[button titleLabel] setFont:[UIFont fontWithName:kEYEDefaultLightFont size:14.0]];
	[[button titleLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 4.0, 0, 4.0)];
	
	[button setTitle:string forState:UIControlStateNormal];
    button.clipsToBounds = YES;
    button.layer.cornerRadius = 1.0;
	
	[button sizeToFit];
	CGRect frame = [button frame];
	frame.size.width += 8.0;
	frame.size.height = 20.0;
	[button setFrame:frame];
	
	[button setToggled:NO];
	
	[button setRepresentedObject:obj];
	
	return button;
}

- (void)setToggled:(BOOL)toggled
{
	_toggled = toggled;
	if (_toggled)
	{
		[self setBackgroundImage:self.highlightedBg forState:UIControlStateNormal];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	}
	else
	{
		[self setBackgroundImage:self.normalBg forState:UIControlStateNormal];
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	}
}

- (void)dealloc
{
	self.representedObject = nil;
	self.highlightedBg = nil;
	self.normalBg = nil;
    [super dealloc];
}

- (BOOL)becomeFirstResponder {
    BOOL superReturn = [super becomeFirstResponder];
    if (superReturn) {
        self.toggled = YES;
    }
    return superReturn;
}

- (BOOL)resignFirstResponder {
    BOOL superReturn = [super resignFirstResponder];
    if (superReturn) {
        self.toggled = NO;
    }
    return superReturn;
}

#pragma mark - UIKeyInput

- (void)deleteBackward {
	id <JSTokenFieldDelegate> delegate = _parentField.delegate;
    if ([delegate respondsToSelector:@selector(tokenField:shouldRemoveToken:representedObject:)]) {
        NSString *name = [self titleForState:UIControlStateNormal];
        BOOL shouldRemove = [delegate tokenField:_parentField shouldRemoveToken:name representedObject:self.representedObject];
        if (!shouldRemove) {
            return;
        }
    }
    [_parentField removeTokenForString:[self titleForState:UIControlStateNormal]];
}

- (BOOL)hasText {
    return YES;
}
- (void)insertText:(NSString *)text {
    [self deleteBackward];
    _parentField.textField.text = text;
    return;
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark UITextInputTraits methods

- (UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDark;
}

@end
