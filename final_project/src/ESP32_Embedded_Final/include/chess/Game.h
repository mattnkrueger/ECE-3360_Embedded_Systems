/*
 *  Game.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of a chess game.
 */

#ifndef GAME_H
#define GAME_H

#include "Square.h"

/*
 * Class Game
 *
 * This class handles logic for the chess game. 
 * Rules: https://www.chess.com/learn-how-to-play-chess 
 * 
 */
class Game() {
    public:
        /* @brief initilize game of chess
         * 
         * creates new board - squares, pieces, etc 
         * sets cursor locations to starting positions
         * sets player1 start
         *
         * @return void 
         */
        Game();
        
        bool isGameFinished() const;
        String getWinner() const;
        
    private:
        Square board[][];       // chess board created of squares. 
        bool finished;          // is the game finished?
        String winner;          // winner of the game
        ChessCursor player1;    // player1's cursor
        ChessCursor player2;    // player2's cursor
}

#endif GAME_H