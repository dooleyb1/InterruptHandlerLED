; Definitions  -- references to 'UM' are to the User Manual.

; Timer Stuff -- UM, Table 173

T0	equ	0xE0004000								; Timer 0 Base Address
T1	equ	0xE0008000								; Timer 1 Base Address

IR	equ	0										; Add this to a timer's base address to get actual register address
TCR	equ	4 										; Timer Command Reset Register offset 
MCR	equ	0x14 									; Timer Mode Reset and Interrupt Offset
MR0	equ	0x18 									; Match Register (counter) offset

TimerCommandReset			equ	2				; Reset timer 
TimerCommandRun				equ	1		    	; Run timer
TimerModeResetAndInterrupt	equ	3				; Reset timer mode and interrupt
TimerResetTimer0Interrupt	equ	1 				; Reset timer 0 and interrupt
TimerResetAllInterrupts		equ	0xFF 			; Reset all timer interrupts

; VIC Stuff -- UM, Table 41
VIC	equ	0xFFFFF000								; VIC Base Address
IntEnable	equ	0x10 							; Interrupt Enable
VectAddr	equ	0x30 							;
VectAddr0	equ	0x100 							; Vectored Interrupt 0
VectCtrl0	equ	0x200 							; Vectored Interrupt Control 0

Timer0ChannelNumber	equ	4						; UM, Table 63
Timer0Mask			equ	1<<Timer0ChannelNumber	; UM, Table 63
IRQslot_en			equ	5						; UM, Table 58

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN	EQU	0xE0028010

	AREA	InitialisationAndMain, CODE, READONLY
	IMPORT	main

; (c) Mike Brady, 2014â€“2016.

	EXPORT	start
start

; initialisation code
	ldr	r1,=IO1DIR			
	ldr	r2,=0x000f0000							;select P1.19--P1.16
	str	r2,[r1]									;make them outputs
	ldr	r6,=IO1SET								;R6 = Set
	str	r2,[r6]									;set them to turn the LEDs off
	ldr	r7,=IO1CLR								;R7 = Clearr

	ldr	r5,=0x00100000							; end when the mask reaches this value
	ldr	r3,=0x00010000							; start with P1.16.
	str	r3,[r7]	   								; clear the bit -> turn on the LED


; Initialise the VIC
	ldr	r0,=VIC									; looking at you, VIC!

	ldr	r1,=irqhan								; IRQ Handler
	str	r1,[r0,#VectAddr0] 						; associate our interrupt handler with Vectored Interrupt 0

	mov	r1,#Timer0ChannelNumber+(1<<IRQslot_en)
	str	r1,[r0,#VectCtrl0] 						; make Timer 0 interrupts the source of Vectored Interrupt 0

	mov	r1,#Timer0Mask
	str	r1,[r0,#IntEnable]						; enable Timer 0 interrupts to be recognised by the VIC

	mov	r1,#0
	str	r1,[r0,#VectAddr]   					; remove any pending interrupt (may not be needed)

	; Initialise Timer 0
	ldr	r0,=T0									; looking at you, Timer 0!

	mov	r1,#TimerCommandReset			
	str	r1,[r0,#TCR]

	mov	r1,#TimerResetAllInterrupts
	str	r1,[r0,#IR]

	ldr	r1,=(14745600/200)-1	 				; 5 ms = 1/200 second
	str	r1,[r0,#MR0]

	mov	r1,#TimerModeResetAndInterrupt
	str	r1,[r0,#MCR]

	mov	r1,#TimerCommandRun
	str	r1,[r0,#TCR]


xloop	b	xloop  								; branch always
												; main program execution will never drop below the statement above.

	AREA	InterruptStuff, CODE, READONLY
irqhan	sub	lr,lr,#4
	stmfd	sp!,{r0-r1,lr}						; the lr will be restored to the pc

	cmp r4, #200								; if(count < oneSecond)
	blt keepCounting							;	keepCounting()...
		
	cmp	r3,	r5									; if(curPin > lastPin)
	blt nextLED									; {	
	ldr	r3,=0x00010000							; 	Reset to P1.16
	str r3, [r7]								;	Turn on P.16
	LDR R4, =0									;	count = 0;
	B keepCounting								; }

nextLED
	str	r3,[r6]									; set the bit -> turn off the current LED
	mov	r3,r3,lsl #1							; shift up to next bit. P1.16 -> P1.17 etc.
	str	r3,[r7]	   								; clear the bit -> turn on the LED
	
keepCounting
	add r4, r4, #1								; count++
	
		
	;this is where we stop the timer from making the interrupt request to the VIC
	;i.e. we 'acknowledge' the interrupt

	ldr	r0,=T0
	mov	r1,#TimerResetTimer0Interrupt
	str	r1,[r0,#IR]	   	; remove MR0 interrupt request from timer

	;here we stop the VIC from making the interrupt request to the CPU:
	ldr	r0,=VIC
	mov	r1,#0
	str	r1,[r0,#VectAddr]	; reset VIC

	ldmfd	sp!,{r0-r1,pc}^	; return from interrupt, restoring pc from lr
							; and also restoring the CPSR

	AREA	Subroutines, CODE, READONLY

	AREA	Stuff, DATA, READWRITE

	END
