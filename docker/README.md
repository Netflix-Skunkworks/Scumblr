# Docker environment for Scumblr 2.0

This is a docker configuration for Scumblr 2.0 suitable for non-production use

## Quick start

1. Add API keys and configure the admin user account name and password in `scumblr-vars.env`
2. Run `docker-compose up` from the directory of `Dockerfile`
3. After rails and sidekiq are started on the scumblr container visit `http://localhost:3000`

## Advanced

The default docker compose configuration passes the `init` argument to the Scumblr container's entrypoint. This will cause the scumblr container to attempt initializion of the scumblr database on the postgres container. If the postgres container's volumes are to be persisted consider removing this argument after a successful initialization.

Bash or ruby scripts added to the `/docker-init.d` folder will be run at the start of the scumblr container when `init` is passed to the entrypoint. If they are dependent on each other ensure they execute in the correct order.
