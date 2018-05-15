import React from "react";
import { CameraConsumer } from "./view";
import Region from "./region";
import PropTypes from "prop-types";
CameraRegion = props => {
  return (
    <Region {...{ ...props, children: null }}>
      {regionInfo => {
        return (
          <CameraConsumer>
            {value => {
              const newValue = {
                ...regionInfo,
                ...value,
                style: calculateRectangles({ ...regionInfo, ...value })
              };
              return props.children(newValue);
            }}
          </CameraConsumer>
        );
      }}
    </Region>
  );
};
const calculateRectangles = data => {
  console.log(data);
  if (!data.viewPortDimensions) return null;
  const vpRatio =
    data.viewPortDimensions.width / data.viewPortDimensions.height;
  const iRatio = data.imageDimensions.width / data.imageDimensions.height;
  const totalRatio = vpRatio / iRatio;
  const subRectangle =
    data.viewPortGravity == "fill"
      ? totalRatio > 1
        ? {
            x: 0,
            y: (1.0 - 1.0 / totalRatio) / 2,
            height: 1.0 / totalRatio,
            width: 1
          }
        : {
            x: (1.0 - totalRatio) / 2,
            y: 0,
            height: 1,
            width: totalRatio
          }
      : totalRatio > 1
        ? {
            x: (1 / totalRatio - 1) / 2,
            y: 0,
            height: 1,
            width: totalRatio
          }
        : {
            x: 0,
            y: (totalRatio - 1) / 2,
            height: 1 / totalRatio,
            width: 1
          };
  if (data.isCameraFront) {
    data.originalx = data.x;
    data.x = 1 - data.x - data.width;
  }
  const style = {
    position: "absolute",
    width: (data.width / subRectangle.width * 100).toFixed(2) + "%",
    height: (data.height / subRectangle.height * 100).toFixed(2) + "%",
    left:
      ((data.x / subRectangle.width - subRectangle.x) * 100).toFixed(2) + "%",
    top:
      ((data.y - subRectangle.y) / subRectangle.height * 100).toFixed(2) + "%"
  };
  return style;
};
CameraRegion.propTypes = {
  ...Region.propTypes,
  children: PropTypes.func.isRequired
};
export default CameraRegion;
