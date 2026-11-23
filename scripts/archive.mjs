#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { root, readJSON, hash } from './common.mjs';
import { check } from './check.mjs';

try {
  const c=check();
  if(!c.initialized)throw Error('Initialize a real project before preparing a release');
  const tag=process.env.RELEASE_TAG;
  if(!/^v\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?$/.test(tag||''))throw Error('Set RELEASE_TAG to a semantic version tag');
  const git=(...args)=>{const r=spawnSync('git',args,{cwd:root,encoding:'utf8'});if(r.status!==0)throw Error(r.stderr);return r.stdout.trim();};
  if(git('status','--porcelain'))throw Error('Release requires a clean checkout');
  if(git('cat-file','-t',tag)!=='tag')throw Error('Release requires an annotated tag');
  if(git('rev-parse',`${tag}^{commit}`)!==git('rev-parse','HEAD'))throw Error('Release tag must resolve to this exact commit');
  const a=readJSON(path.join(root,'docs/ACCEPTANCE.json'));
  // An owner may release with honestly documented live gaps. This requires both
  // a source-bound authorization record and an explicit per-commit dispatch flag.
  const authorizedPending=a.status==='pending-live'
    && process.env.RELEASE_ACCEPT_PENDING_LIVE===git('rev-parse','HEAD')
    && a.version===tag.slice(1)
    && a.release_authorization?.version===a.version
    && a.release_authorization?.input_commit===a.input_commit
    && a.release_authorization?.actor && a.release_authorization?.statement
    && Array.isArray(a.pending) && a.pending.length>0;
  if((a.status!=='passed'&&!authorizedPending)||!a.platform||!a.date||!Array.isArray(a.commands)||!a.commands.length||!Array.isArray(a.results)||!a.results.length||!/^[a-f0-9]{40}$/.test(a.input_commit||''))throw Error('Record actual acceptance evidence before release');
  // Evidence may be recorded in a later docs-only commit, never after a runtime change.
  git('merge-base','--is-ancestor',a.input_commit,'HEAD');
  const changed=git('diff','--name-only',a.input_commit,'HEAD').split('\n').filter(Boolean);
  if(changed.some(f=>!f.startsWith('docs/')&&!['README.md','CREDITS.md'].includes(f)))throw Error('Runtime/build inputs changed after acceptance');
  if(fs.readFileSync(path.join(root,'VERSION'),'utf8').trim()!==tag.slice(1))throw Error('VERSION must match tag');
  if(readJSON(path.join(root,'manifest.json')).version!==tag.slice(1))throw Error('Manifest version must match tag');
  const out=path.join(root,'dist');fs.mkdirSync(out,{recursive:true});
  const archive=path.join(out,`${c.slug}-${tag}-source.tar.gz`);
  const r=spawnSync('git',['archive','--format=tar.gz',`--prefix=${c.slug}/`,'-o',archive,'HEAD'],{cwd:root,encoding:'utf8'});
  if(r.status!==0)throw Error(r.stderr);
  const source={repository:`https://github.com/${c.owner}/${c.repo}`,commit:git('rev-parse','HEAD'),tree:git('rev-parse','HEAD^{tree}')};
  const version=tag.slice(1),created=git('show','-s','--format=%cI','HEAD');
  const write=(name,value)=>fs.writeFileSync(path.join(out,name),JSON.stringify(value,null,2)+'\n');
  const entry=name=>({name,bytes:fs.statSync(path.join(out,name)).size,sha256:hash(fs.readFileSync(path.join(out,name)))});
  write('SOURCE-MANIFEST.json',{schemaVersion:1,version,source,format:'Complete tracked Git source; not an installable binary',acceptance:a.input_commit});
  write('SBOM.spdx.json',{
    spdxVersion:'SPDX-2.3',dataLicense:'CC0-1.0',SPDXID:'SPDXRef-DOCUMENT',name:`${c.slug}-${tag}`,
    documentNamespace:`${source.repository}/releases/spdx/${version}-${source.commit}`,
    creationInfo:{creators:[`Tool: ${c.slug}/scripts/archive.mjs`],created:new Date(created).toISOString().replace('.000Z','Z')},
    packages:[{name:c.slug,SPDXID:'SPDXRef-Package',versionInfo:version,downloadLocation:`git+${source.repository}.git@${source.commit}`,
      filesAnalyzed:false,licenseConcluded:'NOASSERTION',licenseDeclared:'MIT',copyrightText:'NOASSERTION',
      checksums:[{algorithm:'SHA256',checksumValue:entry(path.basename(archive)).sha256}],
      comment:'Source package inventory only. Runtime dependencies are supplied by Omarchy; third-party marks and notices are documented in CREDITS.md.'}],
    relationships:[{spdxElementId:'SPDXRef-DOCUMENT',relationshipType:'DESCRIBES',relatedSpdxElement:'SPDXRef-Package'}]
  });
  const artifacts=[entry(path.basename(archive))],releaseDocuments=['SOURCE-MANIFEST.json','SBOM.spdx.json'].map(entry);
  write('RELEASE-MANIFEST.json',{schemaVersion:1,version,source,artifacts,releaseDocuments});
  fs.writeFileSync(path.join(out,'SHA256SUMS'),[...artifacts,...releaseDocuments,entry('RELEASE-MANIFEST.json')].map(e=>`${e.sha256}  ${e.name}\n`).join(''));
  console.log(`Created ${archive}. This is a source archive, not an installable application binary.`);
} catch(e){console.error(e.message);process.exitCode=1;}
