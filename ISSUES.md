# Features

- Present most recently recorded video for the user, let them decide what to do with that media (save vs share)

- UI handles rotation based on device orientation
    + Allow some UI elements to rotate in place
- Include some text, or animation indicating the direction of movement of the phone based on push VS pull mode. A lot of times people don't know they need to move the phone while recording
- Looping / Preview Mode
    + This might go hand-in-hand with the sharing aspect. That is does the user want to "keep" or "retake" the photo. Once taken, immediately go to "replay" the clip
- Tap to automatic focus and/or lighting adjustment
- Save app state/settings between launches
- Play a start/end recording sound
    + respect the muted setting
- Accessibility
- Social
    + Post straight to Instagram (Ask Tim)
- Front Facing Camera?
- Allow for "reversing" the video to get the opposite of the push/pull effect

# Better UI

- Improve record button
    + Transition animation between recording / waiting modes
- Slider UI
    + Duration and zoom level appear inline with the slider or next to the slider
    + As value changes a magnified value is presented in the center of the screen
- Countdown to recording
    + Improve the coundown animation
    + For push text animates up
    + For pull text animates down
- Progress of the recording 0-100%
    + Place on the bottom
    + Progress bar on the push/pull indicator?
    + Progress bar some place else?
    + Countdown timer of duration?
    + Duration slider converted into progress par?

# Bugs

- address TODO in code
    + Error handling
- If the device is auto focusing, recording doesn't start. if it's in the process of focusing should give some visual feedback
    + Only provide feedback if it's in states leading to recording
- 

# Future Goals / Ideas

- post processing video for effect
- Automatic zoom adjustment based object tracking / phone movement
- Zoom Adjustment?
    + Given anything beyond 2x zoom looks crappy should this even be allowed?