// Custom Flutter web bootstrap.
//
// Pins the CanvasKit renderer. The default ("auto") picks skwasm where the
// browser supports it, and skwasm does not composite `BackdropFilter`
// correctly: every frosted-glass surface in the Liquid Glass design system
// renders as an opaque fill that swallows its own content, leaving the app
// visually blank. CanvasKit composites the filter properly.
//
// Revisit once skwasm handles backdrop filters; until then this pin is what
// makes the glass surfaces render on web at all.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    renderer: "canvaskit",
  },
});
