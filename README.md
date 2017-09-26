# Image Picker

An easy to use drop-in framework for quickly accessing images and camera

## Permissions

App must have in info plist permissions for:

- NSPhotoLibraryUsageDescription - for displaying photos in picker
- NSCameraUsageDescription - for taking pictures
- NSMicrophoneUsageDescription - for recording videos with audio track

## Styling

Image picker view hierarchy contains of `UICollectionView` and an overlay view. Collection view has all cells provided by user and overlay view is asked by datasource when needed, so it's users responsibility to style her views. However, few style attributes are supported such as background color. Please use custom appearance mechanism to achieve desired styling.

1. to style all image pickers globally use global appearance proxy object:

```
ImagePickerController.appearance().backgroundColor = UIColor.black
```

1. to style a particular instance of image picker use instances appearance proxy object:

```
let vc = ImagePickerController()
vc.appearance().backgroundColor = UIColor.black
```

For default styling attributes and more info please refer to public interface of `Appearance` class.

Please note that UIKit's appearance proxy is not currently supported.

## Features to add

1. landscape layout for camera cell - video is already in landscape but cell must be wider to properly display it
2. [ok] flip cameras
3. [ok] blur/unblur camera cell video layer when capture session is suspended/unsuspended
4. [ok] blur/unblur camera cell video layer when capture session is interrupted, failed or app goes to background/unactive
5. add public API for recording videos
6. [ok] add public API for enabling/disabling live photos
7. [ok] add public API for setting if taken pictures should be saved in camera roll or just directly provided through delegate
8. when user denies access to camera, don't show camera cell or show that access is denied
9. implement image pre-caching based on visible rectangle bounds
10. [ok] add default features for base CameraCollectionViewCell - tap to take photo
11. [ok] support styling through appearance

## Known Issues

1. autorotate to landsacpe on iPhone X does not work properly - safe area is not updated so layout is broken
2. [fixex] live photos does not work - it says device does not support live photos event thought all shold be set correctly (does not work on SE nor iPhone 7) -> this is because session preset is to video, see comments in code to fix it
3. [fixed] flipping camera animation is flickering, I could not find a proper way how to achieve nice animation with blurred content, I tried following solutions:
    1. adding UIVisualEffectsView as subview of camera output but it's flickering when camera goes black on a while
    2. taking screenshot of AVVideoPreviewLayer is not possible - it returns transparent empty image
    used solution: use image buffer from AVVideoCaptureOutupt, blur it and add it as subview to the cell
    TODO: need to transform image from front camera horizontally - it's mirrored so the blurring effect is not 100% nice when flipping camera
4. when camera cell will be blurred first time it lags - need to use instruments to find out why it's lagging
    reproduce: simple scroll camera cell so it's not visible, you will notice a lag (iPhone SE), this lag might be caused by Photos framework when loading first buch of images
5. when rotating device, there is a little lag in video when changing orientation of outputs - it should be smooth though
6. [fixed] when flipping from front camera to back camera, latest sample buffer image that is used does not have proper transform, you can see that it is rotated horizontally so it creates unpleasant effect durring unblur animation when flipping cameras
7. when user defines layout configuration without camera - image picker still initializes capture session wich asks for permissions, crashes if no privacy key in info.plist is set and this is all not necessary 

## Technologies used

1. UICollectionView - for laying out views, we decided to use regular horizontal flow layout with implemented flow delegate. Nicer solution in terms of clean code would be to use custom layout, but most of the flow layout would have to be replicated.
2. AVCaptureSession - for capturing video on input and output. At first we tried to exploit UIImagePickerController, however apart from it's hacky, there were 3 problems with this solution:
    1. presenting image picker was causing a lag that was not possible to remove
    2. video output view was not rotating properly when interface was rotating and there was no API to rotate it manually
    3. when video output is not more visible on screen (user scrolled elsewhere) there was no API to resume/suspend the capture session and that is wasting resources
3. By using custom capture session instead of using existing UIImagePickerController we gained much of flexibility, but on the other side we had to reimplement many features such us:
    1. bluring / unbluring video output when capture session is suspended / resumed - to achieve this we used latest frame from sample buffer and added is as blurred UIImageView subview. To collect recent frame from sample buffer we had to implement custom video data output and remember latest frame from the buffer. This is then converted to UIImage and used with the visual effect view.
    2. flipping front / rear camera - we use method similar to mentioned in point 1.
    
