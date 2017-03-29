//
//  HFKVOBlocks.h
//
//  Created by Evan Long on 9/14/14.
//

NS_ASSUME_NONNULL_BEGIN

typedef void(^HFObserverBlock)(id object, NSDictionary *change);

@interface NSObject (KVOBlocks)

// returns token that can be used with hf_removeBlockObserverWithToken:
- (id)hf_addBlockObserver:(HFObserverBlock)block forKeyPath:(NSString *)keyPath;

// It's not required to call this. Dealloc will take care of it
- (void)hf_removeBlockObserverWithToken:(id)token;

@end

NS_ASSUME_NONNULL_END
