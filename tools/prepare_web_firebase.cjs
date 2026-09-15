// Writes only public Firebase SDK settings, never service-account credentials.
const { execFileSync } = require('node:child_process');
const { writeFileSync } = require('node:fs');
const project = process.argv[2];
if (!project) throw new Error('Firebase project ID is required');
function firebase(args) {
  const output = execFileSync('firebase', [...args, '--project', project, '--non-interactive', '--json'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'] });
  const data = JSON.parse(output);
  if (data.status !== 'success') throw new Error('Firebase command failed');
  return data.result;
}
const apps = firebase(['apps:list', 'WEB']);
if (!Array.isArray(apps)) throw new Error('Unexpected Firebase apps response');
let app = apps.find(x => x.displayName === 'Auto Deals Iraq Web');
if (!app && apps.length === 1) app = apps[0];
if (!app) app = firebase(['apps:create', 'WEB', 'Auto Deals Iraq Web']);
if (!app.appId || !app.appId.includes(':web:')) throw new Error('Missing Firebase Web app ID');
const result = firebase(['apps:sdkconfig', 'WEB', app.appId]);
const source = result.sdkConfig;
if (!source) throw new Error('Firebase CLI did not return Web SDK configuration');
const config = {};
for (const key of ['apiKey', 'appId', 'projectId', 'messagingSenderId', 'authDomain', 'storageBucket', 'measurementId', 'databaseURL']) {
  if (typeof source[key] === 'string' && source[key]) config[key] = source[key];
}
for (const key of ['apiKey', 'appId', 'projectId', 'messagingSenderId']) {
  if (!config[key]) throw new Error('Missing public Firebase setting: ' + key);
}
if (config.projectId !== project || config.appId !== app.appId) throw new Error('Firebase configuration does not match selected app');
writeFileSync('build/web/firebase-config.json', JSON.stringify(config, null, 2));
console.log('Firebase Web configuration prepared for ' + project);
