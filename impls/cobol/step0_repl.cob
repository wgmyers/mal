*> step0_repl.cob
*> NB We are using the modern 'free' format, so must compile with -free
*>    This allows us not to have to muck about with weird columns
IDENTIFICATION DIVISION.
PROGRAM-ID. MAL-STEP0.
AUTHOR. WAYNE MYERS.

DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-PROMPT-MSG PIC X(6) VALUE 'user> '.
01 WS-QUIT PIC 9(1) VALUE 0.
01 WS-INPUT PIC X(255).

PROCEDURE DIVISION.
*> Main program loop
     PERFORM REPL-PARA UNTIL WS-QUIT = 1.
STOP RUN.

REPL-PARA.
*> Implement the READ/EVAL/PRINT loop
     PERFORM READ-PARA.
     PERFORM EVAL-PARA.
     PERFORM PRINT-PARA.

READ-PARA.
*> Display prompt and get response from user
     DISPLAY WS-PROMPT-MSG WITH NO ADVANCING.
     ACCEPT WS-INPUT.
     IF WS-INPUT = "q" OR WS-INPUT = "Q" THEN
       MOVE 1 TO WS-QUIT.

EVAL-PARA.
*> Do nothing for now.

PRINT-PARA.
*> Print respoonse from user
     DISPLAY FUNCTION TRIM(WS-INPUT).
