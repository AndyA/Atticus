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
  MenuItem,
  Glyphicon
} from "react-bootstrap";

import {LinkContainer} from "react-router-bootstrap";

import JSONComponent from "atticus/app/JSONComponent.jsx";
import ApproveContainer from "atticus/app/ApproveContainer.jsx";
import EditContainer from "atticus/app/EditContainer.jsx";

import {StateIcon} from "atticus/app/Common.jsx";

import {config} from "atticus/app/Config";
import {progress} from "atticus/app/Progress";

import numberFormat from "underscore.string/numberFormat";

class Atticus extends React.Component {
  render() {
    return (
      <div>
        <NavLink to="/atticus/some/page">A page {this.props.path}</NavLink>
      </div>
    );
  }
}

class AtticusContainer extends React.Component {
  render() {
    console.log("Rendering ", this.props.match.params[0]);
    return React.createElement(Atticus, {path: this.props.match.params[0]});
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
