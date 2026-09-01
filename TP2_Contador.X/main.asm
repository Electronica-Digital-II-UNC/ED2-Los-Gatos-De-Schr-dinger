LIST P=16F887
    #include <p16f887.inc>
; --- Palabra de Configuración 
; Config 1: Cristal XT (4MHz), Watchdog apagado, Master Clear habilitado, LVP apagado
__CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; Config 2: Sin protección de escritura
__CONFIG _CONFIG2, _WRT_OFF & _BOR4V_BOR40V
    
CONTEO         EQU 0x20
REG1           EQU 0X21
REG2           EQU 0X22
ESTADO_SISTEMA EQU 0x23   
CONTA_2SEG     EQU 0x24   
SALIDA_D       EQU 0x25    ; registro sombra: arma el proximo valor                      
REG3           EQU 0x26    ; contador del bucle de demora (300ms)

    ORG 0x0000
    GOTO INICIO

    
INICIO: 
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH     ; pongo todos los puertos en modo digital
    
    BANKSEL PORTD
    CLRF PORTD      ; pongo todos los bits del puerto D en 0
    
    BANKSEL TRISD   ; me ubico en el TRIS del puerto D
    MOVLW 0x00 
    MOVWF TRISD     ; pongo PORTD en modo salida
    
    BANKSEL TRISA   ; me ubico en el TRIS del puerto A
    BSF TRISA,4     ; pongo el pin 4 en modo entrada 
    
    BANKSEL CONTEO
    CLRF CONTEO     ; cargo 0 al contador
    CLRF ESTADO_SISTEMA ; arranca en modo 0 (contador)
    
    
ESPERAR_PRESION:
	CALL    EVALUAR_ESTADO  ; verifica el estado actual
        BANKSEL PORTA
        BTFSC   PORTA, 4        ; RA4 ES 0?(Boton pulsado)
        GOTO  ESPERAR_PRESION  ;si sigue en 1 sigue esperando la presión, skipea si es 0

        CALL    RETARDO         ; Antirrebote de entrada     
        BANKSEL PORTA
        BTFSC   PORTA, 4        ; Sigue en 0 tras el retardo?
        GOTO    ESPERAR_PRESION ; sino si sigue en 1 vuelve a esperar la presion
        
        CALL    EVALUAR_PULSACION   ; evalua si es pulsacion corta o de 2s
        

    ; se asgura de que el pulsador haya sido soltado para que no se dispare el conteo con un solo pulso
ESPERAR_LIBERACION:
        BANKSEL PORTA
        BTFSS   PORTA, 4        ; RA4 volvió a 1?
        GOTO    ESPERAR_LIBERACION  ; sino si sigue en 0 espera que el usuario lo suelte, skipea cuando manda un 1(no presionado)

        CALL    RETARDO         ; Antirrebote de salida
        GOTO    ESPERAR_PRESION ; Vuelve al inicio del ciclo
        

    
;SUBRUTINAS:


EVALUAR_ESTADO:
    BANKSEL ESTADO_SISTEMA
    BTFSC ESTADO_SISTEMA,0 ; ¿esta en modo secuencia?
    GOTO SECUENCIA	   ; si es 1 va a dar un paso de las luces
    RETURN		   ; si es 0 vuelve a espiar el botón
    
    
    
; evalua el boton para el cambio de modo segun el issue    
EVALUAR_PULSACION:
    BANKSEL ESTADO_SISTEMA
    BTFSC   ESTADO_SISTEMA, 0   ; ¿esta en 1(secuencia)?
    GOTO    SALIR_DE_SECUENCIA  ; si estaba en secuencia vuelve a contador, sino se saltea esta linea

    CALL    ESPERAR_2_SEGUNDOS  ;Si no estaba en secuencia, mide si se mantiene 2 seg pulsado

    BANKSEL PORTA
    BTFSS   PORTA, 4            ; si sigue en 0 pasaron los 2s
    GOTO    PASAR_A_SECUENCIA

    ;PULSACION CORTA
    CALL    AUMENTAR_CONTEO     ; suma 1 al contador
    RETURN

PASAR_A_SECUENCIA:
    BANKSEL ESTADO_SISTEMA
    BSF     ESTADO_SISTEMA, 0   ; pasa a modo 1(secuencia)
    MOVLW   0x01
    MOVWF   SALIDA_D      ; arranca con el LED en RD0
    RETURN			; vuelve a la linea donde fue llamada

SALIR_DE_SECUENCIA:
    BANKSEL CONTEO
    CLRF    CONTEO              ; resetea la cuenta a 0
    BANKSEL PORTD
    CLRF    PORTD               ; limpia los leds
    BANKSEL ESTADO_SISTEMA
    BCF     ESTADO_SISTEMA, 0   ; vuelve al modo 0
    RETURN


; bucle para esperar los 2 segundos
ESPERAR_2_SEGUNDOS:
    BANKSEL CONTA_2SEG
    MOVLW   D'100'              ; 100 vueltas de 20ms
    MOVWF   CONTA_2SEG

BUCLE_2SEG:
    
    CALL    RETARDO		; espera 20ms
    
    BANKSEL PORTA
    BTFSC   PORTA, 4		; ¿el botón sigue apretado? (RA4 en 0)
    RETURN			; NO (pasó a 1) -> soltó el botón, sale ya mismo
    
    BANKSEL CONTA_2SEG
    DECFSZ  CONTA_2SEG, F       ; resta 1 hasta llegar a 0
    GOTO    BUCLE_2SEG
    RETURN

    
;esta subrutina debe ser llamada cuando se confirma una pulsacion para aumentar el numero del conteo
AUMENTAR_CONTEO:
    BANKSEL CONTEO  ; me ubico en el banco de conteo
    INCF CONTEO,F   ; incremento en 1 el contador
    MOVF CONTEO,W   ; lo paso al Wreg
    
    BANKSEL PORTD   ; me ubico en puerto D
    MOVWF PORTD     ; cargo el valor del contador al puerto D
    
    RETURN      ; vuelve a la linea donde fue llamada esta subrutina
    
    
;RETARDO DE 20MS
RETARDO:
    BANKSEL REG2
        MOVLW D'26'      ;carga 26 en decimal en el registro w
        MOVWF REG2       ;reg2=26 Variable de bucle externo
    
    
BUCLE_EXTERNO:
        MOVLW D'255'            ;carga 255 en decimal en el registro w
        MOVWF REG1              ; reg1=255 Variable de Bucle interno
    
    
BUCLE_INTERNO:
        DECFSZ REG1, F          ; va decrementando en uno 255, si llega a 0 skipea
        GOTO BUCLE_INTERNO      ;si REG1=0 se skipea esta linea
        DECFSZ REG2,F           ;decrementa en uno 26, si llega a 0 skipea sino va a bucle externo
        GOTO BUCLE_EXTERNO   ;si REG2=0 se skipea esta linea y finaliza el retardo
        RETURN          ; vuelve a la linea donde fue llamado el RETARDO
    
    
    


; --- Subrutina de secuencia (barrido circular sobre PORTD) ---
; Requiere: RETARDO ya existente en el archivo (no se duplica)
SECUENCIA:
    BANKSEL SALIDA_D
    

    MOVF    SALIDA_D,W
    BANKSEL PORTD
    MOVWF   PORTD         ; muestra el valor actual (de un solo golpe)

    MOVLW   D'15'         ; 15 x 20ms = 300ms de pausa entre pasos
    MOVWF   REG3
BUCLE_DEMORA:
    CALL    RETARDO
    DECFSZ  REG3,F
    GOTO    BUCLE_DEMORA

    BCF     STATUS,C      ; limpia el acarreo antes de rotar
    RLF     SALIDA_D,F    ; rota el bit; si salio por RD7, queda en Carry
    BTFSC   STATUS,C      ; si salo un bit
    BSF     SALIDA_D,0    ; lo reingresa en RD0 (barrido circular)

    RETURN
    
END