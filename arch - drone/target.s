section .data       
section .bss
section .rodata
section .text                 
        extern y2
        extern x2
        extern co_scheduler
        extern resume
        global createTarget
        extern createloc
        extern locX
        extern locY
        
                createTarget:
                    call createloc
                    mov dword eax, [locX]
                    mov dword [x2],eax
                    mov dword eax,[locY]
                    mov dword [y2], eax
                    
                    mov ebx, co_scheduler
                    call resume
                    jmp createTarget
