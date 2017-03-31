# Features

- Support for Push and Pull
    + Create object/model for storing state of the settings (push/pull, duration, zoom levels)
- Countdown to recording
    + Include some text, or animation indicating the direction of movement of the phone
- Zoom level adjustment in UI
- Better duration adjustment
    + No more toggle
    + Finer grained duration (0.2 or 0.25 seconds)
- UI handles rotation based on device orientation
    + Allow some UI elements to rotate in place
- Present most recently recorded video for the user, let them decide what to do with that media (save vs share)
- Tap to automatic focus and/or lighting adjustment
- Save app state/settings between launches
- Looping / Preview Mode
- Play a start/end recording sound
    + respect the muted setting
- Accessibility
- Social
    + Post straight to Instagram (Ask Tim)
- Front Facing Camera?

# Bugs

- address TODO in code
    + Error handling
- Crash on Mom's iPad NSRangeException likely because we went beyond videoMaxZoomFactor

# Future Goals / Ideas

- post processing video for effect
- Automatic zoom adjustment based object tracking / phone movement


