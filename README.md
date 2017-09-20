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
