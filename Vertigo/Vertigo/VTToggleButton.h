//
//  VTToggleButton.h
//  Vertigo
//
//  Created by Evan Long on 3/23/17.
//
//

NS_ASSUME_NONNULL_BEGIN

// VTToggleButton takes an array of items and cycles through those items for each button tap
@interface VTToggleButton : UIButton

// When items array is updated, the current item is reset to the first item
@property (nonatomic, copy) NSArray<NSString *>* items;

// If items array is empty then this will be nil
@property (nonatomic, nullable, readonly, strong) NSString *currentItem;

@end

NS_ASSUME_NONNULL_END
