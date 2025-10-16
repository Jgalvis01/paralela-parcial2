/**
 * @file board_printer.cpp
 * @brief NxN Board Initialization and Printing Utility
 * 
 * This program reads board size N and an N²-character string representing 
 * an NxN board configuration and converts it into a 2D grid format for display. 
 * The input string is interpreted as row-major order (left to right, top to bottom).
 * 
 * Input format: N board_string
 * Output format: NxN grid with space-separated columns and newline-separated rows
 * 
 * Example:
 *   Input:  4 ABCDEFGHIJKLMNO#
 *   Output: A B C D
 *           E F G H
 *           I J K L
 *           M N O #
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
 * @brief Main function - Reads N and board string, displays NxN board
 * 
 * Reads board size N and N²-character input string, converts it to an NxN board 
 * representation, and prints it in grid format.
 * 
 * Compilation: 
 *      g++ -std=c++11 -o board_printer board_printer.cpp
 * 
 * Usage examples:
 * # 4x4 board
 * echo "4 ABCDEFGHIJKLMNO#" | ./board_printer
 * 
 * # 3x3 board  
 * echo "3 ABCDEFGH#" | ./board_printer
 */
int main() {
    int n;
    string board_string;
    
    cin >> n >> board_string;
    
    vector<vector<char>> board(n, vector<char>(n));
    
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            board[i][j] = board_string[i * n + j];
        }
    }
    
    print_board(board);
    return 0;
}