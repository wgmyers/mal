*> readline.cob
*> An attempt to interface to the C readline library
*> NB We are using the modern 'free' format, so must compile with -free
*>    This allows us not to have to muck about with weird columns
IDENTIFICATION DIVISION.
PROGRAM-ID. READLINE IS INITIAL.
AUTHOR. WAYNE MYERS.

DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-PROMPT-MSG-C PIC X(7).
01 WS-READLINE-PTR USAGE POINTER.
01 WS-READLINE-BUFFER PIC X(255) BASED.

LINKAGE SECTION.
01 WS-PROMPT-MSG PIC X(6).
01 WS-INPUT PIC X(255).

PROCEDURE DIVISION USING WS-PROMPT-MSG, WS-INPUT.
     PERFORM INIT-PROMPT-PARA.
     CALL 'readline' USING
          WS-PROMPT-MSG-C
          RETURNING WS-READLINE-PTR
     END-CALL.
     CALL 'add_history' USING
          BY VALUE WS-READLINE-PTR
     END-CALL.
     PERFORM COPY-CSTRING-PARA.
     PERFORM PROCESS-CSTRING-PARA.
     EXIT PROGRAM.

*> C strings have NULL terminators
*> COBOL strings do not
*> See https://svn.code.sf.net/p/gnucobol/code/external-doc/GnuCOBOL_C_Interaction.pdf
INIT-PROMPT-PARA.
     MOVE FUNCTION CONCATENATE(WS-PROMPT-MSG,X'00') TO WS-PROMPT-MSG-C.

*> GnuCOBOL 3.0 has a built-in for this, but we don't have it
*> So. Clobber WS-INPUT and use our WS-READLINE-BUFFER to copy across.
COPY-CSTRING-PARA.
     INSPECT WS-INPUT REPLACING CHARACTERS BY SPACE.
     SET ADDRESS OF WS-READLINE-BUFFER TO WS-READLINE-PTR.
     STRING
          WS-READLINE-BUFFER DELIMITED BY X'00'
          INTO WS-INPUT
     END-STRING.

*> Convert back to a proper COBOL string before returning.
*> NB - possibly not necessary after COPY-STRING-PARA - not sure where NULL goes.
PROCESS-CSTRING-PARA.
     INSPECT WS-INPUT
     REPLACING FIRST X'00' BY SPACE
     CHARACTERS BY SPACE AFTER INITIAL X'00'.
