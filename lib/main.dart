import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vec;
import 'package:virtual_map_test/dijkstra.dart';
import 'dart:math' as math;

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Road and intersections endpoints
const roadPoints = {
  "A": Offset(500, -682),
  "B": Offset(447, -72),
  "C": Offset(432, 679),
  "D": Offset(334, 1839),
  "E": Offset(1453, 86),
  "F": Offset(1468, 884),
  "G": Offset(-159, -1348),
  "H": Offset(-451, -284),
  "I": Offset(-732, 554),
  "J": Offset(-991, 1894),
  "K": Offset(-1620, -677),
  "L": Offset(-1914, 192)
};

class _MyAppState extends State<MyApp> {
  var viewerController = TransformationController();

  // current user position
  var position = Offset.zero;

  var searchRadius = 700.0;

  // hard coded roads in map
  final roads = [
    (roadPoints["A"]!, roadPoints["B"]!),
    (roadPoints["B"]!, roadPoints["C"]!),
    (roadPoints["C"]!, roadPoints["D"]!),
    (roadPoints["E"]!, roadPoints["B"]!),
    (roadPoints["F"]!, roadPoints["C"]!),
    (roadPoints["G"]!, roadPoints["H"]!),
    (roadPoints["H"]!, roadPoints["I"]!),
    (roadPoints["I"]!, roadPoints["J"]!),
    (roadPoints["H"]!, roadPoints["B"]!),
    (roadPoints["I"]!, roadPoints["C"]!),
    (roadPoints["H"]!, roadPoints["K"]!),
    (roadPoints["I"]!, roadPoints["L"]!),
  ];

  // location of parks and name
  final parks = {
    "Park A": const Offset(-862, -560),
    "Park B": const Offset(-1051, 1159),
    "Park C": const Offset(235, -218),
    "Park D": const Offset(1235.4, 968.2)
  };

  // helper function to find closest point to nearest road from any location in map, also returns index of road
  (Offset, int) closestPointOnRoad(Offset from) {
    Offset? closestPoint;
    double? distanceSqToPoint;
    int? roadIndex;

    for (var (index, road) in roads.indexed) {
      var cp = closestPointBetween2D(from, road.$1, road.$2);
      var dist = (cp - from).distanceSquared;
      if (closestPoint == null || dist < distanceSqToPoint!) {
        closestPoint = cp;
        distanceSqToPoint = dist;
        roadIndex = index;
      }
    }
    return (closestPoint!, roadIndex!);
  }

  // return nearest park if any in search radius
  String? getNearestPark() {
    String? nearestPark;
    double? distance;
    for (var park in parks.entries) {
      var pd = (park.value - position).distanceSquared;
      if ((nearestPark == null || distance! > pd) &&
          pd < math.pow(searchRadius, 2)) {
        nearestPark = park.key;
        distance = pd;
      }
    }
    return nearestPark;
  }

  // get all parks in search radius
  List<(String, double)> getParksInRadius() {
    List<(String, double)> nearParks = [];
    for (var park in parks.entries) {
      var pd = (park.value - position).distanceSquared;
      if (pd < math.pow(searchRadius, 2)) {
        nearParks.add((park.key, pd));
      }
    }
    return nearParks;
  }

  // return path to nearest park
  List<Offset>? getPathToNearestPark() {
    var park = getNearestPark();
    if (park != null) {
      return getPathToPark(park);
    }
    return null;
  }

  // returns shortest path to given park uusing dijkstra's algorithm
  List<Offset> getPathToPark(String park) {
    var startPoint = closestPointOnRoad(position);
    var endPoint = closestPointOnRoad(parks[park]!);

    var nodes = <Offset>{};
    for (var road in roads) {
      nodes.add(road.$1);
      nodes.add(road.$2);
    }
    nodes.add(startPoint.$1);
    nodes.add(endPoint.$1);
    var nodeList = nodes.toList();
    var graph = Graph(nodeList.length);
    for (var road in roads) {
      var si = nodeList.indexOf(road.$1);
      var di = nodeList.indexOf(road.$2);
      var distance = (road.$1 - road.$2).distanceSquared;
      graph.addEdge(si, di, distance.round());
      graph.addEdge(di, si, distance.round());
    }

    var startingRoad = roads[startPoint.$2];
    graph.addEdge(
        nodeList.indexOf(startingRoad.$1),
        nodeList.indexOf(startPoint.$1),
        (startingRoad.$1 - startPoint.$1).distanceSquared.round());
    graph.addEdge(
        nodeList.indexOf(startPoint.$1),
        nodeList.indexOf(startingRoad.$1),
        (startingRoad.$1 - startPoint.$1).distanceSquared.round());
    graph.addEdge(
        nodeList.indexOf(startingRoad.$2),
        nodeList.indexOf(startPoint.$1),
        (startingRoad.$2 - startPoint.$1).distanceSquared.round());
    graph.addEdge(
        nodeList.indexOf(startPoint.$1),
        nodeList.indexOf(startingRoad.$2),
        (startingRoad.$2 - startPoint.$1).distanceSquared.round());

    var endingRoad = roads[endPoint.$2];
    graph.addEdge(
        nodeList.indexOf(endingRoad.$1),
        nodeList.indexOf(endPoint.$1),
        (endingRoad.$1 - endPoint.$1).distanceSquared.round());

    graph.addEdge(
        nodeList.indexOf(endPoint.$1),
        nodeList.indexOf(endingRoad.$1),
        (endingRoad.$1 - endPoint.$1).distanceSquared.round());
    graph.addEdge(
        nodeList.indexOf(endingRoad.$2),
        nodeList.indexOf(endPoint.$1),
        (endingRoad.$2 - endPoint.$1).distanceSquared.round());
    graph.addEdge(
        nodeList.indexOf(endPoint.$1),
        nodeList.indexOf(endingRoad.$2),
        (endingRoad.$2 - endPoint.$1).distanceSquared.round());

    if (startPoint.$2 == endPoint.$2) {
      graph.addEdge(
          nodeList.indexOf(startPoint.$1),
          nodeList.indexOf(endPoint.$1),
          (startPoint.$1 - endPoint.$1).distanceSquared.round());

      graph.addEdge(
          nodeList.indexOf(endPoint.$1),
          nodeList.indexOf(startPoint.$1),
          (startPoint.$1 - endPoint.$1).distanceSquared.round());
    }

    var shortestPath = graph.shortestPath(
        nodeList.indexOf(startPoint.$1), nodeList.indexOf(endPoint.$1));
    return shortestPath.map((e) => nodeList[e]).toList();
  }

  // convert a list of points to distance
  double pathToDistance(List<Offset> path) {
    var distance = 0.0;
    if (path.isNotEmpty) {
      var lp = path.first;
      for (var point in path.skip(1)) {
        distance += (point - lp).distance;
        lp = point;
      }
    }
    return distance;
  }

  @override
  void initState() {
    super.initState();

    // Some initial values which look good
    position = const Offset(-398.411, -154.895);
    var zoom = 0.321;
    var pos = (309.626, 368.35);
    var mat = Matrix4.diagonal3(vec.Vector3.all(zoom));
    mat.setTranslation(vec.Vector3(pos.$1, pos.$2, 0));

    viewerController.value = mat;
  }

  @override
  Widget build(BuildContext context) {
    var path = getPathToNearestPark();
    return Scaffold(
      body: GestureDetector(
        onTapUp: (val) {
          var point = val.localPosition;
          var tPoint = Matrix4.inverted(viewerController.value)
              .transformed3(vec.Vector3(point.dx, point.dy, 0));
          setState(() {
            position = Offset(tPoint.x, tPoint.y);
          });
        },
        child: InteractiveViewer.builder(
          minScale: 0.2,
          transformationController: viewerController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          builder: (context, viewport) {
            final invertedMat = Matrix4.inverted(viewerController.value);
            final revScale = invertedMat.row0[0];
            return SizedBox(
              height: 1,
              width: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: position.dx - (searchRadius),
                    top: position.dy - (searchRadius),
                    // height: 20,
                    // width: 20,
                    child: Container(
                      key: Key("$searchRadius"),
                      width: searchRadius * 2,
                      height: searchRadius * 2,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.4),
                          border: Border.all(
                            color: Colors.blue,
                            width: 5 * revScale,
                          )),
                    ),
                  ),
                  Positioned(
                    left: position.dx - (40 * revScale) / 2,
                    top: position.dy - (40 * revScale),
                    // height: 20,
                    // width: 20,
                    child: Container(
                      child: Icon(
                        Icons.location_pin,
                        size: 40 * revScale,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CustomPaint(
                      painter: LineDrawer(
                        lines: roads,
                        width: 5 * revScale,
                      ),
                    ),
                  ),
                  ...parks.entries.map(
                    (e) => Positioned(
                      left: e.value.dx - (40 * revScale) / 2,
                      top: e.value.dy - (40 * revScale) / 2,
                      child: Icon(
                        Icons.park,
                        size: 40 * revScale,
                        color: e.key == getNearestPark()
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                  ),
                  if (path != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: CustomPaint(
                        painter: PathPainter(
                          path: path,
                          width: 5 * revScale,
                          startPoint: position,
                          endPoint: parks[getNearestPark()!]!,
                          scale: revScale,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomSheet: SizedBox(
        height: 300,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            border: Border.all(
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DropdownButton<double>(
                  value: searchRadius,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 100.0,
                      child: Text(
                        "100m",
                      ),
                    ),
                    DropdownMenuItem(
                      value: 300.0,
                      child: Text("300m"),
                    ),
                    DropdownMenuItem(
                      value: 500.0,
                      child: Text("500m"),
                    ),
                    DropdownMenuItem(
                      value: 700.0,
                      child: Text("700m"),
                    ),
                    DropdownMenuItem(
                      value: 900,
                      child: Text("900m"),
                    ),
                    DropdownMenuItem(
                      value: 1200,
                      child: Text("1200m"),
                    ),
                    DropdownMenuItem(
                      value: 1500,
                      child: Text("1500m"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        searchRadius = val;
                      });
                    }
                  },
                ),
              ),
              const Divider(),
              if (getParksInRadius().isEmpty)
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.park,
                        size: 34,
                      ),
                      Text(
                        "No park found in given search radius\nIncrease search size or change location.",
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      ...getParksInRadius()
                          .sorted((a, b) => a.$2.compareTo(b.$2))
                          .indexed
                          .map(
                            (park) => ListTile(
                              iconColor:
                                  park.$1 == 0 ? Colors.blue : Colors.green,
                              leading: const Icon(Icons.park),
                              title: Text(park.$2.$1),
                              subtitle: Text(
                                  "Distance: ${math.sqrt(park.$2.$2).toStringAsFixed(2)}m\nRoute Distance: ${pathToDistance([
                                    position,
                                    ...getPathToPark(park.$2.$1),
                                    parks[park.$2.$1]!
                                  ]).toStringAsFixed(2)}m"),
                            ),
                          )
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

typedef LineSegment = (Offset, Offset);

class LineDrawer extends CustomPainter {
  final double width;
  final List<LineSegment> lines;

  LineDrawer({required this.lines, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (var line in lines) {
      canvas.drawLine(line.$1, line.$2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PathPainter extends CustomPainter {
  final double width;
  final List<Offset> path;
  final Offset startPoint;
  final Offset endPoint;
  final double scale;

  PathPainter({
    required this.width,
    required this.path,
    required this.startPoint,
    required this.endPoint,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    var pPath = Path();
    if (path.isNotEmpty) {
      pPath.moveTo(path[0].dx, path[0].dy);
      for (var point in path.skip(1)) {
        pPath.lineTo(point.dx, point.dy);
      }

      _drawDashedLine(canvas, startPoint, path.first, paint);

      _drawDashedLine(canvas, endPoint, path.last, paint);
    }
    canvas.drawPath(pPath, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final double dashWidth = 4 * scale;
    final double dashSpace = 4 * scale;

    // Get normalized distance vector
    var dx = p2.dx - p1.dx;
    var dy = p2.dy - p1.dy;
    final magnitude = math.sqrt(dx * dx + dy * dy);
    final steps = magnitude ~/ (dashWidth + dashSpace);
    dx = dx / magnitude;
    dy = dy / magnitude;
    var startX = p1.dx;
    var startY = p1.dy;

    for (int i = 0; i < steps; i++) {
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + dx * dashWidth, startY + dy * dashWidth), paint);
      startX += dx * (dashWidth + dashSpace);
      startY += dy * (dashWidth + dashSpace);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

const _zero2D = Offset.zero;

Offset closestPointBetween2D(Offset P, Offset A, Offset B) {
  List<double> v = [B.dx - A.dx, B.dy - A.dy];
  List<double> u = [A.dx - P.dx, A.dy - P.dy];
  double vu = v[0] * u[0] + v[1] * u[1];
  double vv = v[0] * v[0] + v[1] * v[1];
  double t = -vu / vv;
  if (t >= 0 && t <= 1) return _vectorToSegment2D(t, _zero2D, A, B);
  double g0 = _sqDiag2D(_vectorToSegment2D(0, P, A, B));
  double g1 = _sqDiag2D(_vectorToSegment2D(1, P, A, B));
  return g0 <= g1 ? A : B;
}

Offset _vectorToSegment2D(double t, Offset P, Offset A, Offset B) {
  return Offset(
    (1 - t) * A.dx + t * B.dx - P.dx,
    (1 - t) * A.dy + t * B.dy - P.dy,
  );
}

double _sqDiag2D(Offset P) {
  return P.dx * P.dx + P.dy * P.dy;
}
