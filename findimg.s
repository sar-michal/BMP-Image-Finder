        section .text
        global findimg
findimg:
        push ebp
        mov ebp, esp

        push ebx
        push esi
        push edi

        mov eax, [ebp+8]    ; void *img
        mov ecx, [ebp+12]   ; uint32_t width
        mov edx, [ebp+16]   ; uint32_t height
        mov ebx, [ebp+20]   ; uint32_t stride
        mov esi, [ebp+24]   ; void* to_find
        mov edi, [ebp+28]   ; uint32_t to_find_width

        pop edi
        pop esi
        pop ebx

        mov esp, ebp
        pop ebp
        ret