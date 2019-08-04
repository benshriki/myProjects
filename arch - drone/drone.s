section .data                    	; we define (global) initialized variables in .data section
        ;function return values:
                destroy:db 0        ;mayDestroy return value-> 1- drone can destroy target,0- drone can't destroy target
                isdist: db 0        ;checkdist return value-> 1-  drone is near target,0- otherwise
                isang: db 0         ;checkangs return value -> 1- target in "view range", 0-otherwise
                isQneg: db 0        ;isneg and isnegT return value-> 1- value is negative number, 0- otherwise

                
        ;drone variables:
                gamma: dd 0.0       ;drone's "view range"?????????????????????????????????????????????????????
               
               
        ;compution  and fix variables
                global oneighty
                comptopi: dd 0.0    ;used in checkangs
                outputang: dd 0.0   ;used in checkangs
                dDist:dd 0          ;delta distance
                hundred: dd 100.0
                oneighty: dd 180.0  ;180 helps to calc in randians
                tsixty: dd 360.0
                tmpint: dd 0        ;used to help calculations
                holddist: dd 0.0    ;used to help calculations
                holdangle: dd 0.0   ;used to help calculations
                deltax: dd 0   
                deltay: dd 0
                deltalpha: dd 0.0


        STKSZ	    equ	16*1024     ;co-routine stack size
        CODEP	    equ	0           ;co_arr[id]+CODEP holds code pointer
        SPP	        equ	4           ;co_arr[id]+spp holds stack pointer
        cord_X        equ 8         ;co_arr[id]+cord_X holds drone/target X's location
        cord_Y        equ 12        ;co_arr[id]+cord_Y holds drone/target Y's location
        drone_alpha    equ 16       ;co_arr[id]+drone_alpha holds drone ALPHA 
        targetcounter   equ 20
        drone_coSize    equ 24      ;drone co-routine struct size
        
        
        
    %macro isnegT 1
        pushad
        pushfd
        mov byte [isQneg],0
        mov eax,dword [%1+6]
        shl eax,1
        jnc %%exitisneg
        inc byte [isQneg]
        %%exitisneg:
            popfd
            popad
    %endmacro
    
    %macro isneg 1
        pushad
        pushfd
        mov byte [isQneg],0
        mov eax,dword [%1]
        shl eax,1
        jnc %%exitisneg
        inc byte [isQneg]
        %%exitisneg:
            popfd
            popad
    %endmacro
    
    %macro convtoAng 1
        pushad
        pushfd
        fld dword [oneighty]
        fldpi
        fdivp
        fld dword [%1]
        fmulp
        fstp dword [%1] ; result in alpha is now in radians (comment code above for degrees)
        popfd
        popad
    %endmacro
    
    %macro convtoRad 1
        pushad
        pushfd
        fldpi
        fld dword [oneighty]
        fdivp
        fld dword [%1]
        fmulp
        fstp dword [%1] ; result in alpha is now in radians (comment code above for degrees)
        popfd
        popad
    %endmacro
    
    %macro get_num_between 2
        pushfd
        pushad
        call random
        mov dword [scale_to],%2
        mov dword [scale_from], %1
        call scale
        popfd
        popad
    %endmacro
        
section .bss

section .rodata
    ;printing formats: 
        format_string: db "%Lf", 10, 0	; long float
        format_string_d: db "%d", 10, 0	; digit
        format_string_e: db "%e", 10, 0	; for testing
        winnerMsg: db "Drone id %d: I am a winner",10,0    ;winner


section .text                    	; we write code in .text section
        global droneCo
        extern random
        extern makeTarget
        extern currDestroyed
        extern currId
        extern alpha
        extern beta
        extern x1
        extern x2
        extern y1
        extern y2
        extern numTarget
        extern co_arr
        extern co_scheduler
        extern co_target
        extern resume
        extern LFSR
        extern maxint
        extern numDist
        extern scale
        extern  scale_from
        extern scale_to
        extern printf
        
        
        schedulerR:
        mov ebx, dword co_scheduler
        call resume
        
        droneCo:

                mov dword ebx,[co_arr]
                mov dword eax,[currId];******************
                mov dword edi, drone_coSize
                mul edi
                add dword ebx,eax       ; drone_coSize
                mov dword eax, [ebx+cord_X]
                mov dword [x1],eax
                mov dword eax, [ebx+cord_Y]
                mov dword [y1],eax                
                mov dword eax, [ebx+drone_alpha]
                mov dword [alpha],eax
                mov dword eax, [ebx+targetcounter]
                mov dword [currDestroyed],eax                
                call calcalpha
                call updatePos
                call mayDestroy
                call rndVal
                cmp byte [destroy],1 ;1 = we an destroy
                jne .dontDestroy
            .destroyTarget:
                mov dword eax,[currDestroyed]
                inc eax
                cmp dword eax, [numTarget]
                jge winner
                mov dword [currDestroyed],eax
                
            ;resume target
                call updatestats
                mov ebx,dword co_target
                call resume
                jmp droneCo
            
            .dontDestroy:
                call updatestats
                jmp schedulerR
                
            
            
        updatestats:
                finit
                mov dword ebx,[co_arr]
                mov dword eax,[currId];******************
                mov dword edi, drone_coSize
                mul edi
                add dword ebx,eax

                mov dword eax,[x1]
                mov dword [ebx+cord_X],eax
                fld dword [ebx+cord_X]  ;test x1

                mov dword eax, [y1]
                mov dword [ebx+cord_Y],eax
                fld dword [ebx+cord_Y]  ;test y1

                mov dword eax, [alpha]
                mov dword [ebx+drone_alpha],eax
                fld dword [ebx+drone_alpha] ;test alpha
        
                ;can test values with tui reg float (values are correct)

                mov dword eax, [currDestroyed]
                mov dword [ebx+targetcounter],eax

                ret

 
 
 
 
 
;check if drone can destroy the target [destroy is local variable]
    mayDestroy:
        pushad
        pushfd
        call calcGamma
        call calcDist
        xor eax ,eax
        mov byte [destroy],0
        call checkdist
        call checkangs
        mov byte al, [isdist]
        mov byte cl, [isang]
        bang1:
        and al,cl
        mov byte [destroy],al
        popfd
        popad
        ret
    
    
    
    
    
    
    checkangs:     ;alpha belongs to drone, gamma calculated in function.
            pushad
            pushfd
            xor eax,eax
            xor ebx,ebx
            xor ecx,ecx
            xor edx,edx
            mov byte [isang],0
        calcang:
            finit
            fld dword [alpha]
            fld dword [gamma]
            bang:
            fsubp
            fabs    ;| alpha - gamma |
            fstp dword [comptopi]
            fld dword [comptopi]
            fld dword [oneighty]
            fcomi
            ja compBeta

            fld dword [gamma]
            fld dword [alpha]
            fcomi
            jb incAlpha

        incGamma:
            fld dword [gamma]
            fld dword [tsixty]
            faddp
            fstp dword [gamma] ;updated alpha
            jmp calcang        ;check again
        
        incAlpha:
            fld dword [alpha]
            fld dword [tsixty]
            faddp
            fstp dword [alpha] ;updated gamma
            jmp calcang         ;check again

        compBeta:
            fld dword [comptopi] ;our ang of attack
            fld dword [beta]    ;allowed ang of attack
            fcomi               ;check ang of attack
            jbe .exit_noAttack
            mov byte [isang],1
            .exit_noAttack:
            popfd
            popad
            ret


        checkdist:
            pushad
            pushfd
            mov dword [isdist],0    ;flag for distance may destroy
            fld dword [y2]
            fld dword [y1]
            fsubp
            fst dword [deltay]
            fmulp               ;[y2] = (y2 - y1)^2
            fld dword [x2]
            fld dword [x1]
            fsubp
            fst dword [deltax]
            fmulp               ;[x2] = (x2 - x1)^2
            faddp               ; [y2] + [x2]
            fsqrt               ;sqrt((y2-y1)^2 + (x2-x1)^2) = DISTANCE
            
            fld dword [holddist]
            fld dword [numDist]
            fcomi
            jbe .exit_noAttack
            mov byte [isdist],1
            .exit_noAttack:
                popfd
                popad
                ret
 
       
       calcGamma:      
            pushad 
            pushfd
            finit
            fld  dword [y2]
            fld dword [y1]
            fsubp
            fld dword [x2]
            fld dword [x1]
            fsubp
            fpatan
            fstp dword [gamma]
            convtoAng gamma
            fld dword [gamma]
            fldz
            fcomi
            jbe .exit
        .isNeg:
            fstp dword [tmpint] ;pop zero
            fld dword [tsixty]
            faddp
            fstp dword [gamma] ; gamma now positive

        .exit:
            fld dword [gamma]
            popfd
            popad
            ret


                    
        calcalpha:
                    pushad
                    pushfd
                    finit
                    get_num_between -60,60           
                    fld  dword [alpha]
                    faddp
            cmpTsixty:
                    fld dword [tsixty]
                    fcomi
                    jae cmpNeg
                    fsubp
                    fldz
                    jmp finishCalc
            cmpNeg:
                    fstp dword [tmpint] ;clear stack
                    fldz
                    fcomi
                    jbe finishCalc
                    fld dword[tsixty]
                    faddp 
                    faddp
                    fldz ;trash element to pop later 
            
            finishCalc:
                    fstp dword [tmpint] ;pop trash
                    fstp dword [alpha] ;updated val
                    popfd
                    popad
                    ret

                        
                        
        calcDist:
                    pushfd
                    pushad
                    get_num_between 0,50
                    fstp dword [dDist]
                    popad
                    popfd
                    ret
                    
        checkTorus:
            pushad
            pushfd
            fld dword [x1] ;updated x before torus
            fld dword [hundred] 
            fcomi
            jae checkXneg ; if x<=100
            fsubp ; 100 - x (will be positive)
            fstp dword [x1] ;updated x (after torus)

            jmp cont_y

        checkXneg:
            fld dword [x1] ;x before torus
            fldz
            fcomi   ; compare x1 to zero
            jbe cont_y ; if x >=0, we continue to y, else add 100 (because it's negative)
            fld dword [hundred]
            faddp ; 0 + 100
            faddp ; x + 100
            fstp dword [x1] ; updated x (after torus)

            jmp cont_y ;for clarity

        cont_y:
            fld dword [y1]
            fld dword [hundred]
            fcomi
            jae checkYneg ; if y<=100, check if it is negative
            fsubp
            fstp dword [y1] ;updated y (after torus)

            jmp checkYneg.exit
        checkYneg:
            finit
            fld dword [y1] ;updated y before torus
            fldz ; st[0] = 0, st[1] = new y loc
            fcomi
            jbe .exit ; if y >= 0
            fld dword [hundred]
            faddp   ;100 + 0
            faddp   ;y + 100
            fstp dword [y1]

            .exit:
            popfd
            popad
            ret


        
        updatePos:
        finit
        fld dword [alpha] ; load alpha
        fsincos ; Compute vectors in y and x 	
        fld dword [dDist]
        fmulp 
        fld dword [x1] 
        faddp 
        fstp dword [x1] 
        fld   dword [dDist]
        fmulp 
        fld dword [y1] 
        faddp 
        fstp dword [y1]
        call checkTorus 
        ret
        
        rndVal:
        finit
        ;convtoAng alpha
        fld dword [alpha]
        ;frndint
        fstp dword [alpha]
        fld dword [x1]
        frndint
        fstp dword [x1]
        fld dword [y1]
        frndint
        
        fstp dword [y1]
        ;fld dword [gamma]
        ;fld dword [x2]
        ;fld dword [y2]
        ret

                
        winner:
            mov eax,[currId]
            push eax
            push winnerMsg
            call printf
            jmp exitClean
       

        exitClean:
            mov eax,1
            mov ebx,0
            mov ecx,0
            mov edx,0
            int 0x80
	
        errorexit:
            ;need to define!
	
	
        popad                    	; restore all previously used registers
        mov esp, ebp			; free function activation frame
        pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
      ;  ret				; returns from do_Str(...) function
        mov eax,1
        mov ebx,0
        mov ecx,0
        mov edx,0
        int 0x80
