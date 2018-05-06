import { requireNativeComponent, NativeModules } from "react-native";
import React, { Component } from "react";

const NativeVision = requireNativeComponent("RHDVisionView", RNVision);

class RNVision extends Component {
  constructor(props) {
    super(props);
  }
  render() {
    return <NativeVision {...this.props} />;
  }
}
RNVision.defaultProps = {
  onStart: () => {
    console.log("I am starting for reals");
  },
  cameraFront: true
};

export default RNVision;
