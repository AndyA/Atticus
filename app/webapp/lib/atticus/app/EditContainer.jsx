"use strict";

import React from "react";
import JSONComponent from "atticus/app/JSONComponent.jsx";
import { Edits } from "atticus/model/Edits";
import { config } from "atticus/app/Config";

class Edit extends React.Component {
  render() {
    return (
      <pre>{ JSON.stringify(this.props, null, 2) }</pre>
      );
  }
}

class EditContainer extends JSONComponent {
  constructor(props) {
    super(props);
    this.state = {
      edits: new Edits()
    };
  }

  dataURI(props) {
    const params = props.params;
    return config.path(["data", "edit", params.uuid]);
  }

  setData(data) {
    this.setState({
      edits: new Edits(data.list, data.versions)
    });
  }

  render() {
    return React.createElement(Edit, {
      params: this.props.params,
      edits: this.state.edits
    });
  }
}

export default EditContainer;
