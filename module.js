import { NativeModules, NativeEventEmitter } from "react-native";
const RNVNative = NativeModules.RHDVisionModule;
//#region Event Management
var cachedEmitter = null;
const getEmitter = () => {
  if (!cachedEmitter) {
    cachedEmitter = new NativeEventEmitter(RNVNative);
  }
  return cachedEmitter;
};
var cachedListener = null;
const addListener = (region, key, cb) => {
  const newKey = region + "_" + key;
  if (!cachedListener) {
    cachedListener = getEmitter().addListener("RNVision", masterHandler);
  }
  cachedHandlers[newKey] = cb;
};
const masterHandler = body => {
  const region = String(body["region"]);
  const thisKey = String(body["key"]);
  const key = region + "_" + thisKey;
  if (typeof cachedHandlers[key] == "function") {
    cachedHandlers[key](body);
  } else {
    console.log("NO handler for ", key, region, thisKey);
  }
};
var cachedHandlers = {};
const removeListener = (region, key) => {
  const newKey = String(region) + "_" + String(key);
  delete cachedHandlers[newKey];
};
//#endregion
//#region Lifecycle management
const start = async cameraFront => {
  return await RNVNative.start(cameraFront);
};
const stop = async () => {
  cachedHandlers = {};
  cachedListener.remove();
  cachedEmitter = null;
  return await RNVNative.stop();
};
const attachCameraView = async () => {
  return await RNVNative.attachCameraView();
};
const isCameraFrame = async isTrue => {
  return await RNVNative.isCameraView(isTrue);
};
const getImageDimensions = async () => {
  return await RNVNative.getImageDimensions();
};
//#endregion
//#region Save Frame
const saveFrame = async (region, disposition, callback) => {
  //Add a listener
  addListener(region, "saveFrame", callback);
  return await RNVNative.saveFrame(disposition, region);
};
const removeSaveFrame = async region => {
  removeListener(region, "saveFrame");
  return await RNVNative.removeSaveFrame(region);
};
const saveFrameOnce = (region, disposition) => {
  return new Promise((resolve, reject) => {
    saveFrame(region, disposition, async body => {
      await removeSaveFrame(region);

      return body;
    });
  });
};
//#endregion
//#region Face Detection
var regionFaceKeys = {};
const detectFaces = async (region, handler) => {
  const key = await RNVNative.detectFaces(region);
  addListener(region, key, body => {
    return handler(body.data);
  });
  regionFaceKeys[region] = key;
  return key;
};
const removeDetectFaces = async region => {
  removeListener(region, regionFaceKeys[region]);
  return await RNVNative.removeDetectFaces(region);
};
const detectFacesOnce = region => {
  return new Promise((resolve, reject) => {
    detectFaces(region, body => {
      removeDetectFaces(region);
      resolve(body);
    });
  });
};
//#endregion
//#region Object Tracking
var boxHandlers = {};
var boxListener = null;
const trackObject = async (region, name, boxDictionary, callback) => {
  if ((await RNVNative.trackObject(name, region, boxDictionary)) !== null) {
    addListener(region, name, callback);
    return true;
  } else return false;
};
const removeTrackObject = async (region, name) => {
  removeListener(region, name);
  return await RNVNative.removeTrackObject(name, region);
};
const removeTrackObjects = async region => {
  const data = await RNVNative.removeTrackObjects(region);
  if (data.removedKeys) {
    data.removedKeys.forEach(removedKey => {
      removeListener(removedKey);
    });
  }
  return true;
};
//#endregion
//#region Region Management
const setRegion = async (region, rectangle) => {
  return await RNVNative.setRegion(region, rectangle);
};
const removeRegion = async region => {
  return await RNVNative.removeRegion(region);
};
//#endregion
//#region Machine Learning Models
const applyMLClassifier = async (
  region,
  modelURL,
  maxResults,
  callback = null
) => {
  if (typeof maxResults == "function") {
    callback = maxResults;
    maxResults = 5;
  }
  const key = await RNVNative.applyMLClassifier(modelURL, region, maxResults);
  if (key) {
    addListener(key, body => {
      callback(body.data);
    });
  }
  return await RNVNative.applyMLClassifier(modelURL, maxResults);
};
const applyMLClassifierOnce = (region, modelURL, maxResults) => {
  return new Promise((resolve, reject) => {
    applyMLClassifier(region, modelURL, maxResults, body => {
      removeML(region, modelURL);
      resolve(body);
    });
  });
};
const applyMLGenerator = async (region, modelURL, handlerOrCallback) => {
  const handler =
    typeof handlerOrCallback == "function" ? "sendEvent" : handlerOrCallback;
  const key = await RNVNative.applyMLGenerator(modelURL, region, handler);
  if (key && handler == "sendEvent") {
    addListener(region, key, callback);
  }
};
const applyMLBottleneck = async modelURL => {
  return await RNVNative.applyMLBottleneck(modelURL);
};
const applyMLGeneric = async (region, modelURL, callback) => {
  const key = await RNVNative.applyMLGeneric(modelURL, region);
  if (key) {
    addListener(region, key, body => {
      callback(body.data);
    });
  }
};
const applyMLGenericOnce = (region, modelURL) => {
  return new Promise((resolve, reject) => {
    applyMLGeneric(region, modelURL, body => {
      removeML(region, modelURL);
      resolve(body);
    });
  });
};
const removeML = async (region, modelURL) => {
  removeListener(region, modelURL);
  return await RNVNative.removeML(modelURL, region);
};
//#endregion
//#region ML Bottlenecks
const REGION_ALL = "";
const applyBottleneckClassifier = async (
  modelURL,
  region,
  toModelURL,
  maxResults,
  callback = null
) => {
  if (typeof maxResults == "function") {
    callback = maxResults;
    maxResults = 5;
  }
  const key = await RNVNative.applyBottleneckClassifier(
    modelURL,
    region,
    toModelURL,
    maxResults
  );
  if (key) {
    addListener(key, body => {
      callback(body.data);
    });
  }
};
const applyBottleneckGenerator = async (
  modelURL,
  region,
  toModelURL,
  handlerOrCallback
) => {
  const handler =
    typeof handlerOrCallback == "function" ? "sendEvent" : handlerOrCallback;
  const key = await RNVNative.applyBottleneckGenerator(
    modelURL,
    handler,
    region,
    toModelURL
  );
  if (key && handler == "sendEvent") addListener(key, handlerOrCallback);
};
const applyBottleneckBottleneck = async (modelURL, region, toModelURL) => {
  return await RNVNative.applyBottleneckBottleneck(modelURL, toModelURL);
};
const applyBottleneckGeneric = async (
  modelURL,
  region,
  toModelURL,
  callback
) => {
  const key = await RNVNative.applyBottleneckGeneric(
    modelURL,
    region,
    toModelURL
  );
  if (key) {
    addListener(key, body => {
      callback(body.data);
    });
  }
};
const removeBottleneck = async (modelURL, region, fromModelURL) => {
  removeListener(modelURL);
  return await RNVNative.removeBottleneck(modelURL, region, fromModelURL);
};
const removeBottlenecks = async (region, fromModelURL) => {
  const out = await RNVNative.removeBottlenecks(region, fromModelURL);
  if (out) {
    if (out.removedBottlenecks) {
      out.removedBottlenecks.forEach(key => {
        removeListener(key);
      });
    }
  }
};
//#endregion
//#region MultiArray access
//Returns URL of saved file
const saveMultiArray = async name => {
  return await RNVNative.saveMultiArray(name);
};
//#endregion
//#region Metadata Capture
var MDListener = null;
const handleMetadata = async callback => {
  removeMetadataListener();
  MDListener = getEmitter().addListener("RNVisionMetaData", callback);
};
const removeMetadataListener = {
  if(MDListener) {
    MDListener.remove();
  }
};
//#endregion
export {
  REGION_ALL,
  start,
  stop,
  attachCameraView,
  isCameraFrame,
  getImageDimensions,
  saveFrame,
  saveFrameOnce,
  removeSaveFrame,
  detectFaces,
  detectFacesOnce,
  removeDetectFaces,
  trackObject,
  removeTrackObject,
  setRegion,
  removeRegion,
  applyMLClassifier,
  applyMLClassifierOnce,
  applyMLGenerator,
  applyMLBottleneck,
  applyMLGeneric,
  applyMLGenericOnce,
  applyBottleneckClassifier,
  applyBottleneckGenerator,
  applyBottleneckBottleneck,
  applyBottleneckGeneric,
  removeML,
  removeBottleneck,
  removeBottlenecks,
  handleMetadata,
  removeMetadataListener
};
export default {
  REGION_ALL,
  start,
  stop,
  attachCameraView,
  isCameraFrame,
  getImageDimensions,
  saveFrame,
  saveFrameOnce,
  removeSaveFrame,
  detectFaces,
  detectFacesOnce,
  removeDetectFaces,
  trackObject,
  removeTrackObject,
  setRegion,
  removeRegion,
  applyMLClassifier,
  applyMLClassifierOnce,
  applyMLGenerator,
  applyMLBottleneck,
  applyMLGeneric,
  applyMLGenericOnce,
  applyBottleneckClassifier,
  applyBottleneckGenerator,
  applyBottleneckBottleneck,
  applyBottleneckGeneric,
  removeML,
  removeBottleneck,
  removeBottlenecks,
  handleMetadata,
  removeMetadataListener
};
