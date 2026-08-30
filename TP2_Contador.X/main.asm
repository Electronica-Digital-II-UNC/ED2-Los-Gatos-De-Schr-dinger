    
    ORG 0x0000
    GOTO INICIO
    
INICIO: 
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH ; pongo todos los puertos en modo digital
    
    BANKSEL PORTD
    CLRF PORTD; pongo todos los bits del puerto D en 0
    
    BANKSEL TRISD ;me ubico en el TRIS del puerto D
    MOVLW 0x00 
    MOVWF TRISD ; pongo PORTD en modo salida
    
    BANKSEL TRISA; me ubico en el TRIS del puerto A
    BSF TRISA,4 ; pongo el pin 4 en modo entrada 
    
    
    
    
    
FIN:
    GOTO FIN
END