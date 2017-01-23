- AVCaptureSession

inputs and outputs

- Attach them all, and hook up a video output, then need to make a call to "startRecordingToOutputFileURL"
- looks like the session code can happen on a session specific queue
- don't auto rotate when recording active
- AVCaptureMovieFileOutput will be the output
- Handle all session processing on a capture thread, consider creating a view for handling the preview
- rotation should be more seemless...
- observers related to interruption

# Error Handling

- consider application backgrounding to make sure things get written to the file system OK...
    + accepting a phone call?
- Need to look at error handling NSHipster and AV sample code have plenty of both:
    - facetime using camera, permission issues, etc
    - Look in sample and nshipster for the common issues and try and prevent them, provide some reasonable feedback

# Things to investigate

- How do we differentiate between the two camera on the 7plus in the capture devices? 3 including front camera...

# Methods

- Looping Mode
- Manual setting of:
    + Min/Max Zoom
    + Push OR Pull
    + Time
    + Zoom Curve

- CaptureConfig object when "run" can send output to another object that implements a protocol so we can test it with command line easily enough, without AVFoundation code getting in the way. Concrete implementation could use

# Issues

- Rotation with preview layer
    + don't clip to bounds on the view when rotating
- output content to a file
- save to camera roll
>> - feedback that recording is taking place, UI control overlay
- Model / Controls describing effect, pass model off to something to perform the recording using config and recorder
- Don't take up whole screen with preview layer, or at least learn limits of the various scaling of this layer
- Improvements
    + which input device to use etc...
    + audio / video. video required, audio optional with ability to mute!
- iOS Gotchas
    - User denies photo library permission. Need to provide UI to delete / share video in some other way?
    -  errors and interruptions (see AV sample code)
    -  background mode to complete and save the recording if home button is pressed etc...
    -  Audio / Video permissions
    -  Device rotation while recording
    -  dynamic fonts
    -  running on iPad with multiple app mode
        +  Info.plist - UIRequiresFullScreen => YES

# Features

- Video explorer when they deny photo access. When video is taken, provide a way to save off or share at that moment, if they don't the video will just be deleted, which seems fine given ephemeral nature of the app
- 
