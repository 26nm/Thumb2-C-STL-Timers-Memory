		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
		PUSH 	{R0, R1, R2, R3} ; Save registers on the stack
		
		; Initialize the first MCB entry with MAX_SIZE
		LDR		R0, =MAX_SIZE 
		LDR 	R1, =MCB_TOP  ; Load the start address of MCB into R1
		STR		R0, [R1], #4  ; Store MAX_SIZE at R1 AND increment it by 4 
		LDR 	R2, =MCB_BOT  ; Load the end address of MCB into R2

        ; loop for initializing mcb entries
init_loop
		CMP		R1, R2        ; Check if current MCB address exceeds end
		BGT 	init_finished ; If it does, we exit; initialization is finished
		MOV 	R3, #0x0      ; Register to hold 0
		STR		R3,[R1]       ; Store 0 at the current MCB address
		ADD 	R1, R1,#4     ; Go to the next MCB entry

		B init_loop              ; Repeat loop
			
init_finished
		POP 	{R0, R1, R2, R3}  ; Restore registers
		BX		LR                ; Return from function
		
			;you must correctly set the value of each MCB block
			; complete your code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	; complete your code
		; r0 = size
		; return value should be saved into r0
		
		PUSH {LR}            ; Save link register
		
		
		LDR 	R1, =MCB_TOP ; Load start of MCB
		LDR 	R2, =MCB_BOT ; Load end of MCB
		PUSH {R0-R5, R7-R12} ; Save other registers
		BL _ralloc           ; Call helper function
		POP {R0-R5, R7-R12}  ; Restore registers
		MOV   R0,R6          ; Move result into R0 before returning
		POP {LR}             ; Restore link register
		BX	LR               ; return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void *_ralloc(int size, int left_mcb_addr, int right_mcb_addr) {
		EXPORT _ralloc
_ralloc
		
		;R0,=size
		;R1 =left_mcb_addr
		;R2 =right_mcb_addr
		
		PUSH {LR}  ; Save Link register

		
		; Computer address space parameters 
		SUB R3, R2, R1 			; R3 = right_mcb_addr - left_mcb_addr
		ADD R3, R3, #0x00000002 ; R3 += MCB_ENT_SZ
		ASR R4, R3, #1		    ; R4 R3/2 -> half of the address space
		ADD R5, R1, R4          ; R5 = R1 + R4 = midpoint address
		
		; Compute heap size calculations
		MOV R6, #0				; Initialize heap address to 0 
		LSL R7, R3, #4		    ; R7 = R3*16 = actual size of entire heap
		LSL R8, R4, #4		    ; R8 = R4 * 16 = half size of the heap
		
		CMP R0, R8				; Compare requested size with half of the heap size
		BLE recursive_left_half ; Branch to the left half if the requested size <= half of the heap size
		
		; Check if left MCB is free
		LDR R10, [R1]           ; Load left MCB value
		AND R10, R10, #1        ; Check LSB to see if its free or used 1 means occupied and 0 means free
		CMP	R10, #0             ; Check if its free
		BNE	return_zero         ; if the block if not free branch to return_zero
		
		LDR R11, [R1]           ; Load left MCB value in the case that it is free
		CMP R11, R7             ; Compare the actual heap size with the MCB size
		BLT return_zero         ; If its less than branch to return_zero
		
		ORR R9, R7, #1          ; If it's greater than mark it now as used
		STR R9, [R1]            ; Store the updated value 
		
		; Calculate and return heap address
		LDR R10, =	MCB_TOP     ; Load MCB_TOP
		SUB R6, R1,R10          ; Calculate offset from MCB_TOP
		LSL R6, R6, #4          ; Convert it to a heap address
		LDR R10, =	HEAP_TOP    ; Add HEAP_TOP to calculate address
		ADD R6, R6, R10         ; Final Heap address
		
		B ralloc_finished            ; return function

recursive_left_half
		PUSH {R0-R5, R7-R12}     ; Save registers for recursion
		SUB	 R2, R5, #0x00000002 ; Adjust bounds for left half
		BL	_ralloc				 ; Recursive call
		POP {R0-R5, R7-R12}      ; Restore registers
		CMP R6, #0				 ; Check if allocation was successful
		BEQ recursive_right_half ; if not successful retry allocation with right half.
		
		;Check if the right MCB is free
		LDR	R9, [R5]             ; Load the right MCB value
		AND	R9, R9, #1           ; Check to see if its free
		CMP R9, #0               ; Compare with 0 to make sure its free
		BEQ	str_half_heap        ; if it is free store the size of half the heap
		B	ralloc_finished      ; end the function
		
str_half_heap
		STR	R8, [R5]
		B	ralloc_finished
		
recursive_right_half		
		PUSH {R0-R5, R7-R12}     ; Save registers
		MOV	R1, R5               ; Update current bounds
		BL _ralloc               ; Call _ralloc
		POP {R0-R5, R7-R12}      ; Restore registers
		B	ralloc_finished      ; end the function

return_zero
		MOV R6, #0 ; simply assign 0 to R6 and end the function
		B	ralloc_finished
		
ralloc_finished		             ; return r6;
		POP {LR}
		BX LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; int _rfree(int mcb_addr) {
		EXPORT _rfree
_rfree
        ; R0 = mcb_addr
	    PUSH{LR}	                ;Save registers
		
		; Load MCB contents and calculate indices and sizes
		LDR R4, [R0]				; R4 = mcb_contents (contents at mcb_addr
		LDR R11, =MCB_TOP           ; R11 Start of MCB array
		SUB R6, R0, R11 			; R6 = mcb_index which is the index of the mcb_addr in the array	
		ASR R4, R4, #4				; mcb_display = mcb_contents by 16
		MOV R7, R4
		LSL R4, R4, #4
		MOV R8, R4                  ; R8 = size
		
		STR R4, [R0]			    ; Clear the used bit of the MCB at mcb_addr

        ; Determine whether we have to merge by checking the buddy blocks that are both above and below the current mcb 
		SDIV R9, R6, R7				; R9 = mcb_index / mcb_display (buddy index) get buddy index
		AND  R9, R9, #1             ; Check index to see if we have to merge buddy below or above LSB = 0 means below LSB = 1 means above
		CMP	 R9, #0					
		BEQ check_buddy_below		; Branch to check below if 0
								
								    ; Else condition: check buddy above and merge if needed
		; Calculate address of buddy above
		SUB R5, R0, R7              ; R5 = address of buddy above
		LDR R11, =	MCB_TOP         
		CMP R5, R11                 ; Check if buddy above is in bounds
		BLT rfree_INVALID           ; If it isn't then return with 0
		
		; Continue since we verified in bounds
		SUB R3, R0, R7
		LDR R12, [R3]               ; R12 MCB_BUDDY
		AND R2, R12, #1             ; Check LSB to see if buddy is in use
		CMP R2, #0                  ; if it is 0 branch to end_rfree
		BNE rfree_finished
		
		; Buddy is not in use and size matches? Time to merge
		
		; Normalize size of MCB_BUDDY since we are about to merge
		ASR R12, R12, #5 
		LSL R12, R12, #5
		
		CMP R12, R8                 ; Compare to make sure they are equal in size
		BNE rfree_finished          ; if sizes do not match rfree_finished
		 
		 
		; Merging logic
		MOV R10, #0
		STR R10, [R0]               ; Clear the MCB     
		 
		LSL R8, R8, #1              ; Double the size
		SUB R9 , R0, R7             
		STR R8, [R9]                ; Update size
		
		PUSH {R0, R2-R12}
		SUB R0, R0, R7
		BL _rfree                   ; Call function to recursively free merged block
		
		POP {R0, R2-R12}

check_buddy_below
		
		ADD R9, R4, R7              ; R9 = MCB conents + display size
		LDR R10, =	MCB_TOP         
		CMP R4, R10                 ; Check in bounds
		BGE rfree_INVALID           ; End if not in bounds

		
		ADD R2, R0, R7              ; R2 = address of the buddy below
		LDR R10, [R2]				; R10 is mcb_buddy which is contents at buddy address
		
		AND R11, R10, #1            ; Check if buddy is in use
		CMP R11, #0                 
		BNE rfree_finished          ; If buddy is in use branch to rfree_finished

		; Normalize buddy size
		ASR R10, R10, #5
		LSL R10, R10, #5
		
		CMP R10, R8                 ; compare with actual size
		BNE rfree_finished          ; end if sizes aren't the same
		
		; Merge with buddy below
		MOV R12, #0                 
		STR R12, [R2]               ; Clear MCB
		LSL R8, R8, #1              ; Double the size
		STR R8, [R0]                ; Update the size
		
		PUSH {R0, R2-R12}           ; Save registers
	 
		BL _rfree                   ; Recursively free merged block
		
		POP {R0, R2-R12}            ; Restore registers

rfree_INVALID
		MOV R1, #0                  ; Set return status to 0 fail
		B rfree_finished
		
rfree_finished	                    ; Branch here if successful
		POP {LR}	                ; Restore registers
		BX LR						; Return mcb_addr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
		PUSH {LR}          ; Save link register
	
		; Check if the address in ptr is within the valid heap range
		MOV R1, R0         ; Copy pointer to R1
		LDR R2, =HEAP_TOP  ; Load HEAP_TOP into R2
		CMP R1, R2         ; Compare the address with HEAP_TOP
		BLT kfree_INVALID  ; Branch to kfree_INVALID if the address is less 

		LDR R2, =HEAP_BOT  ; Load HEAP_BOT into R2
		CMP R1, R2         ; Compare the address with HEAP_BOT
		BGT kfree_INVALID  ; Branch to kfree_INVALID if the address is greater

		; Calculate MCB address from heap pointer
		LDR R2, = HEAP_TOP ; Load MCB_TOP into R2
		SUB R4, R1, R2     ; Calculate ptr - HEAP_TOP
		ASR R4, R4, #4    ; Divide by 16 (size of each block)
		LDR R2, =MCB_TOP
		ADD R0, R4, R2     ; Add MCB_TOP to the result to get the MCB address

		; Call _rfree function
		PUSH {R0, R2-R12}
		BL _rfree          ; Call _rfree with MCB address in R1
		POP {R0, R2-R12}
	
		CMP R0, #0         ; Check if _rfree returned 0 (indicating failure)
		BEQ kfree_INVALID  ; Branch to kfree_INVALID if _rfree failed
 
		MOV R0, R1         ; Return to original pointer
		B kfree_finished       ; Branch to exit
	 
kfree_INVALID
		MOV R0, #0         ; Move 0 and exit
		B kfree_finished
	
kfree_finished
		POP {LR}           ; Restore link register
		BX LR              ; Return from the function
		END


	