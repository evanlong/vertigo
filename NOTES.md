- AVCaptureSession

inputs and outputs

- Think of a "connection" as a "stream" of data
- Attach them all, and hook up a video output, then need to make a call to "startRecordingToOutputFileURL"
- looks like the session code can happen on a session specific queue
- don't auto rotate when recording active
- AVCaptureMovieFileOutput will be the output
- Handle all session processing on a capture thread, consider creating a view for handling the preview
- rotation should be more seemless...
- observers related to interruption

# Error Handling

- Consider application backgrounding to make sure things get written to the file system OK...
    + accepting a phone call?
- Need to look at error handling NSHipster and AV sample code have plenty of both:
    - facetime using camera, permission issues, etc
    - Look in sample and nshipster for the common issues and try and prevent them, provide some reasonable feedback

# Things to Investigate

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
    + resolved: don't clip to bounds on the view when rotating
- output content to a file
- save to camera roll

- !!! feedback that recording is taking place, UI control overlay

- Handle AV Session code on seperate queue since it could be blocking
    - UI isn't enabled until it is "ready"

- Model / Controls describing effect, pass model off to something to perform the recording using config and recorder
- Don't take up whole screen with preview layer, or at least learn limits of the various scaling of this layer
    + sessionPreset can change "size" of what's output. But the layer is really a presentation of what will be captured. Resizing the view/layer causes the realtime video output of camera to be rerendered
- Improvements
    + which input device to use etc...
    + audio / video. video required, audio optional with ability to mute!
- iOS Gotchas
    - User denies photo library permission. Need to provide UI to delete / share video in some other way?
    -  errors and interruptions (see AV sample code)
    -  background mode to complete and save the recording if home button is pressed etc...
    -  Audio / Video permissions
    -  Device rotation while recording
    -  dynamic fonts size changes
    -  running on iPad with multiple app mode
        +  Info.plist - UIRequiresFullScreen => YES

# Features

- Video explorer when they deny photo access. When video is taken, provide a way to save off or share at that moment, if they don't the video will just be deleted, which seems fine given ephemeral nature of the app


# Next to investigate

- AVCaptureSession and app background and resume...
    + I don't think viewDidAppear and disappear get called for app backgrounding



Recorder object
UI state while recording 
Experiment with ramp vs display link maybe or timers on main queue.  Yuck

Recorder would not expose a view but the session performing the recording. The recorder should take care of threading and dispatch to main queue or to an arbitrary queue and let owner or delegate get back to main queue 

The ramping up and down code of the recorder wouldn't need to depend on actual AV items just some protocol to them...

Able to perform the camera manip without recording

Ability to test output it produces without AV objects involved

startRecordingWithSettings...
    - orientation
    - duration
    - push/pull etc...

- experiment with the ramping zoom effect on capture session (might *just* work as I need it too)


