;==========================================================
; TP2 - Parte 1: Contador binario de 8 bits
; PIC16F887 - Oscilador externo 4 MHz
;
; Entrada:  RA4   -> pulsador de proposito general, activo en 0
;                    (pull-up externo de 10k a VDD)
; Salida:   PORTD -> banco de 8 LED
;                    RD0 = bit menos significativo (2^0)
;                    RD7 = bit mas significativo  (2^7)
;
; El contador avanza 0,1,2,...,254,255,0 con cada pulsacion
; valida. Antirrebote por retardo + doble lectura, mismo
; esquema del apunte de clase (Cap. 4, Aplicacion con
; pulsador y LEDs) y del Ejercicio 4.3 de la guia.
;==========================================================

CONTADOR EQU 0x20
RET_EXT  EQU 0x21
RET_INT  EQU 0x22

    ORG     0x0000
    GOTO    INICIO

;----------------------------------------
; Inicializacion
;----------------------------------------
INICIO:
    BANKSEL ANSEL
    CLRF    ANSEL           ; RA4 y PORTD no tienen funcion analogica,
    CLRF    ANSELH          ; se limpia por norma general

    BANKSEL PORTD
    CLRF    PORTD           ; LEDs apagados al arrancar

    BANKSEL CONTADOR
    CLRF    CONTADOR

    BANKSEL TRISA
    MOVLW   0xFF
    MOVWF   TRISA           ; RA4 y pines no usados aun, como entradas

    BANKSEL TRISD
    CLRF    TRISD           ; PORTD completo como salida

;----------------------------------------
; Programa principal
;----------------------------------------
ESPERAR_PRESION:
    BANKSEL PORTA
    BTFSC   PORTA,4         ; Pulsador activo en 0: salta si RA4=1 (no presionado)
    GOTO    ESPERAR_PRESION

    CALL    RETARDO         ; Espera a que pase el rebote inicial

    BANKSEL PORTA
    BTFSC   PORTA,4         ; Confirma que sigue presionado
    GOTO    ESPERAR_PRESION ; Si ya se solto, era ruido: ignorar

    BANKSEL CONTADOR
    INCF    CONTADOR,F      ; 8 bits: FF->00 es automatico, sin mascara
    MOVF    CONTADOR,W

    BANKSEL PORTD
    MOVWF   PORTD           ; Muestra el nuevo valor en los 8 LED

ESPERAR_LIBERACION:
    BANKSEL PORTA
    BTFSS   PORTA,4         ; Espera a que el pulsador vuelva a 1
    GOTO    ESPERAR_LIBERACION

    CALL    RETARDO         ; Antirrebote tambien en la liberacion
    GOTO    ESPERAR_PRESION

;----------------------------------------
; RETARDO: aprox. 19 ms con oscilador de 4 MHz
; (TCY = 4/FOSC = 1us; misma constante 0x19 del apunte,
;  que a 8MHz daba 10ms, aca da el doble)
;----------------------------------------
RETARDO:
    BANKSEL RET_EXT
    MOVLW   0x19
    MOVWF   RET_EXT

LAZO_EXT:
    CLRF    RET_INT

LAZO_INT:
    DECFSZ  RET_INT,F
    GOTO    LAZO_INT
    DECFSZ  RET_EXT,F
    GOTO    LAZO_EXT
    RETURN

    END
