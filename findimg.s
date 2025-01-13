        section .text
        global findimg
findimg:
        push    ebp
        mov	ebp, esp
        sub	esp, 40         ; [ebp-4] width_diff
                                ; [ebp-8] height_diff
                                ; [ebp-12] current_x
                                ; [ebp-16] current_y
                                ; [ebp-20] current_x_offset
                                ; [ebp-24] current_y_offset
                                ; [ebp-28] new_row_mask
                                ; [ebp-32] main image curent_y_offset in bytes
                                ; [ebp-36] current main image mask
                                ; [ebp-40] current to_find image mask

        push	ebx
        push	esi
        push	edi

        mov	eax, [ebp+8]    ; [ebp+8] void *img
        mov	ecx, [ebp+12]   ; [ebp+12] uint32_t width
        mov	edx, [ebp+16]   ; [ebp+16] uint32_t height
                                ; [ebp+20] uint32_t stride
                                ; [ebp+24] void* to_find
                                ; [ebp+28] uint32_t to_find_width
                                ; [ebp+32] uint32_t to_find_height
                                ; [ebp+36] uint32_t to_find_stride
                                ; [ebp+40] uint32_t *x
                                ; [ebp+44] uint32_t *y

        sub	ecx, [ebp+28]       ; width_diff = width - to_find_width
        mov	[ebp-4], ecx        ; [ebp-4] uint32_t width_diff
        sub	edx, [ebp+32]       ; height_diff = height - to_find_height
        mov	[ebp-8], edx        ; [ebp-8] uint32_t height_diff

        mov	dword[ebp-12], 0       ; [ebp-12] uint32_t current_x
        mov	dword[ebp-16], 0       ; [ebp-16] uint32_t current_y
        mov     dword[ebp-28], 0x80000000       ; new_row_mask
        jmp     start
reset_parameters:
        inc     dword[ebp-12]      ; current_x++
        shr     dword[ebp-28], 1   ; shift the mask to the right
        jnz      start
        mov     dword[ebp-28], 0x80000000       ; reset new_row_mask
start:
        mov	dword[ebp-20], 0       ; [ebp-20] uint32_t current_x_offset
        mov	dword[ebp-24], 0       ; [ebp-24] uint32_t current_y_offset
        mov     dword[ebp-32], 0       ; [ebp-32] uint32_t main image curent_y_offset in bytes
        mov	ebx, [ebp+24]      ; [ebp+24] void* to_find
        mov     esi, dword[ebx]    ; load 32 bits of to_find image data
        bswap   esi                ; reverse the byte order
        mov     dword[ebp-40], 0x80000000       ; current to_find image mask

        mov     edx, esi           ; copy to_find image data to edx
        and     edx, [ebp-40]      ; apply mask to sub image data
        test    edx, edx           ; check if the pixel is 0
        setnz   dl                ; set dl to 1 if the pixel is not 0
load:
        mov     edi, [ebp-12]       ; current_x
        shr	edi, 5              ; current_x / 8 = number of bytes to move
        shl     edi, 2              ; multiply by 4 to get the correct offset
        mov	ecx, dword[eax+edi] ; load 32 bits of main image data
        bswap   ecx                ; reverse the byte order

check_pixel:
        mov     edi, [ebp-12]      ; current_x
        cmp	edi, [ebp-4]       ; current_x < width_diff
        ja	next_row

        mov     edi, ecx           ; copy main image data to edi
        and     edi, [ebp-28]      ; apply mask to main image data
        test    edi, edi           ; check if the pixel is 0
        setnz   dh                ; set dh to 1 if the pixel is not 0

        cmp     dl, dh           ; compare the two pixels
        jz      initialize_full_check    ; if equal, start checking the entire image

        inc     dword[ebp-12]      ; current_x++
        shr     dword[ebp-28], 1   ; shift the mask to the right
        jnz     check_pixel               ; if mask is not 0, continue checking
        mov     dword[ebp-28], 0x80000000       ; reset new_row_mask
        jmp     load
initialize_full_check:
        mov     edi, [ebp-28]    ; load new_row_mask
        mov     dword[ebp-36], edi      ; reset mask to new_row_mask
full_check_load:
        mov     edi, [ebp-20]       ; current_x_offset
        shr     edi, 5              ; current_x_offset / 32 = number of 4B to move
        shl     edi, 2              ; multiply by 4 to get the correct offset in bytes (rounded down)
        mov     esi, dword[ebx+edi]    ; load 32 bits of to_find image data
        bswap   esi                ; reverse the byte order

        mov     edi, [ebp-20]       ; current_x_offset
        add     edi, [ebp-12]       ; current_x_offset + current_x
        shr	edi, 5              ; total_x / 8 = number of bytes to move
        shl     edi, 2              ; multiply by 4 to get the correct offset
        add     edi, [ebp-32]       ; add current_y_offset in bytes
        mov	ecx, dword[eax+edi] ; load 32 bits of main image data
        bswap   ecx                ; reverse the byte order

full_check_pixel:
        mov     edi, [ebp-20]      ; current_x_offset
        cmp	edi, [ebp+28]      ; current_x_offset < to_find_width
        jae	full_check_next_row

        mov     edx, esi           ; copy to_find image data to edx
        and     edx, [ebp-40]      ; apply mask to sub image data
        test    edx, edx           ; check if the pixel is 0
        setnz   dl                ; set dl to 1 if the pixel is not 0

        mov     edi, ecx           ; copy main image data to edi
        and     edi, [ebp-36]      ; apply mask to main image data
        test    edi, edi           ; check if the pixel is 0
        setnz   dh                ; set edi to 1 if the pixel is not 0

        cmp     dl, dh           ; compare the two pixels
        jnz     reset_parameters    ; if not equal, end checking

        inc     dword[ebp-20]      ; current_x_offset++
        shr     dword[ebp-40], 1   ; shift the to_find image mask to the right
        jnz     check_main_mask

        mov     dword[ebp-40], 0x80000000 ; if mask is 0, reset it
        mov     edi, [ebp-20]       ; current_x_offsetd
        shr     edi, 5              ; current_x_offset / 32 = number of 4B to move
        shl     edi, 2              ; multiply by 4 to get the correct offset in bytes (rounded down)
        mov     esi, dword[ebx+edi]    ; load 32 bits of to_find image data
        bswap   esi                ; reverse the byte order
check_main_mask:
        shr     dword[ebp-36], 1   ; shift the main image mask to the right
        jnz     full_check_pixel
        mov     dword[ebp-36], 0x80000000 ; if mask is 0, reset it
        jmp     full_check_load  
        

image_found:
        mov     edi, [ebp-12]         ; Load current_x into EDI
        mov     eax, [ebp+40]         ; Load x pointer into EAX
        mov     [eax], edi            ; Store current_x at *x

        mov     edi, [ebp+16]         ; Load main image height into EDI
        sub     edi, [ebp-16]         ; Subtract current_y from height
        sub     edi, [ebp+32]         ; Subtract to_find_height from the result
        mov     eax, [ebp+44]         ; Load y pointer into EAX
        mov     [eax], edi            ; Store current_y at *y

        mov     eax, 0                ; Set return value to 0 (success)
        jmp     end
full_check_next_row:
        inc     dword[ebp-24]           ; current_y_offset++
        mov     edi, [ebp-24]           ; load current_y_offset into edi
        cmp	edi, [ebp+32]       ; current_y_offset < to_find_height
        jae	image_found                 ; image found

        mov	dword[ebp-20], 0     ; current_x_offset = 0
        mov     ecx, [ebp+20]       ; load stride into ecx
        add     dword[ebp-32], ecx      ; increment main image current_y_offset in bytes
        add     ebx, [ebp+36]    ; move to the next row of to_find image (add to_find_stride)
        mov     dword[ebp-40], 0x80000000       ; reset to_find image mask
        jmp	initialize_full_check

next_row:
        inc     dword[ebp-16]           ; current_y++
        mov     edi, [ebp-16]
        cmp	edi, [ebp-8]       ; current_y < height_diff
        ja	not_found

        mov	dword[ebp-12], 0     ; current_x = 0
        add     eax, [ebp+20]    ; move to the next row of main image (add stride)
        mov     dword[ebp-28], 0x80000000       ; reset new_row_mask
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