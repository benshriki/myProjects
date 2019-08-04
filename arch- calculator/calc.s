section .data
 counter: dd 0
  opcount: dd 0

 stacksize EQU 5        ;holds 5 pointer(4 byte) to link
;---------------- Macro ----------------
    %macro sys_call 4
        mov     eax, %1    ; Copy function args to registers: leftmost...        
        mov     ebx, %2   ; Next argument...
        mov     ecx, %3   ; Next argument...
        mov     edx, %4   ; Next argument...
        int     0x80            ; Transfer control to operating system
    %endmacro

    %macro exit 1         ;exit program
        sys_call 1,%1,0,0
    %endmacro

    %macro write 3       ;write to 1-file path(stdout:1 stderr:2) 2-buff to write 3-num of bytes
        pushad
        sys_call 4,%1,%2,%3
        popad
    %endmacro
    
    %macro newline 1       ;write to 1-file path(stdout:1 stderr:2) a new line
        pushad
        mov byte [tmp],0xA
        sys_call 4,%1,tmp,1
        popad
    %endmacro
    
    %macro mread 2        ;read from stdin 1-buff 2-num of byte
        sys_call 3,0,%1,%2
    %endmacro
    
    %macro makelink 0     ;allocate 5 bytes at heap for a link malloc output in eax
        mov ecx, 5
        push ecx
        call malloc
        pop ecx
    %endmacro
    
    %macro addfirst 1       ;adds link to head of list, and updates link
        pushad
        mov byte bl,%1       ;save data
        makelink
        mov byte [eax],bl
        cmp dword [link],0
        je %%first
        mov dword ecx,[link]
        mov dword [eax+1],ecx
        mov dword [link],eax
        jmp %%endaddtolist
        
        %%first:                  ;if no list exists
            mov dword [link],eax
            mov dword [eax+1],0
        
        %%endaddtolist:
            popad
    %endmacro

    %macro spush 1                  ;simple push to stack
        pushad
        mov dword edx,%1
        mov dword ecx, [counter]
        mov dword ebx, [edx]
        mov dword [stack+4*ecx],ebx
        inc dword [counter]
        popad
    %endmacro
    
    %macro spop 1                   ;pops from our stack to args1
        pushad
        mov dword ebx,%1
        dec dword [counter]
        mov dword ecx,[counter]
        mov dword edx,[stack+4*ecx]
        mov dword [stack+4*ecx],0
        mov dword [ebx],edx
        popad
    %endmacro
   
    %macro removelist 1             ;gets a link (head), removes list deep
        pushad
        mov dword ebx,%1
        mov dword esi,[ebx]
            %%loop:
                mov dword edi,[esi+1]
                cmp edi,0
                je %%delcur
                push esi
                call free
                pop esi
                mov esi,edi
                jmp %%loop
            %%delcur:
                push esi
                call free
                pop esi
        popad
        %endmacro
        
        
    %macro copylist 1           ;gets a link (head), copies deep
        pushad
        mov dword [link],0
        mov dword esi,[%1]
        xor ebx,ebx
        mov dword ebx,'$'
        push ebx
        %%intostack:
            cmp esi,0
            je %%cpylist
            xor ebx,ebx
            mov byte bl,[esi]
            push ebx
            mov esi,[esi+1]
            jmp %%intostack
        %%cpylist:
            pop ebx
            cmp byte bl,'$'
            je %%endcopy
            addfirst bl
            jmp %%cpylist
        %%endcopy:
            popad
    %endmacro
 
        
        
    %macro removefirst 1          ;removes first link (used in shiftdown)
        pushad
        mov dword esi,%1
        mov  dword edi,[esi]
        mov dword ebx, [edi+1]
        mov dword [esi],ebx
        push edi
        call free
        pop edi
        popad
    %endmacro
        
        
    %macro printlist 1                  ;uses os stack to reverse the linked list and print
        pushad
        mov dword ecx,%1
        mov dword esi,[ecx]
        xor ecx,ecx
        mov dword ebx,'$'
        push ebx
        %%intostack:
            cmp esi,0
            je %%printfromstack
            xor ebx,ebx
            mov byte bl,[esi]
            push ebx
            mov esi,[esi+1]
            jmp %%intostack
        %%printfromstack:
            cmp dword [esp],'$'
            je %%endprintlist
            pop ebx
            mov byte [chart],bl
            write 1,chart,1
            jmp %%printfromstack
        %%endprintlist:
            newline 1
            pop ebx
            popad
    %endmacro
        
    %macro calcup 1                 ;if more than 2 links, then y > 200, senderr, else calc y and return it
        pushad                      ;save esi
        xor ebx,ebx
        mov dword edi,[%1]

        mov byte bl,[edi]           ;first link
        chartobin bl                ;lsb
        mov edi,[edi+1]
            
        cmp edi,0
        je %%calculate              ;if only one link
        mov byte bh,[edi]           ;second link
        chartobin bh
        someshit:
        mov edi,[edi+1]
                

        cmp edi,0
        je %%calculate
        jmp %%senderr
    
        %%senderr:
            mov dword [y],201
            jmp %%exit
            
        %%calculate:                ;else we calculate the value of the list
            shl bh,4
            or bl,bh
            xor bh,bh
            mov dword [y],ebx
        %%exit:
            popad
    %endmacro
    


    %macro addfunc 2
        pushad
        mov dword esi, [%1]    ;first num at stack
        mov dword edi, [%2]    ;second num on stack
        mov byte [mulflag],0
        cmp esi,edi
        jne %%cont
        %%setflag:
            mov byte [mulflag],1
        %%cont:
        mov eax,'$'
        push eax
        mov eax,0               ;need for div
        mov ebx,0               ;calcuted
        mov ecx,0               ;counter
        mov edx,0               ;need for div
        mov byte [carry],0
            %%checknum1:
                cmp esi,0                     ;counter <= num1 bytes
                je %%zbl                         ;continue calculation                      
                mov bl,byte [esi]             ;read calculation into bl
                mov dword esi,[esi+1]           ;next step 
                chartobin bl                     ;convert
            
            %%checknum2:
                cmp edi,0                    ;counter <= num2 bytes
                je %%zbh                         ;continue calculation
                mov bh, byte [edi]                ;write calculation into bh
                mov dword edi,[edi+1]               ;next step
                chartobin bh                    ;convert
                jmp %%checkcarry                 ;need to add carry?
            
            %%zbl:                               ;zeroes bl
                mov bl,0
                jmp %%checknum2
            
            %%zbh:                               ;zeroes bh
                mov bh,0
                jmp %%stop
                
            %%stop:                             ;bl,bh and carry are zero, then we can stop calculating
                cmp bl,0                        ;^ this means we have nothing left to add
                jne %%checkcarry
                cmp bh,0
                jne %%checkcarry
                cmp byte [carry],0
                jne %%action1                    ;add with carry
                cmp byte [mulflag],1
                je %%clearmem
                mov dword [link],0
                jmp %%endf
                
            %%clearmem:
                removelist link
                mov dword [link],0
                jmp %%endf
            
            %%checkcarry:
                cmp byte [carry],1
                je %%action1
                
            %%action0:                           ;add without carry
                add bl,bh
                cmp byte bl,15
                jg %%carry
                jmp %%intobuff
            
            %%action1:                           ;add with carry
                add bl,bh
                inc bl
                cmp bl,15                       ;if greater than 15, we have a carry (hex)
                jg %%carry
                mov byte [carry],0                 ;reset carry (we used it)
                jmp %%intobuff
            
            %%carry:                    
                mov byte [carry],1
                jmp %%intobuff
                
            %%intobuff:
                xor eax,eax
                mov byte al,bl
                mov dh,16
                div dh
                bintochar ah
                mov byte al,[chart]
                push eax                        ;push converted element into os stack
                jmp %%checknum1
            
            %%endf:
                pop eax
                cmp eax,'$'
                je %%endaddfunc
                addfirst al
                jmp %%endf
            %%endaddfunc:
            popad
            %endmacro

    %macro chartobin 1
            
        cmp byte %1,'A'
        jge %%ltonum
        jmp %%ntobin
        %%ltonum:
            sub byte %1,55
            jmp %%endctob
        %%ntobin:
            sub byte %1,'0'
        %%endctob:
        nop
    %endmacro

        

    %macro bintochar 1
        pushad
        movzx dword edx,%1
        mov byte dl,[btoc+edx]
        mov byte [chart],dl
        popad 
    %endmacro
        
        
    %macro nextnotzero 1        ;finds "next non-zero" in list, borrows from it all the way to head
        pushad
        mov dword esi,[%1]  ;head
        mov dword edi,[%1]  ;checker
        xor ecx,ecx
        cmp byte [esi],'0'
        jne %%endnextnotzero
        %%loop:                         ;checks for next not zero
            mov dword edi,[edi+1]
            cmp edi, 0
            je %%flag
            cmp byte [edi],'0'
            je %%loop
            mov byte cl, [edi]
            chartobin cl
            dec  cl
            bintochar cl
            mov byte cl,[chart]
            mov byte [edi],cl
            jmp %%borrow
        %%borrow:                       ;shifts the "borrow" all the way down to lsb
            cmp esi,edi
            je %%endnextnotzero
            mov byte [esi],'F'
            mov dword esi,[esi+1]
            jmp %%borrow
        %%flag:
            mov byte [yflag],1                  ;means "y" is now 0, we finished dividing
        %%endnextnotzero:
            popad
    %endmacro
        
    %macro divideby2 1                  ;divides a given *list* by 2 ONCE
        pushad
        mov esi,[%1]
        mov byte [carry],0
        xor ebx,ebx
        xor ecx,ecx
        mov dword ebx,'$'
        push ebx
        %%rev:                          ;reverse list (so we operate from msb)
            cmp esi,0
            je %%cleanmem
            xor ebx,ebx
            mov byte bl,[esi]
            chartobin bl
            push ebx
            mov dword esi,[esi+1]
            jmp %%rev
        %%cleanmem:     
            removelist link
            mov dword [link],0
        %%calc:                         ;shifts right one bit, without carry
            xor ebx,ebx
            pop ebx
            cmp ebx, '$'
            je %%enddiv
            cmp byte [carry],0 
            jne %%handlecarry
            shr ebx,1
            jc %%setcarry1
        %%prepinsert:                 ;prepares insertion to list       
            bintochar bl
            mov byte dl,[chart]
            cmp ecx,1
            je %%insertnozero
            cmp byte dl,'0'             ;if not 0, will light up leading zero flag
            je %%calc
        %%insertnozero:                 ;lights leading zero flag and inserts to list
            mov ecx,1
            addfirst dl
            jmp %%calc
        %%handlecarry:                  ;shifts right one bit, with carry               
            shr ebx,1
            jnc %%setcarry0
        %%or:
            or ebx,8 ;                  ;equivalent to adding the carried bit (Bitwise logic)
            jmp %%prepinsert
        %%setcarry0:
            mov byte [carry],0
            jmp %%or
        %%setcarry1:
            mov byte [carry],1
            jmp %%prepinsert
        %%enddiv:
            popad
    %endmacro    
    
    %macro printop 0
    pushad
    xor eax,eax
    mov dword eax,[opcount]
    mov dword esi,out
    mov ebx,16
    %%loop:
        xor edx,edx
        xor ecx,ecx
        cmp dword eax,0
        je %%print
        div ebx
        bintochar dl
        mov byte cl,[chart]
        mov byte [esi],cl
        inc esi
        jmp %%loop
    %%print:
        write 1,out,12
        newline 1
    popad
    %endmacro
    
;---------------- End Macro ----------------

section .bss
 stack:   resb stacksize*4           ;holds 5 pointer(4 byte) to link
 buff:    resb 81
 debug:   resd 1
 link:    resd 1
 calclink1: resd 1
 calclink2: resd 1
 carry: resb 1
 tmp:resb 1
 y: resd 1
 checkarg:resd 1
 calcbuff1:resb 80
 calcbuff2:resb 80
 chart: resb 1
 yflag: resb 1
 mulflag: resb 1
 out: resb 12
section	.rodata			; we define (global) read-only variables in .rodata section
	errs: dq "Error: Operand Stack Overflow"
	erro: dq "Error: Insufficient Number of Arguments on Stack"
	errof: dq "wrong Y value"
	calc: dq "calc: "
	db: dq "Debug: "
	btoc: dq "0123456789ABCDEF"
	no1b: dq "0112122312232334"
	format_string: db "%d", 10, 0	; format string
section .text
  align 16
     global main
     extern printf
     extern fflush
     extern malloc
     extern calloc
     extern free
     extern fgets 
     
	
	

	main:
        jmp myCalc
		exitP:
        .clearstack:
        cmp dword [counter],0
        je .exitprog
        spop link
        removelist link
        jmp .clearstack

        .exitprog:
        mov dword ebx,[opcount]
        push ebx
        push format_string
        call printf
        exit 0
	_start:
	myCalc:

        mov dword [link],0
        mov ecx,[esp+4]
        cmp ecx, 1
        je fmsg
        mov dword [checkarg],1

        
        
    fmsg:
        write 1,calc,6
        mread buff,81
        cmp eax,81
        jg senderrof
        cmp eax,1
        je fmsg
   
   check:
        
        cmp byte [buff],'q'
        je exitP
        cmp byte [buff],'p'
        je popnprint
        cmp byte [buff],'d'
        je duplicate
        cmp byte [buff],'+'
        je add
        cmp byte [buff],'n'
        je numof1bits
        cmp byte [buff],'^'
        je shiftup
        cmp byte [buff],'v'
        je shiftdown

  makelist:
      mov dword [link],0
      cmp dword [counter],stacksize             ;Cchange to EQU (stack size)
      je senderrs                       ;overflow
      pushad
      xor ebx,ebx
      xor edx,edx
     .looplist:                         ;check for invalid chars, inserts valid chars
        mov byte cl,[buff+ebx]
        mov byte [buff+ebx],0
        cmp cl, 0xA                     ;enter
        je .endmakelist
        cmp cl, 0                       ;terminator
        je .check0
        cmp ebx,0
        je .leadzero                    
        .insert:
        addfirst cl
        inc ebx
        inc edx
        jmp .looplist
        .leadzero:
            cmp cl,'0'
            je .handlezero
            cmp cl,0xA
            je .check0
            cmp cl,0
            je .check0
            jmp .insert
        .handlezero:
         inc ebx
         mov byte cl,[buff+ebx]
         mov byte [buff+ebx],0
         jmp .leadzero
     .check0:
            cmp edx,1
            jge .endmakelist
            mov byte cl,'0'
            addfirst cl
            
        .endmakelist:
      popad
      
	
	pushtostack:                      ;push with debug
        spush link
        cmp dword [checkarg],1
        je debuger
        jmp fmsg
       
    debuger:                           ;print debug
        write 1,db,7
        mov dword ecx,[counter]
        dec ecx
        mov dword ebx, [stack+4*ecx]
        mov dword [link],ebx
        printlist link
        mov dword [link],0
        jmp fmsg

    popnprint:  
        inc dword [opcount]
        cmp dword [counter],0
        je senderro
        spop link
        printlist link
        removelist link
        jmp fmsg
  
  duplicate:                    
        pushad
        inc dword [opcount]
        mov dword [link],0
        cmp dword [counter],stacksize             ;Change to EQU (stack size)
        je senderrs                       ;overflow
        cmp dword [counter],0
        je senderro
        mov dword ecx, [counter]
        mov dword esi,[stack+4*ecx-4]
        mov ebx,'$'
        push ebx                            ;this can be changed to "copylist" macro
        .loop:
            cmp esi,0
            je .copylist
            xor ebx ,ebx
            mov byte bl,[esi]
            push ebx
            mov esi,[esi+1]
            jmp .loop
        .copylist:
            cmp byte [esp],'$'
            je .endduplicate
            pop ebx
            addfirst bl
            jmp .copylist
        .endduplicate:
            spush link
            pop ebx
            popad
            jmp fmsg
  
  add:                                      ;calls the addfunc macro to add two prepared lists
        inc dword [opcount]
        cmp dword [counter],2
        jl senderro
        pushad
        spop calclink1
        spop calclink2
        addfunc calclink1,calclink2
        removelist calclink1
        removelist calclink2
        spush link
        popad
        jmp fmsg
                
   
   numof1bits:                          ;our implementation for popcnt
        pushad
        inc dword [opcount]
        cmp dword [counter],0
        je senderro
        mov dword [link],0
        spop calclink1
        mov dword esi,[calclink1]
        mov dword ebx,'$'
        push ebx
        xor ebx,ebx
        xor eax,eax
        xor edx,edx
        .loop:
            cmp esi,0                   ;while not end of string
            je .dectohex         
            mov byte bl,[esi]          
            chartobin bl                ;convert data to binary
            mov bl,[no1b+ebx]       ;count number of ones (look up table)
            sub bl,'0'                  ;convert to int
            add  eax,ebx                  ;sum total 1's
            mov dword esi,[esi+1]
            jmp .loop

        .dectohex:                      ;convert total 1's to hex string
          cmp eax,0
          je .resulte
          mov dword ecx,16              ;divide by 16 for conversion
          div ecx
          bintochar dl                  ;remainder into char, then into array
          push edx                      ;push to stack for reversing
          jmp .dectohex               
          
        .resulte:                       ;pop result in reversed order
            pop edx
            cmp edx,'$'
            je .endnum1bit
            mov byte dl, [chart]        ;converted element into dl
            addfirst dl                 ;create list with result
            jmp .resulte
        .endnum1bit:
            spush link                  ;result into stack
            removelist calclink1         ;clean up memory
            popad
            jmp fmsg
        
            

    shiftup:                   ;convert list into binary list, add "Y" zero links (as lsb), convert back to hex
        pushad
        inc dword [opcount]
        cmp dword [counter],2
        jl senderro
        spop calclink1                  ;"X"
        spop calclink2                  ;"Y"
        mov dword esi,[calclink1]
        mov dword edi,[calclink2]
        copylist calclink1
        xor eax,eax
        xor ebx,ebx
        xor ecx,ecx
        xor edx,edx
        calcup calclink2              ; calculates y
        cmp dword [y],200
        jg .restore
               
        mov cl,4
        mov word ax,[y]
        div cl
        .add0links:                    ;for each time the Y divides by 4, we add a 0 link (bitwise logic)
            cmp al,0
            je .addrem
            mov cl,'0'
            addfirst cl
            dec al
            jmp .add0links
        .addrem:                       ;adds the number to itself "remainder" times to completed the shift
            cmp ah,0
            je .endshiftup
            addfunc link,link
            dec ah
            jmp .addrem
        .restore:                       ;incase of invalid args, restore stack
            mov dword [calclink1],esi
            mov dword [calclink2],edi
            spush calclink2
            spush calclink1
            removelist link
            popad
            jmp senderrof
        .endshiftup:                    ;clean mem and push to stack
            spush link
            mov dword [calclink1],esi
            mov dword [calclink2],edi
            removelist calclink1
            removelist calclink2
            mov dword [y],0
        popad
        jmp fmsg
        
    
    shiftdown:                          ;divides the number using bitwise logic (divide by 2 func), handles cases
        pushad
        inc dword [opcount]
        mov byte [yflag],0             
        cmp dword [counter],2
        jl senderro
        spop calclink1                  ;"X"
        spop calclink2                  ;"Y"
        mov dword esi,[calclink1]
        mov dword edi,[calclink2]
        copylist calclink1
        xor eax,eax
        xor ebx,ebx
        xor ecx,ecx                     
        xor edx,edx
        .divloop:                       ;removes a link for each time "y" is divded by 4
            mov byte cl,[edi]
            mov byte [edi],'0'
            chartobin cl
            add ch,cl
            cmp ch,4
            jl .step
            jmp .checkfour
        .step:     
            nextnotzero calclink2       ;need more bytes, call nextnotzero
            cmp byte [yflag],1
            je .divremainder
            jmp .divloop
        .checkfour:                     ;check if we can keep removing links, else calc remainder
            cmp ch,4
            jge .removelink
            jmp .divloop
        .removelink:
            cmp dword [link],0           ;x reached 0, create empty list and push to stack
            je .emptylist
            sub ch,4
            removefirst link            ;link is the copy of calclink1
            jmp .checkfour
        .divremainder:                   ;divideby2 logic applied here (Bitwise right shift)
            cmp ch,0
            je .endshiftdown
            divideby2 link
            dec ch
            jmp .divremainder
        .emptylist:                     ;creates an "empty list" meaning a list with a value of zero
            mov cl,'0'
            addfirst cl
        .endshiftdown:                  ;mem clean and push to stack
            spush link
            mov dword [calclink1],esi
            mov dword [calclink2],edi
            removelist calclink1
            removelist calclink2
            mov dword [y],0    
        popad
        jmp fmsg
        
   senderro:
        write 2,erro,48
        newline 2
        jmp fmsg
        
    senderrof:
        write 2,errof,13
        newline 2
        jmp fmsg
        
	senderrs:
        write 2,errs,29
        newline 2
        jmp fmsg


