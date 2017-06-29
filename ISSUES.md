# Features

- zoom level y-position issue wrong bug when rotating
    + also, why does duration version animate on rotating, that this was doesn't seem too?
    + Seems maybe related to the _controlHostView

- Sharing and Editing 2.0
    + UI Changes to Save Flow
        * Vertical adjustment slider for zoom editing
            - Animation showing camera movement and zoom level
                + Try and all white varient instead of the colorized version
                - Don't animate in middle position of slider. Just leave in static position
            - Tapping the slider up/down arrows indicators should trigger fine grained adjustments
            - Display start->end zoom level that the editing slider is adjusting
    + As slider drags, display the first / final frames and relative zoom adjustments that are takin gplace
    + Cache results of a "process/composite" operation
    + Improve Transtion TO sharing screen and FROM sharing screen


- Info Button / Panel
    + On each screen consider overlaying a help, tip sheet
    + More detailed popup showing:
        + Help and tutorials
        + My own video samples
        + YouTube Video samples
        + Info on open source that is used

- UI handles rotation based on device orientation
    + Allow some UI elements to rotate in place

- Icons
    + Draw arrows with same line weight, but differing total size. Currently things are just the same rotated and scaled to various sizes. Should try and keep weight same for consistency

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
