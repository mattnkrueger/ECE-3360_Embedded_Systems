/**
 * @file commands.h
 * @author Sage Marks and Matt Krueger
 * @brief Implementation of commands used for terminal emulator used in Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * @copyright Copyright (c) 2025
 * 
 */

#ifndef COMMANDS_H
#define COMMANDS_H

void G_command();
void M_command(char* params);
void S_command(char* params); 
void process_command(char command, char* params);
int read_line(char* buffer, int max_length);

#endif 