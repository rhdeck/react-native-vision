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
  getImageDimensions
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
        ret.todos.push({ key: "getImageDimensions" });
      }
    }
    if (nextProps.isStarted != prevState.isStarted) {
      ret.isStarted = nextProps.isStarted;
      if (nextProps.isStarted) {
        start(ret.isCameraFront);
        ret.todos.push({ key: "getImageDimensions" });
      } else stop();
    }
    if (nextProps.onDetectedFaces != prevState.onDetectedFaces) {
      if (nextProps.onDetectedFaces) {
        //Turn it on
        console.log("Activating detectFaces");
        detectFaces("", nextProps.onDetectedFaces);
        ret.todos.push({ key: "getImageDimensions" });
      } else {
        //Turn it off
        console.log("removing detectfaces");
        removeDetectFaces("");
        ret.todos.push({ key: "getImageDimensions" });
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
        if (!nextProps.trackedObjects[k]) {
          removeTrackObject("", k);
          delete ret.calculatedRegions[k];
        }
      });
      ret.todos.push({ key: "getImageDimensions" });
      ret = nextProps.trackedObjects;
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
  async getImageDimensions() {
    console.log("Getting image dimensions");
    const dims = await getImageDimensions();
    console.log("Got image dimensions!", dims);
    if (dims.height == 0) {
      setTimeout(() => {
        this.getImageDimensions();
      }, 1000);
    } else {
      this.setState(({ imageDimensions }) => {
        if (
          dims &&
          (dims.height != imageDimensions.height ||
            dims.width != imageDimensions.width)
        )
          return { imageDimensions: dims };
      });
    }
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
                ({ calculatedRegions }) => {
                  const newcalcregions = { ...calculatedRegions, [k]: newRect };
                  console.log(
                    "Newcalcregions",
                    newcalcregions,
                    calculatedRegions
                  );
                  return {
                    calculatedRegions: newcalcregions
                  };
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
  providerValue = {};
  setProviderValue() {
    //Check state
    isChanged = false;
    //Regions
    if (Object.keys(this.providerValue).length == 0) {
      isChanged = true;
    } else if (
      this.providerValue &&
      this.providerValue.imageDimensions &&
      (this.providerValue.imageDimensions.height !=
        this.state.imageDimensions.height ||
        this.providerValue.imageDimensions.width !=
          this.state.imageDimensions.width)
    ) {
      isChanged = true;
    } else if (Object.keys(this.state.calculatedRegions).length) {
      isChanged = true;
    } else {
      Object.keys(this.state.fixedRegions).forEach(k => {
        const v = this.state.fixedRegions[k];
        if (
          !providerValue.regions[k] ||
          JSON.stringify(providerValue.regions[k] != JSON.stringify(v))
        ) {
          isChanged = true;
        }
      });
    }
    if (isChanged) {
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
