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

class Game() {
    public:
        Game();
    private:
        Square board[][];
}

#endif GAME_H