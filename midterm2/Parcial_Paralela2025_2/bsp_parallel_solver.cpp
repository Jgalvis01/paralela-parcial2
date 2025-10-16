// bsp_parallel_fixed.cpp
// Compile: g++ -std=c++17 -O3 -fopenmp -march=native -o bsp_parallel_fixed bsp_parallel_fixed.cpp

#include <bits/stdc++.h>
#include <omp.h>
using namespace std;

const int dRow[] = {-1, 1, 0, 0};
const int dCol[] = {0, 0, -1, 1};

struct State {
    string board;
    int blankPos;
    int cost;
    State(const string& b, int pos, int c) : board(b), blankPos(pos), cost(c) {}
};

struct PuzzleResult {
    int puzzleIndex;
    int solution;
    int nodesExpanded;
    double executionTimeMs; // per-puzzle elapsed wall time in ms
    int threadId;
};

// Helper: generate goal like "A...#"
string generateGoalState(int n) {
    string goal;
    char c = 'A';
    for (int i = 0; i < n*n - 1; ++i) {
        goal.push_back(c++);
        if (c > 'Z') c = 'A'; // unlikely for small n
    }
    goal.push_back('#');
    return goal;
}

string swapBoardTiles(const string& currentBoard, int p1, int p2) {
    string nb = currentBoard;
    swap(nb[p1], nb[p2]);
    return nb;
}

bool isSolvable(int n, const string& board) {
    int inversions = 0;
    int blankRow = 0;
    for (size_t i = 0; i < board.size(); ++i) {
        if (board[i] == '#') { blankRow = i / n; continue; }
        for (size_t j = i+1; j < board.size(); ++j)
            if (board[j] != '#' && board[i] > board[j]) inversions++;
    }
    if (n % 2 == 1) return (inversions % 2 == 0);
    else {
        if ((n - blankRow) % 2 == 0) return (inversions % 2 == 1);
        else return (inversions % 2 == 0);
    }
}

// BFS per puzzle: returns moves (or -1) and sets nodesExpanded
pair<int,int> bfsSolver(int n, const string& start) {
    string goal = generateGoalState(n);
    if (start == goal) return {0,0};
    if (!isSolvable(n, start)) return {-1,0};

    queue<State> q;
    unordered_set<string> visited;
    int blankPos = start.find('#');
    q.push(State(start, blankPos, 0));
    visited.insert(start);

    const int MAX_STATES = 1000000;
    const int MAX_QUEUE = 200000;
    int nodesExpanded = 0;
    int statesExplored = 0;

    while (!q.empty() && statesExplored < MAX_STATES) {
        State cur = q.front(); q.pop();
        statesExplored++;
        nodesExpanded++;

        if (cur.board == goal) return {cur.cost, nodesExpanded};
        if ((int)q.size() > MAX_QUEUE) return {-1, nodesExpanded};

        int row = cur.blankPos / n;
        int col = cur.blankPos % n;
        for (int k = 0; k < 4; ++k) {
            int nr = row + dRow[k], nc = col + dCol[k];
            if (nr >= 0 && nr < n && nc >= 0 && nc < n) {
                int newPos = nr * n + nc;
                string nb = swapBoardTiles(cur.board, cur.blankPos, newPos);
                if (visited.find(nb) == visited.end()) {
                    visited.insert(nb);
                    q.push(State(nb, newPos, cur.cost+1));
                }
            }
        }
    }
    return {-1, nodesExpanded};
}

// Process sequential (returns per-puzzle results and total wall time ms)
pair<vector<PuzzleResult>, double> processSequential(const vector<pair<int,string>>& puzzles) {
    vector<PuzzleResult> results;
    results.reserve(puzzles.size());
    double t0 = omp_get_wtime();
    for (size_t i = 0; i < puzzles.size(); ++i) {
        double s = omp_get_wtime();
        auto pr = bfsSolver(puzzles[i].first, puzzles[i].second);
        double elapsed_ms = (omp_get_wtime() - s) * 1000.0;
        results.push_back({(int)i, pr.first, pr.second, elapsed_ms, 0});
    }
    double total_ms = (omp_get_wtime() - t0) * 1000.0;
    return {results, total_ms};
}

// Process parallel with dynamic scheduling and aggregate results after
pair<vector<PuzzleResult>, double> processParallel(const vector<pair<int,string>>& puzzles, int numThreads) {
    vector<PuzzleResult> results(puzzles.size());
    omp_set_num_threads(numThreads);

    double wall0 = omp_get_wtime();

    #pragma omp parallel for schedule(dynamic,1)
    for (int i = 0; i < (int)puzzles.size(); ++i) {
        int tid = omp_get_thread_num();
        double s = omp_get_wtime();
        auto pr = bfsSolver(puzzles[i].first, puzzles[i].second);
        double elapsed_ms = (omp_get_wtime() - s) * 1000.0;
        results[i] = {(int)i, pr.first, pr.second, elapsed_ms, tid};
    }

    double wall_ms = (omp_get_wtime() - wall0) * 1000.0;
    return {results, wall_ms};
}

void printSummaryAndCSV(const vector<PuzzleResult>& seq, double seqWallMs,
                        const vector<PuzzleResult>& par, double parWallMs,
                        int numThreads, const string& csvName = "parallel_results_fixed.csv")
{
    // Totals
    long long seqNodes = 0, parNodes = 0;
    double seqSumMs = 0.0, parSumMs = 0.0;

    for (auto &r : seq) { seqNodes += r.nodesExpanded; seqSumMs += r.executionTimeMs; }
    for (auto &r : par) { parNodes += r.nodesExpanded; parSumMs += r.executionTimeMs; }

    double speedup = seqWallMs / parWallMs;
    double efficiency = speedup / (double)numThreads;

    cout << fixed << setprecision(3);
    cout << "\n=== EXECUTION SUMMARY ===\n";
    cout << "Puzzles: " << seq.size() << "\n";
    cout << "Threads: " << numThreads << "\n";
    cout << "Sequential wall time (ms): " << seqWallMs << "\n";
    cout << "Parallel wall time (ms):   " << parWallMs << "\n";
    cout << "Speedup (wall): " << speedup << "x\n";
    cout << "Efficiency: " << (efficiency * 100.0) << " %\n";
    cout << "Sequential total nodes: " << seqNodes << "\n";
    cout << "Parallel total nodes:   " << parNodes << "\n";

    // Per-thread aggregates from parallel results
    vector<long long> nodesPerThread(numThreads, 0);
    vector<double> timePerThreadMs(numThreads, 0.0);
    for (auto &r : par) {
        if (r.threadId >=0 && r.threadId < numThreads) {
            nodesPerThread[r.threadId] += r.nodesExpanded;
            timePerThreadMs[r.threadId] += r.executionTimeMs;
        }
    }

    cout << "\n=== NODES PER THREAD ===\n";
    for (int t = 0; t < numThreads; ++t) {
        cout << "Thread " << t << ": nodes=" << nodesPerThread[t]
             << ", sum_puzzle_ms=" << timePerThreadMs[t] << "\n";
    }

    // Write CSV (parallel results)
    ofstream fout(csvName);
    fout << "puzzle_index,thread_id,solution,nodes_expanded,per_puzzle_ms,threads_used\n";
    for (auto &r : par) {
        fout << r.puzzleIndex << "," << r.threadId << "," << r.solution << ","
             << r.nodesExpanded << "," << r.executionTimeMs << "," << numThreads << "\n";
    }
    fout.close();
    cerr << "Wrote CSV: " << csvName << "\n";
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        cerr << "Usage: " << argv[0] << " <puzzles_file> <num_threads>\n";
        return 1;
    }
    string filename = argv[1];
    int numThreads = atoi(argv[2]);
    if (numThreads <= 0) numThreads = 1;

    // Read puzzles file (one board per line). Assumes 4x4 puzzles.
    vector<pair<int,string>> puzzles;
    ifstream fin(filename);
    if (!fin) {
        cerr << "Cannot open file: " << filename << "\n";
        return 1;
    }
    string line;
    while (getline(fin, line)) {
        if (line.empty()) continue;
        // Trim whitespace
        string s;
        for (char c : line) if (!isspace((unsigned char)c)) s.push_back(c);
        if (!s.empty()) puzzles.push_back({4, s});
    }
    fin.close();

    if (puzzles.empty()) {
        cerr << "No puzzles found in file.\n";
        return 1;
    }

    cout << "Loaded " << puzzles.size() << " puzzles. Running sequential and parallel.\n";

    // Sequential
    auto seqPair = processSequential(puzzles);
    auto seqResults = seqPair.first;
    double seqWallMs = seqPair.second;

    // Parallel
    auto parPair = processParallel(puzzles, numThreads);
    auto parResults = parPair.first;
    double parWallMs = parPair.second;

    // Print summary and save CSV
    printSummaryAndCSV(seqResults, seqWallMs, parResults, parWallMs, numThreads);

    return 0;
}
