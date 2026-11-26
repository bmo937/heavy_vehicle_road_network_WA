import 'package:flutter/foundation.dart';

/// Identifies one restoration of application-owned map state after a style
/// (or controller) change. Only a run that is still current may mutate the map.
class StyleRestorationRun {
  final int generation;
  final MapStyleRestorationCoordinator _owner;

  StyleRestorationRun._(this.generation, this._owner);

  /// False once a newer style/controller change began or the owner was disposed.
  bool get isCurrent => _owner._generation == generation;
}

/// One unit of application-owned map state to restore.
///
/// [action] returns true on success; returning false or throwing is a failure.
/// A failed [required] step prevents the map from being reported as restored;
/// a failed optional step is only logged.
class StyleRestorationStep {
  const StyleRestorationStep(this.name, this.action, {this.required = true});

  final String name;
  final bool required;
  final Future<bool> Function(StyleRestorationRun run) action;
}

enum StyleRestorationOutcome {
  /// Every required step succeeded for the current style.
  completed,

  /// A required step failed; the style loaded but app state is incomplete.
  failed,

  /// A newer style/controller change (or disposal) made this run stale.
  superseded,
}

/// Latest-wins sequencing for style restoration.
///
/// Separate from NetworkRefreshCoordinator: that one guards HTTP refreshes
/// triggered by camera movement, this one guards the whole restoration of
/// application-owned resources for one style/controller.
class MapStyleRestorationCoordinator {
  int _generation = 0;

  /// Starts a new run, making every earlier run stale.
  StyleRestorationRun begin() => StyleRestorationRun._(++_generation, this);

  /// Makes any in-flight run stale (style change started, controller replaced,
  /// disposal) without starting a new one.
  void invalidate() => _generation++;

  /// Runs [steps] in order. Steps are sequential because later ones depend on
  /// earlier ones (e.g. symbol layers need marker images). After every step the
  /// run's freshness is re-checked, so a stale run stops touching the map.
  Future<StyleRestorationOutcome> restore(StyleRestorationRun run, List<StyleRestorationStep> steps) async {
    var requiredFailed = false;
    for (final step in steps) {
      if (!run.isCurrent) return StyleRestorationOutcome.superseded;
      var ok = false;
      try {
        ok = await step.action(run);
      } catch (e) {
        debugPrint('Style restoration step "${step.name}" threw: ${e.runtimeType}');
      }
      if (!run.isCurrent) return StyleRestorationOutcome.superseded;
      if (!ok) {
        debugPrint('Style restoration step "${step.name}" failed (${step.required ? "required" : "optional"})');
        if (step.required) requiredFailed = true;
      }
    }
    return requiredFailed ? StyleRestorationOutcome.failed : StyleRestorationOutcome.completed;
  }
}
