module.exports = {
  apps: [{
    name: 'nextjs',
    script: 'npm',
    args: 'start',
    env: {
      PORT: 3000,
      NODE_ENV: 'production'
    },
    watch: false,
    autorestart: true
  }]
}
