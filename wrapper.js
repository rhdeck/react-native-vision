import React, { createContext, Component } from "react";
import PropTypes from "prop-types";
import Module, { detach, start, stop } from "./module";
const { Provider, Consumer } = createContext(null);
class Wrapper extends Component {
  state = {
    isStarted: false,
    isCameraFront: false
  };
  componentWillUnmount() {
    if (this.state.connected) {
      stop();
    }
  }
  static getDerivedStateFromProps(nextProps, prevState) {
    var ret = prevState;
    console.log(ret);
    if (nextProps.isCameraFront != prevState.isCameraFront) {
      ret.isCameraFront = nextProps.isCameraFront;
      if (prevState.isStarted) start(ret.isCameraFront);
    }
    if (nextProps.isStarted != prevState.isStarted) {
      ret.isStarted = nextProps.isStarted;
      nextProps.isStarted ? start(ret.isCameraFront) : stop();
    }
    return ret;
  }
  providerValue = {};
  getProviderValue() {
    //Check state
    //Regions
    //If state mutated relative to providerValue, change providerValue
    return this.providerValue;
  }
  render() {
    const base = <Provider value={this.getProviderValue()} />;
    if (typeof this.props.children == "function") {
      return [base, <Region id="">{this.props.children}</Region>];
    } else return base;
  }
}
Wrapper.propTypes = {
  isStarted: PropTypes.bool.isRequired,
  isCameraFront: PropTypes.bool.isRequired
};
export { Wrapper, Consumer };
