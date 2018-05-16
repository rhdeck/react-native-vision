import React, { Component } from "react";
import PropTypes from "prop-types";
import { Consumer } from "./wrapper";
import * as Module from "./module";
class Region extends Component {
  state = {
    classifiers: {},
    generators: {},
    generics: {},
    bottlenecks: {},
    classifications: {},
    genericResults: {},
    frameListener: null
  };
  static getDerivedStateFromProps(nextProps, prevState) {
    var ret = prevState;
    if (prevState.frameListener != nextProps.onFrameCaptured) {
      console.log("FRAME DIFF");
      if (nextProps.onFrameCaptured) {
        console.log("I AM TURNING ON FRAME CAPTURE");
        //Turn it on!
        Module.saveFrame(
          nextProps.region,
          nextProps.frameDisposition ? nextProps.frameDisposition : "file",
          body => {
            console.log("I AM FRAME CAPTURE BACK");
            nextProps.onFrameCaptured(body);
          }
        );
      } else {
        console.log("I AM TURNING OFF FRAME CAPTURE");
        Module.removeSaveFrame(nextProps.region);
      }
      ret.frameListener = nextProps.onFrameCaptured;
    }
    if (nextProps.classifiers != prevState.classifiers) {
      //compare the two
      if (
        JSON.stringify(nextProps.classifiers) !=
        JSON.stringify(prevState.classifiers)
      ) {
        if (nextProps.classifiers)
          Object.keys(nextProps.classifiers).forEach(k => {
            const maxCount = nextProps.classifiers[k];
            if (
              prevState.classifiers[k] &&
              prevState.classifiers[k] == maxCount
            )
              return;
            Module.applyMLClassifier(
              nextProps.region,
              nextProps.region,
              k,
              maxCount,
              newClassifications => {
                this.setState(({ classifications }) => {
                  return {
                    classifications: {
                      ...classifications,
                      k: newClassifications
                    }
                  };
                });
              }
            );
          });
        Object.keys(prevState.classifiers).forEach(k => {
          if (
            !nextProps.classifiers ||
            typeof nextProps.classifiers[k] == "undefined"
          ) {
            Module.removeML(nextProps.region, k);
            this.setState(({ classifications }) => {
              return { ...classifications, k: null };
            });
          }
        });
        ret.classifiers = nextProps.classifiers;
      }
    }
    if (nextProps.bottlenecks != prevState.bottlenecks) {
      //Update bottlenecks - keys are the bottleneck URLS, values are an object of keys generators, generics, classifiers - examine them all
      if (nextProps.bottlenecks)
        Object.keys(nextProps.bottlenecks).forEach(k => {
          //@TODO MUST ACTUALLY CREATE BOTTLENECK SUPPORT
          const v = nextProps.bottlenecks[k];
        });
      Object.keys(prevState.bottlenecks).forEach(k => {
        //Look for no-longer operative bottlenecks and remove them
        if (typeof nextProps.classifiers[k] == "undefined") {
          Module.removeML(nextProps.id, k);
        }
      });
      ret.bottlenecks = nextProps.bottlenecks;
    }
    return ret;
  }
  render() {
    return (
      <Consumer>
        {value => {
          if (!value) return;
          const region = value.regions[this.props.region];
          const regionInfo = {
            ...region,
            imageDimensions: value.imageDimensions,
            isCameraFront: value.isCameraFront,
            classifications: this.state.classifications,
            genericResults: this.state.genericResults
          };
          return this.props.children(regionInfo);
        }}
      </Consumer>
    );
  }
}
Region.propTypes = {
  region: PropTypes.string.isRequired,
  classifiers: PropTypes.array,
  generators: PropTypes.array,
  generics: PropTypes.array,
  bottlenecks: PropTypes.object,
  children: PropTypes.func.isRequired,
  onFrameCaptured: PropTypes.func,
  frameDisposition: PropTypes.string
};
export default Region;
