# Image Picker

An easy to use drop-in framework for quickly accessing images and camera

## Permissions

App must have in info plist permissions for:

- NSPhotoLibraryUsageDescription - for displaying photos in picker
- NSCameraUsageDescription - for taking pictures
- NSMicrophoneUsageDescription - for recording videos with audio track

## Features to add

1. landscape layout for camera cell - video is already in landscape but cell must be wider to properly display it
2. flip cameras
3. blur/unblur camera cell video layer when capture session is suspended/unsuspended
4. add public API for recording videos
5. add public API for enabling/disabling live photos
6. add public API for setting if taken pictures should be saved in camera roll or just directly provided through delegate

## Known Issues

1. autorotate to landsacpe on iPhone X does not work properly - safe area is not updated so layout is broken
2. live photos does not work - it says device does not support live photos event thought all shold be set correctly (does not work on SE nor iPhone 7)
3. flipping camera animation is flickering, I could not find a proper way how to achieve nice animation with blurred content, I tried following solutions:
    1. adding UIVisualEffectsView as subview of camera output but it's flickering when camera goes black on a while
    2. taking screenshot of AVVideoPreviewLayer is not possible - it returns transparent empty image
    possible solution: use image buffer from AVVideoCaptureOutupt, blur it and add it as subview
