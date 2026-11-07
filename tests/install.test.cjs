const {test}=require('node:test'),assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process'),path=require('node:path');
const fs=require('node:fs'),os=require('node:os');
const script=path.join(__dirname,'../install.sh');
test('help is available without installing',()=>assert.equal(spawnSync('bash',[script,'--help']).status,0));
test('unknown options are rejected',()=>assert.equal(spawnSync('bash',[script,'--unknown']).status,2));
test('unsafe roots are refused',()=>assert.notEqual(spawnSync('bash',[script],{env:{...process.env,REPLITDECK_ROOT:'/'}}).status,0));
test('rollback excludes the active version even with a build suffix',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'replit rollback '));
 try {
  const old=path.join(root,'versions/1.0.0-1'),current=path.join(root,'versions/2.0.0-2');
  for(const [dir,v] of [[old,'1.0.0'],[current,'2.0.0']]){fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(path.join(dir,'VERSION'),v);}
  fs.symlinkSync(current,path.join(root,'current'));
  const r=spawnSync('bash',[path.join(__dirname,'../libexec/update.sh'),'--rollback'],{env:{...process.env,REPLITDECK_ROOT:root},encoding:'utf8'});
  assert.equal(r.status,0,r.stderr);assert.equal(fs.realpathSync(path.join(root,'current')),old);
 }finally{fs.rmSync(root,{recursive:true,force:true});}
});
