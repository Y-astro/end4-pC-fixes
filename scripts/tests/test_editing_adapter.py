"""Exercise the migrated menu persistence and widget alignment without a shell."""
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]


class EditingAdapterTest(unittest.TestCase):
    def test_menu_layout_and_alignment(self):
        source = (ROOT / 'services/ContextMenus.qml').read_text()
        menus = source.split('readonly property var menus:', 1)[1].split('function definition', 1)[0].strip()
        methods = []
        for name, arguments, body in re.findall(r'^    function (\w+)\((.*?)\)(?:: \w+)? \{(.*?)^    \}', source, re.M | re.S):
            arguments = re.sub(r':\s*\w+', '', arguments)
            methods.append(f'function {name}({arguments}) {{{body}}}\nroot.{name} = {name};')
        align = (ROOT / 'modules/common/functions/widget_align.js').read_text().replace('.pragma library', '')
        script = '''const assert = require('node:assert/strict');
const calls = [];
const Quickshell = {execDetached: command => calls.push(command)};
const GlobalStates = {desktopMenuOpen: true};
const root = { cfg: {style:'comfortable',layouts:[],customEntries:[]} };
Object.defineProperty(root, 'compact', {get: () => root.cfg.style === 'compact'});
'''
        script += f'root.menus = ({menus});\n' + '\n'.join(methods)
        script += '''
const live = root.definition('desktop').entries.filter(e => !e.header);
const base = root.arrange('desktop', live);
assert(base.rows.some(e => e.id === 'widgets'));
let layout = root.layoutFor('desktop');
layout.order = ['settings', ...layout.order.filter(id => id !== 'settings')];
layout.hidden = ['widgets'];
root.setLayout('desktop', layout);
assert.equal(root.arrange('desktop', live).rows[0].id, 'settings');
assert(!root.arrange('desktop', live).rows.some(e => e.id === 'widgets'));
root.cfg.style = 'compact';
assert(root.arrange('desktop', live).bar.some(e => e.id === 'settings'));
assert(!root.arrange('desktop', live).rows.some(e => e.id === 'settings'));
const id = root.addCustom('desktop', 'terminal', 'Open folder', 'printf "%s" "$II_CONTEXT_TARGET"');
assert(root.arrange('desktop', live).rows.some(e => e.id === id));
root.updateCustom(id, 'folder', 'Changed', 'pwd');
assert.equal(root.customEntriesFor('desktop')[0].title, 'Changed');
root.runCustom(root.customEntriesFor('desktop')[0], '/tmp/space and $(literal)');
assert.deepEqual(calls[0], ['env', 'II_CONTEXT_TARGET=/tmp/space and $(literal)', 'bash', '-c', 'pwd']);
root.setLayout('bar', {order:['settings','edit'], hidden:[], bar:[]});
root.removeCustom(id);
assert(!root.layoutFor('desktop').order.includes(id));
root.resetLayout('desktop');
assert(root.storedLayout('bar'));
assert.equal(root.storedLayout('desktop'), null);
root.cfg.layouts = [{menu:'desktop', order:['removed-entry','separator','settings'], hidden:[], bar:[]}];
const resolved = root.layoutFor('desktop');
assert(!resolved.order.includes('removed-entry'));
assert(resolved.order.includes('widgets'));
const rows = root.arrange('desktop', live).rows;
assert(!rows[0].separator && !rows[rows.length - 1].separator);
'''
        script += align + '''
const members = [
 {id:'a',x:24,y:32,box:{x:24,y:32,width:60,height:50},minX:0,maxX:900,minY:0,maxY:700},
 {id:'b',x:180,y:80,box:{x:180,y:80,width:90,height:70},minX:0,maxX:900,minY:0,maxY:700},
 {id:'c',x:420,y:120,box:{x:420,y:120,width:40,height:60},minX:0,maxX:900,minY:0,maxY:700}
];
const aligned = deltas(members,'left');
for (const m of members) assert.equal(m.box.x + (aligned[m.id]?.dx ?? 0), 24);
const spread = deltas(members,'hdistribute');
assert.equal(spread.a?.dx ?? 0,0); assert.equal(spread.c?.dx ?? 0,0);
assert.equal(members[1].box.x + spread.b.dx - 84, 420 - (members[1].box.x + spread.b.dx + 90));
console.log('Menu arrangement, persistence, custom commands, alignment and distribution passed.');
'''
        result = subprocess.run(['node', '-e', script], text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
