/*
 *  Square.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of a chess square.
 */

#ifndef SQUARE_H
#define SQUARE_H

#include "../ui/Matrix.h"
#include "./Piece.h"

/*
 * Class Square
 *
 * This class defines a single square of the 8x8 chess board. 
 * Each square can be empty, 
 */
class Square {
    public:
        /* @brief initalizes a square 
         * 
         * Initializes a square of the board with a piece (or none if empty), and background color 
         *
         * @param piece: king, queen, rook, ... 
         * @param backgroundColor: white, black, ...
         * @return void 
         */
        Square(LedColor backgroundColor, Piece piece);

        /* @brief remove piece
         * 
         * Removes and deallocates memory for a taken chess piece
         *
         * @return void 
         */
        void removePiece();

        /* @brief add piece
         * 
         * Adds piece to Square. This is called immediately if moving to an empty square 
         * or after remove piece if moving to a occupied square.
         *
         * @param newPiece: piece to move into the square
         * @return void 
         */
        void addPiece(Piece newPiece);

        Piece getPiece() const;           // simple getters
        LedColor getColor() const; 

    private:
        Piece piece;                     // Piece belonging to the Square
        LedColor backgroundColor;        // The squares background color
};

#endif SQUARE_H