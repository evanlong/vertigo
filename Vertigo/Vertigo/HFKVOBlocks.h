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

// It is not required to call this. The observed instances's dealloc will remove observers automatically.
// It is still useful to remove observers, when the lifetime of the observer, is shorter than the object
// being observed
- (void)hf_removeBlockObserverWithToken:(nullable id)token;

@end

NS_ASSUME_NONNULL_END
