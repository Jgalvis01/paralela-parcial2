#include <iostream>
#include <vector>
#include <queue>
#include <set>
#include <string>
#include <algorithm>
#include <fstream>
#include <sstream>
#include <cmath>
#include <chrono>

struct State {
    std::vector<std::vector<char>> board;
    int blank_row, blank_col;
    int g, h, f;
    int nodes_expanded;
    
    State() : g(0), h(0), f(0), nodes_expanded(0) {}
    
    bool operator<(const State& other) const {
        if (f != other.f) return f > other.f;
        return h > other.h;
    }
    
    bool operator==(const State& other) const {
        return board == other.board;
    }
    
    std::string toString() const {
        std::string result;
        for (const auto& row : board) {
            for (char cell : row) {
                result += cell;
            }
        }
        return result;
    }
};

class AStar_H2 {
private:
    int N;
    std::vector<std::vector<char>> goal;
    int total_nodes_expanded;
    
    void generateGoal() {
        goal = std::vector<std::vector<char>>(N, std::vector<char>(N));
        char current = 'A';
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                if (i == N-1 && j == N-1) {
                    goal[i][j] = '#';
                } else {
                    goal[i][j] = current++;
                }
            }
        }
    }
    
    int misplacedTiles(const State& state) {
        int count = 0;
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                if (state.board[i][j] != '#' && state.board[i][j] != goal[i][j]) {
                    count++;
                }
            }
        }
        return count;
    }
    
    std::vector<State> getNeighbors(const State& current) {
        std::vector<State> neighbors;
        int dr[] = {-1, 1, 0, 0};
        int dc[] = {0, 0, -1, 1};
        
        for (int i = 0; i < 4; i++) {
            int new_row = current.blank_row + dr[i];
            int new_col = current.blank_col + dc[i];
            
            if (new_row >= 0 && new_row < N && new_col >= 0 && new_col < N) {
                State neighbor = current;
                std::swap(neighbor.board[current.blank_row][current.blank_col],
                         neighbor.board[new_row][new_col]);
                neighbor.blank_row = new_row;
                neighbor.blank_col = new_col;
                neighbor.g = current.g + 1;
                neighbor.h = misplacedTiles(neighbor);
                neighbor.f = neighbor.g + neighbor.h;
                neighbors.push_back(neighbor);
            }
        }
        return neighbors;
    }
    
    bool isGoal(const State& state) {
        return state.board == goal;
    }
    
public:
    AStar_H2(int size) : N(size), total_nodes_expanded(0) {
        generateGoal();
    }
    
    int solve(const State& initial, double& execution_time) {
        auto start_time = std::chrono::high_resolution_clock::now();
        
        std::priority_queue<State> frontier;
        std::set<std::string> visited;
        
        State start = initial;
        start.h = misplacedTiles(start);
        start.f = start.g + start.h;
        
        frontier.push(start);
        total_nodes_expanded = 0;
        
        // Memory limit to prevent crashes
        const int MAX_STATES = 1000000;
        
        while (!frontier.empty() && visited.size() < MAX_STATES) {
            State current = frontier.top();
            frontier.pop();
            
            std::string current_str = current.toString();
            if (visited.count(current_str)) continue;
            visited.insert(current_str);
            
            total_nodes_expanded++;
            
            if (isGoal(current)) {
                auto end_time = std::chrono::high_resolution_clock::now();
                auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);
                execution_time = duration.count() / 1000.0; // Convert to milliseconds
                return current.g;
            }
            
            for (const State& neighbor : getNeighbors(current)) {
                if (!visited.count(neighbor.toString())) {
                    frontier.push(neighbor);
                }
            }
        }
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);
        execution_time = duration.count() / 1000.0;
        return -1; // No solution found within limits
    }
    
    int getNodesExpanded() const {
        return total_nodes_expanded;
    }
};

State parsePuzzle(const std::string& puzzle_str, int N) {
    State state;
    state.board = std::vector<std::vector<char>>(N, std::vector<char>(N));
    
    int idx = 0;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            state.board[i][j] = puzzle_str[idx++];
            if (state.board[i][j] == '#') {
                state.blank_row = i;
                state.blank_col = j;
            }
        }
    }
    return state;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <puzzles_file> <N_size>" << std::endl;
        return 1;
    }
    
    std::string filename = argv[1];
    int N = std::atoi(argv[2]);
    
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Cannot open file " << filename << std::endl;
        return 1;
    }
    
    AStar_H2 solver(N);
    std::string line;
    int puzzle_count = 0;
    
    std::cout << "puzzle_index,board,solution_length,execution_time_ms,nodes_expanded,solvable,algorithm" << std::endl;
    
    while (std::getline(file, line)) {
        if (line.empty()) continue;
        
        State initial = parsePuzzle(line, N);
        double execution_time;
        int solution_length = solver.solve(initial, execution_time);
        
        std::cout << puzzle_count << "," 
                  << line << ","
                  << solution_length << ","
                  << execution_time << ","
                  << solver.getNodesExpanded() << ","
                  << (solution_length != -1 ? "true" : "false") << ","
                  << "A*-h2" << std::endl;
        
        puzzle_count++;
    }
    
    file.close();
    return 0;
}