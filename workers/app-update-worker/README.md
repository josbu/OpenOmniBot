# Omnibot App Update Worker

Cloudflare Worker for public app update checks and authenticated release metadata management. Release metadata and aggregate check counters are stored in a KV namespace.

## Routes

- `GET /updates?currentVersion=0.5.0.3&edition=omniinfer&source=cnb&includeBeta=true`
  - Public endpoint used by the Android app.
  - Increments aggregate visit counters on every request.
- `POST /admin/releases`
  - Requires `Authorization: Bearer <ADMIN_TOKEN>`.
  - Upserts a release tag and APK assets.
- `DELETE /admin/releases/:tag`
  - Requires admin auth.
  - Removes a tag so clients stop seeing a retracted package.
- `GET /admin/releases`
  - Requires admin auth.
- `GET /admin/stats`
  - Requires admin auth.

## Deploy

Create a KV namespace, bind it to the Worker as `APP_UPDATE_KV`, then configure the admin token.

Dashboard binding:

- Resource type: `KV 命名空间`
- Variable name: `APP_UPDATE_KV`
- KV namespace: the namespace created for app updates

Wrangler deployment:

```bash
wrangler kv namespace create APP_UPDATE_KV
cp wrangler.toml.example wrangler.toml
# Put the created namespace id in wrangler.toml.
wrangler secret put ADMIN_TOKEN
wrangler deploy
```

Use the deployed Worker URL as:

- Android Gradle property: `OMNIBOT_UPDATE_WORKER_URL`
- GitHub Actions secret: `APP_UPDATE_WORKER_URL`

Use the same token as the GitHub Actions secret `APP_UPDATE_WORKER_TOKEN`.
