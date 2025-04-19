/*
 *  Cursor.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of a player cursor for the chess board.
 */

#ifndef CHESSCURSOR_H
#define CHESSCURSOR_H

#include "../ui/Matrix.h"
#include "./Piece.h"

/*
 * Class ChessCursor
 *
 * This defines the UI interaction for chess game
 * Player moves around using the cursor and the color is changed depending on valid move.
 * 
 */
class ChessCursor {
    public:
        /* @brief initialize chess cursor
         * 
         * sets the color, and location of the cursor
         *
         * @return void 
         */
        ChessCursor(LedColor color, int row, int col, bool selected = false);       

        /* @brief move cursor to the left
         * 
         * moves the cursor one location to the left on the chessboard
         *
         * @return void 
         */
        void moveLeft();

        /* @brief move cursor to the right
         * 
         * moves the cursor one location to the right on the chessboard
         *
         * @return void 
         */
        void moveRight();

        /* @brief move cursor up
         * 
         * moves the cursor one location up on the chessboard
         *
         * @return void 
         */
        void moveUp();

        /* @brief move cursor down
         * 
         * moves the cursor one location down on the chessboard
         *
         * @return void 
         */
        void moveDown();
        
        /* @brief selects piece inside of cursor
         * 
         * selects the piece inside of the cursor, saving it to currentlySelected
         *
         * @return void 
         */
        void selectPiece();

        /* @brief removes current selection 
         * 
         * cursor selection of piece is removed. 
         *
         * @return void 
         */
        void deselectPiece();

        /* @brief place piece onto cursor row/col
         * 
         * piece currently selected is moved to the current cursor's row/col.
         * checks for validity of move. ex knight cannot move one square forward. 
         * if the user tries to move to an invalid square then the move is not registered.
         *
         * @return void 
         */
        void placePiece();

        /* @brief set color of cursor
         * 
         * sets the color of the cursor depending on:
         * - player (ex: yellow/blue)
         * - valid move (ex: green/red)
         * - selected cursor (ex: pink)
         *
         * @return void 
         */
        void setColor(LedColor color);    

        // simple setters           note movement methods handle row/col.
        void setSelectedRow(int row);              
        void setSelectedCol(int col);              

        // simple getters
        LedColor getColor() const;

        int getCursorRow() const;
        int getCursorCol() const;

        int getSelectedRow() const;
        int getSelectedCol() const;
        Piece getSelectedPiece() const;
        bool hasSelection() const;

    private:
        // color of the cursor
        LedColor color;     
         
        // current cursor 
        int row;          
        int col;         
        
        // selected cursor. 
        int selectedRow;
        int selectedCol;
        Piece selectedPiece;
        bool selected;
}

#endif CHESSCURSOR_H