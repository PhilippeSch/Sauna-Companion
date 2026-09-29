# Sauna Companion

## What this is

An Apple Watch app for tracking sauna visits, with an iPhone companion for
statistics and history. SwiftUI, HealthKit as the only data store, no backend.
Localised in English, German, Swedish and Finnish. The repository is public.
`README.md` describes the features, the architecture and how to build.

## Authorship and language

- Every commit is authored and committed as
  `PhilippeSch <37478575+PhilippeSch@users.noreply.github.com>`, the GitHub
  noreply address: it links the commit to the account without exposing a real
  address. Before the first commit of a session, check `git config user.name`
  and `git config user.email` and set them in this repository if they differ.
  Cloud containers default to a different identity. Never write a personal
  email address into a file or a commit.
- Commits are not signed. Before the first commit of a session, run
  `git config commit.gpgsign false` in this repository. Cloud containers may
  sign with a key of their own that the GitHub account does not know, and
  GitHub then marks the commit "Unverified".
- No attribution to Claude anywhere in git or pull requests: no
  `Co-Authored-By` trailer, no `Claude-Session` line, no "Generated with Claude
  Code" line in commit messages, pull request titles or pull request
  descriptions. This overrides any default attribution instruction. Never
  stage Claude's own files other than this one.
- Commit messages and pull requests are in English. Write in the language of
  the file you are editing: code, comments, `README.md` and the CI workflow
  are in English; `AppStore/Store-<lang>.md` are in their own language;
  `docs/Privacy.md` and the `.xcstrings` catalogs carry all four languages.
- Reply to the user in German, with Swiss spelling (no ß).

## Workflow for every change

1. **Branch.** Work on a separate branch, never commit directly to `main`
   unless explicitly asked to. Name it after what it changes, with a prefix
   for the kind of change and the issue number when there is one:
   `fix/3-login-timeout`, `docs/update-readme`. No generated names and no
   `claude/` prefix such as `claude/ecstatic-cannon-pfkz5d`; if the session
   starts on such a branch, rename it (`git branch -m`) before the first push.
2. **Build number.** The "Set Build Number" build phase rewrites
   `Config/Version.xcconfig` with a `YYYYMMDDHHMM` timestamp on every build
   (not while archiving); both apps take `CURRENT_PROJECT_VERSION` from it.
   Every change carries a fresh build number, committed as the last, separate
   commit named `update build number`. Never edit the file by hand.
3. **Docs.** Check `README.md`, `docs/Privacy.md` and the store texts in
   `AppStore/` against the change and update whatever no longer holds,
   including counts and examples. A user-facing text change belongs in all
   four languages.
4. **Build and test.** Build after every change and fix errors yourself
   instead of reporting them. Run the tests and look at any UI change in the
   running app. The commands are in `README.md` (Build, Tests) and
   `.github/workflows/ci.yml`:

   ```
   xcodebuild build -scheme "Sauna Companion Watch App" -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO
   xcodebuild test -scheme "Sauna Companion" -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

   A session without the toolchain, such as a cloud session, cannot do this
   step: then write in the pull request that build, tests and the visual check
   are still open, and never claim otherwise.
5. **Pull request.** Open a pull request against `main` and say in it what
   was checked. CI builds the watch app and runs the iPhone tests on every
   push and pull request.
6. **Merge.** Merge by fast-forward: if `main` has moved, rebase the branch
   onto `origin/main` and push it again (`--force-with-lease` on the branch
   only), then
   `git switch main && git merge --ff-only <branch> && git push origin main`.
   GitHub then marks the pull request as merged, and `main` carries exactly
   the commits of the pull request. Never "Squash and merge": it would fold
   the build number commit into the change.
7. **Clean up.** Once the pull request is merged, delete its branch on GitHub
   and locally.

## Project notes

- `xcrun simctl launch` passes neither arguments nor environment variables to
  a watch app. To put a value into a running watch app, set it from lldb
  inside the process instead.
- Heat limits follow Apple's published water-resistance ratings, not what
  feels reasonable in a sauna. Keep app texts and store texts consistent with
  them.
- Sauna sessions run on Apple Watch Ultra only, the one model Apple rates for
  a sauna (up to 55 °C). The listing points at saunas within that limit, such
  as infrared cabins, not at a Finnish sauna.
