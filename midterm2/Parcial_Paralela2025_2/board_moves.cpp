/**
 * @file board_moves.cpp
 * @brief NxN Sliding Puzzle Move Simulator
 * 
 * This program reads board size N, board string, and move direction.
 * Executes the move and prints resulting board.
 * Input: N board_string move_direction
 * 
 * @author JAPeTo
 * @version 2.0
 */
#include <iostream>
#include <vector>
#include <string>

using namespace std;

/**
 * @brief Prints an NxN board with proper formatting
 */
void print_board(const vector<vector<char>>& board) {
    int n = board.size();
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            cout << board[i][j];
            if (j < n - 1) cout << " ";
        }
        cout << endl;
    }
}
/**
 * @brief Executes a move on the puzzle board by sliding the empty space
 * 
 * Searches for the empty space ('#') and attempts to move it in the specified
 * direction by swapping with the adjacent tile. The move is only executed if
 * it remains within the board boundaries.
 */
void doMove(vector<vector<char>>& board, const string& move) {
    int n = board.size();
    
    // Find the blank position '#'
    int blank_row = -1, blank_col = -1;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (board[i][j] == '#') {
                blank_row = i;
                blank_col = j;
                break;
            }
        }
        if (blank_row != -1) break;
    }
    
    // Execute the move
    if (move == "UP" && blank_row > 0) {
        swap(board[blank_row][blank_col], board[blank_row - 1][blank_col]);
    }
    else if (move == "DOWN" && blank_row < n - 1) {
        swap(board[blank_row][blank_col], board[blank_row + 1][blank_col]);
    }
    else if (move == "LEFT" && blank_col > 0) {
        swap(board[blank_row][blank_col], board[blank_row][blank_col - 1]);
    }
    else if (move == "RIGHT" && blank_col < n - 1) {
        swap(board[blank_row][blank_col], board[blank_row][blank_col + 1]);
    }
}

/**
 * @brief Main function - program entry point
 * 
 * Reads board size N, board string, and move direction.
 * Initializes the board and executes the requested move.
 */
int main() {
    int n;
    string board_string, move;
    
    cin >> n >> board_string >> move;
    
    vector<vector<char>> board(n, vector<char>(n));
    
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            board[i][j] = board_string[i * n + j];
        }
    }
    
    doMove(board, move);
    print_board(board);
    
    return 0;
}