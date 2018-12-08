import React from "react";
import { RNVisionProvider } from "./wrapper";
import { RNVCameraView } from "./view";
import { CameraRegion } from "./cameraregion";
const VisionCamera = props => (
  <RNVisionProvider isStarted={true} isCameraFront={false} {...props}>
    <RNVCameraView {...props}>
      {typeof props.children == "function" ? (
        <CameraRegion
          {...props}
          region=""
          classifiers={props.classifier && [{ url: props.classifier, max: 5 }]}
        />
      ) : (
        props.children
      )}
    </RNVCameraView>
  </RNVisionProvider>
);
export { VisionCamera };
