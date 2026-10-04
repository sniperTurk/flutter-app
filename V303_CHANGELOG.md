# V303

- Made `tools/bootstrap_ios_scaffold.sh` transactional when replacing an existing `ios/` scaffold.
- The previous `ios/` tree is moved to a private temporary backup before generation.
- Any failure during Flutter scaffold generation or later metadata/privacy validation removes the partial new tree and restores the previous tree.
- Successful completion deletes the temporary backup.
- Symlinked `ios` directories remain fail-closed.
- Added regression coverage that executes a deliberately failing fake Flutter generator and proves the old iOS tree is restored.
