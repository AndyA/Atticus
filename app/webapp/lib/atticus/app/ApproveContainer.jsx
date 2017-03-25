"use strict";

import React from "react";

import { Table, Pagination } from "react-bootstrap";
import { Link } from "react-router";

import { config } from "atticus/app/Config";
import { StateIcon } from "atticus/app/Common.jsx";

import { Edits } from "atticus/model/Edits";
import JSONComponent from "atticus/app/JSONComponent.jsx";

function EditRow(props) {
  const row = props.row;
  return (
    <tr className={ row.state }>
      <td>
        <StateIcon state={ row.state } />
        { config.approveName(row.state) }
      </td>
      <td>
        { row.created }
      </td>
      <td>
        { row.updated }
      </td>
      <td>
        { row.data.service_key }
      </td>
      <td>
        { row.data.title }
      </td>
      <td>
        { row.data.date }
      </td>
      <td></td>
      <td>
        <Link to={ config.editLink(row.uuid) }> edit
        </Link>
      </td>
    </tr>
    );
}

class Approve extends React.Component {
  render() {
    const editRows = this.props.edits && [...this.props.edits].map(edit => {
      return <EditRow key={ edit.edit.uuid } row={ edit.edit } />;
    });

    const pager = (
    <Pagination bsSize="medium"
      prev
      next
      first
      last
      ellipsis
      items={ this.props.pageCount }
      maxButtons={ 5 }
      activePage={ 1 + parseInt(this.context.router.params.page) }
      onSelect={ eventKey => {
                   this.context.router.push(config.approveLink(this.props.params, {
                     page: eventKey - 1
                   }));
                 } } />
    );

    return (
      <div>
        { pager }
        <Table striped
          bordered
          condensed
          hover
          responsive>
          <thead>
            <tr>
              <th>
                State
              </th>
              <th>
                Created
              </th>
              <th>
                Updated
              </th>
              <th>
                Service
              </th>
              <th>
                Title
              </th>
              <th>
                TX Date
              </th>
              <th>
                Comments
              </th>
              <th>
                Show
              </th>
            </tr>
          </thead>
          <tbody>
            { editRows }
          </tbody>
        </Table>
        { pager }
      </div>
      );
  }
}

Approve.contextTypes = {
  router: React.PropTypes.object.isRequired
};

class ApproveContainer extends JSONComponent {
  constructor(props) {
    super(props);
    this.state = {
      data: {
        list: null
      }
    };
  }

  dataURI(props) {
    const params = props.params;
    const pageSize = config.pageSize();
    return config.path(["data", "list",
      params.kind, params.state, params.page * pageSize,
      pageSize, params.order]);
  }

  render() {
    const data = this.state.data;
    const pageSize = config.pageSize();
    const pageCount = Math.floor((parseInt(data.limit) + pageSize - 1) / pageSize);

    return React.createElement(Approve, {
      children: this.props.children,
      params: this.props.params,
      pageCount: pageCount,
      edits: new Edits(data.list)
    });
  }
}

export default ApproveContainer;

