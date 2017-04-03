//
//  HFKVOBlocks.m
//
//  Created by Evan Long on 9/14/14.
//

#import "HFKVOBlocks.h"

#import <objc/runtime.h>

@interface _HFLocalObserver : NSObject
// When the object being observed is sent a dealloc message it zeros out ARC weak pointers before it removes associated objects.
// A weak target would be nil when we try to remove KVO info from it even though the observed object hasn't
// been fully deallocated (freed) yet.
@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong) id token;
@property (nonatomic, copy) HFObserverBlock block;
- (void)startObservation;
@end

static void *HFObserverContext = &HFObserverContext;
@implementation _HFLocalObserver

- (void)startObservation
{
    [self.target addObserver:self forKeyPath:self.keyPath options:0 context:HFObserverContext];
}

- (void)dealloc
{
    [_target removeObserver:self forKeyPath:self.keyPath context:HFObserverContext];
    _target = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // single object per observer this should always be true
    if (context == HFObserverContext)
    {
        if (self.block)
        {
            self.block(object, change);
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end


@implementation NSObject (KVOBlocks)

- (id)hf_addBlockObserver:(HFObserverBlock)block forKeyPath:(NSString *)keyPath
{
    // Create a new observer
    id token = [[NSUUID UUID] UUIDString];
    
    _HFLocalObserver *observer = [[_HFLocalObserver alloc] init];
    observer.token = token; // hold token strongly so we can use it as the associated object key otherwise it might get dealloced and the address reused
    observer.block = block;
    observer.keyPath = keyPath;
    observer.target = self;
    objc_setAssociatedObject(self, (__bridge void*)token, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [observer startObservation];
    
    return token;
}

- (void)hf_removeBlockObserverWithToken:(id)token
{
    if (token)
    {
        objc_setAssociatedObject(self, (__bridge void*)token, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
