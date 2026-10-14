"""Focused migration checks. No shell instance or system actions are started."""
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OVERVIEW = ROOT / "modules/ii/overview"
ENGINE = (ROOT / "services/LauncherSearch.qml").read_text()


def qml_function(name):
    match = re.search(r"^    function " + name + r"\(.*?^    }", ENGINE, re.M | re.S)
    if not match:
        raise AssertionError(f"missing function {name}")
    return re.sub(r":\s*(?:string|bool|var|int|real)\b", "", match.group())


@unittest.skipUnless(shutil.which("node"), "node required for QML JavaScript contracts")
class LauncherIntegration(unittest.TestCase):
    def run_js(self, source):
        completed = subprocess.run(["node", "-e", source], text=True, capture_output=True, timeout=10)
        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_every_registered_panel_has_implementation(self):
        registry = (ROOT / "modules/common/SearchPanelRegistry.qml").read_text()
        sources = re.findall(r'source:\s*"([^"]+Panel.qml)"', registry)
        self.assertEqual(len(set(sources)), 24)
        for source in sources:
            self.assertTrue((OVERVIEW / source).is_file(), source)
        widget = (OVERVIEW / "SearchWidget.qml").read_text()
        self.assertIn("SearchPanelHost {", widget)
        self.assertIn("SearchKeyRouter {", widget)
        self.assertIn("consumePendingSearchPanel()", widget)

    def test_existing_overview_styles_and_search_ipc(self):
        host = (OVERVIEW / "Overview.qml").read_text()
        self.assertIn("NiriOverview {", host)
        self.assertIn("OverviewWidget {", host)
        self.assertIn("!GlobalStates.searchPanelActive", host)
        for method in ["open", "close", "toggle", "setQuery", "openPanel"]:
            self.assertRegex(host, r"function " + method + r"\(")
        self.assertIn("surfaceMonitorName: panelWindow.screen?.name", host)

    def test_power_requires_two_current_session_activations(self):
        self.run_js("""
const assert = require('node:assert/strict');
const root = {confirmKey: '', _scheduleResultsUpdate() {}};
const resultComp = {createObject(_parent, properties) {return properties;}};
const Translation = {tr(text) {return text;}};
const LauncherSearchResult = {IconType: {Material: 0}};
const GlobalStates = {overviewOpen: true};
""" + qml_function("createSystemControlResult") + """
let calls = 0;
const def = {cmd: 'poweroff', label: 'Power off', requiresConfirmation: true, execute() {calls++;}};
createSystemControlResult(def).execute();
assert.equal(calls, 0);
assert.equal(root.confirmKey, 'poweroff');
const armed = createSystemControlResult(def);
armed.execute();
assert.equal(calls, 1);
assert.equal(root.confirmKey, '');
// A retained armed result cannot execute after dismissal or a changed query.
root.confirmKey = '';
armed.execute();
assert.equal(calls, 1);
GlobalStates.overviewOpen = false;
armed.execute();
assert.equal(calls, 1);
GlobalStates.overviewOpen = true;
root.confirmKey = 'reboot';
armed.execute();
assert.equal(calls, 1);
// Lock/suspend remain single-step as defined by the engine.
createSystemControlResult({...def, cmd: 'lock', requiresConfirmation: false}).execute();
assert.equal(calls, 2);
""")
        item = (OVERVIEW / "SearchItem.qml").read_text()
        callback = item[item.index("    onClicked: {"):]
        self.assertLess(callback.index("            execute();"), callback.index("            GlobalStates.overviewOpen = false;"))
        self.assertRegex(ENGINE, r"onQueryChanged:[\s\S]*?root.confirmKey = \"\";")

    def test_calculator_conversions_and_qalc_route(self):
        self.run_js("const assert = require('node:assert/strict'); const Config = {options: {search: {prefix: {math: '='}}}};\n"
                    + qml_function("normalizeMathExpression") + """
assert.equal(normalizeMathExpression('= 20% of 150'), '20% * 150');
assert.equal(normalizeMathExpression('10 km to mi'), '10 km to -mi');
assert.equal(normalizeMathExpression('255 to hex'), '255 to hex');
assert.equal(normalizeMathExpression('32 F em C'), '32 F to -C');
""")
        self.assertIn('const command = ["qalc", "-t"]', ENGINE)
        self.assertIn("mathProc.pendingExpression !== root.normalizeMathExpression(root.query)", ENGINE)

    def test_clipboard_and_legacy_module_migration(self):
        clipboard = (ROOT / "services/Cliphist.qml").read_text()
        self.assertIn('readErrors.text.trim() === "opening db: please store something first"', clipboard)
        self.assertIn("exitCode === 0 || emptyDatabase", clipboard)
        config = (ROOT / "modules/common/Config.qml").read_text()
        self.assertIn('typeof modules[key] === "boolean"', config)
        self.assertIn("root.options.search.modules[key].enable = modules[key]", config)
        self.assertIn('property string materialSymbols: "."', config)


if __name__ == "__main__":
    unittest.main()
