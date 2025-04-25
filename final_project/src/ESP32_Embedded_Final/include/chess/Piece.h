#ifndef PIECE_H
#define PIECE_H

#include "../ui/Matrix.h"

/**
 * @brief abstract base class for pieces belonging to chess
 * 
 * virtual method for determining whether or not the move is valid. 
 * this method is overridden by ALL pieces as they all have different characteristics.
 */
class Piece {
    public:
        /**
         * @brief Construct a new Piece object
         * 
         * @param color 
         */
        Piece(char* color);

        /**
         * @brief Destroy the Piece object
         * 
         * even though the destructor is default, it is virtual; it extends to children pieces
         * 
         */
        virtual ~Piece() = default;

        /**
         * @brief 
         * 
         * determines whether or not the chess move is valid for the piece
         * 
         * fromRow     - starting row val
         * fromCol     - starting column val
         * toRow       - ending row val
         * toCol       - ending col val
         * 
         * @param fromRow 
         * @param fromCol 
         * @param toRow 
         * @param toCol 
         * @return true 
         * @return false 
         */
        virtual bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const = 0;
        
        /**
         * @brief Set the Position object
         * 
         * @param row 
         * @param col 
         */
        void setPosition(int row, int col);
        
        /**
         * @brief Get the Color object
         * 
         * @return char* 
         */
        char* getColor() const { return color; }

        /**
         * @brief Get the Row object
         * 
         * @return int 
         */
        int getRow() const { return currentRow; }

        /**
         * @brief Get the Col object
         * 
         * @return int 
         */
        int getCol() const { return currentCol; }

        /**
         * @brief Check if row and column are within the bounds of the chess board
         * 
         * @param row The row to check
         * @param col The column to check
         * @return true if within bounds, false otherwise
         */
        bool moveInBounds(int row, int col) const;
        
        /**
         * @brief Calculate the delta values between two positions
         * 
         * @param fromRow Starting row
         * @param fromCol Starting column
         * @param toRow Ending row
         * @param toCol Ending column
         * @param deltaR Reference to store row delta
         * @param deltaC Reference to store column delta
         */
        void calculateDelta(int fromRow, int fromCol, int toRow, int toCol, int& deltaR, int& deltaC) const;

    protected:
        char* color;
        int currentRow;   
        int currentCol;   
        int startingRow;        // needed for pawn to avoid writing during the virtual method... shouldnt take too much space
        int startingCol;
};

/**
 * @brief Pawn piece
 * 
 * moves only 1 square forward unless starting from its initial spot, which it can move 2. 
 * We did not program 'en passant'... hopefully no one knows this move haha
 */
class Pawn : public Piece {
    public:
        Pawn(char* color, bool atStart = true);
        bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const override;
};

/**
 * @brief Rook piece
 * 
 * can only move vertically and horizontally
 */
class Rook : public Piece {
    public:
        Rook(char* color);
        bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const override;
};

/**
 * @brief Knight
 * 
 * moves in L (you know what i mean)
 */
class Knight : public Piece {
    public:
        Knight(char* color);
        bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const override;
};

/**
 * @brief Bishop
 * 
 * moves diagonally (45* angle... not any diagonal; must stay on its color)
 */
class Bishop : public Piece {
    public:
        Bishop(char* color);
        bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const override;
};

/**
 * @brief Queen
 * 
 * all movement types besides the Knight 
 */
class Queen : public Piece {
    public:
        Queen(char* color);
        bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const override;
};

/**
 * @brief King 
 * 
 * moves like an omnidirectional pawn 
 * 
 */
class King : public Piece {
    public:
        King(char* color);
        bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) const override;
};


#endif