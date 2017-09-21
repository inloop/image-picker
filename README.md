# Image Picker

An easy to use drop-in framework for quickly accessing images and camera

## Permissions

App must have in info plist permissions for:

- NSPhotoLibraryUsageDescription - for displaying photos in picker
- NSCameraUsageDescription - for taking pictures
- NSMicrophoneUsageDescription - for recording videos with audio track

## Features to add

1. landscape layout for camera cell - video is already in landscape but cell must be wider to properly display it
2. [ok] flip cameras
3. [ok] blur/unblur camera cell video layer when capture session is suspended/unsuspended
4. blur/unblur camera cell video layer when capture session is interrupted, failed or app goes to background/unactive
5. add public API for recording videos
6. add public API for enabling/disabling live photos
7. add public API for setting if taken pictures should be saved in camera roll or just directly provided through delegate

## Known Issues

1. autorotate to landsacpe on iPhone X does not work properly - safe area is not updated so layout is broken
2. live photos does not work - it says device does not support live photos event thought all shold be set correctly (does not work on SE nor iPhone 7)
3. [partly fixed] flipping camera animation is flickering, I could not find a proper way how to achieve nice animation with blurred content, I tried following solutions:
    1. adding UIVisualEffectsView as subview of camera output but it's flickering when camera goes black on a while
    2. taking screenshot of AVVideoPreviewLayer is not possible - it returns transparent empty image
    used solution: use image buffer from AVVideoCaptureOutupt, blur it and add it as subview to the cell
4. when camera cell will be blurred first time it lags - need to use instruments to find out why it's lagging
    reproduce: simple scroll camera cell so it's not visible, you will notice a lag (iPhone SE)
5. when rotating device, there is a little lag in video when changing orientation of outputs - it should be smooth though
6. when flipping from front camera to back camera, latest sample buffer image that is used does not have proper transform, you can see that it is rotated horizontally so it creates unpleasant effect durring unblur animation when flipping cameras
