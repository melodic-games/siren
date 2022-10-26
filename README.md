# Siren

## Recommended git config

If possible add this to avoid merge conflicts

```toml
[merge]
	tool = unityyamlmerge
[mergetool "unityyamlmerge"]
	trustExitCode = false
	cmd = 'C:\\Program Files\\Unity\\Hub\\Editor\\2021.3.10f1\\Editor\\Data\\Tools\\UnityYAMLMerge.exe' merge -p "$BASE" "$REMOTE" "$LOCAL" "$MERGED"
```
