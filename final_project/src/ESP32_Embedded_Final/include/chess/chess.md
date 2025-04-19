# Chess Implementation
Our implementation of chess on a 64x64 LED Matrix uses a hierarchy of objects for robust logic and interaction with the user via the arduino. 

## 1. Game (class):
- **manages game logic**
- defines the current board 
- composed of two Cursors. The existence of two Cursors implies that there are two players, thus we can get away without using a Player class. This saves memory and overhead.

![Game](img/Game.png)

## 2. Cursor (class): 
- **user interaction**
- indexes the board row/col
- simple user interaction: 1. select, 2. move, 3. place

## 3: Square (class): 
- **defines each square on the board**
- 64 squares creates the board inside of the Game class. 
- composed of a piece and a background color

![Cursors and Squares](img/Cursors_and_Squares.png)

## 4: Piece (struct):
- **no behavior; just a definition of a piece belonging to a square**
- type: PieceType (enum) king, queen, rook, bishop, knight, pawn
- color: white or black (or user defined)


![Piece Types](img/Piece_Types.png)
![Pieces](img/Pieces.png)

## Driver
Since this is displayed to an LED Matrix, the chess logic must be translated to the LED Matrix.
The object ChessDriver handles this by providing methods to draw the current board state and cursors to the matrix.

![Chess Hierarchy](img/Chess_Hierarchy.png)

## Resolution of Pieces
Because we are limited by the number of LEDs on our matrix, we must keep the resolution of the pieces very minimal. Here is how we are sectioning the board:
- there are 4096 pixels on the board
- there are 64 squares on a chess board (8x8)
- there are 64 rows/cols on the matrix
- we make a square 8x8
8x8x64 = 4096 

Therefore, we have a square that is 8x8. To include a cursor, we must have padding around the piece. This way, an outline of a square can be drawn at the current player's cursor position. We make the resolution of each piece 6x6.

![Pawn](img/Led_Piece.png)
![Cursor on Pawn](img/Led_Cursor.jpg)

## Img Attribution
Screenshots taken (and altered using Figma) from [Britannica](https://www.britannica.com/topic/chess)
