# V296

- Hardened the production `ManualCatalogStore`: both loaded records and new upserts are now structurally validated. Unknown kinds/platforms, invalid numeric values, and firearm/PCP ammunition-type mismatches fail closed before reaching the catalog UI or persistent storage.
- Added a platform-derived `ValueKey` to the legacy manual-catalog ammunition dropdown so its field state cannot retain an item that is no longer present after a PCP/firearm switch. The live catalog already had the equivalent v295 protection.
- Added source-level regression coverage for both protections.
- Real Flutter analyzer/tests remain pending because the pinned Flutter/Dart SDK is unavailable in this environment.
