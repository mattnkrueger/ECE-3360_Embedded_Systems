#ifndef COMMANDS_H
#define COMMANDS_H

void G_command() {};

void M_command(char* params) {};

void S_command(char* params) {}; 

void process_command(char command, char* params) {};

int read_line(char* buffer, int max_length) {};

#endif 