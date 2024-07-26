# normalizepath

Normalizes path using one (or more) heuristics.

---

Get the latest [release](https://github.com/Reproducible-Bioinformatics/normalizepath/releases/latest).

Usage example:

```R
normalized <- normalize_path(
    path = "../the/path/to_normalize",
    path_mappers = c(docker_mount_mapper)
)
```
