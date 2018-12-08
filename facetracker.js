import React, { Component } from "react";
import { RNVisionProvider, RNVisionConsumer } from "./wrapper";
import PropTypes from "prop-types";

const intersect = (a, b) => {
  if (!a && !b) return false;
  return !(
    b.x > a.x + a.width ||
    a.x > b.x + b.width ||
    b.y > a.y + a.height ||
    a.y > b.y + b.height
  );
};
class FaceTracker extends Component {
  state = {
    interval: null,
    intervalDuration: 0,
    onDetectedFaces: null,
    regions: null
  };
  static getDerivedStateFromProps(nextProps, prevState) {
    var ret = prevState;
    if (
      nextProps.interval &&
      nextProps.interval != prevState.intervalDuration
    ) {
      ret.intervalDuration = nextProps.interval;
    }
    return ret;
  }
  updateInterval() {
    clearInterval(this.state.interval);
    this.setState({
      interval: setInterval(() => {
        this.setState({
          onDetectedFaces: faces => {
            var out = {};
            var doneIndexes = [];
            if (faces && faces.length) {
              if (this.state.regions) {
                faces.forEach((v, i) => {
                  var done = false;
                  const newRect = {
                    x: v.x - v.width * 0.1,
                    y: v.y - v.height * 0.2,
                    height: v.height * 1.4,
                    width: v.width * 1.2
                  };
                  Object.keys(this.state.regions).forEach(region => {
                    if (done) return;
                    if (region == "") return;
                    const rect = this.state.regions[region];
                    if (intersect(newRect, rect)) {
                      out[region] = newRect;
                      doneIndexes.push(i);
                      done = true;
                    }
                  });
                });
              }
              faces.forEach((v, i) => {
                if (doneIndexes.indexOf(i) > -1) return;
                var i = 0;
                var key;
                do {
                  key = "face" + String(i);
                  i++;
                } while (Object.keys(out).indexOf(key) > -1);
                const newRect = {
                  x: v.x - v.width * 0.1,
                  y: v.y - v.height * 0.2,
                  height: v.height * 1.4,
                  width: v.width * 1.2
                };
                out[key] = newRect;
              });
              this.setState({ trackedObjects: out, onDetectedFaces: null });
            } else {
              this.setState({ trackedObjects: null, onDetectedFaces: null });
            }
          }
        });
      }, this.state.intervalDuration)
    });
  }
  componentDidUpdate(prevProps, prevState) {
    if (prevState.intervalDuration != prevState.intervalDuration) {
      this.updateInterval();
    }
  }
  componentDidMount() {
    this.updateInterval();
  }
  componentWillUnmount() {
    if (this.state.interval) clearInterval(this.state.interval);
  }
  render() {
    return (
      <RNVisionProvider
        {...this.props}
        onDetectedFaces={this.state.onDetectedFaces}
        trackedObjects={{
          ...this.props.trackedObjects,
          ...this.state.trackedObjects
        }}
        onRegionsChanged={regions => {
          this.setState({ regions: regions });
          if (this.props.onRegionsChange) this.props.onRegionsChange(regions);
        }}
        children={
          typeof this.props.children == "function" ? (
            <RNVisionConsumer>{this.props.children}</RNVisionConsumer>
          ) : (
            this.props.children
          )
        }
      />
    );
  }
}
FaceTracker.propTypes = {
  ...RNVisionProvider.propTypes,
  interval: PropTypes.number.isRequired
};
export default FaceTracker;
