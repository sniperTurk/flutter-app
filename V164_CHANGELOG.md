# V164 Changelog

- Continued from V163 without reverting catalog or test-hardening work.
- Added five manufacturer-verified active Vector Optics riflescopes missing from the bundled catalog: Forester SCOM-02, Forester SCOM-16, Forester JR SCOM-35, Paragon GenII SCOM-25 and Paragon GenII SCOL-27.
- Retailer/discovery listings were not used as technical authority. Stored fields come from Vector Optics official product pages verified 2026-09-27.
- Preserved native click units. Manufacturer MOA adjustment ranges are explicitly converted to MRAD only because the current domain model stores total range in MRAD.
- Added unittest-discoverable regression coverage for critical specs, provenance and unique scope IDs.
