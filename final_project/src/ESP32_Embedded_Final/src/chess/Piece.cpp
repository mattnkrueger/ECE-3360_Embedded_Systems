#include "../include/chess/Piece.h"
#include <cstdlib>

// trivial getters already implemented inside of Piece.h

// constructor
Piece::Piece(char* color) : color(color) {};

// set position of piece
void Piece::setPosition(int row, int col) {
    currentRow = row;
    currentCol = col;
};

// Check if position is within board bounds
bool Piece::moveInBounds(int row, int col) const {
    return (row >= 0 && row < 8 && col >= 0 && col < 8);
}

// Calculate the delta values between two positions
void Piece::calculateDelta(int fromRow, int fromCol, int toRow, int toCol, int& deltaR, int& deltaC) const {
    deltaR = toRow - fromRow;
    deltaC = toCol - fromCol;
}

// pawn vector is only forward by 1 unless at 2; else not valid
// three cases
// start
// during
// capture
bool Pawn::isValidMove(int fromRow, int fromCol, int toRow, int toCol) const {
    // Check if the move is within the board bounds
    if (!moveInBounds(toRow, toCol)) {
        return false;
    }

    int deltaR, deltaC;
    calculateDelta(fromRow, fromCol, toRow, toCol, deltaR, deltaC);

    // case 1: start
    bool atStart = (fromRow == startingRow && fromCol == startingCol);
    if (atStart && deltaC == 1 || deltaC == 2) {
        return true;
    }

    // case 2: normal
    if (deltaC == 1 && deltaR == 0) {
        return true;
    }

    // case 3: capture 
    if (deltaC == 1 && abs(deltaR) == 1) {
        return true;
    }

}

// lat and longitudally
bool Rook::isValidMove(int fromRow, int fromCol, int toRow, int toCol) const {
    // Check if the move is within the board bounds
    if (!moveInBounds(toRow, toCol)) {
        return false;
    }
    
    int deltaR, deltaC;
    calculateDelta(fromRow, fromCol, toRow, toCol, deltaR, deltaC);
    
    // if both row and column have moved, then invalid
    if (deltaR != 0 && deltaC != 0) {
        return false;
    }
    
    return true;
}

// L shape, 2 in first direction, then 1 in the other. can be 1 then 2 as well. 
bool Knight::isValidMove(int fromRow, int fromCol, int toRow, int toCol) const {
    // Check if the move is within the board bounds
    if (!moveInBounds(toRow, toCol)) {
        return false;
    }

    int deltaR, deltaC;
    calculateDelta(fromRow, fromCol, toRow, toCol, deltaR, deltaC);
    
    return (abs(deltaR) == 2 && abs(deltaC) == 1) || (abs(deltaR) == 1 && abs(deltaC) == 2);
}

// diagonal: slope = 1, i.e delta r == delta c
bool Bishop::isValidMove(int fromRow, int fromCol, int toRow, int toCol) const {
    // Check if the move is within the board bounds
    if (!moveInBounds(toRow, toCol)) {
        return false;
    }

    int deltaR, deltaC;
    calculateDelta(fromRow, fromCol, toRow, toCol, deltaR, deltaC);
    
    // Bishop moves diagonally (absolute values of deltaR and deltaC must be equal)
    return abs(deltaR) == abs(deltaC);
}

bool Queen::isValidMove(int fromRow, int fromCol, int toRow, int toCol) const {
    // Check if the move is within the board bounds
    if (!moveInBounds(toRow, toCol)) {
        return false;
    }

    int deltaR, deltaC;
    calculateDelta(fromRow, fromCol, toRow, toCol, deltaR, deltaC);
    
    // Queen can move like a rook or bishop or k
    // rook                                                              
    if ((deltaR == 0 && deltaC != 0) || (deltaR != 0 && deltaC == 0)) {
        return true;
    }

    // bishop
    if (abs(deltaR) == abs(deltaC)) {
        return true;
    }

    // else false
    return false;
}

// king moves in any direction by 1 square
bool King::isValidMove(int fromRow, int fromCol, int toRow, int toCol) const {
    // Check if the move is within the board bounds
    if (!moveInBounds(toRow, toCol)) {
        return false;
    }

    int deltaR, deltaC;
    calculateDelta(fromRow, fromCol, toRow, toCol, deltaR, deltaC);
    
    // King can move one square in any direction
    // diagonal
    if (abs(deltaR) == 1 && abs(deltaC) == 1) {
        return true;
    }

    // horizontal/vertical
    if ((abs(deltaR) == 1 && abs(deltaC) == 0) || (abs(deltaR) == 0 && abs(deltaC) == 1)) {
        return true;
    }

    // else false
    return false;
}