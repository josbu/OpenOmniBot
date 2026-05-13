# Omnibot App Update Worker

Cloudflare Worker for public app update checks, authenticated release metadata management, and APK delivery through Cloudflare R2. Release metadata and aggregate check counters are stored in KV; APK files are stored in R2.

## Routes

- `GET /updates?currentVersion=0.5.0.3&edition=omniinfer&source=worker&includeBeta=true`
  - Public endpoint used by the Android app.
  - Increments aggregate visit counters on every request.
  - Returns `apkDownloadUrl` pointing at this Worker.
- `GET /downloads/:tag/:asset`
  - Public APK download endpoint backed by R2.
- `PUT /admin/releases/:tag/assets/:asset`
  - Requires `Authorization: Bearer <ADMIN_TOKEN>`.
  - Streams an APK or `.apk.sha256` file into the bound R2 bucket.
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

Create a KV namespace and an R2 bucket, bind them to the Worker, then configure the admin token.

Dashboard binding:

- Resource type: `KV 命名空间`
- Variable name: `APP_UPDATE_KV`
- KV namespace: the namespace created for app updates
- Resource type: `R2 bucket`
- Variable name: `APP_UPDATE_BUCKET`
- R2 bucket: the bucket that stores APK release files

Wrangler deployment:

```bash
wrangler kv namespace create APP_UPDATE_KV
wrangler r2 bucket create omnibot-app-updates
cp wrangler.toml.example wrangler.toml
# Put the created namespace id and bucket name in wrangler.toml.
wrangler secret put ADMIN_TOKEN
wrangler deploy
```

Use the deployed Worker URL as:

- Android Gradle property: `OMNIBOT_UPDATE_WORKER_URL`
- GitHub Actions secret: `APP_UPDATE_WORKER_URL`

Use the same token as the GitHub Actions secret `APP_UPDATE_WORKER_TOKEN`.

GitHub release publishing uploads staged APKs with:

```bash
curl --request PUT \
  --header "Authorization: Bearer $APP_UPDATE_WORKER_TOKEN" \
  --header "Content-Type: application/vnd.android.package-archive" \
  --upload-file OpenOmniBot-v1.6.2-omniinfer.apk \
  "$APP_UPDATE_WORKER_URL/admin/releases/v1.6.2/assets/OpenOmniBot-v1.6.2-omniinfer.apk"
```
