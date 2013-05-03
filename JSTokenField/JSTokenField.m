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

#import "JSTokenField.h"
#import "JSTokenButton.h"
#import "JSBackspaceReportingTextField.h"
#import <QuartzCore/QuartzCore.h>

NSString *const JSTokenFieldFrameDidChangeNotification = @"JSTokenFieldFrameDidChangeNotification";
NSString *const JSTokenFieldNewFrameKey = @"JSTokenFieldNewFrameKey";
NSString *const JSTokenFieldOldFrameKey = @"JSTokenFieldOldFrameKey";
NSString *const JSDeletedTokenKey = @"JSDeletedTokenKey";

#define HEIGHT_PADDING 10
#define WIDTH_PADDING 3

#define DEFAULT_HEIGHT 20
#define MAX_HEIGHT	80

@interface JSTokenField ();
- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj;
- (void)deleteHighlightedToken;

- (void)commonSetup;
@end


@implementation JSTokenField

- (id)initWithFrame:(CGRect)frame
{
	if (frame.size.height < DEFAULT_HEIGHT)
	{
		frame.size.height = DEFAULT_HEIGHT;
	}
	
    if ((self = [super initWithFrame:frame]))
	{
        [self commonSetup];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup {
    CGRect frame = self.frame;
	
	//default limit
	self.tagLimit = 4;
	

	self.bounces = YES;
    [self setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
	
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, frame.size.height)];
    [_label setBackgroundColor:[UIColor clearColor]];
    [_label setTextColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]];
    [_label setFont:[UIFont fontWithName:@"Helvetica Neue" size:17.0]];
    
    [self addSubview:_label];
	
	
	UIImageView *searchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8.0, 11.0, 13, 15)];
	searchImageView.image = [UIImage imageNamed:@"people.search.icon.png"];
	[self addSubview:searchImageView];
	
    
    //		self.layer.borderColor = [[UIColor blueColor] CGColor];
    //		self.layer.borderWidth = 1.0;
    
    _tokens = [[NSMutableArray alloc] init];
    
    frame.origin.y += HEIGHT_PADDING;
    frame.size.height -= HEIGHT_PADDING * 2;
    _textField = [[JSBackspaceReportingTextField alloc] initWithFrame:frame];
    [_textField setDelegate:self];
    [_textField setBorderStyle:UITextBorderStyleNone];
    [_textField setBackground:nil];
    [_textField setBackgroundColor:[UIColor clearColor]];
    [_textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	_textField.returnKeyType = UIReturnKeyDone;
	_textField.textColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	_textField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
	
    //		[_textField.layer setBorderColor:[[UIColor redColor] CGColor]];
    //		[_textField.layer setBorderWidth:1.0];
    
    [self addSubview:_textField];
    
    [self.textField addTarget:self action:@selector(textFieldWasUpdated:) forControlEvents:UIControlEventEditingChanged];
    [self.textField addTarget:self action:@selector(textFieldWasUpdated:) forControlEvents:UIControlEventValueChanged];
	
}


- (void)addTokenWithTitle:(NSString *)string representedObject:(id)obj
{
	NSString *aString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
	if ([aString length])
	{
		JSTokenButton *token = [self tokenWithString:aString representedObject:obj];
        token.parentField = self;
		[_tokens addObject:token];
		
		if ([self.delegate respondsToSelector:@selector(tokenField:didAddToken:representedObject:)])
		{
			[self.delegate tokenField:self didAddToken:aString representedObject:obj];
		}
		
		[self setNeedsLayout];
	}
}

- (void)removeTokenWithTest:(BOOL (^)(JSTokenButton *token))test {
    JSTokenButton *tokenToRemove = nil;
    for (JSTokenButton *token in [_tokens reverseObjectEnumerator]) {
        if (test(token)) {
            tokenToRemove = token;
            break;
        }
    }
    
    if (tokenToRemove) {
        if (tokenToRemove.isFirstResponder) {
            [_textField becomeFirstResponder];
        }
        [tokenToRemove removeFromSuperview];
        [[tokenToRemove retain] autorelease]; // removing it from the array will dealloc the object, but we want to keep it around for the delegate method below
        
        [_tokens removeObject:tokenToRemove];
        if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveToken:representedObject:)])
        {
				NSString *tokenName = [tokenToRemove titleForState:UIControlStateNormal];
				[self.delegate tokenField:self didRemoveToken:tokenName representedObject:tokenToRemove.representedObject];

		}
	}
	
	[self setNeedsLayout];
}

- (void)removeTokenForString:(NSString *)string
{
    [self removeTokenWithTest:^BOOL(JSTokenButton *token) {
        return [[token titleForState:UIControlStateNormal] isEqualToString:string];
    }];
}

- (void)removeTokenWithRepresentedObject:(id)representedObject {
    [self removeTokenWithTest:^BOOL(JSTokenButton *token) {
        return [[token representedObject] isEqual:representedObject];
    }];
}

- (void)removeAllTokens {
	NSArray *tokensCopy = [_tokens copy];
	for (JSTokenButton *button in tokensCopy) {
		[self removeTokenWithTest:^BOOL(JSTokenButton *token) {
			return token == button;
		}];
	}
	[tokensCopy release];
}

- (void)deleteHighlightedToken
{
	for (int i = 0; i < [_tokens count]; i++)
	{
		_deletedToken = [[_tokens objectAtIndex:i] retain];
		if ([_deletedToken isToggled])
		{
			NSString *tokenName = [_deletedToken titleForState:UIControlStateNormal];
			if ([self.delegate respondsToSelector:@selector(tokenField:shouldRemoveToken:representedObject:)]) {
				BOOL shouldRemove = [self.delegate tokenField:self
											shouldRemoveToken:tokenName
											representedObject:_deletedToken.representedObject];
				if (shouldRemove == NO) {
					return;
				}
			}
			
			[_deletedToken removeFromSuperview];
			[_tokens removeObject:_deletedToken];
			
			if ([self.delegate respondsToSelector:@selector(tokenField:didRemove:representedObject:)])
			{
				[self.delegate tokenField:self didRemoveToken:tokenName representedObject:_deletedToken.representedObject];
			}
			
			[self setNeedsLayout];	
		}
	}
}

- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj
{
	JSTokenButton *token = [JSTokenButton tokenWithString:string representedObject:obj];
	CGRect frame = [token frame];
	
	if (frame.size.width > self.frame.size.width)
	{
		frame.size.width = self.frame.size.width - (WIDTH_PADDING * 2);
	}
	
	[token setFrame:frame];
	
	[token addTarget:self
			  action:@selector(toggle:)
	forControlEvents:UIControlEventTouchUpInside];
	
	return token;
}

- (void)layoutSubviews
{
	CGRect currentRect = CGRectZero;
	
	[_label sizeToFit];
	[_label setFrame:CGRectMake(WIDTH_PADDING, HEIGHT_PADDING, [_label frame].size.width, [_label frame].size.height + HEIGHT_PADDING)];
	
	currentRect.origin.x = _label.frame.origin.x;
	if (_label.frame.size.width > 0) {
		currentRect.origin.x += _label.frame.size.width + WIDTH_PADDING;
	}
	
	NSMutableArray *lastLineTokens = [NSMutableArray array];
    
	for (UIButton *token in _tokens)
	{
		CGRect frame = [token frame];
		
		if ((currentRect.origin.x + frame.size.width + WIDTH_PADDING) > self.frame.size.width)
		{
			[lastLineTokens removeAllObjects];
			currentRect.origin = CGPointMake(WIDTH_PADDING, (currentRect.origin.y + frame.size.height + HEIGHT_PADDING));
		}
		
		frame.origin.x = currentRect.origin.x;
		frame.origin.y = currentRect.origin.y + HEIGHT_PADDING;
		
		[token setFrame:frame];
		
		if (![token superview])
		{
			[self addSubview:token];
		}
		[lastLineTokens addObject:token];
		
		currentRect.origin.x += frame.size.width + WIDTH_PADDING;
		currentRect.size = frame.size;
	}
	
	CGRect textFieldFrame = [_textField frame];
	

	textFieldFrame.origin = currentRect.origin;

	if (currentRect.origin.x == 3) {
		textFieldFrame.origin.x = 25.0;
	}
	
	if ((self.frame.size.width - textFieldFrame.origin.x) >= 60)
	{
		textFieldFrame.size.width = self.frame.size.width - textFieldFrame.origin.x;
	}
	else
	{
		[lastLineTokens removeAllObjects];
		textFieldFrame.size.width = self.frame.size.width;
        textFieldFrame.origin = CGPointMake(WIDTH_PADDING * 2, 
                                            (currentRect.origin.y + currentRect.size.height + HEIGHT_PADDING));
	}
	
	textFieldFrame.origin.y += HEIGHT_PADDING;
	[_textField setFrame:textFieldFrame];
	CGRect selfFrame = [self frame];
	
	CGFloat newHeight = textFieldFrame.origin.y + textFieldFrame.size.height + HEIGHT_PADDING;
	
	if (newHeight < MAX_HEIGHT) {
		selfFrame.size.height = newHeight;
		self.scrollEnabled = NO;
		self.contentSize = selfFrame.size;
	} else {
		selfFrame.size.height = MAX_HEIGHT;
		self.scrollEnabled = YES;
		self.contentSize = CGSizeMake(selfFrame.size.width, newHeight);
	}
	
	CGFloat textFieldMidY = CGRectGetMidY(textFieldFrame);
	for (UIButton *token in lastLineTokens) {
		// Center the last line's tokens vertically with the text field
		CGPoint tokenCenter = token.center;
		tokenCenter.y = textFieldMidY;
		token.center = tokenCenter;
	}

	
	
//	if (self.layer.presentationLayer == nil) {
//		[self setFrame:selfFrame];
//	}
//	else {
		[UIView animateWithDuration:0.25
						 animations:^{
							 [self setFrame:selfFrame];
						 }
						 completion:nil];
//	}
}

- (void)toggle:(id)sender
{	
	JSTokenButton *token = (JSTokenButton *)sender;
	if (token.toggled) {
		[token setToggled:NO];
		[token resignFirstResponder];
	} else {
		[token setToggled:YES];
		[token becomeFirstResponder];
		double delayInSeconds = 0.25;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			if ([self.delegate respondsToSelector:@selector(tokenField:didSelectToken:representedObject:)]) {
				[self.delegate tokenField:self didSelectToken:token.titleLabel.text representedObject:token];
			}
		});


	}
	
//	for (JSTokenButton *token in _tokens)
//	{
//		[token setToggled:NO];
//	}
}

- (void)setContentSize:(CGSize)contentSize
{
	CGSize oldSize = self.contentSize;
    
	[super setContentSize:contentSize];

	
	if (CGSizeEqualToSize(oldSize, contentSize) == NO) {
		[[NSNotificationCenter defaultCenter] postNotificationName:JSTokenFieldFrameDidChangeNotification object:self userInfo:nil];
	}
	
}

- (void)setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    
	[super setFrame:frame];
	
	if (CGSizeEqualToSize(oldFrame.size, frame.size) == NO) {
		[[NSNotificationCenter defaultCenter] postNotificationName:JSTokenFieldFrameDidChangeNotification object:self userInfo:nil];
	}
	
}

#pragma mark -
#pragma mark UITextFieldDelegate


- (void)textFieldWasUpdated:(UITextField *)sender {
//    if ([self.delegate respondsToSelector:@selector(tokenFieldTextDidChange:)]) {
//        [self.delegate tokenFieldTextDidChange:self];
//    }
	
	
	if ([self.delegate respondsToSelector:@selector(tokenField:wantsToSearchFor:)]) {
		[self.delegate tokenField:self wantsToSearchFor:sender.text];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{	
    if ([string isEqualToString:@""] && NSEqualRanges(range, NSMakeRange(0, 0)))
	{
        JSTokenButton *token = [_tokens lastObject];
		if (!token) {
			return NO;
		}
		
		NSString *name = [token titleForState:UIControlStateNormal];
		// If we don't allow deleting the token, don't even bother letting it highlight
		BOOL responds = [self.delegate respondsToSelector:@selector(tokenField:shouldRemoveToken:representedObject:)];
		if (responds == NO || [self.delegate tokenField:self shouldRemoveToken:name representedObject:token.representedObject]) {
			[token becomeFirstResponder];
		}
		return NO;
	} else if ([_tokens count] < self.tagLimit) {
		[self textFieldWasUpdated:textField];
		return YES;		
	} else {
		return NO;
	}
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (_textField == textField) {
        if ([self.delegate respondsToSelector:@selector(tokenFieldShouldReturn:)]) {
            return [self.delegate tokenFieldShouldReturn:self];
        }
    }
	
	return NO;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenFieldDidEndEditing:)]) {
        [self.delegate tokenFieldDidEndEditing:self];
        return;
    }
//    else if ([[textField text] length] > 1)
//    {
//        [self addTokenWithTitle:[textField text] representedObject:[textField text]];
//        [textField setText:nil];
//    }
}

@end
