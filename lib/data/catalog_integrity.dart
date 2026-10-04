import '../models/domain.dart';

class CatalogIssue {
  final String collection;
  final String id;
  final String message;
  const CatalogIssue(this.collection, this.id, this.message);
  @override
  String toString() => '$collection/$id: $message';
}

/// Static catalog guardrails. These checks are intentionally independent from
/// Flutter so the same rules can be reused by future JSON/remote importers.
class CatalogIntegrity {
  const CatalogIntegrity();

  List<CatalogIssue> validate({
    required Iterable<Rifle> rifles,
    required Iterable<Ammunition> ammunition,
    required Iterable<ScopeOptic> scopes,
  }) {
    final issues = <CatalogIssue>[];
    _duplicateIds('rifles', rifles.map((e) => e.id), issues);
    _duplicateIds('ammunition', ammunition.map((e) => e.id), issues);
    _duplicateIds('scopes', scopes.map((e) => e.id), issues);

    for (final r in rifles) {
      if (r.id.trim().isEmpty)
        issues.add(const CatalogIssue('rifles', '<empty>', 'id is required'));
      if (r.brand.trim().isEmpty || r.model.trim().isEmpty)
        issues.add(CatalogIssue('rifles', r.id, 'brand/model is required'));
      if (!r.caliberMm.isFinite || r.caliberMm <= 0)
        issues.add(
          CatalogIssue('rifles', r.id, 'caliberMm must be finite and > 0'),
        );
      if (r.magazineCapacity != null && r.magazineCapacity! <= 0)
        issues.add(
          CatalogIssue(
            'rifles',
            r.id,
            'magazineCapacity must be > 0 when present',
          ),
        );
      for (final value in <MapEntry<String, double?>>[
        MapEntry('barrelLengthMm', r.barrelLengthMm),
        MapEntry('airCapacityCc', r.airCapacityCc),
        MapEntry('overallLengthMm', r.overallLengthMm),
        MapEntry('weightKg', r.weightKg),
        MapEntry('plenumCc', r.plenumCc),
      ]) {
        if (value.value != null &&
            (!value.value!.isFinite || value.value! <= 0))
          issues.add(
            CatalogIssue(
              'rifles',
              r.id,
              '${value.key} must be finite and > 0 when present',
            ),
          );
      }
      if ((r.sourceName == null) != (r.sourceDocument == null))
        issues.add(
          CatalogIssue(
            'rifles',
            r.id,
            'sourceName and sourceDocument must be supplied together',
          ),
        );
      if (r.brand != 'Manuel' && r.sourceName == null)
        issues.add(
          CatalogIssue(
            'rifles',
            r.id,
            'non-manual catalog records require provenance',
          ),
        );
    }
    for (final a in ammunition) {
      if (a.id.trim().isEmpty)
        issues.add(
          const CatalogIssue('ammunition', '<empty>', 'id is required'),
        );
      if (a.brand.trim().isEmpty || a.model.trim().isEmpty)
        issues.add(CatalogIssue('ammunition', a.id, 'brand/model is required'));
      if (!a.caliberMm.isFinite || a.caliberMm <= 0)
        issues.add(
          CatalogIssue('ammunition', a.id, 'caliberMm must be finite and > 0'),
        );
      if (!a.grain.isFinite || a.grain <= 0)
        issues.add(
          CatalogIssue('ammunition', a.id, 'grain must be finite and > 0'),
        );
      if (a.ballisticCoefficient != null &&
          (!a.ballisticCoefficient!.isFinite || a.ballisticCoefficient! <= 0)) {
        issues.add(
          CatalogIssue(
            'ammunition',
            a.id,
            'ballisticCoefficient must be finite and > 0 when present',
          ),
        );
      }
      if ((a.ballisticCoefficient == null) != (a.ballisticModel == null)) {
        issues.add(
          CatalogIssue(
            'ammunition',
            a.id,
            'ballisticCoefficient and ballisticModel must be supplied together',
          ),
        );
      }
      if ((a.sourceName == null) != (a.sourceDocument == null)) {
        issues.add(
          CatalogIssue(
            'ammunition',
            a.id,
            'sourceName and sourceDocument must be supplied together',
          ),
        );
      }
      if (a.brand != 'Manuel' && a.sourceName == null) {
        issues.add(
          CatalogIssue(
            'ammunition',
            a.id,
            'non-manual catalog records require provenance',
          ),
        );
      }
    }
    for (final s in scopes) {
      if (s.id.trim().isEmpty)
        issues.add(const CatalogIssue('scopes', '<empty>', 'id is required'));
      if (s.brand.trim().isEmpty || s.model.trim().isEmpty)
        issues.add(CatalogIssue('scopes', s.id, 'brand/model is required'));
      if (!s.objectiveDiameterMm.isFinite || s.objectiveDiameterMm <= 0)
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'objectiveDiameterMm must be finite and > 0',
          ),
        );
      if (!s.clickValue.isFinite || s.clickValue <= 0)
        issues.add(
          CatalogIssue('scopes', s.id, 'clickValue must be finite and > 0'),
        );
      for (final value in <MapEntry<String, double?>>[
        MapEntry('objectiveOuterDiameterMm', s.objectiveOuterDiameterMm),
        MapEntry('tubeDiameterMm', s.tubeDiameterMm),
        MapEntry('minMagnification', s.minMagnification),
        MapEntry('maxMagnification', s.maxMagnification),
        MapEntry('elevationRangeMrad', s.elevationRangeMrad),
        MapEntry('windageRangeMrad', s.windageRangeMrad),
        MapEntry('lengthMm', s.lengthMm),
        MapEntry('weightG', s.weightG),
      ]) {
        if (value.value != null &&
            (!value.value!.isFinite || value.value! <= 0)) {
          issues.add(
            CatalogIssue(
              'scopes',
              s.id,
              '${value.key} must be finite and > 0 when present',
            ),
          );
        }
      }
      if (s.minMagnification != null &&
          s.maxMagnification != null &&
          s.minMagnification! > s.maxMagnification!) {
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'minMagnification must be <= maxMagnification',
          ),
        );
      }
      if (s.objectiveOuterDiameterMm != null &&
          s.objectiveOuterDiameterMm! < s.objectiveDiameterMm) {
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'objectiveOuterDiameterMm cannot be smaller than objectiveDiameterMm',
          ),
        );
      }
      // Lower-bound provenance is meaningful only when the corresponding
      // manufacturer adjustment range is actually present. Reject orphaned
      // flags so consumers never render an unknown range as a published `>`
      // value merely because stale provenance metadata survived an edit.
      if (s.elevationRangeIsLowerBound && s.elevationRangeMrad == null) {
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'elevationRangeIsLowerBound requires elevationRangeMrad',
          ),
        );
      }
      if (s.windageRangeIsLowerBound && s.windageRangeMrad == null) {
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'windageRangeIsLowerBound requires windageRangeMrad',
          ),
        );
      }
      if ((s.sourceName == null) != (s.sourceDocument == null)) {
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'sourceName and sourceDocument must be supplied together',
          ),
        );
      }
      if (s.brand != 'Manuel' && s.sourceName == null) {
        issues.add(
          CatalogIssue(
            'scopes',
            s.id,
            'non-manual catalog records require provenance',
          ),
        );
      }
    }
    return List.unmodifiable(issues);
  }

  void _duplicateIds(
    String collection,
    Iterable<String> ids,
    List<CatalogIssue> issues,
  ) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id))
        issues.add(CatalogIssue(collection, id, 'duplicate id'));
    }
  }
}
