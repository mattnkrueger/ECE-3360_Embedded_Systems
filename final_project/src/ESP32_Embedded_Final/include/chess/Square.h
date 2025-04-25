#ifndef SQUARE_H
#define SQUARE_H

#include "./Piece.h"

class Square {
    public:
        // 
        Square(char* background_color, Piece piece);

        // call remove and then place 
        void place(Piece newPiece);
        
        // remove current piece
        void removePiece();

        // add new piece
        void addPiece(Piece newPiece);
        
        // get the piece
        Piece getPiece() const;  

    private:
        Piece piece;             
};

#endif SQUARE_H