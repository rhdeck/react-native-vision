import React from "react";
import { RNVisionProvider } from "./wrapper";
import { RNVDefaultRegion, fixURL } from "./region";
import { RNVImageView } from ".";

const StyleView = props => {
  const generatorURL = fixURL(props.generator);
  return (
    <RNVisionProvider isStarted={true} isCameraFront={false} {...props}>
      <RNVDefaultRegion
        {...props}
        generators={props.generator && [{ url: generatorURL, type: "view" }]}
      />
      <RNVImageView {...props} style={{ ...props.style }} id={generatorURL} />
    </RNVisionProvider>
  );
};

export { StyleView };
