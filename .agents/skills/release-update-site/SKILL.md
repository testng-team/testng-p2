---
name: release-update-site
description: Release a new TestNG P2 update site. Bumps the TestNG version in testng-p2, builds the p2 repo with Gradle, copies it into the sibling testng-p2-update-site repo, and opens PRs for both. Use when asked to release, publish, or update to a new TestNG version (e.g. "update to testng 7.12.0").
argument-hint: "TestNG version, e.g. 7.12.0"
---

# Release a TestNG P2 update site

Two GitHub repos are involved (use `gh`, not `glab`):

| Repo | Path | Role |
| --- | --- | --- |
| `testng-team/testng-p2` | current repo | Gradle build that produces the p2 site |
| `testng-team/testng-p2-update-site` | `../testng-p2-update-site` (ask if missing) | Published update sites, base branch `main` |

`<ver>` = TestNG release, e.g. `7.12.0`. `<qualifier>` = build timestamp, e.g. `r202611210109`. Full version = `<ver>.<qualifier>`.

Commit, push, and open PRs only when the user asked for the release. Otherwise stop after the build and report.

## 1. Preconditions

- Working tree of both repos is clean.
- Build needs **JDK 8** (Gradle 2.13 wrapper; CI uses JDK 8). Check `java -version`.
  - No sudo: download Azul Zulu 8 tarball into `~/.jdks`, then `jenv add ~/.jdks/<dir>/Contents/Home`. The repo's committed `.java-version` selects JDK 8 via jenv.

## 2. Bump the version in testng-p2

1. Confirm the release exists: `https://repo1.maven.org/maven2/org/testng/testng/maven-metadata.xml` (`<release>`).
2. Read `https://repo1.maven.org/maven2/org/testng/testng/<ver>/testng-<ver>.pom` and compare its dependency versions (jcommander, snakeyaml, ...) with the pins in `build.gradle`. Update `bundle` lines that differ. Keep the existing `exclude` entries.
3. In `build.gradle` set `version = '<ver>'` (no `-SNAPSHOT`; the release build asserts this).
4. Branch and PR, following earlier release PRs:
   ```bash
   git switch -c release/<ver>
   git add build.gradle
   git commit -m "feat: update to testng:<ver>"
   git push -u origin HEAD
   gh pr create --base master --title "feat: update to testng:<ver>" --body "..."
   ```
   State in the body whether the release build was run.

## 3. Build the release site

```bash
./gradlew updateSiteZip -DBUILD_MODE=release
```

`updateSiteZip` depends on `clean`. Outputs in `build/`:

- `build/updatesite/` (`artifacts.jar`, `content.jar`, `features/`, `plugins/`)
- `build/updatesite.zip`
- `build/category.xml` — read `<qualifier>` from the feature file name (`org.testng.p2.feature_<ver>.<qualifier>.jar`).

Sanity check: `plugins/` has `org.testng_<ver>.jar`, jcommander, jquery, snakeyaml and their `.source_` jars, and **no** slf4j-api or bsh.

## 4. Copy into testng-p2-update-site

Let `U=../testng-p2-update-site`, `Q=<ver>.<qualifier>`.

```bash
cd $U && git switch main && git pull --ff-only && git switch -c release/<ver>
mkdir -p updatesites/$Q zipped/$Q <ver>
cp -R ../testng-p2/build/updatesite/. updatesites/$Q/
cp ../testng-p2/build/updatesite.zip zipped/$Q/updatesite.zip
```

Then update the indexes. Mirror the previous release commits (`git log`, `git show <ver-commit>`).

**New version** (no `<ver>/` directory yet):

- Create `<ver>/compositeArtifacts.xml` and `<ver>/compositeContent.xml` by copying the latest version's files and replacing the child with `<child location="../updatesites/$Q"/>`.
- Append `<child location="<ver>"/>` as the last child in the root `compositeArtifacts.xml` and `compositeContent.xml`.
- Add `* https://testng.org/testng-p2-update-site/<ver>` at the top of the versioned list in `README.md`.

**Rebuild of an existing version** (`<ver>/` exists): only change the child location in `<ver>/compositeArtifacts.xml` and `<ver>/compositeContent.xml` to `../updatesites/$Q`. Keep old `updatesites/` and `zipped/` directories.

## 5. Commit, push, PR (update-site)

```bash
git add README.md compositeArtifacts.xml compositeContent.xml <ver> updatesites/$Q zipped/$Q
git commit -m "release $Q"
git push -u origin HEAD
gh pr create --base main --title "release $Q" --body "..."
```

PR body: update site path, zip path, composite changes, bundle versions, and a link to the testng-p2 PR.

## Verify

- `git show --stat HEAD` in the update-site repo lists only the files above.
- Both `<ver>/composite*.xml` point to `../updatesites/$Q`, and that directory exists.
- Report the two PR URLs and anything not verified (e.g. install into Eclipse was not tested).
