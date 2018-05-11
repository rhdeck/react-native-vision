import { requireNativeComponent, NativeModules } from "react-native";
import { attachCameraView } from "./module";
import React, { Component } from "react";

const NativeVision = requireNativeComponent("RHDVisionCameraView", RNVision);

class RNVision extends Component {
  constructor(props) {
    super(props);
  }
  componentDidMount() {
    attachCameraView();
  }
  render() {
    return <NativeVision {...this.props} />;
  }
}
export default RNVision;
