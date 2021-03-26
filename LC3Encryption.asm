; Encryption Program
; Samuel Fritz

; Program prompts the user for choice of operations (Encrypt, Decrypt, Exit)
; 5-character key used for encrpytion and decryption

.ORIG x3000; Start Program
    AND R0,R0,#0; Clear R0 to hold the message
    LEA R0, startMsg
    PUTS; Print the message to the screen

    prompt LEA R0, opPrompt; Load the prompt for the operation type into R0
    PUTS; Print the prompt to the screen
    GETC; Take in the input operation
    OUT; Echo the character back
    ; Need to check to make sure that the input is valid - if a match case if found,
    ;   jump to the next part of the program. If it fails to find a match, jump back
    ;   to the prompt
    AND R1, R1, #0; Clear R1 - holds the given offset
    AND R2, R2, #0; Clear R2 to hold the result of the test
    ; Checking for encryption (E or e)
    LD R1, EOffset; Load the set ASCII offset for E into R1
    ADD R2, R0, R1; Compute the sum
    BRz encryptJump; Matches - jump to next part and skip these operations
    LD R1, lowerEOffset
    ADD R2, R0, R1
    BRz encryptJump
    ; Checking for decryption (D or d)
    LD R1, DOffset
    ADD R2, R0, R1
    BRz decryptJump
    LD R1, lowerDOffset
    ADD R2, R0, R1
    BRz decryptJump
    ; Checking for exiting (X or x)
    LD R1, XOffset
    ADD R2, R0, R1
    BRz exiting
    LD R1, lowerXOffset
    ADD R2, R0, R1
    BRz exiting

    ; If it reaches this point, we can assume that none of the cases found a match and
    ;   the input must be invalid - print out the invalid message and then jump back 
    ;   to the operation prompt
    LEA R0, invalidIn
    PUTS
    BR prompt

    ; Jumping points for the subroutines in case the BR offset range does not allow them to be reached
    ; There are multiple ones that do similar operations, but since the operation has
    ;   already been identified, it is easier to keep them separated here as well
    encryptJump LD R0, encryptPointer; Load address of encrypt subroutine
    JSRR R0; Go through encryption
    ; Could print something out to say that encryption was successful - really just 
    ;   need to jump up to the prompt again
    ; Using BR caused errors, so doing the jumping with the actual jmp command
    LD R0, beginPointer
    JMP R0

    decryptJump LD R0, decryptPointer; Load address of decrypt subroutine
    JSRR R0; Go through decryption
    ; Could print out the decrypted message, but just need to go back to the operation prompt
    ; Have to use the JMP because BR would sometimes produce access violations
    LD R0, beginPointer
    JMP R0

    ; Jumping point for exiting the program - can't just jump to the HALT since we 
    ;   need to clear the memory where the message is
    ; Use the message location and set each memory location to zero by iteration
    exiting AND R1, R1, #0; Clear R1 to hold the counter
    LD R0, messageLoc
    clearLoop AND R2, R2, #0; Clear R2 to use the STR method and clear the spot
              STR R2, R0, #0; Clear the spot by storing a zero into the char. Don't need an offset since
                            ;      R0 already has been updated for the index
              ADD R0, R0, #1; Move to the next message location
              ADD R1, R1, #1; Increment R1 to reflect the number of clears done
              ADD R3, R1, #-10; Check to make sure it's still within the 10 string range
              BRnz clearLoop; Loop back around until the entire message has been cleared
    ; At this point, the message has been wiped and the R3 computation has returned a positive            
done HALT; End of main program
    ; Offsets used for ASCII equality tests for the operation input
    ; Offsets for E and e
    EOffset .fill #-69; E
    lowerEOffset .fill #-101; e
    ; Offsets for D and d
    DOffset .fill #-68; D
    lowerDOffset .fill #-100; d
    ; Offset for X and x
    XOffset .fill #-88; X
    lowerXOffset .fill #-120; x

    ; Various pointers or other variables
    messageLoc .fill x4000; Message starts at x4000

    ; Pointers to encrypt and decrypt
    encryptPointer .fill x3500
    decryptPointer .fill x3750

    ; Pointer to the beginning of the program
    beginPointer .fill x3003

    ; Welcome message
    startMsg .STRINGZ "Starting Privacy Module\n"
    ; Message asking what operation the user wants to run
    opPrompt .STRINGZ "ENTER: E TO ENCRYPT, D TO DECRYPT, X TO EXIT\n"
    ; Invalid input message
    invalidIn .STRINGZ "\nINVALID ENTRY, PLEASE TRY AGAIN\n"
.END; End of program

.ORIG x3500; Area for the encrypt subroutine - need an assured address to access it
    ; Subroutine for encrypting
    encrypt ST R7, returnPointer; Save the return address - gets wiped out from other subroutine calls
            LD R0, getKeyPointer; Load the address for the getKey subroutine
            JSRR R0; Get the key right away
            BR clearPrev; Clear away any message that may have been there from a previous operation- will return here
            restartMsg LEA R0, msgPrompt
            PUTS; print out the message for the message text to be encrypted
            ; Get the message
            AND R2, R2, #0; Clear R2 to use as counter
            getMsg LD R1, messageLocation; Beginning of message area into R1
                   ADD R1, R1, R2; Go to current index
                   GETC; Get the character input into R0
                   OUT; Echo the input
                   ADD R3, R0, #-10; Check to see if enter was inputted
                   BRz breakmsg; Enter was inputted, break out of loop
                   ; Otherwise, save the input and continue on
                   STR R0, R1, #0; Store the number into the memory location
                   ADD R2, R2, #1; Increment the counter 
                   BR getMsg; Keep looping until Enter is pressed
            breakmsg ADD R3, R2, #-10; Check to make sure the limit has not been exceeded
            BRnz validMsg; Message is within limit
            LEA R0, invalidMsg; Load the invalid message in
            PUTS; print out the invalid message statement
            ; Need to clear out the message in case a string with less than 10 chars is inputted
            clearPrev AND R1, R1, #0; R1 is counter
            LD R0, messageLocation
            clearMsg AND R2, R2, #0; Clear R2 to use the STR method and clear the spot
                     STR R2, R0, #0; Clear the spot by storing a zero into the char. Don't need an offset since
                            ;      R0 already has been updated for the index
                     ADD R0, R0, #1; Increment the location in message
                     ADD R1, R1, #1; Increment R1 to reflect the number of operations done so far
                     ADD R3, R1, #-10; Check to make sure it's still within the 10 string range
                     BRnz clearMsg;
            BR restartMsg; Get a new message until valid
            validMsg ST R2, messageLength; Save the length of the message, allowing for shorter messages
            ;JSR printMsg; For testing purpose
            ; Once the message has been fully saved, we can enter the encryption path

            ; First is Vignere's Cipher - XOR with x1
            ; Going to call an XOR subroutine that uses R0 and R1 as the operands and the result in R3
            ; Operand 1 is going the be x1 from the key
            LD R0, keyLocation; Load the beginning of the key into R0
            ADD R0, R0, #1; Go to the second char in the key - x1
            LDR R1, R0, #0; Load the value into R1
            ; For the second operand in each of these, need to get the message character, iterating through
            ; R2 is the counter
            vigLoop LD R4, messageLocation; Load the beginning of the message into R4
                    LD R2, index; Load the index into R2 to use
                    ADD R4, R4, R2; Updated index found
                    LDR R0, R4, #0; Load the value into R1
                    ; Both of the operands have been found, can call the XOR subroutine now
                    ; R0 = pi, R1 = x1
                    JSR XORsub; Result will be in R3
                    LD R4, messageLocation; Reload the message - errors without this
                    LD R2, index
                    ADD R4, R4, R2; Go to current index
                    STR R3, R4, #0; Store into the message location
                    ; The value has been saved, prepare for the next iteration
                    ADD R2, R2, #1; Increment the index
                    LD R3, messageLength; Load the length of the message into R3
                    ST R2, index; Save the incremented value
                    NOT R3, R3
                    ADD R3, R3, #1; Take 2C representation of the length
                    ADD R3, R2, R3; Check to see if the end has been reached -> index-length
                    BRn vigLoop; If negative, then iterate again
            ; Otherwise, we can asumme the case checking found zero or positive, in which case it is done
            ; At this point Vignere's cipher (encryption 1) has been finished
            AND R2, R2, #0
            ST R2, index; Clear the index variable for future use

            ; Move on to the second encryption - Caesar's cipher - modular arithmetic
            ; Get the value to be added with the character from the message - y1y2y3
            ; ci = (pi + K) mod 128
            LD R3, keyLocation; beginning of the key
            LDR R5, R3, #5; Get the net y value stored in memory - this will stay in R5 throughout subroutine calls
            ; R2 is the counter for the index
            caesarLoop LD R4, messageLocation; Load the beginning of the message into R4
                       LD R2, index; Load the index into R2 for use
                       ADD R4, R4, R2; Find the current index value
                       ; Need to use the char at the index added with the key y value in the mod operation
                       LDR R1, R4, #0; Load the character into R1
                       ; Take the sum now - save into R0 to use as the first operand in the mod operation
                       ADD R0, R5, R1; (pi + K)
                       LD R1, mod128; Load the second operand in (N)
                       JSR modulo; Call the modulo subroutine to perform the modular arithmetic
                       LD R4, messageLocation; Reload the message
                       LD R1, index; Reload the index
                       ADD R4, R4, R1; Go to current index
                       ; Result is in R2
                       STR R2, R4, #0; Save the result into the current location of the message
                       ; Value saved, prepare for next iteration
                       ADD R1, R1, #1; Increment index
                       LD R3, messageLength; Load message length
                       ST R1, index; Save the updated index
                       NOT R3, R3
                       ADD R3, R3, #1; Take the 2C representation of the length
                       ADD R3, R1, R3; Check to see if the end has been reached - subtract length from index
                       BRn caesarLoop; If negative, not done - iterate again
            ; Can assume here that the length matches (zero as result), encryption 2 is done
            AND R2, R2, #0
            ST R2, index; Clear the index variable for future use

            ; Move on to the third encryption - Left bit shift
            ; ci = (pi << K)
            ; Get number of times that we are going to shift left from the key - z1
            LD R0, keyLocation
            LDR R4, R0, #0; Load the first value of the key (z1) into R4
            BRz skipShiftE; If z1 = 0, can skip the calling process
            shiftELoop LD R3, messageLocation; Beginning of message into R3
                       LD R2, index; index value into R2
                       ADD R3, R3, R2; Get the current address of message
                       LDR R0, R3, #0; Load the current char of the message into R0
                       ADD R1, R4, #0; Load the z1 value into R1
                       ST R2, index; save the index - R2 in use soon
                       JSR shiftLeft; Call bit shift left subroutine (pi << K)
                       LD R3, messageLocation; Reload the message area
                       LD R5, index; Reload the index up
                       ADD R3, R3, R5; Go to the current index of message
                       ; Result in R2
                       STR R2, R3, #0; Save the result into the message 
                       ; Prepare for next iteration
                       ADD R5, R5, #1; Increment the index
                       ST R5, index; Save the updated index
                       LD R3, messageLength; Load the message length up
                       NOT R3, R3
                       ADD R3, R3, #1; Take full 2C representation of length
                       ADD R3, R3, R5; Check to see how current position compares -> index-length
                       BRn shiftELoop; If negative, not done yet
            ; The third encryption has been finished - length matches with the index
            skipShiftE AND R2, R2, #0
            ST R2, index; Clear the index for any future use
            
            ; At this point, all three encryption functions have been carried out
            ; Print out the encrypted message and then return to the main program
            JSR printMsg
       
            LD R7, returnPointer; Load the return address back into R7 to get back to main program
            LD R6, messageLength; Load the length into R6 so that decrypt can use it to stop on time
    RET; Return to caller

    ; Pointers to where the key and message are
    keyLocation .fill x4100; Key starts at x4100 - z1, x1, y1, y2, y3, ynet - 0,1,2,3,4,5
    messageLocation .fill x4000; Message starts at x4000

    ; Pointer for the getKey
    getKeyPointer .fill x4500

    decOffset .fill #-48; for converting to decimal value of numbers
    endDecOffset .fill #-57; The end of the numbers
    index .fill #0; Want to be zero, will be updated when needed - holds index
    mod128 .fill #128; for use in Caesar's cipher

    ; Return address pointer
    returnPointer .fill #0; Will be set when reaching here-get stuck in here without it
    ; Length of message
    messageLength .fill #0; Set when message is fully inputted

    ; Subroutine for XOR - from HW 4, ques2
    XORsub AND R3, R3, #0; Clear R3 for result
        ; Store A NAND B into R2 (used multiple times)
        AND R2, R0, R1
        NOT R2, R2; invert it to represent NAND - don't need to leave it in A AND B form

        ; First half of expression
        ; A NAND (A NAND B) --> NOT (R0 AND R2)
        AND R4, R2, R0
        NOT R4, R4; Invert the AND result --> NAND found

        ; Second half of expression
        ; B NAND (A NAND B) --> NOT (R1 AND R2)
        AND R5, R2, R1
        NOT R5, R5; Invert the AND result --> NAND found

        ; Total Expression
        ; NOT(R4 AND R5)
        AND R3, R4, R5
        NOT R3, R3; Inverted --> NAND found, total result found
    RET; Return to encrypt

    ; Subroutine for modulo operator - from HW 5, ques3
    ; N mod K, N in R0, K in R1
    ; Result in R2
    modulo NOT R1, R1; Invert the K value to allow it to be subtracted - R1 = -K
           ADD R1, R1, #1; Add 1 to R1 to make the full 2s complement conversion
           ADD R2, R0, #0; Store K into R2
           loop ADD R2, R2, R1; Subtract K from N --> N - K
                BRp loop; Not done yet
           ; Negative or zero has been computed, now need to add the resulting negative/zero with the original
           ;   divisor --> always makes the remainder
           NOT R1, R1
           ADD R1, R1, #1; Revert K back to the unsigned notation for use next
           ADD R2, R2, R1; Will add the negative number with the divisor, producing the remainder
        ; Result is now in R2, good to return back to caller
    RET

    ; Subroutine for bit shift left
    ; a << b
    ; R0 = a, R1 = b
    ; Result saved into R2
    ; Assume b =/= 0; There's a catch in the main encryption section
    shiftLeft 
       AND R2, R2, #0; Clear R2 to hold the sum
       ADD R2, R0, #0; Add a as a base line - it doubles, without this here, it will not fully represent the 
       ;      doubling process
       ; b/R1 acts as a counter in this subroutine
       shiftLoop ADD R2, R2, R2; Double the number again
                 ADD R1, R1, #-1; Decrement the counter/b value
                 BRp shiftLoop; Not done yet
    RET; Return to caller

    ; Subroutine for printing out the message
    printMsg AND R1, R1, #0; Clear R1 to use as a counter
             AND R0, R0, #0
             ADD R0, R0, #10; Put Enter into R0
             OUT; Print to a new line
             printLoop LD R2, messageLocation; Load the beginning of the message into R0
                       ADD R2, R2, R1; Go to the current index
                       LDR R0, R2, #0; Load the char to print into R0
                       OUT; Print out the character at the index
                       ADD R1, R1, #1; Increment the index
                       ADD R3, R1, #-10; Check to see if the end has been reached
                       BRn printLoop; The end has not been reached yet
             ; Otherwise can assume that the end has been reached and the string has been printed to the console 
             AND R0, R0, #0
             ADD R0, R0, #10; Load Enter into R0
             OUT; Print out a new line
    RET; Return to caller

    ; Prompt for the message, used in the encrypt subroutine
    msgPrompt .STRINGZ "\nEnter input plain text of length at most 10. When done press < enter >\n"
    invalidMsg .STRINGZ "\nINVALID MESSAGE INPUT. PLEASE TRY AGAIN\n"
.END 

.ORIG x3750; assured address for decryption
    ; Subroutine for decrypting
    decrypt ST R7, returnAdd; Store the return address right away
            ST R6, mLength; Store the length of the message to not go over
            LD R0, pointerGetKey
            JSRR R0; Get the key for decryption
            ; Move to decryption - in the reverse order of encryption

            ; First is the bit shift
            ; Need to shift to the right this time
            ; a >> b --> ci >> K
            ; Using a right shift subroutine, with a in R0 and b in R1 - result in R2
            LD R0, keyLocated; Load the address of the key into R0
            LDR R6, R0, #0; Load the first digit of the key (z1) into R6 --> K
            BRz skipShiftD; If z1 is zero, don't need to go into this area
            shiftDLoop LD R1, msgLoc; Load the beginning of the message into R0
                       LD R2, msgIndex; Load the index up 
                       ADD R1, R1, R2; Go to the current index location 
                       LDR R0, R1, #0; Load the message char into R0
                       ADD R1, R6, #0; Load the value of K (b) into R1
                       JSR rightShift; Call the subroutine to shift the value to the right
                       ; Result in R2
                       LD R0, msgLoc; Load the beginning of the message back into R0
                       LD R1, msgIndex; Load the index into R1
                       ADD R0, R0, R1; Go to the current index
                       STR R2, R0, #0; Store the result into the current location
                       ; Prepare for next iteration
                       ADD R1, R1, #1; Update the index
                       ST R1, msgIndex; Store the updated index
                       LD R3, mLength; Load the length of the message into R3
                       NOT R3, R3
                       ADD R3, R3, #1; Take 2C representation of R3
                       ADD R3, R3, R1; Check to see if the length has been reached
                       BRn shiftDLoop; Haven't reached the end yet, loop again
            skipShiftD AND R2, R2, #0; Clear R2 - also jumping point for skipping the bit shift section of decryption
            ST R2, msgIndex; Set the index to zero for future use

            ; Can now move on to the second part of decryption - the modular arithmetic section
            ; Encrypted as ci = (pi + K) mod 128
            ; To decrypt, pi = (ci -K) mod 128
            LD R3, keyLocated
            LDR R5, R3, #5; Get the net y value of the key from memory - stays in R5 through iterations
            NOT R5, R5
            ADD R5, R5, #1; Take the 2C conversion for subtracting
            caesarDLoop LD R4, msgLoc; Beginning of messge into R4
                        LD R2, msgIndex; Load the index up
                        ADD R4, R4, R2; Go to current index location
                        LDR R1, R4, #0; Load the current char into R1
                        ADD R0, R5, R1; (ci - K)
                        BRzp modJump; If (ci - K) isnt negative, jump straight to the modulus call
                        ; If (ci - K) is negative, need to find the inverse before calling the subroutine
                        LD R2, modN; Load 128 into R2
                        ADD R2, R2, R5; Do 128 - K
                        ADD R0, R2, R1; (ci + (128 - K)) - good for operations now
                        modJump LD R1, modN; Load 128 into R1
                        JSR modulus; Call the mod subroutine to perform (ci - K) mod 128
                        ; Result is in R2
                        LD R4, msgLoc; Load the beginning of the message
                        LD R3, msgIndex; Load the index up
                        ADD R4, R4, R3; Got to current index
                        STR R2, R4, #0; Store the result into memory
                        ; Value has been saved, prep for the next iteration
                        ADD R3, R3, #1; Increment the index
                        ST R3, msgIndex; Save the updated index
                        LD R1, mLength; Load the length up
                        NOT R1, R1
                        ADD R1, R1, #1; Do 2C conversion of the length
                        ADD R1, R1, R3; Check to see if the end has been reached --> index - length
                        BRn caesarDLoop; Length not reached, iterate again
        ; Can now assume that the second decrption has been finished
        AND R2, R2, #0
        ST R2, msgIndex; Clear the index for future use

        ; Can move to the third decryption now - the XOR area
        ; Encrypted as ci = pi XOR x1
        ; Decrypt by taking XOR again - code will be the same as the vignere's encryption area
        LD R0, keyLocated
        LDR R1, R0, #1; Load the second value of the key (x1) into R1 - not changed
        ; The second operand in each XOR call is the current message text
        vigDLoop LD R4, msgLoc; Load the message location
                 LD R2, msgIndex; Load index up
                 ADD R4, R4, R2; Go to current index
                 LDR R0, R4, #0; Load the current character of the message into R0
                 JSR XORDec; Call XOR subroutine - R0 XOR R1 --> R3
                 LD R4, msgLoc; Load message location back
                 LD R2, msgIndex; Load current index up
                 ADD R4, R4, R2; Go to current index address
                 STR R3, R4, #0; Store the result into memory
                 ; Prep for next iteration
                 ADD R2, R2, #1; Increment the index
                 ST R2, msgIndex; Save the updated index
                 LD R3, mLength; Load the length of the message
                 NOT R3, R3
                 ADD R3, R3, #1; Take 2C conversion
                 ADD R3, R3, R2; Subtract length from index to see if done yet
                 BRn vigDLoop; Length hasn't been reached, iterate again
        ; The third decryption has been finished
        AND R2, R2, #0
        ST R2, msgIndex; Clear the index for any future use

        ; Decryption is fully finished
        ; Print out the message text and return to main program
        JSR printMessage

        LD R7, returnAdd; Load the return address into R7 to get back to main program
    RET; Return to caller

    ; Variable for the index
    msgIndex .fill #0; Set to zero at first, altered through the algorithms
    modN .fill #128; For decrypting the modulus function

    ; Hold the return address to go back to when this is called - lost without it
    returnAdd .fill #0; Set when the subroutine is called
    ; Pointer to the subroutine for getting the key
    pointerGetKey .fill x4500
    ; Pointer to where the message is
    msgLoc .fill x4000
    ; Pointer to where the key is located at
    keyLocated .fill x4100
    ; Variable to hold the length of the message
    mLength .fill #0; Set upon entry to subroutine

    ; Subroutine for shifting right
    ; This will esentially work by doing integer division
    ; a >> b
    ; Arguments: R0 = a, R1 = b
    ; Result in R2
    ; Assume that b =/= 0; There's a catch in the main decryption loop
    rightShift ST R7, RSRet; Save the return address
               ADD R3, R0, #0; Move a into R3 before calling mutliply
               ; Need to take 2^b in order to use for integer division
               ; R4 will be the net result
               AND R4, R4, #0
               ADD R4, R4, #1; Set 1 as the base line - need to double
               ; b acts as the counter for the power -> move into R5 to avoid changes
               ADD R5, R1, #0;
               pow AND R0, R0, #0; Clear R0 and set 2 in it each time
                   ADD R0, R0, #2; Put 2 into R0
                   ADD R1, R4, #0; Second operand is the current sum
                   JSR mult; Call the multiplication to double the current sum
                   ; Result is in R2, set R4 as it
                   ADD R4, R2, #0; R4 = R4 *2
                   ADD R5, R5, #-1; Decrement the counter (b)
                   BRp pow; Still have more doubles to do
               ; Can now assume that 2^b is in R4
               ; Need to execute some integer division now
               ; a // (2^b) --> R3 // R4
               ; Done by subtracting (2^b) from a until a < (2^b)
               ; R2 as the counter for the number of times
               ; Could move the operands back into R0 and R1, but not really necessary
               AND R2, R2, #0; Clear R2
               NOT R4, R4
               ADD R4, R4, #1; Take 2C representation of (2^b)
               intDiv ADD R2, R2, #1; Increment R2
                      ADD R3, R3, R4; a - (2^b)
                      BRp intDiv; a > (2^b), keep going
               ; Can now assume that R3 is negative or zero
               ; R2 holds the result/ result of right shift
               LD R7, RSRet; Load the return address back up to go back to decrpyt
    RET; Return to caller 

    ; Variable holding the return address for the rightShift subroutine - it gets lost when calling mult
    RSRet .fill #0; Set when the right shift subroutine is called

    ; Subroutine for multiplication - Operands in R0 and R1 - result in R2
    ; Used in the right shift subroutine for power
    mult AND R2, R2, #0; Clear R2 to hold result
         multiplyLoop ADD R2, R2, R1; Add the second number to R2, will be working result in power calc
                      ADD R0, R0, #-1; Decrement the 'counter'/ first operand
                      BRp multiplyLoop; Hasnt reached zero yet, loop through again
         ; The result has been found - in R2
    RET; Return to caller

    ; Subroutine for modulo operator - from HW 5, ques3
    ; N mod K, N in R0, K in R1
    ; Result in R2
    modulus NOT R1, R1; Invert the K value to allow it to be subtracted - R1 = -K
           ADD R1, R1, #1; Add 1 to R1 to make the full 2s complement conversion
           ADD R2, R0, #0; Store N into R2
           modloop ADD R2, R2, R1; Subtract K from N --> N - K
                BRp modloop; Not done yet
           ; Negative or zero has been computed, now need to add the resulting negative/zero with the original
           ;   divisor --> always makes the remainder
           NOT R1, R1
           ADD R1, R1, #1; Revert K back to the unsigned notation for use next
           ADD R2, R2, R1; Will add the negative number with the divisor, producing the remainder

        ; Result is now in R2, good to return back to caller
    RET

    ; Subroutine for XOR - from HW 4, ques2
    ; Result in R3
    XORDec AND R3, R3, #0; Clear R3 for result
        ; Store A NAND B into R2 (used multiple times)
        AND R2, R0, R1
        NOT R2, R2; invert it to represent NAND - don't need to leave it in A AND B form

        ; First half of expression
        ; A NAND (A NAND B) --> NOT (R0 AND R2)
        AND R4, R2, R0
        NOT R4, R4; Invert the AND result --> NAND found

        ; Second half of expression
        ; B NAND (A NAND B) --> NOT (R1 AND R2)
        AND R5, R2, R1
        NOT R5, R5; Invert the AND result --> NAND found

        ; Total Expression
        ; NOT(R4 AND R5)
        AND R3, R4, R5
        NOT R3, R3; Inverted --> NAND found, total result found
    RET; Return to encrypt

    ; Subroutine for printing out the message
    printMessage AND R1, R1, #0; Clear R1 to use as a counter
             AND R0, R0, #0
             ADD R0, R0, #10; Put Enter into R0
             OUT; Print to a new line
             printingLoop LD R2, msgLoc; Load the beginning of the message into R0
                          ADD R2, R2, R1; Go to the current index
                          LDR R0, R2, #0; Load the char to print into R0
                          OUT; Print out the character at the index
                          ADD R1, R1, #1; Increment the index
                          ADD R3, R1, #-10; Check to see if the end has been reached
                          BRn printingLoop; The end has not been reached yet
             ; Otherwise can assume that the end has been reached and the string has been printed to the console 
             AND R0, R0, #0
             ADD R0, R0, #10; Load Enter into R0
             OUT; Print out a new line
    RET; Return to caller
.END

.ORIG x4500; Assured address for getting the key - couldn't get the exact address of the encryption subroutine
    ;      without the use of a separate memory area
    ; Subroutine for getting the encryption key
    getKey ST R7, retPointer; Save the return address before doing anything - need to save it to get back, as errors arise without it
           restartKey LEA R0, keyPrompt; Load the prompt into R0
           PUTS; Print out the prompt
           AND R2, R2, #0; Clear R2 for use as the counter
           keyLoop LD R1, keyLoc; Load the beginning of the key area into R1
                   ADD R1, R1, R2; Add the current offset to get to the correct memory address
                   GETC; Get the character inputted into R0
                   OUT; Echo the character back
                   STR R0, R1, #0; Store the result into memory - R1 has saved offset already
                   ADD R2, R2, #1; Increment the counter
                   ADD R3, R2, #-5; Check if length 5 reached
                   BRnp keyLoop; Jump back up to the beginning of the loop until 5 characters inputted
           AND R2, R2, #0; Clear R2 to use as the counter
           convertLoop LD R0, keyLoc; Load the beginning of the key into R0
                       ADD R0, R0, R2; Go to the current index
                       ADD R1, R2, #-1; Check to see if on x1 - key[1] 
                       BRz continueConvert; If on x1, don't need to convert from ASCII since the operation it's
                       ;    used for uses the ASCII value
                       ; Otherwise, subtract 48 from each number input to get a usable value
                       LDR R1, R0, #0; Load the value into R1
                       LD R3, asciiOff; Load ascii offset for decimals
                       ADD R1, R1, R3; Subtract 48 
                       STR R1, R0, #0; Store the value back into the key location

                       continueConvert ADD R2, R2, #1; Increment the index counter
                       ADD R3, R2, #-5; Check to see if at end of key (i < keylength)
                       BRn convertLoop; If 0 or above, end of key has been reached
           ; Need to find the net number from y1y2y3, not just the individual parts
           LD R1, keyLoc; Get the beginning of the key string
           ; For each number, need to multiply by the place value (100, 10, or 1) and add to an overall result
           ; Calling the multiply subroutine with the inputted value and the place value
           LDR R0, R1, #2; Load the first operand into R0, using the offset that puts at y1
           LD R1, oneHund; Put 100 into R1
           JSR multiply; Call multiply --> y1 * 100 - result in R2
           AND R3, R3, #0; Clear R3 - will hold the overall sum and net three digit number
           ADD R3, R3, R2; Add the result from the multiplication into R3
           ; Repeat the process for the next two numbers
           LD R1, keyLoc; Beginning of key string into R1
           LDR R0, R1, #3; Load the second operand into R0, y2
           AND R1, R1, #0; Clear R1 and put 10 in
           ADD R1, R1, #10; 
           JSR multiply; Call multiply --> y2 *10
           ADD R3, R3, R2; Add the result to the working
           LD R1, keyLoc
           LDR R0, R1, #4; Load the third operand, y3
           AND R1, R1, #0; Clear R1 and insert 1
           ADD R1, R1, #1
           JSR multiply; Call multiply --> y3* 1
           ADD R3, R3, R2; Add the result to sum

           ; At this point, can check to make sure that the number is actually valid
           LD R2, yUpperTest
           ADD R2, R3, R2; Check to make sure the number is between 0 and 128 (exclusively)
           BRp invalidKeyIn; greater than 127
           ADD R3, R3, #0; Bring value onto global bus
           BRzp saveNetY; greater than zero, is valid input
           ; If it reaches this point, y value is wrong
           invalidKeyIn LEA R0, invalidKey
           PUTS; Print out the invalid key message
           BR restartKey; Jump back up to the area to get the key
           ; Net number has been found, store into the location just past the key - will not be printed, but just
           ;  for use in future operations
           saveNetY LD R0, keyLoc; Beginning of the key into R0
           STR R3, R0, #5; Store the number into x4105

           ; Check z1, the value for bit shift, to make sure it's between 0 and 7 (inclusively)
           LDR R1, R0, #0; Load the value into R1 for easy use
           ADD R0, R1, #-8; Check if greater than 7
           BRzp invalidKeyIn; Was >7
           ADD R1, R1, #0; Bring value back onto global bus
           BRn invalidKeyIn; Was <0
           ; Can now assume that z1 is valid

           ; Check to see if x1 has zero inputted - if it does, it needs to reflect that - switch it from 48 to 0
           LD R1, keyLoc; Load the key into R1
           LDR R0, R1, #1; Get the second value of the key (x1) into R0
           LD R2, asciiOff; Load the ascii offset into R1
           ADD R3, R0, R2; Check if the value is zero
           BRz savex1As0
           BRn keyfinished; Character below the number range- can skip tests
           ; Not zero, now need to check if it's another number
           ; Subtract 9 from the previous result (range of numbers, excluding zero)
           ADD R3, R3, #10
           BRn invalidKeyIn; Returned negative -> was a non-zero number
           ; Otherwise, we can assume that the value is good (non numeric char) and can just leave it
           BRzp keyfinished; Jump past the section saving zero for x1
           savex1As0 STR R3, R1, #1; Save the previous result into the x1 location of key
           ; Key has been save

           ; The key has been found and converted for use, echo the key
           keyfinished ;JSR printKey; Print key and then finish subroutine
           LD R7, retPointer; Load the return address back into R7 to ensure that we go back
    RET; Return to caller
    oneHund .fill #100; Holds one hundred for use in the above subroutine
    asciiOff .fill #-48; for converting to decimal value of numbers

    ; Variables for use in computations
    yUpperTest .fill #-127
    yLowerTest .fill #128

    ; The pointer to get back to the encrypt/decrypt area - seems to get stuck here without it
    retPointer .fill #0; Initialize to zero, saved when reaching the subroutine
    
    ; Subroutine for printing out the key
    printKey AND R1, R1, #0; R1 is the counter
             AND R0, R0, #0
             ADD R0, R0, #10; Put Enter into R0
             OUT; Print to a new line
             printing LD R2, keyLoc; Load beginning of key into R0
                      ADD R2, R2, R1; Get the current index
                      LDR R0, R2, #0; Load the current char to be printed out into R0
                      OUT; Print out the character at the index
                      ADD R1, R1, #1; Increment the index
                      ADD R3, R1, #-5; Check to see if the has been reached
                      BRn printing; The end hasn't been reached - loop again
             ; Can assume the key has been fully printed out
             AND R0, R0, #0; Clear R0
             ADD R0, R0, #10; Put Enter into R0
             OUT; Go to the next line in console
    RET; Return to caller

    ; Subroutine for multiplication - Operands in R0 and R1 - result in R2
    multiply AND R2, R2, #0; Clear R2 to hold result
             ; Check to see if the first operand is zero (R0, the inputted y1)
             ADD R0, R0, #0; Pull onto global bus
             BRz skip; Don't need to multiply with this
             multLoop ADD R2, R2, R1; Add the second number to R1 - will be 100, 10 or 1
                      ADD R0, R0, #-1; Decrement the 'counter'/ first operand
                      BRp multLoop; Hasnt reached zero yet, loop through again
             ; The result has been found - in R2
             skip; Jump point for an operand being zero - R2 still holds zero
    RET; Return to caller
    
    ; Pointers to where the key and message are
    keyLoc .fill x4100; Key starts at x4100 - z1, x1, y1, y2, y3, ynet - 0,1,2,3,4,5
    
    ; Invalid key message
    invalidKey .STRINGZ "\nINVALID KEY CONSTRAINTS. PLEASE TRY AGAIN.\n"
    ; Prompt for the encryption key
    keyPrompt .STRINGZ "\nENTER KEY (Length 5, single digit less than 8 followed by non-numeric character or the number 0 followed by a 3 digit number between 0 and 127)\n"
.END 