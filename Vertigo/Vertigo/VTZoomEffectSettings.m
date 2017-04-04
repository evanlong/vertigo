//
//  VTZoomEffectSettings.m
//  Vertigo
//
//  Created by Evan Long on 4/3/17.
//
//

#import "VTZoomEffectSettings.h"

@implementation VTZoomEffectSettings
{
@protected
    CGFloat _initalZoomLevel;
    CGFloat _finalZoomLevel;
    NSTimeInterval _duration;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _initalZoomLevel = 1.0;
        _finalZoomLevel = 2.0;
        _duration = 1.0;
    }
    return self;
}

- (instancetype)initWithZoomEffectSettings:(VTZoomEffectSettings *)settings
{
    if (settings)
    {
        self = [self init];
        if (self)
        {
            self->_initalZoomLevel = settings->_initalZoomLevel;
            self->_finalZoomLevel = settings->_finalZoomLevel;
            self->_duration = settings->_duration;
        }
    }
    else
    {
        self = nil;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[VTZoomEffectSettings allocWithZone:zone] initWithZoomEffectSettings:self];
}

-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[VTMutableZoomEffectSettings allocWithZone:zone] initWithZoomEffectSettings:self];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> (initialZoomLevel=%@, finalZoomLevel=%@, duration=%@)",
            NSStringFromClass([self class]),
            self,
            @(self.initalZoomLevel),
            @(self.finalZoomLevel),
            @(self.duration)];
}

@end


@implementation VTMutableZoomEffectSettings

@dynamic initalZoomLevel;
- (void)setInitalZoomLevel:(CGFloat)initalZoomLevel
{
    _initalZoomLevel = initalZoomLevel;
}

@dynamic finalZoomLevel;
- (void)setFinalZoomLevel:(CGFloat)finalZoomLevel
{
    _finalZoomLevel = finalZoomLevel;
}

@dynamic duration;
- (void)setDuration:(NSTimeInterval)duration
{
    _duration = duration;
}

@end
