import { requireNativeComponent, NativeModules } from "react-native";
import React, { Component } from "react";
import PropTypes from "prop-types";
import { RHDVisionImageView } from "./RNSwiftBridge";
// const NativeVision = requireNativeComponent("RHDVisionImageView", RNVImageView);

class RNVImageView extends Component {
  render() {
    return (
      <RHDVisionImageView
        {...this.props}
        resizeMode={
          this.props.style.resizeMode ? this.props.style.resizeMode : "cover"
        }
      />
    );
  }
}
RNVImageView.propTypes = {
  id: PropTypes.string.isRequired
};
export default RNVImageView;
