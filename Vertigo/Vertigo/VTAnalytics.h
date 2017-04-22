//
//  VTAnalytics.h
//  Vertigo
//
//  Created by Evan Long on 4/22/17.
//
//

#import <HockeySDK/HockeySDK.h>

// Helper Macros
#ifndef VTAnalyticsTrackEvent
    #if DEBUG
        #define VTAnalyticsTrackEvent(event)
    #else
        #define VTAnalyticsTrackEvent(event) [[[BITHockeyManager sharedHockeyManager] metricsManager] trackEventWithName:event];
    #endif
#endif

// App Events
VT_EXTERN NSString *const VTAnalyticsAppDidLaunchEvent;

// Recording Events
VT_EXTERN NSString *const VTAnalyticsDidPressRecordingWhileWaitingEvent;
VT_EXTERN NSString *const VTAnalyticsDidPressRecordingWhileCountingDownEvent;
VT_EXTERN NSString *const VTAnalyticsDidPressRecordingWhileRecordingEvent;
VT_EXTERN NSString *const VTAnalyticsDidStartRecordingEvent;

// Sharing
VT_EXTERN NSString *const VTAnalyticsDidPressShareEvent;
