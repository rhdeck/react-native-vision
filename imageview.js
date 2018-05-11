import { requireNativeComponent, NativeModules } from "react-native";
import React, { Component } from "react";
import PropTypes from "prop-types";

const NativeVision = requireNativeComponent("RHDVisionImageView", RNVision);

class RNVision extends Component {
  constructor(props) {
    super(props);
    if (typeof props.id == "undefined")
      throw Error("ImageView requires an id prop");
  }
  render() {
    return <NativeVision {...this.props} />;
  }
}
RNVision.propTypes = {
  id: PropTypes.string
};
export default RNVision;
