"use strict";

import capitalize from "underscore.string/capitalize";

class Config {
  constructor(root) {
    this.root = root;
  }

  path(path) {
    const uriPath = path || [];
    return [this.root, ...uriPath].join("/");
  }

  pageSize() {
    return 40;
  }

  approveLink(props, adjust) {

    const args = Object.assign({}, {
      kind: "*",
      state: "*",
      page: 0,
      order: "-updated"
    }, props || {}, adjust || {});

    return this.path(["approve", args.kind, args.state, args.page, args.order]);
  }

  homeLink() {
    return this.approveLink({
      state: "pending"
    });
  }

  editLink(uuid) {
    return this.path(["edit", uuid]);
  }

  stateName(state) {
    if (state === "*") return "all";
    return state;
  }

  approveName(state) {
    return capitalize(this.stateName(state));
  }

  approveIcon(state) {
    switch (this.stateName(state)) {
      case "pending":
        return "star";
      case "accepted":
        return "ok";
      case "rejected":
        return "remove";
      case "review":
        return "tag";
      case "all":
        return "globe";
      default:
        throw new Error("Bad state: " + state);
    }
  }

}

export let config = new Config("");
