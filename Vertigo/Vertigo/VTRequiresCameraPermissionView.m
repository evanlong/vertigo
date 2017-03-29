//
//  VTRequiresCameraPermissionView.m
//  Vertigo
//
//  Created by Evan Long on 3/21/17.
//
//

#import "VTRequiresCameraPermissionView.h"

#import "VTMath.h"

static const CGFloat VTRequiresCameraPermissionViewTextPadding = 10.0;

@interface VTRequiresCameraPermissionView ()

@property (nonatomic, strong) UILabel *requirePermissionLabel;
@property (nonatomic, strong) UIButton *openSettingsButton;

@end

@implementation VTRequiresCameraPermissionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];

        _requirePermissionLabel = [[UILabel alloc] init];
        VTAllowAutolayoutForView(_requirePermissionLabel);
        _requirePermissionLabel.numberOfLines = 0;
        _requirePermissionLabel.textAlignment = NSTextAlignmentCenter;
        _requirePermissionLabel.text = NSLocalizedString(@"RequiresCameraPermission", nil);
        [self addSubview:_requirePermissionLabel];
        
        _openSettingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        VTAllowAutolayoutForView(_openSettingsButton);
        _openSettingsButton.titleLabel.numberOfLines = 0;
        _openSettingsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_openSettingsButton setTitle:NSLocalizedString(@"RequiresCameraPermissionTapHere", nil) forState:UIControlStateNormal];
        [_openSettingsButton addTarget:self action:@selector(_handleTapToSettings) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_openSettingsButton];

        [self _updateLabelFonts];
        
        [_requirePermissionLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_requirePermissionLabel.bottomAnchor constraintEqualToAnchor:self.centerYAnchor constant:-VTRequiresCameraPermissionViewTextPadding].active = YES;
        [_requirePermissionLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.90].active = YES;
        
        [_openSettingsButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_openSettingsButton.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:VTRequiresCameraPermissionViewTextPadding].active = YES;
        [_openSettingsButton.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.90].active = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleContentSizeChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

#pragma mark - Notifications

- (void)_handleContentSizeChange:(NSNotification *)notification
{
    [self _updateLabelFonts];
}

#pragma mark - Events

- (void)_handleTapToSettings
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:NULL];
}

#pragma mark - Private

- (void)_updateLabelFonts
{
    self.requirePermissionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.openSettingsButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

@end
