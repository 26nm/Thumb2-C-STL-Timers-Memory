		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
		LDR R0, =STCTRL         ; Load the address of the SysTick Control Register into R0
		LDR R1, =STCTRL_STOP    ; Load the value to stop SysTick timer into R1
	
		STR R1, [R0]            ; Store the stop value into the SysTick Control register
	 
		LDR R0, =STRELOAD       ; Load the addres of the SysTick Reload register into R0
		LDR R1, =STRELOAD_MX    ; Load the maximum reload value into R1
		STR R1, [R0]            ; Store the maximum reload value into the SysTick reload register
	
	    MOV		PC, LR			; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	    LDR R3, =SECOND_LEFT    ; Load the address of the SECOND_LEFT variable into R3
		MOV R1, R0              ; Move the seconds parameter into R1
		LDR R0, [R3]            ; Load the value of the SECOND_LEFT into R0
		 
		STR R1, [R3]            ; Store the new seconds value into second_left
		 
		LDR R1, =STCURRENT      ; Load the address of the SysTick current value register into R1
	    LDR R2, =STCURR_CLR     ; Load the value to clear the Systick Current Value register into R2
		STR R2, [R1]            ; Store the clear value into the Systick current value register to clear it
	
		LDR R1, =STCTRL         ; Load value of SysTick control register into R1
		LDR R2, =STCTRL_GO      ; Load value to start SysTick Timer into R2
		STR R2, [R1]            ; Store that value to start timer
		
		MOV		PC, LR 		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
    LDR R3, =SECOND_LEFT
    LDR R0, [R3]         ; Load current SECOND_LEFT
    SUBS R0, R0, #1      ; Decrement by 1
    STR R0, [R3]         ; Store back

    CMP R0, #0           ; Compare SECOND_LEFT with 0
    BNE _timer_update_done  ; If not zero exit

    LDR R1, =STCTRL      ; Load the address of the SysTick Control Register into R1
    LDR R4, =STCTRL_STOP ; Load the value to stop timer into R4
    STR R4, [R1]         ; Stop the timer

_timer_update_done
    MOV PC, LR           ; Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
		CMP R0, #SIGALRM         ; Compare signum with SIGALRM
		BNE _signal_done         ; if they aren't equal branch to done
		LDR R3, =USR_HANDLER     ; Load the address of the user handler  into R3
		LDR R2, [R3]             ; Store the userhandler address into R2 ->  R2 will become previous
		STR R1, [R3]             ; Store the given new handler address into R3 -> R3 AKA user_handler will now hold current

_signal_done
		MOV R0, R2  ; store previous handler into R0  
		MOV pc, lr ; return to Reset_Handler
		END		
			