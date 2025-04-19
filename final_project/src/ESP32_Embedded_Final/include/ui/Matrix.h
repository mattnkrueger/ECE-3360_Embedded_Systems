/*
 *  Matrix.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of the 64x64 LED Matrix.
 */

#ifndef MATRIX_H
#define MATRIX_H

enum class LedColor {
    White,
    Black,
    Red,
    Orange,
    Yellow,
    Green,
    Blue,
    Purple
};

class Matrix() {
    public:
      Matrix();
      void clearScreen();
      void fillScreen(LedColor color);
      void drawSquare(int x, int y, LedColor color);
      void drawCursor(int x, int y, LedColor color);
      void drawText(int x, int y, LedColor color);
      void drawPiece(Piece piece, LedColor color);
    // private:
}

#endif