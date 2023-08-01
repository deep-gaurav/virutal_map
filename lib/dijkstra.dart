import 'package:collection/collection.dart';

class Graph {
  final int V;
  final List<List<int>> adj;

  Graph(this.V) : adj = List.generate(V, (index) => []);

  void addEdge(int u, int v, int weight) {
    adj[u].add(v);
    adj[u].add(weight);
  }

  (List<int>, List<int>) dijkstra(int src) {
    List<int> distance = List.generate(V, (index) => double.maxFinite.toInt());
    List<int> parent = List.generate(V, (index) => -1);
    distance[src] = 0;

    PriorityQueue<int> pq = PriorityQueue((a, b) => distance[a] - distance[b]);
    pq.add(src);

    while (pq.isNotEmpty) {
      int u = pq.removeFirst();
      for (int i = 0; i < adj[u].length; i += 2) {
        int v = adj[u][i];
        int weight = adj[u][i + 1];
        int newDist = distance[u] + weight;
        if (newDist < distance[v]) {
          distance[v] = newDist;
          parent[v] = u;
          pq.add(v);
        }
      }
    }

    return (distance, parent);
  }

  List<int> shortestPath(int src, int dest) {
    var (distance, parent) = dijkstra(src);
    List<int> path = [];

    if (distance[dest] == double.maxFinite.toInt()) {
      return path;
    }

    int current = dest;
    while (current != -1) {
      path.insert(0, current);
      current = parent[current];
    }

    return path;
  }
}
