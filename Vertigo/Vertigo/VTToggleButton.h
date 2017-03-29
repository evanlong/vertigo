//
//  VTToggleButton.h
//  Vertigo
//
//  Created by Evan Long on 3/23/17.
//
//

NS_ASSUME_NONNULL_BEGIN

// EL TODO: Maybe refactor the item to just be a string for now...

// VTToggleButtonItem represents toggled state for the VTToggleButton
@interface VTToggleButtonItem : NSObject <NSCopying>

+ (instancetype)toggleButtonItemWithTitle:(NSString *)title;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly, copy) NSString *title;

@end

// VTToggleButton takes an array of items and cycles through those items for each button tap
@interface VTToggleButton : UIButton

// When items array is updated, the current item is reset to the first item
@property (nonatomic, copy) NSArray<VTToggleButtonItem *>* items;

// If items array is empty then this will be nil
@property (nonatomic, nullable, readonly, strong) VTToggleButtonItem *currentItem;

@end

NS_ASSUME_NONNULL_END
