*> readline.cob
*> An attempt to interface to the C readline library
*> NB We are using the modern 'free' format, so must compile with -free
*>    This allows us not to have to muck about with weird columns
IDENTIFICATION DIVISION.
PROGRAM-ID. READLINE IS INITIAL.
AUTHOR. WAYNE MYERS.

DATA DIVISION.
WORKING-STORAGE SECTION.

LINKAGE SECTION.
01 WS-PROMPT-MSG PIC X(6).
01 WS-INPUT PIC X(255).

PROCEDURE DIVISION USING WS-PROMPT-MSG, WS-INPUT.
     DISPLAY WS-PROMPT-MSG WITH NO ADVANCING.
     ACCEPT WS-INPUT.
     EXIT PROGRAM.
