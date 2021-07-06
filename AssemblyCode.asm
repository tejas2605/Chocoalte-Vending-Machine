#make_bin#

; BIN is plain binary format similar to .com format, but not limited to 1 segment;
; All values between # are directives, these values are saved into a separate .binf file.
; Before loading .bin file emulator reads .binf file with the same file name.

; All directives are optional, if you don't need them, delete them.

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=0500h#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0500h#	; same as loading segment
#IP=0000h#	; same as loading offset

; set segment registers
#DS=0500h#	; same as loading segment
#ES=0500h#	; same as loading segment

; set stack
#SS=0500h#	; same as loading segment
#SP=FFFEh#	; set to top of loading segment

; set general registers (optional)
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here

jmp st1
    nop
    db 252 dup(0)     ;Int1 Int39-not used
	
	dw t_isr
    dw 0
	
	;Int 41h- Int 255h not used
	db 860 dup(0)
	
st1:  cli

; intialize ds, es, ss to start of RAM
    mov ax,0100h
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,01ffeH

PortA equ 00h
PortB equ 02h
PortC equ 04h
Creg1 equ 06h

Port1A equ 08h
Port1B equ 0ah
Port1C equ 0ch
CregNew equ 0eh

Cnt0 equ 10h
Cnt1 equ 12h
Cnt2 equ 14h
Creg2 equ 16h


Press_Key db ?
Coins db ?
;Perk-5
;5star=10
;dairymilk-20
Key_Perk db 1
Key_5star db 2
Key_Dairymilk db 3

coins_Perk db 1
coins_5star db 2
coins_Dairymilk db 4

Left_Perk db 100
Left_5star db 100
Left_Dairymilk db 100

ADCValue db 01H
Rteeth db 200

Start:        mov cl,00h

		mov al,91h   ;Initialising the ports of 8255 as input and output (PortA-Input, PortB-Output, Upper PortC-Output, Lower PortC-Input)
		out Creg1,al
		
		mov al,82h   ;Initialising the ports of 8255(2) as input and output (PortA-output, PortB-input, Upper PortC-Output, Lower PortC-output)
		out CregNew,al

X1:		in al,04h   ;To check if all switches are open 1-switch open, 0-switch closed
		and al,07h
		cmp al,07h
        jnz X1
		
		call Delay20ms
		
X2:		in al,04h    ;To check if one of the switches has been closed
		and al,07h
		cmp al,07h
		jz X2

        call Delay20ms

		in al,04h    ;To check again if one of the switches has been closed
		and al,07h
		cmp al,07h
		jz X2	
		
		in al,04h    ;To check if the switch for perk is closed i.e.0
		and al,07h
		cmp al,06h
		jnz X4
		mov al,1             ;To store which key has been pressed
		mov Press_Key,al
		mov al,1
		mov Coins,al
		mov al,Left_Perk
		cmp al,00
		jz GlowPerk 
		jmp X6
		
X4:		in al,04h    ;To check if the switch for 5star is closed i.e.0
		and al,07h
		cmp al,05h
		jnz X5
		mov al,2             ;To store which key has been pressed
		mov Press_Key,al
		mov al,2
		mov Coins,al
		mov al,Left_5star
		cmp al,00
		jz Glow5star 
		jmp X6
		
	    ;To check if the switch for Dairymilk is closed i.e.0
X5:		mov al,3            ;To store which key has been pressed
		mov Press_Key,al
		mov al,4
		mov Coins,al
		mov al,Left_Dairymilk
		cmp al,00
		jz GlowDairymilk
		jmp X6
		

X6:		mov di,04
		mov al,00110110b   ;Initialise counter0 in mode3
		mov Creg2,al
		mov al,01110100b   ;Initialise counter1 in mode2
		out Creg2,al
		mov al,10110100b   ;Initialise counter2 in mode2
		out Creg2,al
		
		mov al,02h        ;Loading value 2(02h) in counter0
		out Cnt0,al
		mov al,00h
		out Cnt0,al
		
		mov al,10h        ;Loading value 10000 (2710h) in counter1
		out Cnt1,al
		mov al,27h
		out Cnt1,al
		
		mov al,0E8h        ;Loading value 1000 (3E8h) in counter2
		out Cnt2,al
		mov al,03h
		out Cnt2,al
		
		
		mov al,00010011b   ;ICW1 Initialisation (8086, edge triggered, single 8259)
		out 10h,al
		mov al,01000000b   ;ICW2 Initialisation (starting vector no is 40H)
		out 12h,al
		mov al,00000001b   ;ICW4 Initialisation (no automatic eoi)
		out 12h,al 
		mov al,11111110b   ;OCW1 Initialisation (IR0 Enabled, all others disabled) 
		out 12h,al
		
		sti         ;Make IF=1
		
X10:	nop
		nop
		nop
		nop
		cmp di,00h
		jnz X10
		 
		mov al,01100000b    ;Specific end of interrupt
		out 10h,al
		
		cmp Coins,cl
		jnz InvalidCase
		mov al,1
		cmp Press_Key,al
		jz DispensePerk
		inc al
		cmp Press_Key,al
		jz Dispense5star
		mov al,Left_Dairymilk
		dec al
		mov Left_Dairymilk,al
		
		; Code for Dairymilk dispension
		mov bl,Rteeth
X11:	mov al,0Ah          ;rotating motor3 once
		out Port1C,al
		call Delay20ms
		mov al,09h
		out Port1C,al
		call Delay20ms
		mov al,05h
		out Port1C,al
		call Delay20ms
		mov al,06h
		out Port1C,al
		call Delay20ms
		mov al,0Ah
		out Port1C,al
		call Delay20ms
		dec bl
		jnz X11
		
		jmp Start
		
DispensePerk:	mov al,Left_Perk
                dec al
                mov Left_Perk,al
				
				;Code for Perk dispension
				mov bl,Rteeth
		X12:	mov al,0Ah          ;rotating motor1 once
		        out Port1C,al
		        call Delay20ms
		        mov al,09h
		        out Port1C,al
		        call Delay20ms
		        mov al,05h
		        out Port1C,al
		        call Delay20ms
		        mov al,06h
		        out Port1C,al
		        call Delay20ms
		        mov al,0Ah
		        out Port1C,al
		        call Delay20ms
				dec bl
				jnz X12
				
				jmp Start
				
Dispense5star:  mov al,Left_5star
				dec al
                mov Left_5star,al
				
				;Code for 5star dispension
				mov bl,Rteeth
		X13:	mov al,0A0h          ;rotating motor2 once
		        out Port1C,al
		        call Delay20ms
		        mov al,90h
		        out Port1C,al
		        call Delay20ms
		        mov al,50h
		        out Port1C,al
		        call Delay20ms
		        mov al,60h
		        out Port1C,al
		        call Delay20ms
		        mov al,0A0h
		        out Port1C,al
		        call Delay20ms
				dec bl
				jnz X13
				
				jmp Start
		
InvalidCase:     ;cl-number of coins
				;dispense the refund
				mov al,Rteeth
				mul cl
				mov bx,ax
		X14:	mov al,0A0h          ;rotating motor4 once
		        out Port1C,al
		        call Delay20ms
		        mov al,90h
		        out Port1C,al
		        call Delay20ms
		        mov al,50h
		        out Port1C,al
		        call Delay20ms
		        mov al,60h
		        out Port1C,al
		        call Delay20ms
		        mov al,0A0h
		        out Port1C,al
		        call Delay20ms
				dec bx
				jnz X14
				

GlowPerk:   mov al,00000001b
			out PortB,al
			jmp Final
			
Glow5star:  mov al,00000010b
            out PortB,al
			jmp Final
			
GlowDairymilk:  mov al,00000100b
			    out PortB,al
				jmp Final
		
Final:      call Delay5s
			mov al,00000000b
			out PortB,al
			jmp Start
			


;Delay of 5s is provided by this
Delay5s:	  mov       dl,11 
xm1:           mov		cx,50000     ;delay generated will be approx 0.45 secs
xn1:		      loop		xn1
              dec       dl
              jnz       xm1
		      ret 

;Delay of 20ms is provided by this
Delay20ms:	  mov       dl,1 
xm:           mov		cx,5550     ;delay generated will be approx 0.2ms
xn:		      loop		xn
              dec       dl
              jnz       xm
		      ret 			  
		
		
		
		;In location 00100H  (40H x4 + 00000)–IP, 
		;CS value of sub-routine of timer isr
		
t_isr:  PUSH ax
		PUSH bx
		dec di
        mov al,00001011b    ;Making ALE 1
		out Creg1,al
		
		nop
		nop
		
		mov al,00001001b    ;Making SOC 1
		out Creg1,al
		
X8:		in al,PortC         ;Check whether EOC=1 (PC3)
		and al,00001000b
		cmp al,00001000b
		jnz X8
		
		mov al,00001101b    ;Making OE 1
		out Creg1,al
		
		in al,PortA
		cmp al,ADCvalue
		jnz X9
		inc cl
     		
X9:		mov al,00001010b    ;Making ALE 0
		out Creg1,al
		
		mov al,00001000b    ;Making SOC 0
		out Creg1,al
		
		POP bx
		POP ax
		IRET


HLT           ; halt!


