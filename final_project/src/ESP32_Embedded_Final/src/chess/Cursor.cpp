#include "../../include/chess/Cursor.h"
#include "../../include/chess/Square.h"

Cursor::Cursor(int row, int col, bool selected) : row(row), col(col), selected(selected) {}

void Cursor::moveLeft(Square board[]) {}


void Cursor::selectPiece()
{
    // access the current row/col of the board, and select the piece. if nothing is there exit
    // change the color to orange
}

void Cursor::deselectPiece()
{
    // removes the selected piece. 
    // change the color back to normal 
}

void Cursor::placePiece()
{
    // if valid move, then 
}

void Cursor::setSelectedRow(int row)
{
}

void Cursor::setSelectedCol(int col)
{
}

int Cursor::getCursorRow() const
{
}

int Cursor::getCursorCol() const
{
}

int Cursor::getSelectedRow() const
{
}

int Cursor::getSelectedCol() const
{
}

Piece Cursor::getSelectedPiece() const
{
}

bool Cursor::hasSelection() const
{
}
