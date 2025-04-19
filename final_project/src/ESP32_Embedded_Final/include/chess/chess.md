# Chess Implementation
Our implementation of chess on a 64x64 LED Matrix uses a hierarchy of objects for robust chess logic and interaction with the user via the arduino.

## Design
1. Game (class): manages game logic
- defines the current board 
- composed of two cursors. Existence of two cursors implies that there are two players, thus we can get away without using a Player class to save memory and overhead.

2: Square (class): defines each square on the board
- 64 squares creates the board inside of the Game class. 
- composed of a piece

3: Piece (struct): no behavior; just a definition of a piece belonging to a square
- type: PieceType
- color: white or black (or user defined)

4: PieceType (enum class): enumeration of pieces belonging to chess
- type: king, queen, rook, bishop, knight, pawno

5: GameState (enum class): enumeration of states belonging to chess
- in progress, check, checkmate, stalemate, forfeit