        section .text
        global findimg
findimg:
        push    ebp
        mov	ebp, esp
        sub	esp, 32         ; [ebp-4] width_diff
                                ; [ebp-8] height_diff
                                ; [ebp-12] current_x
                                ; [ebp-16] current_y
                                ; [ebp-20] current_x_offset
                                ; [ebp-24] current_y_offset
                                ; [ebp-28] new_row_mask


        push	ebx
        push	esi
        push	edi

        mov	eax, [ebp+8]    ; [ebp+8] void *img
        mov	ecx, [ebp+12]   ; [ebp+12] uint32_t width
        mov	edx, [ebp+16]   ; [ebp+16] uint32_t height
                                ; [ebp+20] uint32_t stride
        mov	ebx, [ebp+24]   ; [ebp+24] void* to_find
                                ; [ebp+28] uint32_t to_find_width
                                ; [ebp+32] to_find_height
                                ; [ebp+36] to_find_stride
                                ; [ebp+40] uint32_t *x
                                ; [ebp+44] uint32_t *y
        sub	ecx, [ebp+28]       ; width_diff = width - to_find_width
        mov	[ebp-4], ecx        ; [ebp-4] uint32_t width_diff
        sub	edx, [ebp+32]       ; height_diff = height - to_find_height
        mov	[ebp-8], edx        ; [ebp-8] uint32_t height_diff

        mov	dword[ebp-12], 0       ; [ebp-12] uint32_t current_x
        mov	dword[ebp-16], 0       ; [ebp-16] uint32_t current_y
load:
        mov     edi, [ebp-12]       ; current_x
        shr	edi, 3              ; current_x / 8 = number of bytes to move
        mov	ecx, dword[eax+edi] ; load 32 bits of main image data
        mov     dword[ebp-28], 0x1       ; reset new_row_mask
        mov     esi, dword[ebx]    ; load 32 bits of to_find image data

check_pixel:
        mov     edi, [ebp-12]      ; current_x
        cmp	edi, [ebp-4]       ; current_x < width_diff
        jae	next_row

        mov     edi, ecx           ; copy main image data to edi
        and     edi, [ebp-28]      ; apply mask to main image data
        mov     edx, esi           ; copy to_find image data to edx
        and     edx, [ebp-28]      ; apply mask to sub image data
        cmp     edi, edx           ; compare the two pixels
        jz     check_match        ; if equal, start checking the entire image
        inc     dword[ebp-12]           ; current_x++
        shl     dword[ebp-28], 1   ; shift the mask to the left
        jz      load               ; if mask is 0, load new data
        jmp     check_pixel
check_match:
        ; Save current_x to *x
        mov     edi, [ebp-12]         ; Load current_x into EDI
        mov     eax, [ebp+40]         ; Load x pointer into EAX
        mov     [eax], edi            ; Store current_x at *x

        ; Save current_y to *y
        mov     edi, [ebp-16]         ; Load current_y into EDI
        mov     eax, [ebp+44]         ; Load y pointer into EAX
        mov     [eax], edi            ; Store current_y at *y

        ; Indicate success (assuming eax is return value)
        mov     eax, 0                ; Set return value to 0 (success)
        jmp     end

next_row:
        inc     dword[ebp-16]           ; current_y++
        mov     edi, [ebp-16]
        cmp	edi, [ebp-8]       ; current_y < height_diff
        jae	not_found

        mov	dword[ebp-12], 0     ; current_x = 0
        add     eax, [ebp+20]    ; move to the next row of main image (add stride)
        jmp	load

not_found:
        mov     eax, 1
end:

        pop	edi
        pop	esi
        pop	ebx

        mov	esp, ebp
        pop	ebp
        ret