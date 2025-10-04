import subprocess
import sys
from collections import defaultdict


class Graph:
    def __init__(self):
        self.graph = defaultdict(list)

    def addEdge(self, u, v):
        if u not in self.graph:
            self.graph[u] = []
        if v not in self.graph:
            self.graph[v] = []
        self.graph[u].append(v)

    def isCyclicUtil(self, v, visited, recStack, path):
        if v not in visited:
            visited[v] = False
        if v not in recStack:
            recStack[v] = False

        visited[v] = True
        recStack[v] = True
        path.append(v)

        for neighbour in self.graph[v]:
            if not visited.get(neighbour, False):
                cycle = self.isCyclicUtil(neighbour, visited, recStack, path)
                if cycle:  # If a cycle is found deeper in the recursion, bubble it up.
                    return cycle
            elif recStack.get(neighbour, False):
                # Found a cycle, return the path leading to the cycle and including the cycle start point
                cycle_start_index = path.index(neighbour)
                cycle_path = path[cycle_start_index:]
                cycle_path.append(
                    neighbour
                )  # Include the first dependency again at the end
                return cycle_path

        path.pop()  # Remove the current node from the path as we backtrack
        recStack[v] = False
        return None

    def findCycle(self):
        visited = {}
        recStack = {}

        for node in self.graph.keys():
            if node not in visited:
                cycle = self.isCyclicUtil(node, visited, recStack, [])
                if cycle:
                    return cycle
        return None


def get_dependencies(port_command, package):
    command = f"{port_command} deps {package}"
    process = subprocess.run(
        command, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True
    )
    output = process.stdout
    dependencies = []
    for line in output.split("\n"):
        if any(
            prefix in line
            for prefix in [
                "Extract Dependencies:",
                "Build Dependencies:",
                "Library Dependencies:",
                "Runtime Dependencies:",
            ]
        ):
            # if any(prefix in line for prefix in ["Extract Dependencies:", "Build Dependencies:"]):
            deps = line.split(":", 1)[1].strip().split(", ")
            dependencies.extend(deps)
    return dependencies


def build_graph(port_command, root_package):
    g = Graph()
    stack = [root_package]
    visited = set()

    while stack:
        current_package = stack.pop()
        if current_package not in visited:
            visited.add(current_package)
            deps = get_dependencies(port_command, current_package)
            for dep in deps:
                if (
                    dep and not dep.isspace()
                ):  # Check if dep is not empty or just whitespace
                    g.addEdge(current_package, dep)
                    if dep not in visited:
                        stack.append(dep)
    return g


# Example usage
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python detect_cycles.py <path_to_port_command> <root_package>")
        sys.exit(1)

    port_command = sys.argv[1]
    root_package = sys.argv[2]
    g = build_graph(port_command, root_package)
    cycle = g.findCycle()
    if cycle:
        print("Graph has a circular dependency:", " -> ".join(cycle))
    else:
        print("No circular dependencies found")
