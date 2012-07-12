Prereqs:
  - node.js >= 0.6 (with npm)
  - git
  - Foreman
  - Make
  - an account on heroku, joyent, azure, linode, or rackspace

What the user creates:
  - package.json
  - app code
  - git repository
  - .gitignore
  - Procfile
  - nimbus.json

What the user does:

  $ nimbus list

    lists all the targets defined in the nimbus.json file

  $ nimbus provision `serviceName`

    provisions the service at `serviceName`

    - root: add keys to the remote system
    - root: upgrade basic systems (build chain, etc)
    - root: create user for the service
    - local: render scripts for the service
    - local: copy rendered scripts to the remote machine
    - serviceuser: run the remote scripts

  $ nimbus update `serviceName`

    updates the service at `serviceName`
    (for example, updating config files, environment settings...)
    (should be non-destructive... no risk of losing user data)
    (should be fast & not require a restart)

  $ nimbus deploy `serviceName` [branch|hash]

    deploys the git branch or hash specified to `serviceName`

    - system does a git push to remote
    - post-receive hook on remote copies the checked out codebase into a versions/{{gitHash}} directory
    - post-receive hook then runs npm install
    - if npm install goes okay, post-receive hook does an rsync between the new version and the /current directory running the app
    - post-receive hook restarts foreman

TODO:
  - set NODE_ENV to production via .env.json