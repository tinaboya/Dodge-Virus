;
; Dodge virus part.asm
;
; Created: 5/5/2020 3:04:06 PM
; Author : BOYA

.INCLUDE "m328pdef.inc"

.ORG 0x0000
RJMP init
.ORG 0x0020
RJMP TOVI

init:

;screen
SBI DDRB,3
CBI PORTB,3 ;PB3 output

SBI DDRB,4
CBI PORTB,4 ;PB4 output

SBI DDRB,5
CBI PORTB,5 ;PB5 output

;buzzer
SBI DDRB,1
SBI PORTB,1

;keyboard
;PD7-4,row,output
;PD3-0,column,input,pull-up register

LDI R16,0b11110000
OUT DDRD,R16

LDI R16,0b11111111
OUT PORTD,R16

;timer
LDI R17,0X04
OUT TCCR0B,R17;set timer0 prescalar to 256

LDI R18,185 ;f=440Hz
OUT TCNT0,R18

SEI ;enable global interrupt

;LED
SBI DDRC,3
SBI PORTC,3

RCALL FrontPage ;Store the front page charbuffer in the storage

MAIN:
	RCALL Game ;Display

	;keyboard 4-steps method
	step1:
	;row1
	LDI R16,0b01111111
	OUT PORTD,R16
	NOP
	SBIS PIND,3
	RCALL UselessButton ;BUTTON7
	SBIS PIND,2
	RCALL BUTTON8
	SBIS PIND,1
	RCALL UselessButton ;BUTTON9
	SBIS PIND,0
	RCALL UselessButton ;BUTTONF

	step2:
	;row2
	LDI R16,0b10111111
	OUT PORTD,R16
	NOP
	SBIS PIND,3
	RCALL BUTTON4
	SBIS PIND,2
	RCALL BUTTON5
	SBIS PIND,1
	RCALL BUTTON6
	SBIS PIND,0
	RCALL UselessButton ;BUTTONE

	step3:
	;row3
	LDI R16,0b11011111
	OUT PORTD,R16
	NOP
	SBIS PIND,3
	RCALL UselessButton ;BUTTON1
	SBIS PIND,2
	RCALL BUTTON2
	SBIS PIND,1
	RCALL UselessButton ;BUTTON3
	SBIS PIND,0
	RCALL UselessButton ;BUTTOND

	step4:
	;row4
	LDI R16,0b11101111
	OUT PORTD,R16
	NOP
	SBIS PIND,3
	RCALL UselessButton ;BUTTONA
	SBIS PIND,2
	RCALL UselessButton ;BUTTON0
	SBIS PIND,1
	RCALL UselessButton ;BUTTONB
	SBIS PIND,0
	RCALL UselessButton ;BUTTONC

	;No buttons pressed: buzzer off
	LDI R17,0 ;disable timer0 interrupt
	STS TIMSK0,R17
	SBI PORTC,3
	RJMP MAIN

//--------------------Function--------------------//

//--------------------Screen Show--------------------//

ShowNothing:
	LDI ZL,0x00
	LDI ZH,0x01
	LDI R20,2
	LDI R17,16
	SNG:
		ST Z+,R20
		DEC R17
		BRNE SNG
RET

FrontPage:
;level1 initial state
LDI ZL,0x00
LDI ZH,0x01
;DODGE
LDI R20,13
ST Z+,R20
LDI R20,5
ST Z+,R20
LDI R20,13
ST Z+,R20
LDI R20,14
ST Z+,R20
LDI R20,9
ST Z+,R20

LDI R20,2 ;safe place
ST Z+,R20
LDI R20,0 ;steve
ST Z+,R20
LDI R20,2 ;safe place
ST Z+,R20
;VIRUS
LDI R20,15
ST Z+,R20
LDI R20,11
ST Z+,R20
LDI R20,16
ST Z+,R20
LDI R20,17
ST Z+,R20
LDI R20,8
ST Z+,R20

LDI R20,2 ;safe place
ST Z+,R20
LDI R20,2 ;safe place
ST Z+,R20
LDI R20,1 ;virus
ST Z,R20
RET

LEVEL1:
	;steve initial position
	LDI R24,0x01
	LDI R25,0x00
	
	;level1 initial state
	LDI ZL,0x00
	LDI ZH,0x01

	LDI R20,0 ;steve
	ST Z+,R20
	LDI R20,1 ;virus
	ST Z+,R20
	RCALL PrintThreeNone ;safe place
	LDI R20,1 ;virus
	ST Z+,R20
	LDI R20,2 ;safe place
	ST Z+,R20
	LDI R20,2 ;safe place
	ST Z+,R20
	RCALL PrintThreeNone ;safe place
	LDI R20,1 ;virus
	ST Z+,R20
	RCALL PrintThreeNone ;safe place
	LDI R20,3 ;exit
	ST Z,R20
RET

PrintThreeNone:
	LDI R20,2
	LDI R17,3
	TEST:
		ST Z+,R20
		DEC R17
		BRNE TEST
RET

Game:
	LDI R21,7 ;rownumbwe-1
	LDI R20,0b00000001

	Send8Row:
		;send column data
		LDI R22,16 ;#block
		LDI YL,low(0x0110)
		LDI YH,high(0x0110)
		BlockLoop:	
			LDI ZH,high(CharTable<<1)
			LDI ZL,low(CharTable<<1)
			
			CLR R6 ;set R6 to 0 so we can add a zero with carry (this is the same as just adding the carry)
			ADD ZL,R21 ;+(rownumber-1)
			ADC ZH, R6 ;(ADC is add with carry or ZH + R6 + Carry bit)

			LD R23,-Y ;R23 = X, be careful with X(it does minus first)

			LDI R19,8 ;+(rownumbwe-1)+8*X
			loop:
				CLR R6
				ADD ZL,R23
				ADC ZH,R6

				DEC R19
				BRNE Loop

			LPM R0,Z
			LDI R16,5
			CLC

			BlockColLoop:
				;send 5 bits of loaded byte to the screen
				CBI PORTB,3
				ROR R0
				BRCC CarryIs0
					SBI PORTB,3
				CarryIs0:
				CBI PORTB,5
				SBI PORTB,5

				DEC R16
				BRNE BlockColLoop

			DEC R22
			BRNE BlockLoop

		LDI R19,8
		CLC

		RowLoop:
				CBI PORTB,3 ;init PB=0
			ROR R20
			BRCC CarryIs1
				SBI PORTB,3
			CarryIs1:
			CBI PORTB,5
			SBI PORTB,5 ;create rising edge of PB5 to shift

			DEC R19 ;loop 8 times
			BRNE RowLoop

		RCALL ENABLE
		DEC R21
		TST R20
		BRNE Send8Row
		
RET

ENABLE:
	SBI PORTB,4
	RCALL DELAY
	CBI PORTB,4
RET

DELAY:
	LDI R16,0xFF
	Delayloop1:
		NOP
		LDI R17,4
		DelayLoop2:
			NOP
			DEC R17
			BRNE DelayLoop2
		DEC R16
		BRNE DelayLoop1
RET

//--------------------Button and game logic--------------------//

;up and down
BUTTON8:
RCALL UP
RCALL Sound1
RET

BUTTON2:
RCALL DOWN
RCALL Sound1
RET

;left and right
BUTTON6:
RCALL RIGHT
RCALL Sound1
RET

BUTTON4:
RCALL LEFT
RCALL Sound1
RET

;restart
BUTTON5:
RCALL LEVEL1
RET

UselessButton:
	CBI PORTC,3
	RCALL Sound1
RET

UP:
MOV ZH,R24
MOV ZL,R25
LDI R20,2 ;none
ST Z,R20
LDI R22,8
SUB ZL,R22 ;-8
CPI ZL,16 ;compare the value, if ZH not between 0-15, then out of boundary
BRSH DoNothing_UP
RCALL Decision
DoNothing_UP:
	ADD ZL,R22 ;+8
	LDI R20,0  ;Steve
	ST Z,R20
RET

DOWN:
MOV ZH,R24
MOV ZL,R25
LDI R20,2 ;none
ST Z,R20
LDI R22,8
ADD ZL,R22 ;+8
CPI ZL,16 ;compare the value, if ZL not between 0-15, then out of boundary
BRSH DoNothing_DOWN
RCALL Decision
DoNothing_DOWN:
	SUB ZL,R22 ;-8
	LDI R20,0  ;Steve
	ST Z,R20
RET

LEFT:
MOV ZH,R24
MOV ZL,R25
LDI R20,2 ;none
ST Z,R20
LDI R22,1
SUB ZL,R22 ;-1
CPI ZL,7 ;botton left and top right,special locations,need the do nothing also
BREQ DoNothing_LEFT
CPI ZL,16 ;compare the value, if ZH not between 0-15, then out of boundary
BRSH DoNothing_LEFT
RCALL Decision
DoNothing_LEFT:
	ADD ZL,R22 ;+1
	LDI R20,0  ;Steve
	ST Z,R20
RET

RIGHT:
MOV ZH,R24
MOV ZL,R25
LDI R20,2 ;none
ST Z,R20
LDI R22,1
ADD ZL,R22 ;+1
CPI ZL,8 ;botton left and top right,special locations,need the do nothing also
BREQ DoNothing_RIGHT
CPI ZL,16 ;compare the value, if ZH not between 0-15, then out of boundary
BRSH DoNothing_RIGHT
RCALL Decision
DoNothing_RIGHT:
	SUB ZL,R22 ;-1
	LDI R20,0  ;Steve
	ST Z,R20
RET

Hold:
		LDI R18,0x30
		Hold1:
			RCALL GAME
			DEC R18
		BRNE Hold1
RET

Continue:
	LDI R20,0 ;steve
	ST Z,R20
	MOV R24,ZH
	MOV R25,ZL
	RCALL Hold
RET

WIN:
	LDI ZL,0x00
	LDI ZH,0x01

	LDI R20,4
	ST Z+,R20
	LDI R20,5
	ST Z+,R20
	LDI R20,6
	ST Z+,R20
	LDI R20,2
	ST Z+,R20

	LDI R20,10
	ST Z+,R20
	LDI R20,11
	ST Z+,R20
	LDI R20,12
	ST Z+,R20

	LDI R20,2
	LDI R17,9
	TEST2:
		ST Z+,R20
		DEC R17
		BRNE TEST2
	RCALL Hold
RET

LOSE:
	LDI ZL,0x00
	LDI ZH,0x01

	LDI R20,4
	ST Z+,R20
	LDI R20,5
	ST Z+,R20
	LDI R20,6
	ST Z+,R20
	LDI R20,2
	ST Z+,R20
	LDI R20,7
	ST Z+,R20
	LDI R20,5
	ST Z+,R20
	LDI R20,8
	ST Z+,R20
	LDI R20,9
	ST Z+,R20

	LDI R20,2
	LDI R17,8
	TEST1:
		ST Z+,R20
		DEC R17
		BRNE TEST1
	RCALL Hold
RET

Decision:
	CPI ZL,15
	BREQ WIN
	CPI ZL,1
	BREQ LOSE
	CPI ZL,5
	BREQ LOSE
	CPI ZL,11
	BREQ LOSE
	RCALL Continue
RET

Sound1:
	LDI R17,1 ;enable timer0 interrupt
	STS TIMSK0,R17
RET

TOVI:
;reset correct 'reload values'
LDI R18,185 ;f=440Hz
OUT TCNT0,R18
SBI PINB,1 ;toggle a pin
RETI

CharTable:
.db 0b00001110,0b00001010,0b00001110,0b00000100,0b00011111,0b00000100,0b00011011,0b00000000 ;pattern steve, charbuffer 0
.db 0b00000000,0b00010101,0b00001110,0b00011011,0b00001110,0b00010101,0b00000000,0b00000000 ;pattern virus, charbuffer 1
.db 0b00000000,0b00000000,0b00000000,0b00000000,0b00000000,0b00000000,0b00000000,0b00000000 ;pattern none, charbuffer 2
.db 0b00000100,0b00001110,0b00010101,0b00000100,0b00010101,0b00010101,0b00011111,0b00000000 ;pattern exit, charbuffer 3

.db 0b00010001,0b00010001,0b00001010,0b00000100,0b00000100,0b00000100,0b00000100,0b00000000;pattern Y, charbuffer 4
.db 0b00001110,0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00001110,0b00000000;pattern O, charbuffer 5
.db 0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00001110,0b00000000;pattern U, charbuffer 6
.db 0b00010000,0b00010000,0b00010000,0b00010000,0b00010000,0b00010000,0b00011111,0b00000000;pattern L, charbuffer 7
.db 0b00001110,0b00010001,0b00010000,0b00001110,0b00000001,0b00010001,0b00001110,0b00000000;pattern S, charbuffer 8
.db 0b00011111,0b00010000,0b00010000,0b00011111,0b00010000,0b00010000,0b00011111,0b00000000;pattern E, charbuffer 9
.db 0b00010001,0b00010001,0b00010101,0b00010101,0b00010101,0b00010101,0b00001010,0b00000000;pattern W, charbuffer 10
.db 0b00011111,0b00000100,0b00000100,0b00000100,0b00000100,0b00000100,0b00011111,0b00000000;pattern I, charbuffer 11
.db 0b00010001,0b00011001,0b00010101,0b00010101,0b00010101,0b00010011,0b00010001,0b00000000;pattern N, charbuffer 12

.db 0b00011100,0b00010010,0b00010001,0b00010001,0b00010001,0b00010010,0b00011100,0b00000000 ;D,charbuffer 13
.db 0b00001110,0b00010001,0b00010000,0b00010111,0b00010001,0b00010001,0b00001111,0b00000000 ;G,charbuffer 14

.db 0b00010001,0b00010001,0b00010001,0b00010001,0b00001010,0b00001010,0b00000100,0b00000000 ;V,charbuffer 15
.db 0b00011110,0b00010001,0b00010001,0b00011110,0b00010100,0b00010010,0b00010001,0b00000000 ;R,charbuffer 16
.db 0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00010001,0b00001110,0b00000000 ;U,charbuffer 17