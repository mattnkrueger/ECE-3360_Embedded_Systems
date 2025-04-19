/*
 *  Piece.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of a chess piece.
 */

#ifndef PIECE_H
#define PIECE_H

#include "../ui/Matrix.h"

enum class PieceType {
    King,
    Queen, 
    Rook, 
    Bishop,
    Knight,
    Pawn
};

struct Piece {
    PieceType piece;
    Color color;
};

#endif