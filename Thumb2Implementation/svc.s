		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init

	STMFD SP!, {R1-R12, LR}        ; Save registers
	
	; store all these functions so that they can be initlialized in reset_handler with their relative addresses
	; they are going to be used later when svc needs to jump to their locations

	IMPORT _kalloc                 
	LDR R0, =_kalloc               
	LDR R1, =0x20007B10
	STR R0, [R1]                  
	
	IMPORT _kfree
	LDR R0, =_kfree
	LDR R1, =0x20007B14           
	STR R0, [R1]
	
	IMPORT _signal_handler
	LDR R0, =_signal_handler
	LDR R1, =0x20007B08
	STR R0, [R1]
	
	IMPORT _timer_start
	LDR R0, =_timer_start
	LDR R1, =0x20007B04
	STR R0, [R1]
	
	
	LDMFD SP!, {R1-R12, LR}  ; Restore registers
	MOV	  PC, LR             ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump

	STMFD SP!, {R1-R12, LR}  ; Save registers
	
	; Code to determine proper address of function  base address = 0x20007B00
	; offset is calculated by shifiting by multiplying number in R7 by 4 and adding it to base address
	; Basically the number in R7 is mapped to its proper address which is stored in R8.  For exmample if R7 = 2, and base = 0x20007B00
	; R7 = 2*4 = 8 + 0x20007B00  = 0x20007B08 which in this case is signal or 0x2 for R7
	LDR R8, =SYSTEMCALLTBL
	MOV R9, R7
	LSL R9, #2
	ADD R8, R8, R9
	
	; Logic to determine which place to jump to (what function it is) based on number in R7
	CMP R7, #SYS_FREE
	BEQ free_method
	
	CMP R7, #SYS_MALLOC
	BEQ malloc_method
	
	CMP R7, #SYS_ALARM
	BEQ alarm_method
	
	CMP R7, #SYS_SIGNAL
	BEQ signal_method

                        ; Branch to appropriate method in this case using the address, after method gets executed branch to finish
free_method
     LDR R8, =_kfree
	 BLX R8
	 B finish

malloc_method
     LDR R8, =_kalloc
	 BLX R8
	 B finish 
	 
alarm_method
     LDR R8, =_timer_start
	 BLX R8                  
	 B finish

signal_method
     LDR R8, =_signal_handler
	 BLX R8
	 B finish

finish
		LDMFD SP!, {R1-R12, LR} ; Restore registers
		MOV		PC, LR			
		END


		
