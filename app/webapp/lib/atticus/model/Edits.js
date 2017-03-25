"use strict";

class Edit {
  constructor(edit, versions) {
    this.edit = edit || {};
    this.versions = versions || [];
  }
}

class Edits {
  constructor(list, versions) {
    this.list = list || [];
    this.versions = versions || {};
  }

  [ Symbol.iterator]() {
    let idx = 0;
    const list = this.list;
    const versions = this.versions;
    return {
      next() {
        if (idx == list.length) return {
            done: true
        }
        const edit = list[idx++];
        return {
          value: new Edit(edit, versions[edit.object]),
          done: false
        };
      }
    };
  }
}

export { Edits };
