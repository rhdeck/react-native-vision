import { requireNativeComponent, NativeModules, View } from "react-native";
import { attachCameraView } from "./module";
import { Consumer } from "./wrapper";
import PropTypes from "prop-types";
import React, { Component } from "react";
import Region from "./region";
const NativeVision = requireNativeComponent("RHDVisionCameraView", RNVision);
var height = 0;
var width = 0;
const { Provider, Consumer: CameraConsumer } = React.createContext();
class RNVision extends Component {
  state = {
    viewPortRectangle: null,
    height: null,
    width: null
  };
  stringified = "";
  constructor(props) {
    super(props);
  }
  componentDidMount() {
    attachCameraView();
  }
  onLayout(e) {
    const layout = e.nativeEvent.layout;
    height = layout.height;
    width = layout.width;
  }
  render() {
    return (
      <View style={this.props.style}>
        <NativeVision
          {...{ ...this.props, children: null }}
          onLayout={this.onLayout}
        />
        <Provider
          value={{
            viewPortDimensions: { height: height, width: width },
            viewPortGravity: this.props.gravity
          }}
        >
          {typeof this.props.children == "function" ? (
            <Consumer>
              {value => {
                const newValue = {
                  ...value,
                  viewPortDimensions: { height: height, width: width },
                  viewPortGravity: this.props.gravity
                };
                return this.props.children(newValue);
              }}
            </Consumer>
          ) : (
            this.props.children
          )}
        </Provider>
      </View>
    );
  }
}
RNVision.defaultProps = {
  gravity: "fill"
};
RNVision.propTypes = {
  gravity: PropTypes.string.isRequired
};
export { RNVision as CameraView, CameraConsumer };
export default RNVision;
