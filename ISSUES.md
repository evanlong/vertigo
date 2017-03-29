# Features

# Bugs

- Start the zoom when we know recording started
    + zoom code triggers on request to start instead of the notification of start
    + should also ensure callback happens on the session queue since we are reading isRampingVideoZoom value
    + Improve observation is setup and torn down
- Refactor VTToggleButtonItem to just be an NSString
