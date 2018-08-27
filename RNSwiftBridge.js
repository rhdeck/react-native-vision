import { PropTypes } from "prop-types";
import { Component } from "react";
import { NativeModules, requireNativeComponent } from "react-native";
//#region Code for object RHDVisionModule
const NativeRHDVisionModule = NativeModules.RHDVisionModule;
const start = async cameraFront => {
  return await NativeRHDVisionModule.start(cameraFront);
};
const stop = async () => {
  return await NativeRHDVisionModule.stop();
};
const getImageDimensions = async () => {
  return await NativeRHDVisionModule.getImageDimensions();
};
const attachCameraView = async () => {
  return await NativeRHDVisionModule.attachCameraView();
};
const detachCameraView = async () => {
  return await NativeRHDVisionModule.detachCameraView();
};
const cameraIsView = async newIsCameraView => {
  return await NativeRHDVisionModule.cameraIsView(newIsCameraView);
};
const saveFrame = async (disposition, region) => {
  return await NativeRHDVisionModule.saveFrame(disposition, region);
};
const removeSaveFrame = async region => {
  return await NativeRHDVisionModule.removeSaveFrame(region);
};
const detectFaces = async region => {
  return await NativeRHDVisionModule.detectFaces(region);
};
const removeDetectFaces = async region => {
  return await NativeRHDVisionModule.removeDetectFaces(region);
};
const trackObject = async (name, region, dict) => {
  return await NativeRHDVisionModule.trackObject(name, region, dict);
};
const removeTrackObject = async (name, region) => {
  return await NativeRHDVisionModule.removeTrackObject(name, region);
};
const removeTrackObjects = async region => {
  return await NativeRHDVisionModule.removeTrackObjects(region);
};
const applyMLClassifier = async (thisURL, field, resultMax) => {
  return await NativeRHDVisionModule.applyMLClassifier(
    thisURL,
    field,
    resultMax
  );
};
const applyMLGenerator = async (thisURL, field, handler) => {
  return await NativeRHDVisionModule.applyMLGenerator(thisURL, field, handler);
};
const applyMLBottleneck = async (thisURL, field) => {
  return await NativeRHDVisionModule.applyMLBottleneck(thisURL, field);
};
const applyMLGeneric = async (thisURL, field) => {
  return await NativeRHDVisionModule.applyMLGeneric(thisURL, field);
};
const removeML = async (thisURL, field) => {
  return await NativeRHDVisionModule.removeML(thisURL, field);
};
const applyBottleneckClassifier = async (
  thisURL,
  toField,
  toModel,
  maxResults
) => {
  return await NativeRHDVisionModule.applyBottleneckClassifier(
    thisURL,
    toField,
    toModel,
    maxResults
  );
};
const applyBottleneckGenerator = async (thisURL, handler, toField, toModel) => {
  return await NativeRHDVisionModule.applyBottleneckGenerator(
    thisURL,
    handler,
    toField,
    toModel
  );
};
const applyBottleneckBottleneck = async (thisURL, toField, toModel) => {
  return await NativeRHDVisionModule.applyBottleneckBottleneck(
    thisURL,
    toField,
    toModel
  );
};
const applyBottleneckGeneric = async (thisURL, toField, toModel) => {
  return await NativeRHDVisionModule.applyBottleneckGeneric(
    thisURL,
    toField,
    toModel
  );
};
const removeBottleneck = async (modelURL, fromField, fromModel) => {
  return await NativeRHDVisionModule.removeBottleneck(
    modelURL,
    fromField,
    fromModel
  );
};
const removeBottlenecks = async (fromField, fromModel) => {
  return await NativeRHDVisionModule.removeBottlenecks(fromField, fromModel);
};
const setRegion = async (region, rectDic) => {
  return await NativeRHDVisionModule.setRegion(region, rectDic);
};
const removeRegion = async region => {
  return await NativeRHDVisionModule.removeRegion(region);
};
const saveMultiArray = async key => {
  return await NativeRHDVisionModule.saveMultiArray(key);
};
//#endregion
const NativeRHDVisionImageView = requireNativeComponent(
  "RHDVisionImageView",
  SwiftRHDVisionImageView
);
class SwiftRHDVisionImageView extends Component {
  render() {
    return <NativeRHDVisionImageView {...props} />;
  }
}
SwiftRHDVisionImageView.propTypes = {
  isMirrored: PropTypes.boolean,
  resizeMode: PropTypes.string,
  id: PropTypes.string
};
const NativeRHDVisionCameraView = requireNativeComponent(
  "RHDVisionCameraView",
  SwiftRHDVisionCameraView
);
class SwiftRHDVisionCameraView extends Component {
  render() {
    return <NativeRHDVisionCameraView {...props} />;
  }
}
SwiftRHDVisionCameraView.propTypes = {
  gravity: PropTypes.string
};
//#region Exports
export {
  start,
  stop,
  getImageDimensions,
  attachCameraView,
  detachCameraView,
  cameraIsView,
  saveFrame,
  removeSaveFrame,
  detectFaces,
  removeDetectFaces,
  trackObject,
  removeTrackObject,
  removeTrackObjects,
  applyMLClassifier,
  applyMLGenerator,
  applyMLBottleneck,
  applyMLGeneric,
  removeML,
  applyBottleneckClassifier,
  applyBottleneckGenerator,
  applyBottleneckBottleneck,
  applyBottleneckGeneric,
  removeBottleneck,
  removeBottlenecks,
  setRegion,
  removeRegion,
  saveMultiArray,
  SwiftRHDVisionImageView,
  SwiftRHDVisionCameraView
};
//#endregion
