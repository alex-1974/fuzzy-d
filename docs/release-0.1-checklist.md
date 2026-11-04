# fuzzy-d 0.1.0 release-candidate checklist

Status: preparation checklist; no release has been published.

## Locally demonstrated

- [x] DMD 2.111.0 library tests
- [x] LDC 1.42.0 library tests
- [x] DMD release consumer smoke
- [x] LDC release consumer smoke
- [x] DMD Ddoc build
- [x] representative benchmark harness
- [x] thermostat consumer and conformance grid
- [x] prepared worker-clone behavior
- [x] multi-output buffer and prepared paths
- [x] explicit No-Result and Missing-Input behavior

Run the local gates with:

```sh
bash tools/qualify.sh
```

## Required external confirmation

- [ ] CI release matrix passes DMD 2.111.0, 2.112.1 and 2.113.0.
- [ ] CI release matrix passes LDC 1.41.0, 1.42.0 and 1.43.0.
- [ ] No compiler-specific failure is hidden by a local workaround.
- [ ] Package metadata, license and changelog checks pass on the release branch.
- [ ] Maintainer reviews the candidate public API and migration note.

## Release decision

Publish `0.1.0` only after every external confirmation is checked. If a matrix
entry fails, record the exact compiler/configuration and either fix it, narrow
the support claim, or document the toolchain issue before release.

