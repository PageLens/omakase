//= require_self
//= require jquery
//= require_tree .
if (!window.PageLens) { window.PageLens = {}; }
if (!window.console) { window.console = {}; }
if (typeof window.console.log !== 'function' ) { window.console.log = function() {}; }
if (typeof window.console.warn !== 'function') { window.console.warn = function() {}; }
window.PLbm = function() {
  new PageLens.LinkCreator();
};
