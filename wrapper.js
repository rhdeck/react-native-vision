import React, { createContext, Component } from "react";
import PropTypes from "prop-types";
import Module, {
  detach,
  start,
  stop,
  detectFacesOnce,
  removeDetectFaces,
  detectFaces,
  removeRegion,
  setRegion,
  trackObject,
  removeTrackObject,
  getImageDimensions,
  setImageDimensionListener,
  removeImageDimensionListener
} from "./module";
const { Provider, Consumer } = createContext(null);
class Wrapper extends Component {
  state = {
    isStarted: false,
    isCameraFront: false,
    onDetectedFaces: null,
    fixedRegions: {},
    trackedObjects: {},
    calculatedRegions: {},
    imageDimensions: { height: 0, width: 0 },
    providerValue: null
  };
  componentDidMount() {
    this.setProviderValue();
  }
  componentWillUnmount() {
    if (this.state.connected) {
      stop();
    }
  }
  static getDerivedStateFromProps(nextProps, prevState) {
    var ret = prevState;
    if (!ret.todos) ret.todos = [];
    if (nextProps.isCameraFront != prevState.isCameraFront) {
      ret.isCameraFront = nextProps.isCameraFront;
      if (prevState.isStarted) {
        start(ret.isCameraFront);
      }
    }
    if (nextProps.isStarted != prevState.isStarted) {
      ret.isStarted = nextProps.isStarted;
      if (nextProps.isStarted) {
        start(ret.isCameraFront);
        ret.todos.push({ key: "getImageDimensions" });
      } else {
        stop();
        removeImageDimensionListener();
      }
    }
    if (nextProps.onDetectedFaces != prevState.onDetectedFaces) {
      if (nextProps.onDetectedFaces) {
        //Turn it on
        detectFaces("", nextProps.onDetectedFaces);
      } else {
        //Turn it off
        removeDetectFaces("");
      }
      ret.onDetectedFaces = nextProps.onDetectedFaces;
    }
    if (nextProps.trackedObjects != prevState.trackedObjects) {
      if (nextProps.trackedObjects)
        Object.keys(nextProps.trackedObjects).forEach(k => {
          const v = nextProps.trackedObjects[k];
          if (!prevState.trackedObjects[k]) {
            if (!ret.todoObjects) ret.todoObjects = {};
            ret.todoObjects[k] = nextProps.trackedObjects[k];
          }
          if (
            JSON.stringify(prevState.trackedObjects[k]) != JSON.stringify(v)
          ) {
            if (!ret.todoObjects) ret.todoObjects = {};
            ret.calculatedRegions[k] = v;
            ret.todoObjects[k] = v;
          }
        });
      Object.keys(prevState.trackedObjects).forEach(k => {
        const v = prevState.trackedObjects[k];
        if (!nextProps.trackedObjects || !nextProps.trackedObjects[k]) {
          removeTrackObject("", k);
          delete ret.calculatedRegions[k];
          ret.todos.push({ key: "setProviderValue" });
        }
      });
      ret.trackedObjects = nextProps.trackedObjects;
    }
    if (nextProps.regions != prevState.fixedRegions) {
      var shouldChange = false;
      Object.keys(prevState.fixedRegions).forEach(k => {
        if (!nextProps.regions[k]) {
          shouldChange = true;
          removeRegion(k);
        }
      });
      if (shouldChange) {
        ret.fixedRegions = nextProps.regions;
        Object.keys(ret.fixedRegions).forEach(k => {
          setRegion(k, ret.fixedRegions[k]);
        });
      }
    }
    if (ret && ret.todos && ret.todos.length == 0) delete ret.todos;
    return ret;
  }
  getImageDimensions() {
    setImageDimensionListener(dims => {
      this.setState(({ imageDimensions }) => {
        if (
          dims &&
          (dims.height != imageDimensions.height ||
            dims.width != imageDimensions.width)
        )
          return { imageDimensions: dims };
      });
    });
  }
  manageTodo() {
    const todos = this.state.todos;
    if (todos) {
      todos.forEach(v => {
        const k = v.key;
        if (this[k]) return this[k](v);
      });
      this.setState({ todos: null }, () => {
        this.setProviderValue();
      });
    }
    const todo = this.state.todoObjects;
    if (todo) {
      Object.keys(todo).forEach(k => {
        (async () => {
          try {
            await removeTrackObject("", k);
            await trackObject("", k, todo[k], data => {
              const newRect = data.frame;
              this.setState(
                ({ calculatedRegions, trackedObjects }) => {
                  if (!trackedObjects || !trackedObjects[k]) {
                    return {
                      calculatedRegions: { calculatedRegions, [k]: null }
                    };
                  } else {
                    return {
                      calculatedRegions: {
                        ...calculatedRegions,
                        [k]: newRect
                      }
                    };
                  }
                },
                () => {
                  this.setProviderValue();
                }
              );
            });
          } catch (e) {
            console.log("TRACKOBJECT FAIL", k, todo[k], e);
          }
        })();
      });
      this.setState({ todoObjects: null }, () => {
        this.setProviderValue();
      });
    }
  }
  componentDidUpdate() {
    this.manageTodo();
  }
  setProviderValue() {
    this.setState(
      {
        providerValue: {
          imageDimensions: this.state.imageDimensions,
          isCameraFront: this.state.isCameraFront,
          regions: {
            "": null,
            ...this.state.fixedRegions,
            ...this.state.calculatedRegions
          }
        }
      },
      () => {
        if (typeof this.props.onRegionsChanged == "function") {
          this.props.onRegionsChanged(this.state.providerValue.regions);
        }
      }
    );
  }
  render() {
    return (
      <Provider value={this.state.providerValue}>
        {this.props.children}
      </Provider>
    );
  }
}
Wrapper.propTypes = {
  isStarted: PropTypes.bool.isRequired,
  isCameraFront: PropTypes.bool.isRequired,
  onDetectedFaces: PropTypes.func,
  trackedObjects: PropTypes.object,
  regions: PropTypes.object,
  onRegionsChanged: PropTypes.func
};
Wrapper.detectFaces = async () => {
  return await detectFacesOnce("");
};
export { Wrapper, Consumer };
