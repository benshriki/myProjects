section .data                    	; we define (global) initialized variables in .data section
        global k
        global LFSR
        global x1
        global y1
        global alpha
        global currDestroyed
        global x2
        global y2
        global maxint
        global scale_from
        global scale_to
        global scale
        global startCo
        global locX
        global locY
        ;function return values:
                scale_from: dd 0.0
                scale_to: dd 0.0

        ;drone variables:
                x1: dd 0           ;drone's X's location
                y1: dd 0           ;drone's Y's location
                alpha: dd 0.0       ;drone's direction
                currDestroyed: dd 0.0 ;drone's target counter
                tmp: dd 0.0
               
        ;target location:
                x2: dd 0
                y2: dd 0        
        
        
                locX: dd 0
                locY:dd 0
        ;compution  and fix variables
                LFSR: dd 0          ;used to create random numbers
                k: dd 0
                maxint: dd 65535    ;the max int that LFSR random can return

        ;co-routines:

        STKSZ	    equ	16*1024     ;co-routine stack size
        CODEP	    equ	0           ;co_arr[id]+CODEP holds code pointer
        SPP	    equ 4           ;co_arr[id]+spp holds stack pointer
        cord_X      equ 8         ;co_arr[id]+cord_X holds drone/target X's location
        cord_Y      equ 12        ;co_arr[id]+cord_Y holds drone/target Y's location
        drone_alpha    equ 16       ;co_arr[id]+drone_alpha holds drone ALPHA 
        targetcounter   equ 20
        drone_coSize    equ 24      ;drone co-routine struct size
        
        global co_arr
        global currId
        global co_scheduler
        global co_target
        global co_printer
       
       
        co_arr: dd 0        ;will hold a pointer to co-routine array
        
        currId: dd -1        ;drone's id
        
        co_target:
                dd 0        ;co_target+CODEP
                dd 0        ;co_target +SPP
        co_printer:
                dd 0        ;co_printer+CODEP
                dd 0        ;co_printer+SPP        
        co_scheduler:
                dd 0        ;co_scheduler+CODEP
                dd 0        ;co_scheduler+SPP       
    
    %macro get_num_between 2
        pushfd
        pushad
        call random
        mov dword [scale_to],%2
        mov dword [scale_from], %1
        call scale
        popad
        popfd
    %endmacro
    
    %macro handleArgs 3
        push %3           
        push %2           
        push dword %1     
        call sscanf
        add esp, 12       
    %endmacro
        
section .bss
    ;arguments:
    global numDrone
    global numTarget
    global numStep
    global beta
    global numDist
    global seed
        numDrone: resd 1
        numTarget: resd 1
        numStep: resd 1
        beta: resd 1 ;0-360
        numDist: resd 1
        seed: resb 2 ;16 bit
        STKPT: resd 1 ;save main esp
        curr_co: resd 1; address of current co-routine
        counter: resd 1
        mallocadress: resd 1
        mallocbytes: resd 1
section .rodata
    ;printing formats: 
        format_string: db "%lf", 10, 0	; long float
        format_string_d: db "%d", 10, 0	; digit
        format_string_e: db "%e", 10, 0	; for testing
        
        format_int: db "%d"
        format_f: db "%f"
        format_s: db "%s",10,0
        
        
        winnerMsg: dq "Drone id %d: I am a winner",10,0    ;winner


section .text                    	; we write code in .text section
        global main          		; 'global' directive causes the function do_Str(...) to appear in global 
        global resume
        extern printf            	; 'extern' directive tells linker that printf(...) function is defined 
        extern fprintf
        extern droneCo 	
        extern malloc
        extern printer
        extern scheduler
        extern createTarget
        extern sscanf
        global createloc
 	
 	main:			
	_start:
        
        push ebp              		; save Base Pointer (bp) original value
        mov ebp, esp         		; use Base Pointer to access stack contents (do_Str(...) activation frame)
        pushad                   	; push all signficant registers onto stack (backup registers values)
        

        read_arguments:
            mov ebx, [ebp+12] ;ebx holds argv[]
            handleArgs [ebx+4], format_int, numDrone ; [ebx+4] = arv[1]
            handleArgs [ebx+8], format_int, numTarget ; [ebx+8] = arv[2]
            handleArgs [ebx+12], format_int, numStep ; [ebx+12] = arv[3]
            handleArgs [ebx+16], format_f, beta ; [ebx+16] = arv[4]
            handleArgs [ebx+20], format_f, numDist ; [ebx+20] = arv[5]
            handleArgs [ebx+24], format_int, seed ; [ebx+24] = arv[6]
            mov word ax, [seed]
            mov word [LFSR],ax
                
    

            init_printer:;create co_printer
                mov dword ebx, co_printer
                mov dword esi,printer 
                call init_s_co
                
            init_scheduler:;create co_scheduler
                mov dword ebx, co_scheduler
                mov dword esi,scheduler
                call init_s_co
                
            init_target:   ;create co_target
                mov dword ebx, co_target
                mov dword esi,createTarget
                call init_s_co
                call createloc
                mov dword eax, [locX]
                mov dword [x2],eax
                mov dword eax,[locY]
                mov dword [y2], eax
            
            
    init_co_arr:
            mov eax,dword [numDrone]
            mov ecx, drone_coSize
            mul ecx
            mov dword [mallocbytes],eax
            call make_room
            mov dword ebx,[mallocadress]
            mov dword [co_arr],ebx
            
            make_Drone_co_struct:
                mov dword esi,[co_arr]
                add esi, eax
                .loop:
                cmp ebx,esi
                je startCo
                mov dword [ebx+CODEP] , droneCo
                call make_stk                       ;create routine stack
                mov dword edi,[mallocadress]
                add edi, STKSZ
                mov dword [ebx+SPP],edi             
                                                    ;initialize drone variables 
                call createloc                    ;initialize drone location
                mov dword edi, [locX]
                mov dword [ebx+cord_X],edi
                mov dword edi,[locY]
                mov dword [ebx+cord_Y],edi
                
                call createAlpha                    ;initialize drone alpha
                mov edi,[alpha]
                mov dword [ebx+drone_alpha],edi
                
                mov dword [ebx+targetcounter],0     ;initialize drone score
               
               
                mov dword [STKPT],esp
                mov dword esp, [ebx+SPP]
                mov dword                                                                                                                                                                                    eax, droneCo
                push eax
                pushfd
                pushad
                mov dword [ebx+SPP],esp                                                                                                                                                                                                                                    
                mov dword esp, [STKPT]
                add dword ebx,drone_coSize
                jmp .loop
                
                
            
            
            startCo:
                pushfd
                pushad
                mov dword [STKPT],esp
                mov ebx,co_scheduler
                jmp do_resume
                
                resume:
                    pushfd
                    pushad
                    mov dword edx,[curr_co]
                    mov dword [edx+SPP],esp
                do_resume:
                    mov dword esp,[ebx+SPP]
                    mov dword [curr_co],ebx
                    popad
                    popfd
                    ret
                    

    random:                             ;working 100%
            pushad
            pushfd
            xor eax,eax
            xor ebx,ebx                     ;16' bit =>bl 14'bit=>bh 
            xor ecx, ecx                     ;13'bit=>cl 11'bit=>ch
            mov word ax,[LFSR]
            shr ax,1
            jc bit16
            set14:
                shr ax,2
                jc bit14
            set13:
                shr ax,1
                jc bit13
            set11:
                shr ax,2
                jc bit11
                jmp xors
            bit16:
                mov byte bl,1
                jmp set14
            bit14:
                mov byte bh,1
                jmp set13
            bit13:
                mov byte cl,1
                jmp set11
            bit11:
                mov byte ch,1
            
            xors:
            xor bl,bh                             ;xor 16b and 14b bl=>result
            xor bl,cl                             ;xor result and 13b bl=>result
            xor bl,ch                             ;xor result and 11b bl=>result
            mov word ax,[LFSR]
            cmp bl,0
            je insertzero
            shr ax,1
            mov word bx,32768 ;1000000000000000b
            or ax,bx
            jmp endrandom
            insertzero:
                shr ax,1
                jmp endrandom
                
            endrandom:
                mov word [LFSR],ax
                popfd
                popad
                ret
                
    
        init_s_co:
            mov dword [ebx+CODEP],esi
            mov dword [STKPT],esp
            call make_stk
            mov dword edi, [mallocadress]
            add dword edi, STKSZ
            mov dword [ebx + SPP],edi
            
            mov eax, [ebx+CODEP]
            mov dword esp,[ebx+SPP]
            push esi ;was eax
            pushfd
            pushad
            mov dword [ebx+SPP],esp
            mov dword esp,[STKPT]
            ret

            
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

        createAlpha:
                    pushad
                    pushfd
                    get_num_between 0,360
                    fstp dword [alpha]
                    popfd
                    popad
                    ret
        
        createloc:
                    pushad
                    pushfd
                    get_num_between 0,100 
                    fstp dword [locX]
                    get_num_between 0,100 
                    fstp dword [locY]
                    popfd
                    popad
                    ret
        scale:
            pushad 
            pushfd 
            finit 
            fild dword [scale_to]
            fild dword [scale_from]
            fsubp           ; to - from
            fild dword [maxint] ; ((to-from)*LFSR)/maxint =ans
            fdivp
            fild dword [LFSR]; (to-from)*LFSR
            fmulp
            fild dword [scale_from]
            faddp           ;from+ans
            popfd
            popad	
            ret

        make_room:
            pushfd
            pushad
            mov dword ecx, [mallocbytes]
            push ecx
            call malloc
            mov dword [mallocadress],eax
            pop ecx
            popad
            popfd
            ret
            
        make_stk:
            pushfd
            pushad
            mov dword eax, STKSZ
            mov dword [mallocbytes],eax
            call make_room
            popad
            popfd
            ret
            
