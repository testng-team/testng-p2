Development
===

## Build and release

### Build beta

```bash
./gradlew updateSiteZip --stacktrace
```

### Build release

```bash
./gradlew clean updateSiteZip -DBUILD_MODE=release
```
