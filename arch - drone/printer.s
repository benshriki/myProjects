section .data                    	; we define (global) initialized variables in .data section
        
        
        STKSZ	    equ	16*1024     ;co-routine stack size
        CODEP	    equ	0           ;co_arr[id]+CODEP holds code pointer
        SPP	        equ	4           ;co_arr[id]+spp holds stack pointer
        cord_X        equ 8         ;co_arr[id]+cord_X holds drone/target X's location
        cord_Y        equ 12        ;co_arr[id]+cord_Y holds drone/target Y's location
        drone_alpha    equ 16       ;co_arr[id]+drone_alpha holds drone ALPHA 
        targetcounter   equ 20
        drone_coSize    equ 24      ;drone co-routine struct size
        stkp: dd 0
        
        section .bss
section .rodata
        format_printer: db "%d,%.2f,%.2f,%.2f,%d",10, 0	;
        format_printer_t: db "%.2f,%.2f", 10, 0
section .text                    	; we write code in .text section
	extern oneighty
        extern co_arr
        extern numDrone
        extern k
        extern x2
        extern y2
        extern co_scheduler
        extern resume
        global printer
        extern printf

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

    printer:	
        ;print target
	;finit

        sub esp,8           ;for printing float, need to test
	fld dword [y2]
        fstp qword [esp]

        sub esp,8           ;for printing float, need to test
	fld dword [x2]
        fstp qword [esp]

        push format_printer_t
        call printf
        add esp,20          ;reset esp (x(8)+y(8)+format(4))
       
        mov dword ebx ,[co_arr]
        xor esi,esi
        loop:
	    finit
            mov ecx, dword [numDrone]
            cmp esi,ecx
            jge .done
            mov eax,esi
            mov dword edi,drone_coSize
            mul edi
            add ebx,eax
            call print_drone
            inc esi
            jmp loop
        .done:
            mov dword ebx, co_scheduler
            call resume
            jmp printer
        

        
        
        ;target->alpha->y->x->id->format
        print_drone:
            pushad
            pushfd
            mov dword [stkp],esp
            mov dword ecx,[ebx+targetcounter]
            push ecx
            mov dword ecx,[ebx+drone_alpha]
            push ecx
            mov dword ecx,[ebx+cord_Y]
            push ecx
            mov dword ecx,[ebx+cord_X]
            push ecx

            push esi
            push format_printer
            call printf
            mov dword esp,[stkp]
            popfd
            popad
            ret
            
