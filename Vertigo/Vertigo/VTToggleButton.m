//
//  VTToggleButton.m
//  Vertigo
//
//  Created by Evan Long on 3/23/17.
//
//

#import "VTToggleButton.h"

@interface VTToggleButton ()

@property (nonatomic, assign) NSUInteger currentItemIndex;

@end

@implementation VTToggleButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _items = @[];
        _currentItemIndex = 0;
        [self addTarget:self action:@selector(_handleTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setItems:(NSArray<NSString *> *)items
{
    if (_items != items)
    {
        _items = [items copy];
        _currentItemIndex = 0;
        [self _updateButton];
    }
}

- (NSString *)currentItem
{
    NSString *item = nil;
    if (self.items.count)
    {
        item = [self.items objectAtIndex:self.currentItemIndex];
    }
    return item;
}

#pragma mark - Events

- (void)_handleTap
{
    [self _next];
}

#pragma mark - Private

- (void)_next
{
    self.currentItemIndex = (self.currentItemIndex + 1) % self.items.count;
    [self _updateButton];
}

- (void)_updateButton
{
    [self setTitle:self.currentItem forState:UIControlStateNormal];
}

@end
