#ifndef CURSOR_H
#define CURSOR_H

#include "../ui/Matrix.h"
#include "./Piece.h"
#include "./Square.h"

class Cursor{
    public:
        Cursor(int row, int col, bool selected = false);       

        // movement 
        void moveLeft(Square board[]);
        void moveRight(Square board[]);
        void moveUp(Square board[]);
        void moveDown(Square board[]);

        // sel/del
        void selectPiece();
        void deselectPiece();

        // make move
        void placePiece();

        // simple setters           
        void setSelectedRow(int row);              
        void setSelectedCol(int col);              

        // get current position
        int getCursorRow() const;
        int getCursorCol() const;

        // get position of selected piece
        int getSelectedRow() const;
        int getSelectedCol() const;

        // get selected piece from the board 
        Piece getSelectedPiece() const;

        // check if there is a selection
        bool hasSelection() const;

    private:
        int row;            
        int col;            
        int selectedRow;     
        int selectedCol;     
        Piece selectedPiece; 
        bool selected;       
        bool moveMade;          // altered after place piece if valid square
};

#endif 