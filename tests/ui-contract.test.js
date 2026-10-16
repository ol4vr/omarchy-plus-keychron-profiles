const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));
const service = fs.readFileSync(path.join(root, "Service.qml"), "utf8");
const indicators = fs.readFileSync(path.join(root, "Indicators.qml"), "utf8");
const gamepad = fs.readFileSync(path.join(root, "indicators", "GamepadMode.qml"), "utf8");
const helper = fs.readFileSync(path.join(root, "keychron-profiles"), "utf8");
const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");
const thirdParty = fs.readFileSync(path.join(root, "THIRD_PARTY.md"), "utf8");

test("manifest declares a singleton owned Indicators clone", () => {
  assert.equal(manifest.id, "io.github.ol4vr.keychron-profiles");
  assert.equal(manifest.version, "0.1.1");
  assert.deepEqual(manifest.kinds, ["service", "bar-widget"]);
  assert.equal(manifest.entryPoints.service, "Service.qml");
  assert.equal(manifest.entryPoints.barWidget, "Indicators.qml");
  assert.equal(manifest.barWidget.allowMultiple, false);
  assert.equal(manifest.barWidget.defaultSection, "center");
  assert.equal(manifest.omarchy.clonedFrom, "omarchy.indicators");
  assert.equal(manifest.author, "ol4vr");
  assert.equal(manifest.barWidget.defaults.serial, "");
});

test("only the process-wide service owns polling and helper processes", () => {
  assert.match(service, /interval: 2000/);
  assert.match(service, /triggeredOnStart: true/);
  assert.equal((service.match(/Process \{/g) || []).length, 2);
  assert.doesNotMatch(gamepad, /Process \{/);
  assert.doesNotMatch(gamepad, /Timer \{/);
  assert.match(gamepad, /serviceFor\("io\.github\.ol4vr\.keychron-profiles"\)/);
});

test("one directly clickable Gamepad toggle replaces the standalone UI", () => {
  assert.equal(fs.existsSync(path.join(root, "BarWidget.qml")), false);
  assert.equal(fs.existsSync(path.join(root, "Panel.qml")), false);
  assert.match(indicators, /result\.push\("GamepadMode"\)/);
  assert.match(gamepad, /root\.service\.selectProfile\(root\.gamepadEnabled \? "default" : "gamepad"\)/);
  assert.doesNotMatch(gamepad, /Panel|Popup|Loader|Fn\s*\+/);
});

test("toggle state is hardware-confirmed and unavailable states are distinct", () => {
  assert.match(gamepad, /gamepadEnabled: hardwareReady && snapshot\.activeIndex === 2/);
  assert.match(gamepad, /active: root\.unavailable \|\| root\.gamepadEnabled/);
  assert.match(gamepad, /interactive: belongsInBlock && root\.hardwareReady && !root\.busy/);
  assert.match(gamepad, /Color\.urgent/);
  assert.match(gamepad, /Profile 2 active/);
  assert.doesNotMatch(service, /activeIndex\s*=\s*[02]/);
});

test("helper source contains only the approved HE command constants", () => {
  assert.match(helper, /GET_PROFILES_INFO = 0x10/);
  assert.match(helper, /SELECT_PROFILE = 0x11/);
  assert.doesNotMatch(helper, /SET_CURVE|SAVE_PROFILE|RESET_PROFILE|CALIBR/);
  assert.match(helper, /SELECTABLE_PROFILES = \{"default": 0, "gamepad": 2\}/);
});

test("release documentation records recovery, clone reconciliation, and hardware limits", () => {
  assert.match(readme, /scripts\/plugins\/reconcile/);
  assert.match(readme, /Omarchy Indicators clone maintenance/);
  assert.match(readme, /supports only the wired K10 HE/);
  assert.match(readme, /Q1 HE 8K/);
  assert.match(thirdParty, /c668141e9c42b13c80c9ca4ea108e11708c5e8a5/);
  assert.match(thirdParty, /No mutable\s+upstream branch is an automatic update authority/);
});
