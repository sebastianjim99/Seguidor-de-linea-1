;-----------------------------------------------------------------------------
;   		        ______         _                  
;                      (_____ \       | |             _   
;                       _____) ) ___  | |__    ___  _| |_ 
;                      |  __  / / _ \ |  _ \  / _ \(_   _)
;                      | |  \ \| |_| || |_) )| |_| | | |_ 
;                      |_|   |_|\___/ |____/  \___/   \__)
;                                                         
;       ______                       _      _                      _        
;      / _____)                     (_)    | |                    | |       
;     ( (____   _____   ____  _   _  _   __| |  ___    ____     __| | _____ 
;      \____ \ | ___ | / _  || | | || | / _  | / _ \  / ___)   / _  || ___ |
;      _____) )| ____|( (_| || |_| || |( (_| || |_| || |      ( (_| || ____|
;     (______/ |_____) \___ ||____/ |_| \____| \___/ |_|       \____||_____)
;                     (_____|                                               
;                           _   _                      
;                          | | (_)                     
;                          | |  _  ____   _____  _____ 
;                          | | | ||  _ \ | ___ |(____ |
;                          | | | || | | || ____|/ ___ |
;                           \_)|_||_| |_||_____)\_____|
;______________________________________________________________________________

;Archivo: Seguidor_de_linea.s
;Fecha de creaciòn: 06/03/21    
;Autores:
;	JUAN SEBASTIAN JIMENEZ PEÑA     --2420192018
;	JUAN FELIPE BETANCOURTH LEDEZMA --2420191018
;Dispositivo: PIC16F877A
;File Version: XC8, PIC-as 2.31 
;Descripciòn: El robot seguidor de línea tiene un sencillo propósito 
;	      el cual es seguir una trayectoria demarcada en una pista sin
;             salirse o perder el camino, haciendolo en el menor tiempo posible.
;______________________________________________________________________________
    
PROCESSOR 16F877A

#include <xc.inc>
    
;------------------------------------------------------------------------------
  
; Configuraciones (pag 144- datasheet)

CONFIG CP=OFF     ; Flash Program Memory --->  Protección del código 
CONFIG DEBUG=OFF  ; Background debugger disabled 
CONFIG WRT=OFF    ; Flash Program Memory Write ---> 
CONFIG CPD=OFF    ; Data EEPROM Memory Code Protection
CONFIG WDTE = OFF ; Watchdog Timer --->  Habilitar el perro guardian del tiempo
CONFIG LVP=OFF     ; Low voltage programming enabled, MCLR pin, MCLRE ignored ---> Para configuraciones de voltaje
CONFIG FOSC=XT    ;Oscillator ---> Tipo de oscilador que utilizamos (XT:Crystal/Resonator)
CONFIG PWRTE=ON   ;Power-up Timer ---> Permite la activación del reset por medio de la fuente de alimentación. 
CONFIG BOREN=OFF  ; Brown-out Reset
 
PSECT udata_bank0 ; Reserva una parte de la memoria RAM; para guardar los datos   
;------------------------------------------------------------------------------
max:
DS 1 ; reserve 1 byte for max

tmp:
DS 1 ;reserve 1 byte for tmp
PSECT resetVec,class=CODE,delta=2

resetVec:
    PAGESEL main ;jump to the main routine
    goto INISYS
;------------------------------------------------------------------------------
 
PSECT code ; Aqui inicia el codigo
 

INISYS:

;CAMBIANDO DE BANCO -- Por defecto, estamos en el Banco 0
    
BCF STATUS, 6 ; RP1=0
BSF STATUS, 5 ; RP0=1
; 01---> pasamos al Banco 1

;DEFINIENDO ENTRADAS Y SALIDAS
    
;Entradas
BSF TRISB, 0  ;PORT_BO <--Entrada S1
BSF TRISB, 1  ;PORT_B1 <--Entrada S2
BSF TRISB, 2  ;PORT_B2 <--Entrada S3
BSF TRISB, 3  ;PORT_B3 <--Entrada S4
BSF TRISB, 4  ;PORT_B4 <--Entrada S5
;Salidas
BCF TRISC, 0  ;PORT_C0 <--Salida MOTOR MI
BCF TRISC, 1  ;PORT_C1 <--Salida MOTOR MD 
BCF TRISC, 2  ;PORT_C2 <--Salida MOTOR MI2 
BCF TRISC, 3  ;PORT_C3 <--Salida MOTOR MD2 
BCF TRISC, 4  ;PORT_C4 <--Salida LED AMARILLO IZQUIERDO 
BCF TRISC, 5  ;PORT_C5 <--Salida LED AMARILLO DERECHO
BCF TRISC, 6  ;PORT_C6 <--Salida LED ROJO CENTRO
 
 ;REGRESANDO AL BANCO 0
  
BCF STATUS, 5 ; RP0=0

MOVF PORTB,0 ; Pansado las entradas al acumulador 
     
;------------------------------------------------------------------------------
main:
;CREANDO VARIABLES 
;--------------------------------------------

;NEGADAS

;R21[0]= !S1
    MOVF PORTB,0 ;Movemos la entrada de los sensores a W >X X X S1 S2 S3 S4 S5 < 
    ANDLW 0b00010000 ; Realizando una W AND '00010000' salvamos el bit 4 >000 S1 0000< 
    MOVWF 0x21 ; Guardamos W en el registro 21
    RRF   0x21,1 ; Rotamos a la derecha >0000 S1 000< guardamos en R21
    RRF   0x21,1 ; Rotamos a la derecha >00000 S1 00< guardamos en R21
    RRF   0x21,1 ; Rotamos a la derecha >000000 S1 0< guardamos en R21
    RRF   0x21,1 ; Rotamos a la derecha >0000000 S1 < guardamos en R21
    COMF  0x21,1 ; Haciendo complemento >1111111 !S1< guardamos en R21
    MOVF  0x21,0 ; Movemos R21 a W
    ANDLW 0b00000001 ; Hacemos W AND '00000001' salvando >0000000 !S1 <
    MOVWF 0x21 ; Finalmente los guardamos !S1 en R21[0]

;----->>Replicamos este proceso para todas las entradas teniendo en cuenta el bit que toca salvar.   
    
;R22[0]= !S2
    MOVF PORTB,0     ; >X X X S1 S2 S3 S4 S5 < 
    ANDLW 0b00001000 ; W =  >0000 S2 000<
    MOVWF 0x22	     ; R22= >0000 S2 000< 
    RRF   0x22,1     ; R22= >00000 S2 00< 
    RRF   0x22,1     ; R22= >000000 S2 0< 
    RRF   0x22,1     ; R22= >0000000 S2 <
    COMF  0x22,1     ; R22= >1111111 !S2<
    MOVF  0x22,0     ; W= >1111111 !S2<
    ANDLW 0b00000001 ; W= >0000000 !S2<
    MOVWF 0x22       ; R22[0]= !S2
    
    
 ;R23[0]= !S3
    MOVF PORTB,0     ; >X X X S1 S2 S3 S4 S5 < 
    ANDLW 0b00000100 ; >00000 S3 00<
    MOVWF 0x23       ; R23= >0000 S3 000< 
    RRF   0x23,1     ; R23= >000000 S3 0< 
    RRF   0x23,1     ; R23= >0000000 S3 < 
    COMF  0x23,1     ; R23= >1111111 !S3 < 
    MOVF  0x23,0     ; W= >1111111 !S3<
    ANDLW 0b00000001 ; W= >0000000 !S3<
    MOVWF 0x23       ; R23[0]= !S3
    
    
 ;R24[0]= !S4
    MOVF PORTB,0     ; >X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00000010 ; >000000 S4 0<
    MOVWF 0x24       ; R24= >000000 S4 0<
    RRF   0x24,1     ; R24= >0000000 S4 <
    COMF  0x24,1     ; R24= >1111111 !S4 <
    MOVF  0x24,0     ; W= >1111111 !S4 <
    ANDLW 0b00000001 ; W= >0000000 !S4<
    MOVWF 0x24       ; R24[0]= !S4
     
   
 ;R25[0]= !S5
    MOVF PORTB,0     ; >X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00000001 ; >0000000 S5<
    MOVWF 0x25	     ; R25= >0000000 S5<
    COMF  0x25,1     ; R25= >1111111 !S5 <
    MOVF  0x25,0     ; W= >1111111 !S5 <
    ANDLW 0b00000001 ; W= >0000000 !S5<
    MOVWF 0x25       ; R25[0]= !S5
 ;--------------------------------------------
 ; NO NEGADAS
  
;R31[0]= S1
    MOVF PORTB,0     ; Movemos la entrada de los sensores a W >X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00010000 ; Realizando una W AND '00010000' salvamos el bit 4 >000 S1 0000< 
    MOVWF 0x31       ; Guardamos W en el registro 31
    RRF   0x31,1     ; Rotamos a la derecha >0000 S1 000< guardamos en R31
    RRF   0x31,1     ; Rotamos a la derecha >00000 S1 00< guardamos en R31
    RRF   0x31,1     ; Rotamos a la derecha >000000 S1 0< guardamos en R31
    RRF   0x31,1     ; Rotamos a la derecha >0000000 S1 < guardamos en R31
    MOVF  0x31,0     ; Movemos R31 a W
    MOVWF 0x31       ; Finalmente los guardamos !S1 en R31[0]
    
    
;R32[0]= S2
    MOVF PORTB,0     ; >X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00001000 ; W= >0000 S2 000<
    MOVWF 0x32       ; R32= >0000 S2 000<
    RRF   0x32,1     ; R32= >00000 S2 00<
    RRF   0x32,1     ; R32= >000000 S2 0<
    RRF   0x32,1     ; R32= >0000000 S2 <
    MOVF  0x32,0     ; W = >0000000 S2 <
    MOVWF 0x32       ; R32[0]= S2
   
    
;R33[0]= S3
    MOVF PORTB,0      ; >X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00000100  ; W= >00000 S3 00<
    MOVWF 0x33        ; R33= >00000 S3 00<
    RRF   0x33,1      ; R33= >000000 S3 0<
    RRF   0x33,1      ; R33= >0000000 S3 <
    MOVF  0x33,0      ; W= >0000000 S3 <
    MOVWF 0x33        ; R33[0]= S3
    
;R34[0]= S4
    MOVF PORTB,0     ;>X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00000010 ; W= >000000 S4 0<
    MOVWF 0x34       ; R34= >000000 S4 0<
    RRF   0x34,1     ; R34= >0000000 S4 <
    MOVF  0x34,0     ; W= >0000000 S4 <
    MOVWF 0x34       ; R34[0]= S4
  
   
;R35[0]= S5
    MOVF PORTB,0      ; >X X X S1 S2 S3 S4 S5 <
    ANDLW 0b00000001  ; W= >0000000 S5<
    MOVWF 0x35        ; R35[0]= S5
   
 ;--------------------------------------------------------------------------
 
 ;OPERACIONES 
 ;funciones obtenidas de los karnaugh (K)
 ;NOTACIÓN: & --> AND    |  + --> OR INCLUSIVA 
 
 ;--------------------
 ; MOTORES
 ;--------------------
 ; << K1 >> --> MI---> MOTOR IZQUIERDO (Sentido horario)
 
 ;R40[0]= !S3 & S5
 MOVF  0x23,0		; W= R23[0] 
 ANDWF 0x35,0 		; W = W AND R35[0]
 MOVWF 0x40		; R40[0]=W   ---> Este es el primer dato del K1
 
 ;R41[0]= !S3 & S4 
 MOVF  0x23,0		; W= R23[0]
 ANDWF 0x34,0		; W = W AND R34[0]
 MOVWF 0x41		; R41[0] = W  ---> Este es el segundo dato del K1
 
 ;R42[0]= !S2 & S3
 MOVF  0x22,0		; W= R22[0]
 ANDWF 0x33,0		; W= W AND R33[0]
 MOVWF 0x42		; R42[0] = W  ---> Este es el tercer dato del K1
 
 ;R43[0] = R40[0] + R41[0] + R42[0] 
 MOVF  0x40,0 		; W= R40[0]
 IORWF 0x41,0 		; W= W OR R41[0]
 IORWF 0x42,0		; W= W OR R42[0]
 MOVWF 0x43		; R43[0]= W ---> Esta es la FUNCIÓN del K1

 ;----------------------------------------------
 
 ; << K2 >> --> MD---> MOTOR DERECHO (Sentido horario)
 
 ; R44[0]= S2 & !S3
 MOVF  0x32,0		; W= R32[0]
 ANDWF 0x23,0		; W= W AND R23[0]
 MOVWF 0x44		; R44[0]= W ---> Este es el primer dato del K2
 
 ; R45[0]= S1 & !S2
 MOVF  0x31,0		; W= R31[0]
 ANDWF 0x22,0		; W= W AND R22[0]
 MOVWF 0x45		; R45= W ---> Este es el segundo dato del K2
 
 ; R46[0]= S3 & !S4 
 MOVF  0x33,0		; W= R33[0]
 ANDWF 0x24,0		; W= W AND R24[0]
 MOVWF 0x46		; R46[0]= W ---> Este es el Tercer dato del K2
 
 
 ; R48[0]= R44[0] + R45[0] + R46[0]
 MOVF  0x44,0		; W= R44[0]
 IORWF 0x45,0		; W= W OR R45[0]
 IORWF 0x46,0		; W= W OR R46[0]
 MOVWF 0x48		; R48[0]= W ---> Esta es la FUNCIÓN del K2
 ;------------------------------------------

 ; << K3 >>  --> MI2---> MOTOR IZQUIERDO (Sentido Anti-horario)

 ; R49[0]= S1 & !S3
 MOVF  0x31,0		; W= R31[0]
 ANDWF 0x23,0		; W= W AND R23[0]
 MOVWF 0x49		; R49[0]= W ---> Este es el primer dato del K3
 
 
 ; R50[0]= !S2 & !S3 & !S4 & !S5
 MOVF  0x22,0		; W= R22[0]
 ANDWF 0x23,0		; W= W AND R23[0]
 ANDWF 0x24,0		; W= W AND R24[0]
 ANDWF 0x25,0		; W= W AND R25[0]
 MOVWF 0x50		; R50[0]= W --->Este es el segundo dato del K3
 
 ; R51[0]= R49[0] + R50[0]
 MOVF  0x49,0		; W= R49[0]
 IORWF 0x50,0		; W= W OR R50[0]
 MOVWF 0x51		; R51[0]= W ---> Esta es la FUNCIÓN del K3
 
 ;----------------------------------------
 
 ; << K4 >>  --> MD2---> MOTOR DERECHO (Sentido Anti-horario)
 
 ; R53[0]= !S3 & S5
 MOVF  0x23,0		; W= R23[0]
 ANDWF 0x35,0		; W= W AND R35[0]
 MOVWF 0x53		; R53[0]= W ---> Este es el primer dato del K4
 
  
 ; R54[0]= !S1 & !S2 & !S3 & !S4
 MOVF  0x21,0		; W= R21[0]
 ANDWF 0x22,0		; W= W AND R22[0]
 ANDWF 0x23,0		; W= W AND R23[0]
 ANDWF 0x24,0		; W= W AND R24[0]
 MOVWF 0x54		; R54[0]= W ---> Este es el segundo dato del K4
 
 ; R55[0]= R53[0] + R54[0] 
 MOVF  0x53,0		; W= R53[0]
 IORWF 0x54,0		; W= W OR R54[0]
 MOVWF 0x55		; R55[0]= W ---> Esta es la FUNCIÓN del K4

 ;---------------------------
  ;LEDS DIRECCIONALES   
 ;---------------------------

 ; << K5 >>  --> LED IZQ---> LED IZQUIERDA 

 ; R56[0]= !S1 & S2 
 MOVF 0x21,0		; W= R21[0]
 ANDWF 0x32,0		; W= W AND R32[0]
 MOVWF 0x56		; R56[0]= W ---> Este es el primer dato del K5
 
; R57[0]= S1 & !S3
 MOVF  0x31,0		; W= R31[0]
 ANDWF 0x23,0		; W= W AND R23[0]
 MOVWF 0x57		; R57[0]= W ---> Este es el segundo dato del K5
 
 ;R58[0]= R56[0] + R57[0]
 MOVF  0x56,0		; W= R56[0]
 IORWF 0x57,0		; W= W OR R57[0]
 MOVWF 0x58   		; R58[0]= W ---> Esta es la FUNCIÓN del K5
 
;---------------------------------------------

 ; << K6 >>  --> LED CENT----> LED CENTRO

 ; R59[0]= S1 & S3 
 MOVF  0x31,0		; W= R31[0]
 ANDWF 0x33,0		; W= W AND R33[0]
 MOVWF 0x59   		;R59[0]= W ---> Este es el primer dato del K6
 
 ;R60[0]= !S1 & !S2 & !S3 & !S4 & !S5
 MOVF  0x21,0		; W= R21[0]
 ANDWF 0x22,0		; W= W AND R22[0]
 ANDWF 0x23,0		; W= W AND R23[0]
 ANDWF 0x24,0		; W= W AND R24[0]
 ANDWF 0x25,0		; W= W AND R25[0]
 MOVWF 0x60   		; R60[0]= W ---> Este es el segundo dato del K6
 
  ;R61[0]= R59[0] + R60[0]
 MOVF  0x59,0		; W= R59[0]
 IORWF 0x60,0		; W= W OR R60[0]
 MOVWF 0x61		; R61[0]= W ---> Esta es la FUNCIÓN del K6

;---------------------------------------------
 
 ; << K7 >>  --> LED DER ---> LED DERECHO

; R62[0]= !S3 & S5 
 MOVF  0x23,0		; W= R23[0]
 ANDWF 0x35,0		; W= W AND R35[0]
 MOVWF 0x62		; R62[0]= W ---> Este es el primer dato del K7
 
; R63[0]= S4 & !S5
 MOVF  0x34,0		; W= R34[0]
 ANDWF 0x25,0		; W= W AND R25[0]
 MOVWF 0x63		; R63[0]= W ---> Este es el segundo dato del K7
 
 ;R64[0]= R62[0] + R63[0]
 MOVF  0x62,0		; W= R62[0]
 IORWF 0x63,0		; W= W OR R63[0]
 MOVWF 0x64		; R64[0]= W ---> Esta es la FUNCIÓN del K7

 
 ;--------------------------------------------------------------------------
 ; ASIGNACION DE SALIDAS < PUERTO C >
 ;--------------------------------------------------------------------------

 ; Antes de asignar las salidas  es necesario realizar unas operaciones de rotación para poder organizar el codigo en un solo registro. Teniendo en cuenta desde el menos significativo hasta el más significativo.
; Formando con las funciones de los karnaugh--> << X K7 K6 K5 K4 K3 K2 K1 >>

 ;>----------
 ; ROTANDO 
 ;>----------

  ;MI ROTACION ---> R43[0]

  ;R43[0] no fue modificado porque K1 ya esta en el bit menos significativo 
  ;SALIDA 0000000 K1 
;------------------------------------------ 
  ;MD ROTACION ---> R65[1]= R48[0]

  MOVF  0x48,0 		; W= 0000000 K2 
  RLF   0x48,1		; R48= 000000 K2 0
  MOVF  0x48,0		; W= 000000 K2 0
  MOVWF 0x65 		; R65= 0 0 0 0 0 0 K2 0 
 ;------------------------------------------  
  ;MI2 ROTACION ---> R66[2]= R51[0]

  MOVF  0x51,0		; W= 0000000 K3
  RLF   0x51,1		; R51= 000000 K3 0
  RLF   0x51,1		; R51= 00000 K3 00
  MOVF  0x51,0		; W= 00000 K3 00
  MOVWF 0x66 		; R66= W
;------------------------------------------   
  ;MD2 ROTACION ---> R67[3]= R55[0]

  MOVF  0x55,0		; W= 0000000 K4
  RLF   0x55,1		; R55= 000000 K4 0
  RLF   0x55,1		; R55= 00000 K4 00
  RLF   0x55,1		; R55= 0000 K4 000
  MOVF  0x55,0		; W= R55
  MOVWF 0x67 		; R67= W 
;------------------------------------------   
 ;LED-IZQUIERDO ---> R68[4]= R58[0]

 MOVF  0x58,0		; W= 0000000 K5
 RLF   0x58,1		; R58= 000000 K5 0
 RLF   0x58,1		; R58= 00000 K5 00
 RLF   0x58,1		; R58= 0000 K5 000
 RLF   0x58,1		; R58= 000 K5 0000
 MOVF  0x58,0		; W = R58
 MOVWF 0x68   		; R68= W
;------------------------------------------  
 ;LED-DERECHO ---> R69[5]= R64[0]
 MOVF  0x64,0		; W= 0000000 K6
 RLF   0x64,1		; R64= 000000 K6 0
 RLF   0x64,1		; R64= 00000 K6 00
 RLF   0x64,1		; R64= 0000 K6 000
 RLF   0x64,1		; R64= 000 K6 0000
 RLF   0x64,1		; R64= 00 K6 00000
 MOVF  0x64,0		; W= R64
 MOVWF 0x69   		; R69 =W 
;------------------------------------------ 
 ;LED-CENTRO ---> R70[6]= R61[0]
 MOVF  0x61,0		; W= 0000000 K7
 RLF   0x61,1		; R61= 000000 K7 0
 RLF   0x61,1		; R61= 00000 K7 00
 RLF   0x61,1		; R61= 0000 K7 000
 RLF   0x61,1		; R61= 000 K7 0000
 RLF   0x61,1		; R61= 00 K7 00000
 RLF   0x61,1		; R61= 0 K7 000000
 MOVF  0x61,0		; W= R61
 MOVWF 0x70   		; R70= W
;------------------------------------------
;  SALIDA PUERTO C
;----------------------
; PORTC=  R70[6] + R69[5] + R68[4] + R67[3] + R66[2] + R65[1] + R43[0]

 MOVF  0x43,0		; W= 0000000 K1
 IORWF 0x65,0		; W= W + 000000 K2 0
 IORWF 0x66,0		; W= W + 00000 K3 00
 IORWF 0x67,0		; W= W + 0000 K4 000
 IORWF 0x68,0		; W= W + 000 K5 0000
 IORWF 0x69,0		; W= W + 00 K6 00000
 IORWF 0x70,0		; W= W + 0 K7 000000
 MOVWF PORTC  		; PORTC= W = X K7 K6 K5 K4 K3 K2 K1 ---> RESULTADO SALIDA DEL PUERTO C
 
goto main  ;leer de nuevo 
 
END