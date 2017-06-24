# Features

- Sharing and Editing 2.0
    + UI Changes to Save Flow
        * Vertical adjustment slider for zoom editing
            - Animation showing camera movement and zoom level
        * Progress Bar as playback occurs during editing/sharing
    + Cache results of a "process/composite" operation

- Icons
    + Draw arrows with same line weight, but differing total size. Currently things are just the same rotated and scaled to various sizes. Should try and keep weight same for consistency

- UI handles rotation based on device orientation
    + Allow some UI elements to rotate in place

- Info panel
    + Help and tutorials
    + My own video samples
    + YouTube Video samples
    + Info on open source that is used

- Include some text, or animation indicating the direction of movement of the phone based on push VS pull mode. A lot of times people don't know they need to move the phone while recording
- Looping / Preview Mode
    + Sharing currently loops, looping/preview would occur in realtime
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

- Countdown to recording
    + Improve the coundown animation
    + For push text animates up
    + For pull text animates down
- Progress of the recording 0-100%
    + Place on the bottom - Currently how it is done and works well
    + Progress bar on the push/pull indicator?
    + Progress bar some place else?
    + Countdown timer of duration?
    + Duration slider converted into progress par?

# Bugs

- If a podcast or some other media is playing on the device, the sharing screen is blank for a moment
    + Present a screen grab of the first frame of video
- address TODO in code
    + Error handling
- If the device is auto focusing, recording doesn't start. if it's in the process of focusing should give some visual feedback
    + Only provide feedback if it's in states leading to recording

# Future Goals / Ideas

- post processing video for effect
- Automatic zoom adjustment based object tracking / phone movement
- Zoom Adjustment?
    + Given anything beyond 2x zoom looks crappy should this even be allowed?
