;в первой и второй строке вводится число (первый символ 0 или '-' , дальше число идет) 
;(Пример 0111111 012 или -111111 012)
;в ответ выводится та операция которая выбрана в коде (524 строчка и далее) (сумма, разность,умножение)
;также в 531 строчке выбирается в какой системе счисления идет подсчет
assume cs: code, ds: data
data segment
    number1 db 100,100 dup ('$');первый символ всегда знак!!! (- или что угодно)
    number2 db 100,100 dup ('$');первый символ всегда знак!!! (- или что угодно)
    result1 db 100, 100 dup ('$')
    err_msg db "bad symbol$"
    rasn db 0
    sign db 0 ;знак результата ( если 1 то отрицательно)
    resultlen dw 10
data ends
code segment
error proc ;вывод ошибки и завершение программы
    mov dx, offset err_msg
    mov ah, 09h
	int 21h
	mov AX,4C00h
	int 21h
error endp
signchange proc ;если число отрицательно то представляем как отрицательное (дополнение до степени 2)
    ;call error
    xor bx,bx
    mov bl,[si]
    while2:
        NEG  byte ptr [si + bx]
        CMP bl,1
        dec bl
        JE ret2
        jmp while2
    ret2:
    ret
signchange endp
tonumbers proc ;чтобы в каждой строке не лежала цифра в ascii, в si находится преобразуемая строка
    xor dx,dx
    cmp byte ptr [si],'-' ;определяем отрицательное ли число
    JnE nnextt
    mov dx,1
    nnextt:
    call searchlen
    mov byte ptr [si],bl
    xor bx,bx
    mov bl,[si]
    while:

        cmp byte ptr [si + bx],'0'
        JL err1
        cmp byte ptr [si + bx],'9'
        JLE decimal
        cmp byte ptr [si + bx],'G'
        JGE err1
        cmp byte ptr [si + bx],'A'
        JGE hexadecimal
        decimal:
            sub byte ptr  [si + bx],'0'
            jmp continuation
        hexadecimal:
            sub byte ptr  [si + bx],'A'
            add byte ptr  [si + bx],10
            jmp continuation
        continuation:
        CMP bl,1
        dec bl
        JE ret1
        jmp while
    err1:
    call error
    ret1:
    cmp dx,1
    JE signn
    ret
    signn:
    call signchange ; если отрицательное число то
    ret

tonumbers endp
searchlen proc
    xor bx,bx
    while17:
        inc bx
        cmp byte ptr [si+bx],'$'
        JNE while17
    dec bx
    ret
searchlen endp
findlen proc ;ищем размерность строки вывода (2*(длину+1))
    xor ax,ax
    mov si,offset number1
    call searchlen
    mov al ,bl
    xor cx,cx
    mov si,offset number2
    call searchlen
    mov cl ,bl
    CMP ax,cx
    JG bolshe
    mov ax,cx
    xor bx,bx
    dec ax
    mov bl,2
    mul bl
    mov resultlen,ax
    jmp retfind
    bolshe:
    xor bx,bx
    mov bl,2
    dec ax
    mul bl
    mov resultlen,ax

    retfind:
ret
findlen endp
tonumberspositive proc ;чтобы в каждой строке не лежала цифра в ascii, в si находится преобразуемая строка 
    call searchlen
    mov byte ptr [si],bl
    xor bx,bx
    mov bl,[si]
    while111:

        cmp byte ptr [si + bx],'0'
        JL err11
        cmp byte ptr [si + bx],'9'
        JLE decimal1
        cmp byte ptr [si + bx],'G'
        JGE err11
        cmp byte ptr [si + bx],'A'
        JGE hexadecimal1
        decimal1:
            sub byte ptr  [si + bx],'0'
            jmp continuation1
        hexadecimal1:
            sub byte ptr  [si + bx],'A'
            add byte ptr  [si + bx],10
            jmp continuation1
        continuation1:
        CMP bl,1
        dec bl
        JE ret11
        jmp while111
    err11:
    call error
    ret11:
    ret

tonumberspositive endp

addition proc
    ;в si лежит строка 1
    ;в di лежит строка 2
    
    call tonumbers
    push si
    mov si,di
    call tonumbers
    pop si
    xor bx,bx
    mov bl,[si]
    xor cx,cx
    mov cl,[di]
    add si,bx
    add di,cx
    CMP bl,cl
    JG nextt
    mov rasn,cl 
    sub rasn,bl
    ;если di>si
    mov cx,bx
    mov bx,offset result1
    add bx,resultlen
    lp01 :
        
        xor ax,ax
        mov al,[si]
        mov byte ptr [bx],al
        xor ax,ax
        mov al,[di]
        add byte ptr [bx],al
        dec bx 
        dec si
        dec di
    loop lp01
    xor cx,cx
    mov cl, rasn
    CMP cx,0
    je ret3
    lp11 :
    xor ax,ax
    mov al, [di]
    mov byte ptr [bx], al
        dec bx 
        dec di
    loop lp11
    jmp ret3
    nextt:
     mov rasn,bl 
    sub rasn,cl
    ;если si>di
    mov bx,offset result1
    add bx,resultlen
    lp02 :
        xor ax,ax
        mov al,[si]
        mov byte ptr [bx],al
        xor ax,ax
        mov al,[di]
        add byte ptr [bx],al
        dec bx 
        dec si
        dec di
    loop lp02
    xor cx,cx
    mov cl, rasn
    CMP cx,0
    je ret3
    lp12 :
    xor ax,ax
    mov al, [si]
    mov byte ptr [bx], al
        dec bx 
        dec si
    loop lp12
    ret3:
    ret
addition endp

subtraction proc ;просто переворачиваем знак у 2 числа и запускаем сложение
        cmp byte ptr [di],'-'
        JE minus
        mov byte ptr [di],'-'
        jmp ret4
    minus:
        mov byte ptr [di],'0'
    ret4:
        call addition
        ret
subtraction endp
searchsign proc ;поиск знака результата (кладется в sign)
    mov bx,2
    while7:
        CMP result1[bx],0
        JNE ret7
        CMP bx,resultlen
        inc bl
        JE ret8
        jmp while7

    ret7:
    CMP result1[bx],0
    JGE ret8
    mov sign,1
    ret8:
    ret

searchsign endp
additiontotwo proc
    mov bx,resultlen
    while9:
        NEG result1[bx]
        CMP bl,1
        dec bl
        JE ret15
        jmp while9
    ret15:
    ret
additiontotwo endp
normalizedec proc
    
    call searchsign ;ищем знак
    mov bx,resultlen
    CMP sign,1
    JNE while5
    JE while6
    while5: ;если положительно (проходим по каждой цифре)
        wwhile5: ;(обработка 1 цифры)
            mov cl,result1[bx]
            CMP cl,0
            JL negative
            CMP cl,10
            JL exit1
            sub cl, 10
            inc result1[bx-1]
            mov result1[bx],cl
            jmp wwhile5
            negative:
            add cl, 10
            dec result1[bx-1]
            mov result1[bx],cl
            jmp wwhile5
            exit1:
        CMP bl,2
        JE ret9

        dec bl
        
        jmp while5
    while6: ;если отрицательно (проходим по каждой цифре)
        wwhile6: ;(обработка 1 цифры)
            ;;call error
            CMP result1[bx],0
            JE exit2
            CMP result1[bx],246
            JA exit2
            add result1[bx],10
            dec result1[bx-1]
            jmp wwhile6
            exit2:
        CMP bl,2
        JE retminus
        dec bl
        
        jmp while6
    retminus:
    call additiontotwo
    ret9:
    call transformationdec
    ret
normalizedec endp
normalizenex proc
    
    call searchsign ;ищем знак
    mov bx,resultlen
    CMP sign,1
    JNE while15
    JE while16
    while15: ;если положительно (проходим по каждой цифре)
        wwhile15: ;(обработка 1 цифры)
            mov cl,result1[bx]
            CMP cl,0
            JL negative1
            CMP cl,16
            JL exit11
           
            sub cl, 16
            inc result1[bx-1]
            mov result1[bx],cl
            
            jmp wwhile15
            negative1:
            add cl, 16
            dec result1[bx-1]
            mov result1[bx],cl
            
            jmp wwhile15
            exit11:
        CMP bl,2
        JE ret19
        dec bl
        jmp while15
    while16: ;если отрицательно (проходим по каждой цифре)
        wwhile16: ;(обработка 1 цифры)
            CMP result1[bx],0
            JE exit2
            CMP result1[bx],240
            JA exit12
            add result1[bx],16
            dec result1[bx-1]
            jmp wwhile16
            exit12:
        CMP bl,2
        JE retminus1
        dec bl
        jmp while16
    retminus1:
    call additiontotwo
    ret19:
    call transformationnex
    ret
normalizenex endp
numberoutput proc ;Вывод строки
	mov AX, data
	mov DS, AX
	mov AH, 09h
	mov DX, offset result1
	int 21h
    mov ax,0000h
	ret
numberoutput endp
vanishing proc
    mov bx,resultlen
    while4:
        mov result1[bx],0
        CMP bl,1
        dec bl
        JE ret6
        jmp while4
    ret6:
    ret
vanishing endp
transformationdec proc ;Земеняем число на символ числа
    CMP sign,1  ;если число отрицательно то ставим -
    JNE rest
    mov result1[1],'-'
    rest:
    mov bx,resultlen
    while8:
        add result1[bx],'0'
        CMP bl,2
        JE ret10
        dec bl
        
        jmp while8
    ret10:
    ret
transformationdec endp
transformationnex proc ;Земеняем число на символ числа
    CMP sign,1  ;если число отрицательно то ставим -
    JNE rest1
    mov result1[1],'-'
    rest1:
    mov bx,resultlen
    while18:
        CMP result1[bx],10
        JL positive1
        add result1[bx],'A'
        sub result1[bx],10
        jmp nnnext
        positive1:
        add result1[bx],'0'
        nnnext:
        CMP bl,2
        dec bl
        JE ret110
        jmp while18
    ret110:
    ret
transformationnex endp
definitesign proc ;для умножения определение знака результата
    mov bx,0000h
    CMP byte ptr [si],'-'
    JNE signnext1
    inc bx
    signnext1:
    CMP byte ptr [di],'-'
    JNE signnext2
    inc bx
    signnext2:
    CMP bx,2
    JE signret
    CMP bx,0
    JE signret
    mov result1[1],'-'
    signret:
    ret

definitesign endp
multiplication proc
    ;в si лежит строка 1
    ;в di лежит строка 2
    call definitesign
    call tonumberspositive
    push si
    mov si,di
    call tonumberspositive
    pop si
    mov bx,0000h
    mov bl,[si] ;размер si
    mov dx,offset result1
    add dx,resultlen
    while13:
        push bx
        mov cl, [si + bx]
        push si
        xor bx,bx
        mov bl,[di] ; размер
        mov si,dx
        while113:
            xor ax,ax
            mov al, [di + bx]
            mul cl
            add [si],al
            CMP bl,01
            JE exit13
            dec bx
            dec si
            jmp while113
            exit13:
        pop si
        pop bx
        CMP bl,1
        dec dx
        dec bl
        JE ret13
        jmp while13
    ret13:
    ret



multiplication endp
input proc
    mov ah,0ah
    mov dx,offset number1
    int 21h ; ввод строки
    mov dl,0ah
    mov ah,2
    int 21h ; курсор - на следующую строку
    xor bx,bx
    mov bl,[number1+1]
    mov [number1+2+bx],'$' ; вставляем последним символом
    mov ah,0ah
    mov dx, offset number2
    int 21h ; ввод строки
    mov dl,0ah
    mov ah,2
    int 21h ; курсор - на следующую строку
    xor bx,bx
    mov bl,[number2+1]
    mov [number2+2+bx],'$' ; вставляем последним символом
    ret

input endp
start:	
    mov ax, data
	mov ds, ax
    call input ;вводим 2 числа
    call findlen ; ищем длину строки вывода
    call vanishing;Зануляем строку с ответом 

    mov si,offset number1+2
    mov di,offset number2+2
    
    call addition ;сумма
    ;call subtraction ;разность
    ;call multiplication ;умножение
    
    
    ;нормализация чисел
    call normalizedec ;для dec
    ;call normalizenex ;для nex

    mov dx, offset result1+1 ;вывод результата
    mov ah, 09h
	int 21h
	mov AX,4C00h
	int 21h
code ends
end start