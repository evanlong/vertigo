- AVCaptureSession

inputs and outputs

- Attach them all, and hook up a video output, then need to make a call to "startRecordingToOutputFileURL"
- looks like the session code can happen on a session specific queue
- don't auto rotate when recording active
- AVCaptureMovieFileOutput will be the output
- Handle all session processing on a capture thread, consider creating a view for handling the preview
- rotation should be more seemless...

# Error Handling

- consider application backgrounding to make sure things get written to the file system OK...
    + accepting a phone call?
- Need to look at error handling NSHipster and AV sample code have plenty of both:
    - facetime using camera, permission issues, etc
    - Look in sample and nshipster for the common issues and try and prevent them, provide some reasonable feedback

# Things to investigate

- How do we differentiate between the two camera on the 7plus in the capture devices? 3 including front camera...

