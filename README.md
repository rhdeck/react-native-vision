# react-native-vision

Library for accessing VisionKit and visual applications of CoreML from React Native. **iOS Only**

Incredibly super-alpha, and endeavors to provide a relatively thin wrapper between the underlying vision functionality and RN. Higher-level abstractions are @TODO and will be in a separate library.

# Installation

```
yarn add react-native-vision react-native-swift
react-native link
```

**Note** `react-native-swift` is a peer dependency of `react-native-vision`.

# Reference

the package exports a number of components

## RNVisionProvider

Context provider for information captured from the camera. Allows the use of regional detection methods to initialize identification of objects in the frame.

### Props

- `isStarted`: Whether the camera should be activated for vision capture. Boolean
- `isCameraFront`: Facing of the camera. False for the back camera, true to use the front. _Note_ only one camera facing can be used at a time. As of now, this is a hardware limitation.
- `regions`: Specified regions on the camera capture frame articulated as `{x,y,width,height}` that should always be returned by the consumer
- `trackedObjects`: Specified regions that should be tracked as objects, so that the regions returned match these object IDs and show current position.
- `onRegionsChanged`: Fires when the list of regions has been altered
- `onDetectedFaces`: Fires when the number of detected faces has changed

### Class imperative member

- `detectFaces`: Triggers one call to detect faces based on current active frame. Directly returns locations.

## RNVisionConsumer

Consumer partner of `RNVisionProvider`. Must be its descendant in the node tree.

### Render Prop Members

- `imageDimensions`: Object representing size of the camera frame in `{width, height}`
- `isCameraFront`: Relaying whether camera is currently in selfie mode. This is important if you plan on displaying camera output, because in selfie mode a preview will be mirrored.
- `regions`: The list of detected rectangles in the most recently captured frame, where detection is driven by the `RNVisionProvider` props

## RNVRegion

### Props

- `region`: ID of the region
- `classifiers`: CoreML classifiers passed as file URLs to the classifier mlmodelc itself. Array
- `generators`: CoreML image generators passed as file URLs to the classifier mlmodelc itself. Array
- `generators`: CoreML models that generate a collection of output values passed as file URLs to the classifier mlmodelc itself.
- `bottlenecks`: A collection of CoreML models that take other CoreML model outputs as their inputs. Keys are the file URLs of the original models (that take an image as their input) and values are arrays of mdoels that generate the output passed via render props.
- `onFrameCaptured`: Callback to fire when a new image of the current frame in this region has been captured. Making non-null activates frame capture, setting to null turns it off. The callback passes a URL of the saved frame image file.

### Render Prop members

- `key`: ID of the region
- `frame`: Collection containing `{x, y, width, height}` of the frame containing the region. All values expressed as percentages of the overall frame size, so a 50x100 frame at origin 5,10 in a 500x500 frame would come across as `{x: 0.01, y: 0.02, width: .1, height: .2}`. Changes in this value are often what drives the re-render of the component (and therefore re-run of the render prop)
- `confidence`: If set, the confidence that the object identified as `key` is actually at this location. Used by tracked objects API of iOS Vision. Sometimes null.
- `classifications`: Collection, keyed by the file URL of the classifier passed in props, of collections of labels and probabilities. (e.g. `{"file:///path/to/myclassifier.mlmodelc": {"label1": 0.84, "label2": 0.84}}`)
- `genericResults`: Collection of generic results returned from generic models passed in via props to the region

## RNVCameraView

Preview of the camera captured by the `RNVisionProvider`.
**Note** that the preview is flipped in selfie mode (e.g. when `isCameraFront` is true)

### Props

The properties of a `View` plus:

- `gravity`: how to scale the captured camera frame in the view. String. Valid values:
  - `fill`: Fills the rectangle much like the "cover" in an Image
  - `resize`: Leaves transparent (or style:{backgroundColor}) the parts of the rectangle that are left over from a resized version of the image.

## RNVCameraConsumer

Render prop consumer for delivering additional context that regions will find helpful, mostly for rendering rectangles that map to the regions identified.

### Render Prop Members

- `viewPortDimensions`: A collection of `{width, height}` of the view rectangle.
- `viewPortGravity`: A pass-through of the `gravity` prop to help decide how to manage the math converting coordinates.

## RNVCameraRegion

A compound consumer that blends the render prop members of `RNVRegion` and `RNVCameraConsumer` and adds a `style` prop that can position the region on a specified camera preview

### Props

Same as `RNVRegion`

### Render Prop Members

Includes members from `RNVRegion` and `RNVCameraConsumer` and adds:

- `style`: A pre-built colleciton of style prop members `{position, width, height, left, top}` that are designed to act in the context of the `RNVCameraView` rectangle. Spread-prop with your other style preferences (border? backgroundColor?) for easy on-screen representation.

## RNVImageView

View for displaying output of image generators. Link it to , and the resulting image will display in this view. Useful for style transfer models. More performant because there is no round trip to JavaScript notifying of each frame update.

### Props

- `id`: the ID of an image generator model attached to a region. Usually is the `file:///` URL of the .mlmodelc.

Otherwise conforms to Image and View API.
