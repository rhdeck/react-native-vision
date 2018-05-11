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
    genericResults: {}
  };
  static getDerivedStateFromProps(nextProps, prevState) {
    var ret = prevState;
    if (nextProps.classifiers != prevState.classifiers) {
      //compare the two
      if (
        JSON.stringify(nextProps.classifiers) !=
        JSON.stringify(prevState.classifiers)
      ) {
        nextProps.classifiers.forEach((k, maxCount) => {
          if (prevState.classifiers[k] && prevState.classifiers[k] == maxCount)
            return;
          Module.applyMLClassifier(
            nextProps.id,
            nextProps.id,
            k,
            v,
            newClassifications => {
              this.setState(({ classifications }) => {
                return {
                  classifications: { ...classifications, k: newClassifications }
                };
              });
            }
          );
        });
        prevState.classifiers.forEach((k, maxCount) => {
          if (typeof nextProps.classifiers[k] == "undefined") {
            Module.removeML(nextProps.id, k);
            this.setState(({ classifications }) => {
              return { ...classifications, k: null };
            });
          }
        });
        ret.classifiers = nextProps.classifiers;
      }
    }
    if (nextProps.bottlenecks != prevState.bottlenecks) return ret;
  }
  render() {
    return (
      <Consumer>
        {value => {
          const region = value.regions[id];
          const regionInfo = {
            ...region,
            region: id,
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
  id: PropTypes.string.isRequired,
  classifiers: PropTypes.array.optional,
  generators: PropTypes.array.optional,
  generics: PropTypes.array.optional,
  bottlenecks: PropTypes.object.optional,
  children: PropTypes.func.isRequired
};
export default Region;
