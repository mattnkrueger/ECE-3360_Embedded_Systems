# Commands
As we are humans and 115200 baud rate will never cause a perceivable delay to our eyes, we can 
design our commands to be formatted in JSON for ease of use.

format = {
            origin: string,
            mode: string,
            command: string,
            status: bool
        }

### Description of keys
1. Origin: command origin - did this come from user (development mode), player1 or player2 (game mode)
2. Mode: location to execute command - location to take action. some modes may consist of different commands
3. Command: executable - action to execute: cursor/general movements, mode specific commands, etc
4. Status: reception status - did the receiver get the message?

## Commands
