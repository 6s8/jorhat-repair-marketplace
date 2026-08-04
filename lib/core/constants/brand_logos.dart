/// Maps each brand name to its local asset path under `assets/brands/`.
/// SVG files are rendered via `flutter_svg`; PNG files via `Image.asset`.
///
/// Key   → brand name (matches [applianceBrands])
/// Value → asset path string
const Map<String, String> brandLogoAssets = {
  'Samsung':   'assets/brands/samsung.png',   // PNG
  'LG':        'assets/brands/lg.svg',         // SVG
  'Godrej':    'assets/brands/godrej.png',     // PNG
  'Whirlpool': 'assets/brands/whirlpool.svg',  // SVG
  'Haier':     'assets/brands/haier.svg',      // SVG
  'Voltas':    'assets/brands/voltas.png',     // PNG
  'Blue Star': 'assets/brands/bluestar.svg',   // SVG
  'Panasonic': 'assets/brands/panasonic.svg',  // SVG
  'IFB':       'assets/brands/ifb.png',        // PNG
};
