import { requireNativeComponent, NativeModules, View } from "react-native";
import { attachCameraView } from "./module";
import { RNVisionConsumer } from "./wrapper";
import PropTypes from "prop-types";
import React, { Component } from "react";
import Region from "./region";
const NativeVision = requireNativeComponent("RHDVisionCameraView", RNVision);
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
    this.setState({ height: layout.height, width: layout.width });
  }
  render() {
    return (
      <View
        style={this.props.style}
        onLayout={e => {
          this.onLayout(e);
        }}
      >
        <NativeVision {...{ ...this.props, children: null }} />
        <Provider
          value={{
            viewPortDimensions: {
              height: this.state.height,
              width: this.state.width
            },
            viewPortGravity: this.props.gravity
          }}
        >
          {typeof this.props.children == "function" ? (
            <RNVisionConsumer>
              {value => {
                const newValue = {
                  ...value,
                  viewPortDimensions: {
                    height: this.state.height,
                    width: this.state.width
                  },
                  viewPortGravity: this.props.gravity
                };
                return this.props.children(newValue);
              }}
            </RNVisionConsumer>
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
export { RNVision as RNVCameraView, RNVCameraConsumer };
export default RNVision;
