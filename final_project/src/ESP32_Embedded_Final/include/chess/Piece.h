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

/*
 * Enum PieceType
 *
 * This enumerates the possible pieces in chess
 */
enum class PieceType {
    King,
    Queen, 
    Rook, 
    Bishop,
    Knight,
    Pawn
};

/*
 * Struct Piece
 *
 * This defines a piece. 
 * Each piece as a type and color 
 *
 */
struct Piece {
    PieceType piece;
    Color color;
};

#endif