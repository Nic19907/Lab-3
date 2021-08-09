; Archivo: contador_100ms.s
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: encender un led de 7 segmentos con tablas
; Hardware: led de 7 segmentos conectado al puerto C y push buttons al D,0 y 1
;    
; Creado 07/08/2021
; Modificado: 08/08/2021   
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>

;-------------------------------------------------------------------------------
; Palabras de configuracion
;-------------------------------------------------------------------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;-------------------------------------------------------------------------------
; Macros
;-------------------------------------------------------------------------------
  
bank0 MACRO
    bcf STATUS, 5
    bcf	STATUS, 6
    endm

bank1 MACRO
    bsf STATUS, 5
    bcf	STATUS, 6
    endm
    
bank2 MACRO
    bcf STATUS, 5
    bsf	STATUS, 6
    endm
    
bank3 MACRO
    bsf STATUS, 5
    bsf	STATUS, 6
    endm

/*
input MACRO arg1, arg2
    bank1
    bsf arg1, arg2
    bank0
    endm

output MACRO arg1, arg2
    bank1
    bcf arg1, arg2
    bank0
    endm
*/    
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr	;variables en la RAM compartida
cont_1:
    DS 2 ;Variable con 2 localidades en RAM
cont_2:
    DS 2
num_but:
    DS 1
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------
   
PSECT code, delta=2, abs
ORG 0x0000
resetVect:
    goto main

;-------------------------------------------------------------------------------
; TABLAS
;-------------------------------------------------------------------------------
ORG 0x0100
tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0 ;PCLATH = 101, PCL=02
    ;andlw   0x0f    ; solo contara los primeros 4 bits
    addwf   PCL	    ; PC = PCLATH + PCL + W
    retlw   00111111B	;0
    retlw   00000110B	;1
    retlw   01011011B	;2
    retlw   01001111B	;3
    retlw   01100110B	;4
    retlw   01101101B	;5
    retlw   01111101B	;6
    retlw   00000111B	;7
    retlw   01111111B	;8
    retlw   01100111B	;9
    retlw   01110111B	;A
    retlw   01111100B	;b
    retlw   00111001B	;C
    retlw   01011110B	;d
    retlw   01111001B	;E
    retlw   01110001B	;F
;-------------------------------------------------------------------------------
; Configruacion
;-------------------------------------------------------------------------------
PSECT loopPrincipal, class=code, delta=2, abs
ORG 0x000A
 
main:
    call    config_io
    ;call    config_clock
    bank0
    
config_io:
    bank3
    clrf    ANSEL   ;digital
    clrf    ANSELH  ;digital
    
    bank1
    clrf    TRISC   ;puerto C como salida
    clrf    TRISA   ;puerto A como salida
    
    bank0
    clrf    PORTA
    clrf    PORTC   ;limpiar ambos puertos al inicio

;-------------------------------------------------------------------------------
; LOOP
;-------------------------------------------------------------------------------

loop:
    bank0
    btfsc   RD0	    ;Push button en Pull DOWN
    call    inc_A   
    btfsc   RD1	    ;lo mismo que RD0
    call    dec_A
    
    movf    PORTA, W
    call    tabla
    movwf   PORTC
    goto loop
;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------

delay_500us:
    movlw   250	;valor inicial contador 
    movwf   cont_1
    decfsz  cont_1, 1	;decrementar por 1 el contador 
    goto    $-1		;ejecutar linea anterior
return

delay_200ms:
    movlw   200
    movwf   cont_2
    call    delay_500us
    decfsz  cont_2,1
    goto    $-2
    return
        
inc_A:
    call    delay_500us	    ;esta para evitar un rebote
    btfsc   RD0		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    incf    PORTA	    ;incrementar el conteo de PORTC
    btfsc   PORTA, 4	    ;si el bit 4 es 1 reiniciar el contador
    clrf    PORTA	    ;borrar todo como si fuese un loop al contador
return

dec_A:
    call    delay_500us
    btfsc   RD1
    goto    $-1
    decf    PORTA
    btfsc   PORTA,7 ;si se resta 1 cuando es 0 que se llenen los primeros 4bits
    call    lim_A   ;asegurarme que solo se utilicen los primeros 4 bits
return
    
lim_A:
    bcf	    PORTA, 4
    bcf	    PORTA, 5
    bcf	    PORTA, 6
    bcf	    PORTA, 7	;hacer que el contador este un su max. de 4bits,, F
    return


/*
           ,::////;::-.
      /:'///// ``::>/|/
    .',  ||||    `/( e\
-==~-'`-Xm````-mm-' `-_\ 
    */
END