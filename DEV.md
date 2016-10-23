Development
===

## Build and release

### Build local p2 repo

```bash
./gradlew updateSiteZip --stacktrace
```

### Release to bintray

```bash
export BINTRAY_USER={your_bintray_user}
export BINTRAY_API_KEY={your_bintray_api_key}

./gradlew updateSiteZip publishP2Repo --stacktrace
```