// dart format off
import 'drag_table.dart';

/// Standard G1/G7 Cd-vs-Mach reference tables.
///
/// Provenance: JBM Ballistics "More Drag Functions" downloads, which states
/// these G-function tables were obtained from the U.S. Ballistics Research
/// Laboratory (BRL). Values are stored verbatim; interpolation is delegated to
/// [DragTable]. Retrieved 2026-09-24.
///
/// IMPORTANT: these tables establish trusted reference drag data only. They do
/// not by themselves validate SNIPER TÜRK's full aerodynamic trajectory solver.
abstract final class StandardDragTables {
  static const sourceName = 'JBM Ballistics / BRL standard drag functions';
  static const g1SourceUrl = 'https://jbmballistics.com/downloads/mcg1.txt';
  static const g7SourceUrl = 'https://jbmballistics.com/downloads/mcg7.txt';

  static final g1 = DragTable(const [
    DragSample(0.00,0.2629), DragSample(0.05,0.2558), DragSample(0.10,0.2487), DragSample(0.15,0.2413), DragSample(0.20,0.2344), DragSample(0.25,0.2278), DragSample(0.30,0.2214), DragSample(0.35,0.2155), DragSample(0.40,0.2104), DragSample(0.45,0.2061), DragSample(0.50,0.2032), DragSample(0.55,0.2020), DragSample(0.60,0.2034), DragSample(0.70,0.2165), DragSample(0.725,0.2230), DragSample(0.75,0.2313), DragSample(0.775,0.2417), DragSample(0.80,0.2546), DragSample(0.825,0.2706), DragSample(0.85,0.2901), DragSample(0.875,0.3136), DragSample(0.90,0.3415), DragSample(0.925,0.3734), DragSample(0.95,0.4084), DragSample(0.975,0.4448), DragSample(1.0,0.4805), DragSample(1.025,0.5136), DragSample(1.05,0.5427), DragSample(1.075,0.5677), DragSample(1.10,0.5883), DragSample(1.125,0.6053), DragSample(1.15,0.6191), DragSample(1.20,0.6393), DragSample(1.25,0.6518), DragSample(1.30,0.6589), DragSample(1.35,0.6621), DragSample(1.40,0.6625), DragSample(1.45,0.6607), DragSample(1.50,0.6573), DragSample(1.55,0.6528), DragSample(1.60,0.6474), DragSample(1.65,0.6413), DragSample(1.70,0.6347), DragSample(1.75,0.6280), DragSample(1.80,0.6210), DragSample(1.85,0.6141), DragSample(1.90,0.6072), DragSample(1.95,0.6003), DragSample(2.00,0.5934), DragSample(2.05,0.5867), DragSample(2.10,0.5804), DragSample(2.15,0.5743), DragSample(2.20,0.5685), DragSample(2.25,0.5630), DragSample(2.30,0.5577), DragSample(2.35,0.5527), DragSample(2.40,0.5481), DragSample(2.45,0.5438), DragSample(2.50,0.5397), DragSample(2.60,0.5325), DragSample(2.70,0.5264), DragSample(2.80,0.5211), DragSample(2.90,0.5168), DragSample(3.00,0.5133), DragSample(3.10,0.5105), DragSample(3.20,0.5084), DragSample(3.30,0.5067), DragSample(3.40,0.5054), DragSample(3.50,0.5040), DragSample(3.60,0.5030), DragSample(3.70,0.5022), DragSample(3.80,0.5016), DragSample(3.90,0.5010), DragSample(4.00,0.5006), DragSample(4.20,0.4998), DragSample(4.40,0.4995), DragSample(4.60,0.4992), DragSample(4.80,0.4990), DragSample(5.00,0.4988),
  ]);

  static final g7 = DragTable(const [
    DragSample(0.00,0.1198), DragSample(0.05,0.1197), DragSample(0.10,0.1196), DragSample(0.15,0.1194), DragSample(0.20,0.1193), DragSample(0.25,0.1194), DragSample(0.30,0.1194), DragSample(0.35,0.1194), DragSample(0.40,0.1193), DragSample(0.45,0.1193), DragSample(0.50,0.1194), DragSample(0.55,0.1193), DragSample(0.60,0.1194), DragSample(0.65,0.1197), DragSample(0.70,0.1202), DragSample(0.725,0.1207), DragSample(0.75,0.1215), DragSample(0.775,0.1226), DragSample(0.80,0.1242), DragSample(0.825,0.1266), DragSample(0.85,0.1306), DragSample(0.875,0.1368), DragSample(0.90,0.1464), DragSample(0.925,0.1660), DragSample(0.95,0.2054), DragSample(0.975,0.2993), DragSample(1.0,0.3803), DragSample(1.025,0.4015), DragSample(1.05,0.4043), DragSample(1.075,0.4034), DragSample(1.10,0.4014), DragSample(1.125,0.3987), DragSample(1.15,0.3955), DragSample(1.20,0.3884), DragSample(1.25,0.3810), DragSample(1.30,0.3732), DragSample(1.35,0.3657), DragSample(1.40,0.3580), DragSample(1.50,0.3440), DragSample(1.55,0.3376), DragSample(1.60,0.3315), DragSample(1.65,0.3260), DragSample(1.70,0.3209), DragSample(1.75,0.3160), DragSample(1.80,0.3117), DragSample(1.85,0.3078), DragSample(1.90,0.3042), DragSample(1.95,0.3010), DragSample(2.00,0.2980), DragSample(2.05,0.2951), DragSample(2.10,0.2922), DragSample(2.15,0.2892), DragSample(2.20,0.2864), DragSample(2.25,0.2835), DragSample(2.30,0.2807), DragSample(2.35,0.2779), DragSample(2.40,0.2752), DragSample(2.45,0.2725), DragSample(2.50,0.2697), DragSample(2.55,0.2670), DragSample(2.60,0.2643), DragSample(2.65,0.2615), DragSample(2.70,0.2588), DragSample(2.75,0.2561), DragSample(2.80,0.2533), DragSample(2.85,0.2506), DragSample(2.90,0.2479), DragSample(2.95,0.2451), DragSample(3.00,0.2424), DragSample(3.10,0.2368), DragSample(3.20,0.2313), DragSample(3.30,0.2258), DragSample(3.40,0.2205), DragSample(3.50,0.2154), DragSample(3.60,0.2106), DragSample(3.70,0.2060), DragSample(3.80,0.2017), DragSample(3.90,0.1975), DragSample(4.00,0.1935), DragSample(4.20,0.1861), DragSample(4.40,0.1793), DragSample(4.60,0.1730), DragSample(4.80,0.1672), DragSample(5.00,0.1618),
  ]);
}
