// Guard for live harnesses that drive the real host desktop (not an omadev nest).
// They move the pointer, send keys, launch apps and edit Orb settings, so they
// run only with an explicit opt-in while the desktop is idle.
if (process.env.ORB_LIVE_HOST !== '1') {
  console.error(`${require('node:path').basename(require.main.filename)} controls the real host desktop. ` +
    'Run it only on an idle desktop with ORB_LIVE_HOST=1. Agents: do not set this yourself; ask the owner.');
  process.exit(2);
}
