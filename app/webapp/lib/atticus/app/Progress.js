"use strict";

import Spinner from "spin/spin.js";

class Progress {
  constructor() {
    this.elt = null;
    this.timeout = 250;
    this.spinner = null;
    this.wantSpinner = 0;
  }

  init(elt) {
    this.elt = elt;
  }

  makeSpinner() {
    return new Spinner({
      lines: 11,
      length: 0,
      width: 22,
      radius: 43,
      corners: 1,
      rotate: 0,
      direction: 1,
      color: '#000',
      speed: 1,
      trail: 81,
      shadow: false,
      hwaccel: false,
      className: 'this.spinner',
      zIndex: 2e9,
      top: '50%',
      left: '50%'
    });
  }

  getSpinner() {
    return this.spinner = this.spinner || this.makeSpinner();
  }

  stop() {
    if (this.wantSpinner <= 0)
      throw new Error("Spinner underrun");

    if (--this.wantSpinner === 0 && this.spinner !== null)
      this.getSpinner().stop();
  }

  start() {
    if (this.wantSpinner++ === 0)
      setTimeout(() => {
        if (this.wantSpinner > 0)
          this.getSpinner().spin(this.elt);
      }, this.timeout);
  }
}

export let progress = new Progress();
