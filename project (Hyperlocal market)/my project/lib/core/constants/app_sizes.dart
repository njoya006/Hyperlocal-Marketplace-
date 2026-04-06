/// App size constants for HyperLocal Market.
/// 
/// Defines spacing, padding, border radius, font sizes, and icon sizes
/// used throughout the application for consistent UI design.
abstract final class AppSizes {
  // ============== SPACING & PADDING ==============
  /// Minimal spacing - 2px
  static const double xs = 2.0;

  /// Extra small spacing - 4px
  static const double xxs = 4.0;

  /// Small spacing - 8px
  static const double sm = 8.0;

  /// Medium-small spacing - 12px
  static const double md = 12.0;

  /// Medium spacing - 16px (default spacing unit)
  static const double lg = 16.0;

  /// Large spacing - 20px
  static const double xl = 20.0;

  /// Extra large spacing - 24px
  static const double xxl = 24.0;

  /// 2XL spacing - 32px
  static const double xxxl = 32.0;

  /// 3XL spacing - 40px
  static const double xxxxl = 40.0;

  /// 4XL spacing - 48px
  static const double xxxxxl = 48.0;

  // ============== PADDING ==============
  /// Standard screen padding
  static const double screenPadding = lg;

  /// Container padding
  static const double containerPadding = lg;

  /// Card padding
  static const double cardPadding = lg;

  /// Button padding (horizontal)
  static const double buttonPaddingH = xl;

  /// Button padding (vertical)
  static const double buttonPaddingV = md;

  /// Input field padding
  static const double inputPadding = lg;

  // ============== BORDER RADIUS ==============
  /// Small border radius - 4px
  static const double radiusSm = 4.0;

  /// Medium border radius - 8px
  static const double radiusMd = 8.0;

  /// Large border radius - 12px
  static const double radiusLg = 12.0;

  /// Extra large border radius - 16px
  static const double radiusXl = 16.0;

  /// 2XL border radius - 20px
  static const double radiusXxl = 20.0;

  /// Circular border radius (fully circular)
  static const double radiusCircular = 50.0;

  /// Default card border radius
  static const double cardBorderRadius = radiusLg;

  /// Default button border radius
  static const double buttonBorderRadius = radiusMd;

  /// Default input border radius
  static const double inputBorderRadius = radiusMd;

  // ============== DIVIDER & BORDER ==============
  /// Thin border width - 0.5px
  static const double borderThin = 0.5;

  /// Standard border width - 1px
  static const double borderStandard = 1.0;

  /// Medium border width - 1.5px
  static const double borderMedium = 1.5;

  /// Thick border width - 2px
  static const double borderThick = 2.0;

  // ============== FONT SIZES ==============
  /// Extra small font size - 10px
  static const double fontXs = 10.0;

  /// Small font size - 12px
  static const double fontSm = 12.0;

  /// Medium-small font size - 14px
  static const double fontMd = 14.0;

  /// Base font size - 16px (default)
  static const double fontBase = 16.0;

  /// Large font size - 18px
  static const double fontLg = 18.0;

  /// Extra large font size - 20px
  static const double fontXl = 20.0;

  /// 2XL font size - 24px
  static const double fontXxl = 24.0;

  /// 3XL font size - 28px
  static const double fontXxxl = 28.0;

  /// 4XL font size - 32px (headings)
  static const double fontXxxxl = 32.0;

  /// 5XL font size - 36px (large headings)
  static const double fontXxxxxl = 36.0;

  // ============== LINE HEIGHT ==============
  /// Tight line height - 1.2
  static const double lineHeightTight = 1.2;

  /// Normal line height - 1.5
  static const double lineHeightNormal = 1.5;

  /// Relaxed line height - 1.75
  static const double lineHeightRelaxed = 1.75;

  /// Loose line height - 2.0
  static const double lineHeightLoose = 2.0;

  // ============== ICON SIZES ==============
  /// Extra small icon - 16px
  static const double iconXs = 16.0;

  /// Small icon - 20px
  static const double iconSm = 20.0;

  /// Medium icon - 24px (default)
  static const double iconMd = 24.0;

  /// Large icon - 32px
  static const double iconLg = 32.0;

  /// Extra large icon - 40px
  static const double iconXl = 40.0;

  /// 2XL icon - 48px
  static const double iconXxl = 48.0;

  /// 3XL icon - 56px
  static const double iconXxxl = 56.0;

  // ============== COMPONENT SIZES ==============
  /// Standard app bar height
  static const double appBarHeight = 56.0;

  /// Extended app bar height
  static const double appBarExtendedHeight = 200.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 56.0;

  /// Floating action button size
  static const double fabSize = 56.0;

  /// Mini floating action button size
  static const double fabSizeMini = 40.0;

  /// Standard button height
  static const double buttonHeight = 48.0;

  /// Small button height
  static const double buttonHeightSm = 36.0;

  /// Large button height
  static const double buttonHeightLg = 56.0;

  /// Standard input field height
  static const double inputHeight = 48.0;

  /// Text field height
  static const double textFieldHeight = 56.0;

  /// List item height
  static const double listItemHeight = 56.0;

  /// Small list item height
  static const double listItemHeightSm = 48.0;

  /// Large list item height
  static const double listItemHeightLg = 72.0;

  /// Card height for product cards
  static const double productCardHeight = 200.0;

  /// Shop card height
  static const double shopCardHeight = 240.0;

  /// Shimmer loading height
  static const double shimmerHeight = 100.0;

  // ============== LAYOUT CONSTRAINTS ==============
  /// Maximum width for desktop layout
  static const double maxWidthDesktop = 1200.0;

  /// Maximum width for tablet layout
  static const double maxWidthTablet = 800.0;

  /// Minimum width for responsive layout
  static const double minWidth = 280.0;

  // ============== SHADOWS ==============
  /// Elevation small (subtle shadow)
  static const double elevationSm = 2.0;

  /// Elevation medium (standard shadow)
  static const double elevationMd = 4.0;

  /// Elevation large (prominent shadow)
  static const double elevationLg = 8.0;

  /// Elevation extra large (floating shadow)
  static const double elevationXl = 16.0;

  // ============== OPACITY ==============
  /// Disabled opacity
  static const double opacityDisabled = 0.5;

  /// Hover opacity
  static const double opacityHover = 0.8;

  /// Focus opacity
  static const double opacityFocus = 0.9;

  /// Overlay opacity
  static const double opacityOverlay = 0.6;

  // ============== ANIMATION DURATIONS ==============
  /// Very short animation duration - 100ms
  static const Duration durationVeryShort = Duration(milliseconds: 100);

  /// Short animation duration - 200ms
  static const Duration durationShort = Duration(milliseconds: 200);

  /// Medium animation duration - 300ms
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// Long animation duration - 500ms
  static const Duration durationLong = Duration(milliseconds: 500);

  /// Very long animation duration - 800ms
  static const Duration durationVeryLong = Duration(milliseconds: 800);

  /// Page transition duration - 400ms
  static const Duration durationPageTransition = Duration(milliseconds: 400);
}
