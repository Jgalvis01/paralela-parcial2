/**
 * @file board_available.cpp
 * @brief 4x4 Sliding Puzzle Available Moves Finder
 * 
* This program analyzes a 4x4 sliding puzzle board configuration and determines
 * all valid moves that can be made from the current state.
 */
#include <iostream>
#include <string>

using namespace std;

/**
 * @file board_available.cpp
 * @brief NxN Sliding Puzzle Available Moves Finder
 * 
 * This program analyzes an NxN sliding puzzle board configuration and determines
 * all valid moves that can be made from the current state.
 * Input: N board_string
 * Output: Valid moves in order UP, DOWN, LEFT, RIGHT
 * 
 * @author JAPeTo
 * @version 2.0
 */
#include <iostream>
#include <string>

using namespace std;

/**
 * @brief Finds and displays all available moves for the current board state
 * 
 * Locates the empty space ('#') and determines which directions are valid
 * based on board boundaries. Outputs moves in the specified order.
 */
void listAvailable(int n, const string& board) {
    // Find position of '#'
    int blank_pos = -1;
    for (int i = 0; i < board.length(); i++) {
        if (board[i] == '#') {
            blank_pos = i;
            break;
        }
    }
    
    if (blank_pos == -1) return; // No blank found
    
    // Convert 1D position to 2D coordinates
    int row = blank_pos / n;
    int col = blank_pos % n;
    
    // Check each direction in order: UP, DOWN, LEFT, RIGHT
    if (row > 0) {           // UP is possible
        cout << "UP" << endl;
    }
    if (row < n - 1) {       // DOWN is possible
        cout << "DOWN" << endl;
    }
    if (col > 0) {           // LEFT is possible
        cout << "LEFT" << endl;
    }
    if (col < n - 1) {       // RIGHT is possible
        cout << "RIGHT" << endl;
    }
}
/**
 * @brief Main function - program entry point
 * 
 * Reads the board size N and configuration from standard input and displays all
 * available moves based on the empty space position.
 */
int main() {
    int n;
    string board;
    
    cin >> n >> board;
    listAvailable(n, board);
    
    return 0;
}