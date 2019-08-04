section .data                    	; we define (global) initialized variables in .data section
        drone_coSize    equ 24      ;drone co-routine struct size

section .bss
        extern co_arr
section .rodata
section .text                    	; we write code in .text section

        
        extern currId
        extern numDrone
        extern k
        extern numStep
        extern co_printer
        extern resume
        global scheduler
        scheduler:
            mov dword ecx,[numStep]
            cmp dword ecx, [k]
            je sprinter
            drone_co:
                mov dword  ecx,[numDrone]
                xor eax,eax
                mov dword eax, [currId]
                inc eax
                cmp eax,ecx
                jl drone_loop
                xor eax, eax
            drone_loop:
                mov dword [currId],eax
                mov dword ebx,[co_arr]
                mov dword edi, drone_coSize
                mul edi
                add ebx, eax        ;co arr + currId * drone routine size)
                inc dword [k]
                call resume
                jmp scheduler
        
        
            sprinter:
                mov dword [k],0
                mov ebx ,dword co_printer
                call resume
                jmp drone_co
