"use strict";

import React from "react";
import ReactDOM from "react-dom";
import {BrowserRouter, Route, Redirect, Link, NavLink} from "react-router-dom";

import {
  Button,
  Navbar,
  Nav,
  NavItem,
  NavDropdown,
  MenuItem
} from "react-bootstrap";

import JSONComponent from "atticus/app/JSONComponent.jsx";
import {progress} from "atticus/app/Progress";

import numberFormat from "underscore.string/numberFormat";

function getSuffix(pfx, str) {
  if (str.length < pfx.length)
    return null;
  if (str.substr(0, pfx.length) !== pfx)
    return null;
  return str.substr(pfx.length);
}

function atticusURI(id) {
  var sfx = getSuffix("file://", id);
  if (sfx === null)
    throw new Exception("Invalid atticus ID: " + id);
  return "/atticus/" + sfx;
}

class Atticus extends React.Component {

  getBreadcrumbs() {
    var path = this.props.path;
    var pe = path.split("/");

    if (pe[pe.length - 1] === "")
      pe.pop();

    if (pe.length === 0) {
      return (
        <li key="home" className="breadcrumb-item">
          <i className="fa fa-home"></i>
        </li>
      );
    }

    var out = [];

    out.unshift(
      <li key="leaf" className="breadcrumb-item">{pe.pop()}</li>
    );

    while (pe.length) {
      var link = "/atticus/" + pe.join("/");
      out.unshift(
        <li key={link} className="breadcrumb-item">
          <NavLink to={link}>{pe.pop()}</NavLink>
        </li>
      );
    }

    out.unshift(
      <li key="home" className="breadcrumb-item">
        <NavLink to="/atticus/">
          <i className="fa fa-home"></i>
        </NavLink>
      </li>
    );

    return out;
  }

  getBody() {
    var links = [];

    if (this.props.dir && this.props.dir.children) {
      for (var obj of this.props.dir.children) {
        var uri = atticusURI(obj._id);
        if (uri === null)
          continue;
        links.push(
          <div key={obj._id}>
            <NavLink to={uri}>{obj._id}</NavLink>
          </div>
        );
      }
    }
    return links;
  }

  render() {

    return (
      <div>
        <ol className="breadcrumb">{this.getBreadcrumbs()}</ol>
        <div className="viewer">{this.getBody()}</div>
      </div>
    );
  }
}

class AtticusContainer extends JSONComponent {
  dataURI(props) {
    return "/store/" + props.match.params[0];
  }

  dataFieldName() {
    return "dir";
  }

  render() {
    var props = {
      path: this.props.match.params[0]
    };

    if (this.state && this.state.dir)
      props.dir = this.state.dir;

    return React.createElement(Atticus, props);
  }
}

progress.init(document.getElementById("spinner"));

ReactDOM.render((
  <BrowserRouter>
    <div>
      <Navbar inverse fixedTop>
        <Navbar.Header>
          <Navbar.Brand>
            <NavLink to="/atticus/">Atticus</NavLink>
          </Navbar.Brand>
        </Navbar.Header>
        <Nav>
          <NavItem eventKey={1} href="/atticus/">
            Media Library
          </NavItem>
          <NavDropdown id="menu-tools" eventKey={2} title="Tools">
            <MenuItem href="/help">Help</MenuItem>
          </NavDropdown>
        </Nav>
      </Navbar>
      <div id="content">
        <Route path="/atticus/*" component={AtticusContainer}></Route>
      </div>
    </div>
  </BrowserRouter>
), document.getElementById("root"));
