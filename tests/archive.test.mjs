import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';

test('release source preserves checks and binds manifests, SBOM and checksums',()=>{
  const source=path.resolve(import.meta.dirname,'..');
  const temp=fs.mkdtempSync(path.join(os.tmpdir(),'orb-archive-'));
  const repo=path.join(temp,'repo');fs.mkdirSync(repo);
  const run=(cwd,cmd,args,env={})=>{
    const r=spawnSync(cmd,args,{cwd,encoding:'utf8',env:{...process.env,...env},timeout:30000});
    assert.equal(r.status,0,r.stderr||r.stdout);return r.stdout.trim();
  };
  try {
    const files=run(source,'git',['ls-files','--cached','--others','--exclude-standard','-z']).split('\0');
    for(const file of files){if(!file || !fs.existsSync(path.join(source,file)))continue;const to=path.join(repo,file);fs.mkdirSync(path.dirname(to),{recursive:true});fs.copyFileSync(path.join(source,file),to);fs.chmodSync(to,fs.statSync(path.join(source,file)).mode);}
    const git=(...args)=>run(repo,'git',args);
    git('init','-q');git('config','user.name','Orb archive test');git('config','user.email','test@example.invalid');git('config','commit.gpgsign','false');git('config','tag.gpgsign','false');
    git('add','.');git('commit','-qm','Synthetic runtime fixture');
    const input=git('rev-parse','HEAD');
    fs.writeFileSync(path.join(repo,'docs/ACCEPTANCE.json'),JSON.stringify({status:'passed',input_commit:input,platform:'Synthetic archive fixture; not desktop acceptance',date:'2026-10-19',commands:['fixture'],results:['fixture']}));
    git('add','docs/ACCEPTANCE.json');git('commit','-qm','Synthetic evidence');
    const version=fs.readFileSync(path.join(repo,'VERSION'),'utf8').trim(),tag='v'+version;
    git('tag','-a',tag,'-m','Temporary fixture tag');
    run(repo,process.execPath,['scripts/archive.mjs'],{RELEASE_TAG:tag});
    const dir=path.join(repo,'dist'),read=name=>JSON.parse(fs.readFileSync(path.join(dir,name)));
    const release=read('RELEASE-MANIFEST.json'),manifest=read('SOURCE-MANIFEST.json'),sbom=read('SBOM.spdx.json');
    assert.equal(release.version,version);assert.equal(release.source.commit,git('rev-parse','HEAD'));assert.equal(release.source.tree,git('rev-parse','HEAD^{tree}'));assert.deepEqual(manifest.source,release.source);
    assert.equal(sbom.spdxVersion,'SPDX-2.3');assert.equal(sbom.packages.length,1);assert.equal(sbom.packages[0].versionInfo,version);assert.ok(sbom.packages[0].downloadLocation.endsWith('@'+release.source.commit));
    const digest=name=>createHash('sha256').update(fs.readFileSync(path.join(dir,name))).digest('hex');
    const entries=[...release.artifacts,...release.releaseDocuments];
    for(const entry of entries){assert.equal(entry.sha256,digest(entry.name));assert.equal(entry.bytes,fs.statSync(path.join(dir,entry.name)).size);}
    const sums=Object.fromEntries(fs.readFileSync(path.join(dir,'SHA256SUMS'),'utf8').trim().split('\n').map(line=>{const [hash,name]=line.split('  ');return [name,hash];}));
    assert.deepEqual(Object.keys(sums).sort(),[...entries.map(e=>e.name),'RELEASE-MANIFEST.json'].sort());
    for(const [name,hash] of Object.entries(sums))assert.equal(hash,digest(name));
    const unpack=path.join(temp,'unpack');fs.mkdirSync(unpack);run(repo,'tar',['-xzf',path.join(dir,release.artifacts[0].name),'-C',unpack]);
    const extracted=path.join(unpack,'omarchy-plugin-orb');
    for(const required of ['tests/run','scripts/template.mjs','.template/project.json','.github/workflows/ci.yml'])assert.ok(fs.existsSync(path.join(extracted,required)));
    run(extracted,process.execPath,['scripts/check.mjs']);run(extracted,process.execPath,['tests/model.cjs']);
    const denied=(releaseTag,pattern)=>{const r=spawnSync(process.execPath,['scripts/archive.mjs'],{cwd:repo,encoding:'utf8',env:{...process.env,RELEASE_TAG:releaseTag}});assert.ifError(r.error);assert.notEqual(r.status,0);assert.match(r.stderr+r.stdout,pattern);};
    git('tag','v9.9.9');denied('v9.9.9',/annotated tag/);
    const pending={status:'pending-live',version,input_commit:input,platform:'Synthetic fixture; no desktop acceptance',date:'2026-10-20',commands:['fixture'],results:['portable fixture'],pending:['live desktop'],release_authorization:{version,input_commit:input,actor:'Fixture owner',statement:'Release with documented live gaps'}};
    fs.writeFileSync(path.join(repo,'docs/ACCEPTANCE.json'),JSON.stringify(pending));
    git('add','docs/ACCEPTANCE.json');git('commit','-qm','Synthetic limited release authorization');
    git('tag','-d',tag);git('tag','-a',tag,'-m','Temporary authorized fixture tag');
    denied(tag,/Record actual acceptance/);
    const wrong=spawnSync(process.execPath,['scripts/archive.mjs'],{cwd:repo,encoding:'utf8',env:{...process.env,RELEASE_TAG:tag,RELEASE_ACCEPT_PENDING_LIVE:input}});
    assert.notEqual(wrong.status,0);assert.match(wrong.stderr,/Record actual acceptance/);
    run(repo,process.execPath,['scripts/archive.mjs'],{RELEASE_TAG:tag,RELEASE_ACCEPT_PENDING_LIVE:git('rev-parse','HEAD')});
    fs.appendFileSync(path.join(repo,'README.md'),'\nDirty fixture\n');denied(tag,/clean checkout/);
  }finally{fs.rmSync(temp,{recursive:true,force:true});}
});
