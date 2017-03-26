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
        VTAllowAutolayoutForView(self.requirePermissionLabel);
        self.requirePermissionLabel.numberOfLines = 0;
        self.requirePermissionLabel.textAlignment = NSTextAlignmentCenter;
        self.requirePermissionLabel.text = NSLocalizedString(@"RequiresCameraPermission", nil);
        [self addSubview:self.requirePermissionLabel];
        
        _openSettingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        VTAllowAutolayoutForView(self.openSettingsButton);
        self.openSettingsButton.titleLabel.numberOfLines = 0;
        self.openSettingsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.openSettingsButton setTitle:NSLocalizedString(@"RequiresCameraPermissionTapHere", nil) forState:UIControlStateNormal];
        [self.openSettingsButton addTarget:self action:@selector(_handleTapToSettings) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.openSettingsButton];

        [self _updateLabelFonts];
        
        [self.requirePermissionLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [self.requirePermissionLabel.bottomAnchor constraintEqualToAnchor:self.centerYAnchor constant:-VTRequiresCameraPermissionViewTextPadding].active = YES;
        [self.requirePermissionLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.90].active = YES;
        
        [self.openSettingsButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [self.openSettingsButton.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:VTRequiresCameraPermissionViewTextPadding].active = YES;
        [self.openSettingsButton.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.90].active = YES;

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
