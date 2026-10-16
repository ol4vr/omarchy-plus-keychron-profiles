const assert = require("node:assert/strict");
const model = require("../Model.js");

const ready = model.parseStatus(JSON.stringify({
  schema: 1,
  state: "ready",
  message: "Gamepad hardware profile active.",
  connection: "wired",
  activeIndex: 2,
  activeProfile: "Gamepad",
  profileCount: 3,
  serial: "SERIAL1"
}));

assert.ok(ready);
assert.equal(model.profileName(0), "Default");
assert.equal(model.profileName(1), "Profile 2");
assert.equal(model.profileName(2), "Gamepad");
assert.equal(model.icon(ready), "󰊗");
assert.equal(model.canSwitch(ready), true);
assert.equal(model.stateLabel(ready), "Gamepad");
assert.match(model.tooltip(ready), /Gamepad · Wired/);

const disconnected = model.parseStatus(JSON.stringify({
  schema: 1,
  state: "disconnected",
  message: "No supported wired K10 HE is connected.",
  activeIndex: null,
  activeProfile: null
}));
assert.ok(disconnected);
assert.equal(model.canSwitch(disconnected), false);
const profile2 = model.parseStatus(JSON.stringify({
  schema: 1,
  state: "ready",
  message: "Profile 2 hardware profile active.",
  connection: "wired",
  activeIndex: 1,
  activeProfile: "Profile 2",
  profileCount: 3,
  serial: "SERIAL1"
}));
assert.ok(profile2);
assert.equal(model.canSwitch(profile2), false);
assert.equal(model.stateLabel(profile2), "Profile 2");
assert.equal(model.stateLabel(disconnected), "Disconnected");
assert.equal(model.parseStatus("not json"), null);
assert.equal(model.parseStatus(JSON.stringify({ schema: 1, state: "ready", activeIndex: 4 })), null);

console.log("Keychron Profiles model tests: PASS");
