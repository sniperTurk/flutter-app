# V111 changelog

- Hardened persistent profile writes against lost-update races.
- `PersistentProfileStore` now serializes save/remove read-modify-write operations across all store instances, matching the app's current architecture where Home and Profiles screens may own different store objects.
- The mutation queue recovers after an individual persistence failure instead of blocking every later write.
- Added a regression test that concurrently saves through two independent `PersistentProfileStore` instances and requires both profiles to survive.
- No ballistic solver behavior, catalog values, or production G1/G7 gate state changed in this release.
