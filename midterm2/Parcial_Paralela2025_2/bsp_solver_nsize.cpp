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
    int g;
    
    State() : g(0) {}
    
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

class BFS_NSize {
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
                neighbors.push_back(neighbor);
            }
        }
        return neighbors;
    }
    
    bool isGoal(const State& state) {
        return state.board == goal;
    }
    
public:
    BFS_NSize(int size) : N(size), total_nodes_expanded(0) {
        generateGoal();
    }
    
    int solve(const State& initial, double& execution_time) {
        auto start_time = std::chrono::high_resolution_clock::now();
        
        std::queue<State> frontier;
        std::set<std::string> visited;
        
        frontier.push(initial);
        visited.insert(initial.toString());
        total_nodes_expanded = 0;
        
        // Memory limit to prevent crashes
        const int MAX_STATES = 1000000;
        
        while (!frontier.empty() && visited.size() < MAX_STATES) {
            State current = frontier.front();
            frontier.pop();
            
            total_nodes_expanded++;
            
            if (isGoal(current)) {
                auto end_time = std::chrono::high_resolution_clock::now();
                auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);
                execution_time = duration.count() / 1000.0; // Convert to milliseconds
                return current.g;
            }
            
            for (const State& neighbor : getNeighbors(current)) {
                std::string neighbor_str = neighbor.toString();
                if (!visited.count(neighbor_str)) {
                    visited.insert(neighbor_str);
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
    
    BFS_NSize solver(N);
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
                  << "BFS" << std::endl;
        
        puzzle_count++;
    }
    
    file.close();
    return 0;
}