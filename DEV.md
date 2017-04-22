Development
===

## Build and release

### Build local p2 repo

```bash
./gradlew updateSiteZip --stacktrace
```

### Build beta to Bintray

```bash
export BINTRAY_USER={your_bintray_user}
export BINTRAY_API_KEY={your_bintray_api_key}

./gradlew updateSiteZip publishP2Repo --stacktrace
```

### Build release to Bintray

```bash
./gradlew updateSiteZip publishP2Repo -DBINTRAY_USER={your_bintray_user} -DBINTRAY_API_KEY={your_bintray_api_key} -DBUILD_MODE=release
```
