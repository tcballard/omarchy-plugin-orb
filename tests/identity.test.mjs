import {test} from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import {root,readJSON,validate} from '../scripts/common.mjs';

test('project identity is valid and rejects paths, reserved IDs and multiline values',()=>{
  const c=readJSON(path.join(root,'.template/project.json'));
  validate(c);
  for(const patch of [{slug:'../../x'},{owner:'-flag'},{id:'omarchy.foo.bar'},{name:'x\ny'},{repo:'../other'},{inspiration:'https://user:pass@example.com'}]) assert.throws(()=>validate({...c,...patch}));
});
