# Internals

Material for the maintainers of SDSF. Users read `docs/`, `docs/installation.md` and the books in `docs/books/`.

| File | What it covers |
|---|---|
| [architecture.md](architecture.md) | The modules, the source files, how a panel is built, where the data comes from |
| [development.md](development.md) | Build, host and MVS tests, deploy, the test jobs |
| [authorization.md](authorization.md) | RAKF, the authorized state, the SVC routine `IGX00011`, how they fit together |
| [pitfalls.md](pitfalls.md) | What has bitten before: Wally ISPF, panels, SMP, MVS/CE, JCL |
| [releasing.md](releasing.md) | How a release is cut, the books included |
| [open-work.md](open-work.md) | What each open issue needs, as of the 1.2.0 release |
| [terms.md](terms.md) | The words the help panels, the books and the code share |

**Scope.** SDSF is modeled on IBM's SDSF V1R2, as far as a user can see and do things with it. There is no 1.3.0: all further work is 1.2.x. Where the model's behaviour is not known, the code says so in a comment and an issue carries the open question.

**Public repository rules.**
- IBM's product is named only as "IBM's SDSF V1R2", the model that was looked at and rebuilt.
- No IBM material is copied or committed: no panel texts, no internals, no module names of IBM's SDSF. `internals/ref/` and `internals/screens/` are excluded from the repository and stay that way.
- No names of private systems, host names or job numbers in code, docs, commits or issues.
- The authorization is SDSF's own (RAKF). It is not modeled on IBM's.
