import React, { createContext, Component } from "react";
import { PropTypes } from "prop-types";
import FaceTracker from "./facetracker";
import { RNVisionProvider, RNVisionConsumer } from "./wrapper";
import { RNVRegion } from "./region";
import { calculateRectangles } from "./cameraregion";
import { RNVCameraConsumer } from "./view";
const { Provider, Consumer: FacesConsumer } = createContext({ faces: {} });
class FaceInfo extends Component {
  state = {
    setFaceInfo: this.setFaceInfo.bind(this),
    faces: {}
  };
  componentDidMount() {
    this.timer = setInterval(() => {
      const keys = Object.entries(this.state.faces)
        .filter(([key, { lastUpdate }]) => lastUpdate < Date.now() - 2000)
        .map(([key, val]) => key);
      if (keys.length)
        this.setState(({ faces }) => {
          keys.forEach(k => delete faces[k]);
          return { faces: { ...faces } };
        });
    }, 2000);
  }
  componentWillUnmount() {
    if (this.timer) clearInterval(this.timer);
  }
  setFaceInfo(k, info) {
    setTimeout(() => {
      this.setState(({ faces }) => {
        const lastUpdate = Date.now();
        return {
          faces: { ...faces, [k]: { ...faces[k], ...info, lastUpdate } }
        };
      });
    }, 0);
  }
  render() {
    return <Provider {...this.props} value={this.state} />;
  }
}
class TickTock extends Component {
  state = { tick: true };
  componentDidMount() {
    this.timer = setInterval(() => {
      this.setState(({ tick }) => {
        console.log("tock", tick);
        return { tick: !tick };
      });
    }, this.props.interval);
  }
  componentWillUnmount() {
    if (this.timer) clearInterval(this.timer);
  }
  render() {
    return this.props.children(this.state.tick);
  }
}
TickTock.defaultProps = {
  interval: 300
};
const FacesProvider = props => {
  return (
    // <TickTock>
    //   {tick => (
    <FaceTracker {...props}>
      <FaceInfo>
        <RNVisionConsumer>
          {data => {
            if (!data) return null;
            const regions = data.regions;
            return [
              regions
                ? [
                    ...Object.keys(regions)
                      .filter(k => k.length)
                      .map(k => {
                        return (
                          <RNVRegion
                            key={"raw-region-" + k}
                            region={k}
                            classifiers={
                              props.classifier && [
                                { url: props.classifier, max: 5 }
                              ]
                            }
                          >
                            {({ classifications }) => (
                              <FacesConsumer>
                                {({ setFaceInfo }) => {
                                  if (typeof classifications == "object") {
                                    const fk = Object.keys(
                                      classifications
                                    ).shift();
                                    if (!fk) {
                                      setFaceInfo(k, {
                                        region: k,
                                        ...regions[k]
                                      });
                                    } else {
                                      const firstClassifier =
                                        classifications[fk];
                                      setFaceInfo(k, {
                                        region: k,
                                        ...regions[k],
                                        face: [...firstClassifier].shift()
                                          .label,
                                        faceConfidence: [
                                          ...firstClassifier
                                        ].shift().confidence,
                                        faces: firstClassifier
                                      });
                                    }
                                  } else {
                                    setFaceInfo(k, {
                                      region: k,
                                      ...regions[k]
                                    });
                                  }
                                }}
                              </FacesConsumer>
                            )}
                          </RNVRegion>
                        );
                      })
                  ]
                : null,
              typeof props.children == "function" ? (
                <FacesConsumer>{props.children}</FacesConsumer>
              ) : (
                props.children
              )
            ];
          }}
        </RNVisionConsumer>
      </FaceInfo>
    </FaceTracker>
    //   )}
    // </TickTock>
  );
};
FacesProvider.propTypes = {
  ...RNVisionProvider.propTypes,
  classifier: PropTypes.string
};
FacesProvider.defaultProps = {
  isCameraFront: true,
  isStarted: true,
  interval: 500
};
const Face = props =>
  props.isCamera ? (
    <RNVisionConsumer>
      {({ imageDimensions, isCameraFront }) => (
        <RNVCameraConsumer>
          {value => {
            const newValue = {
              ...props,
              ...value,
              style: calculateRectangles({
                ...props,
                ...value,
                imageDimensions,
                isCameraFront
              }),
              children: null
            };
            return props.children(newValue);
          }}
        </RNVCameraConsumer>
      )}
    </RNVisionConsumer>
  ) : (
    props.children({ ...props, children: null })
  );

export { FacesProvider, FacesConsumer, Face };
