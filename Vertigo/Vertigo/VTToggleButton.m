//
//  VTToggleButton.m
//  Vertigo
//
//  Created by Evan Long on 3/23/17.
//
//

#import "VTToggleButton.h"

@implementation VTToggleButtonItem

- (instancetype)init
{
    VTUnavailableInitializer;
}

- (instancetype)_initWithTitle:(NSString *)title
{
    self = [super init];
    if (self)
    {
        _title = [title copy];
    }
    return self;
}

+ (instancetype)toggleButtonItemWithTitle:(NSString *)title
{
    return [[VTToggleButtonItem alloc] _initWithTitle:title];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[VTToggleButtonItem allocWithZone:zone] _initWithTitle:self.title];
}

- (NSUInteger)hash
{
    return self.title.hash;
}

- (BOOL)isEqual:(id)object
{
    VTEqualityPossibleCheck(self, object, VTToggleButtonItem);

    VTToggleButtonItem *other = object;
    return VTObjectReferencePropertiesAreEqual(self, other, _title);
}

@end


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

- (void)setItems:(NSArray<VTToggleButtonItem *> *)items
{
    if (_items != items)
    {
        _items = [items copy];
        _currentItemIndex = 0;
        [self _updateButton];
    }
}

- (VTToggleButtonItem *)currentItem
{
    VTToggleButtonItem *item = nil;
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
    VTToggleButtonItem *currentItem = self.currentItem;
    if (currentItem)
    {
        [self setTitle:currentItem.title forState:UIControlStateNormal];
    }
    else
    {
        [self setTitle:nil forState:UIControlStateNormal];
    }
}

@end
