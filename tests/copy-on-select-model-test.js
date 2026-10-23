const assert = require("node:assert/strict");
const model = require("../CopyOnSelectModel.js");

const enabled = model.parseStatus(JSON.stringify({
  schema: 1,
  state: "ready",
  enabled: true
}));
const disabled = model.parseStatus(JSON.stringify({
  schema: 1,
  state: "ready",
  enabled: false
}));

assert.ok(enabled);
assert.ok(disabled);
assert.equal(enabled.enabled, true);
assert.equal(disabled.enabled, false);
assert.equal(model.canToggle(enabled), true);
assert.equal(model.canToggle(disabled), true);
assert.equal(model.canToggle(model.failure("failed")), false);
assert.equal(model.parseStatus("not json"), null);
assert.equal(model.parseStatus(JSON.stringify({ schema: 1, state: "ready" })), null);
assert.equal(model.parseStatus(JSON.stringify({ schema: 1, state: "ready", enabled: 1 })), null);

console.log("Copy on Select model tests: PASS");
