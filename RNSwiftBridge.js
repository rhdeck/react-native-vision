import { PropTypes } from "prop-types";
import React, { Component } from "react";
import {
  NativeModules,
  NativeEventEmitter,
  requireNativeComponent,
  ViewPropTypes
} from "react-native";
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
//#region events for object RHDVisionModule
var _getNativeRHDVisionModuleEventEmitter = null;
const getNativeRHDVisionModuleEventEmitter = () => {
  if (!_getNativeRHDVisionModuleEventEmitter)
    _getNativeRHDVisionModuleEventEmitter = new NativeEventEmitter(
      NativeRHDVisionModule
    );
  return _getNativeRHDVisionModuleEventEmitter;
};
const subscribeToRNVision = cb => {
  return getNativeRHDVisionModuleEventEmitter().addListener("RNVision", cb);
};
const subscribeToRNVMetaData = cb => {
  return getNativeRHDVisionModuleEventEmitter().addListener("RNVMetaData", cb);
};
const subscribeToRNVisionImageDim = cb => {
  return getNativeRHDVisionModuleEventEmitter().addListener(
    "RNVisionImageDim",
    cb
  );
};
//#endregion
//#region constants for object RHDVisionModule
const bundlePath = NativeRHDVisionModule.bundlePath;
const bundleURL = NativeRHDVisionModule.bundleURL;
//#endregion
const NativeRHDVisionImageView = requireNativeComponent(
  "RHDVisionImageView",
  RHDVisionImageView
);
class RHDVisionImageView extends Component {
  render() {
    return <NativeRHDVisionImageView {...this.props} />;
  }
}
RHDVisionImageView.propTypes = {
  isMirrored: PropTypes.bool,
  resizeMode: PropTypes.string,
  id: PropTypes.string,
  ...ViewPropTypes
};
const NativeRHDVisionCameraView = requireNativeComponent(
  "RHDVisionCameraView",
  RHDVisionCameraView
);
class RHDVisionCameraView extends Component {
  render() {
    return <NativeRHDVisionCameraView {...this.props} />;
  }
}
RHDVisionCameraView.propTypes = {
  gravity: PropTypes.string,
  ...ViewPropTypes
};
//#region Event marshalling object
const RNSEvents = {
  RNVision: subscribeToRNVision,
  RNVMetaData: subscribeToRNVMetaData,
  RNVisionImageDim: subscribeToRNVisionImageDim
};
//#endregion
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
  subscribeToRNVision,
  subscribeToRNVMetaData,
  subscribeToRNVisionImageDim,
  bundlePath,
  bundleURL,
  RHDVisionImageView,
  RHDVisionCameraView,
  RNSEvents
};
//#endregion
