"use strict";

import React from "react";
import { Glyphicon } from "react-bootstrap";
import { config } from "atticus/app/Config";

function StateIcon(props) {
  return <Glyphicon className={ ["state-icon", config.stateName(props.state)] } glyph={ config.approveIcon(props.state) } />;
}

export { StateIcon };
