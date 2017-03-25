"use strict";

import React from "react";
import "whatwg-fetch";

import { progress } from "./Progress";

function fetchJSON(uri) {
  return fetch(uri).then(response => {
    return response.json();
  });
}

export default class JSONComponent extends React.Component {
  dataFieldName() {
    return "data";
  }

  componentDidMount() {
    this.fetchData(this.props);
  }

  componentWillReceiveProps(nextProps) {
    this.fetchData(nextProps);
  }

  setData(data) {
    var state = {};
    state[this.dataFieldName()] = data;
    this.setState(state);
  }

  fetchData(props) {
    const uri = this.dataURI(props);
    console.log("fetching " + uri);
    progress.start();
    fetchJSON(uri).then(json => {
      console.log(json);
      this.setData(json);
      progress.stop();
    });
  }
}
