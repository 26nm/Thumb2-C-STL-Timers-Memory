		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		STMFD SP!, {R1-R12, LR} 
        LDRB R4, [R0]           ; this is a check to see if the given string in s, r0 is empty or not
        CMP R4, #0              ; if it is empty, we go to finished since we cant zero and empty string
        BEQ _bzero_finished
        
        CMP R1, #0              ; we also compare size with 0 since if we were given 0 as a size, we can quickly get out
        BEQ _bzero_finished
		
		MOV R2, #0              ; last we create an empty variable to store the contents from R0
_bzero_loop
        CMP R1, #0              ; counter variable check if its 0
		BEQ _bzero_finished     ; if it we branch out
		STRB R2, [R0], #0x1     ; store a byte from R0 to R2 and increment by 1
		SUB R1, R1, #1          ; subtract R1 by 0
		B _bzero_loop           ; branch back to counter to check R1
_bzero_finished
		LDMFD SP!, {R1-R12, LR} 
		MOV		PC, LR	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy                  
								; r0 = destination -> stringB
								; r1 = source -> stringA
								; r2 = size -> 40
		STMFD SP!, {R1-R12, LR} 
_strncpy_loop
        CMP R2, #0 				; compare R2 with 0 to see if we have copied enough
		BEQ _strncpy_finished
		LDRB R4, [R1], #0x1 	; load a byte from source string into r4
		STRB R4, [R0], #0x1  	; store a byte from r4 into destination string
		SUB R2, R2, #1          ; decrement the counter
		CMP R4, #0              ; compare to check if we have reached the end of the source string 
		BEQ _strncpy_finished   ; if we have loop to finish
		B _strncpy_loop
_strncpy_finished
		LDMFD SP!, {R1-R12, LR} 		
		MOV		PC, LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;    size    - #bytes to allocate
; Return value
;       void*    a pointer to the allocated space
        EXPORT    _malloc
_malloc
        ; save registers
        STMFD SP!, {R1-R12, LR}
        ;MOV        r3, r0                ; r3 = dest


        ; set the system call # to R7
        MOV        R7, #0x4        ; SYS_MALLOC in svc
        SVC     #0x0        ; initiate call table jump to svc
        ; resume registers
        ;MOV        r0, r3                ; return dest;
        LDMFD    SP!, {R1-R12,LR}
        MOV        PC, LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;    size    - the address of a space to deallocate
; Return value
;       none
        EXPORT    _free
_free
        ; save registers
        STMFD SP!, {R1-R12, LR}
        ; set the system call # to R7
        MOV        R7, #0x5        ; SYS_FREE in svc
        SVC     #0x0        ;jumps to svc handler in startup
        ; resume registers
        LDMFD    SP!, {R1-R12, LR}
        MOV        PC, LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		STMFD SP!, {R1-R12, LR}
		; set the system call # to R7
		MOV R7, #0x1
        SVC     #0x0
		; resume registers	
		LDMFD SP!, {R1-R12, LR}
		MOV	  PC, LR		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		STMFD sp!, {r1-r12, lr}
		; set the system call # to R7
		MOV R7, #0x2
        SVC     #0x0
		; resume registers
		LDMFD sp!, {r1-r12, lr}
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
