        section .text
        global findimg64
findimg64:
        push    rbp
        mov	rbp, rsp
        sub	rsp, 48         ; [rbp-4] width_diff
                                ; [rbp-8] height_diff
                                ; [rbp-12] current_x
                                ; [rbp-16] current_y
                                ; [rbp-20] current_x_offset
                                ; [rbp-24] current_y_offset
                                ; [rbp-28] new_row_mask
                                ; [rbp-32] main image curent_y_offset in bytes
                                ; [rbp-36] current main image mask
                                ; [rbp-40] current to_find image mask

        push	rbx
        push	r12
        push	r13
        push	r14
        push	r15

        xor     r13, r13
        mov	rax, rdi    ; rdi = void *img
        mov	r10d, esi   ; r12d = uint32_t width
        mov	r11d, edx   ; r11d = uint32_t height
                                ; r10d = uint32_t stride
                                ; r8 = void* to_find
                                ; r9 = uint32_t to_find_width
                                ; [rbp+16] (+16) uint32_t to_find_height
                                ; [rbp+24] (+24) uint32_t to_find_stride
                                ; [rbp+32] (+32) uint32_t *x
                                ; [rbp+40] (+40) uint32_t *y

        sub	r10d, r9d       ; width_diff = width - to_find_width
        mov	[rbp-4], r10d        ; [rbp-4] uint32_t width_diff
        sub	r11d, [rbp+16]       ; height_diff = height - to_find_height
        mov	[rbp-8], r11d        ; [rbp-8] uint32_t height_diff

        mov	dword[rbp-12], 0       ; [rbp-12] uint32_t current_x
        mov	dword[rbp-16], 0       ; [rbp-16] uint32_t current_y
        mov     dword[rbp-28], 0x80000000       ; new_row_mask
        jmp     start
reset_parameters:
        inc     dword[rbp-12]      ; current_x++
        shr     dword[rbp-28], 1   ; shift the mask to the right
        jnz      start
        mov     dword[rbp-28], 0x80000000       ; reset new_row_mask
start:
        mov	dword[rbp-20], 0       ; [rbp-20] uint32_t current_x_offset
        mov	dword[rbp-24], 0       ; [rbp-24] uint32_t current_y_offset
        mov     dword[rbp-32], 0       ; [rbp-32] uint32_t main image curent_y_offset in bytes
        mov	rbx, r8      ; r8 void* to_find
        mov     r12d, dword[rbx]    ; load 32 bits of to_find image data
        bswap   r12d                ; reverse the byte order
        mov     dword[rbp-40], 0x80000000       ; current to_find image mask

        mov     r11d, r12d           ; copy to_find image data to r11d
        and     r11d, [rbp-40]      ; apply mask to sub image data
        test    r11d, r11d           ; check if the pixel is 0
        setnz   r15b                ; set r15b to 1 if the pixel is not 0
load:
        mov     r13d, [rbp-12]       ; current_x
        shr	r13d, 5              ; current_x / 8 = number of bytes to move
        shl     r13d, 2              ; multiply by 4 to get the correct offset
        mov	r10d, dword[rax+r13] ; load 32 bits of main image data
        bswap   r10d                ; reverse the byte order

check_pixel:
        mov     r13d, [rbp-12]      ; current_x
        cmp	r13d, [rbp-4]       ; current_x < width_diff
        ja	next_row

        mov     r13d, r10d           ; copy main image data to r13d
        and     r13d, [rbp-28]      ; apply mask to main image data
        test    r13d, r13d           ; check if the pixel is 0
        setnz   r14b                ; set r14b to 1 if the pixel is not 0

        cmp     r15b, r14b           ; compare the two pixels
        jz      initialize_full_check    ; if equal, start checking the entire image

        inc     dword[rbp-12]      ; current_x++
        shr     dword[rbp-28], 1   ; shift the mask to the right
        jnz     check_pixel               ; if mask is not 0, continue checking
        mov     dword[rbp-28], 0x80000000       ; reset new_row_mask
        jmp     load
initialize_full_check:
        mov     r13d, [rbp-28]    ; load new_row_mask
        mov     dword[rbp-36], r13d      ; reset mask to new_row_mask
full_check_load:
        mov     r13d, [rbp-20]       ; current_x_offset
        shr     r13d, 5              ; current_x_offset / 32 = number of 4B to move
        shl     r13d, 2              ; multiply by 4 to get the correct offset in bytes (rounded down)
        mov     r12d, dword[rbx+r13]    ; load 32 bits of to_find image data
        bswap   r12d                ; reverse the byte order

        mov     r13d, [rbp-20]       ; current_x_offset
        add     r13d, [rbp-12]       ; current_x_offset + current_x
        shr	r13d, 5              ; total_x / 8 = number of bytes to move
        shl     r13d, 2              ; multiply by 4 to get the correct offset
        add     r13d, [rbp-32]       ; add current_y_offset in bytes
        mov	r10d, dword[rax+r13] ; load 32 bits of main image data
        bswap   r10d                ; reverse the byte order

full_check_pixel:
        mov     r13d, [rbp-20]      ; current_x_offset
        cmp	r13d, r9d      ; current_x_offset < to_find_width
        jae	full_check_next_row

        mov     r11d, r12d           ; copy to_find image data to r11d
        and     r11d, [rbp-40]      ; apply mask to sub image data
        test    r11d, r11d           ; check if the pixel is 0
        setnz   r15b                ; set r15b to 1 if the pixel is not 0

        mov     r13d, r10d           ; copy main image data to r13d
        and     r13d, [rbp-36]      ; apply mask to main image data
        test    r13d, r13d           ; check if the pixel is 0
        setnz   r14b                ; set r13d to 1 if the pixel is not 0

        cmp     r15b, r14b           ; compare the two pixels
        jnz     reset_parameters    ; if not equal, end checking

        inc     dword[rbp-20]      ; current_x_offset++
        shr     dword[rbp-40], 1   ; shift the to_find image mask to the right
        jnz     check_main_mask

        mov     dword[rbp-40], 0x80000000 ; if mask is 0, reset it
        mov     r13d, [rbp-20]       ; current_x_offsetd
        shr     r13d, 5              ; current_x_offset / 32 = number of 4B to move
        shl     r13d, 2              ; multiply by 4 to get the correct offset in bytes (rounded down)
        mov     r12d, dword[rbx+r13]    ; load 32 bits of to_find image data
        bswap   r12d                ; reverse the byte order
check_main_mask:
        shr     dword[rbp-36], 1   ; shift the main image mask to the right
        jnz     full_check_pixel
        mov     dword[rbp-36], 0x80000000 ; if mask is 0, reset it
        jmp     full_check_load  
        

image_found:
        mov     r13d, [rbp-12]         ; Load current_x into r13d
        mov     rax, [rbp+32]         ; Load x pointer into rax
        mov     [rax], r13d            ; Store current_x at *x

        mov     r13d, edx         ; Load main image height into r13d
        sub     r13d, [rbp-16]         ; Subtract current_y from height
        sub     r13d, [rbp+16]         ; Subtract to_find_height from the result
        mov     rax, [rbp+40]         ; Load y pointer into rax
        mov     [rax], r13d            ; Store current_y at *y

        mov     rax, 0                ; Set return value to 0 (success)
        jmp     end
full_check_next_row:
        inc     dword[rbp-24]           ; current_y_offset++
        mov     r13d, [rbp-24]           ; load current_y_offset into r13d
        cmp	r13d, [rbp+16]       ; current_y_offset < to_find_height
        jae	image_found                 ; image found

        mov	dword[rbp-20], 0     ; current_x_offset = 0
        mov     r10d, ecx       ; load stride into r10d
        add     dword[rbp-32], r10d      ; increment main image current_y_offset in bytes
        add     rbx, [rbp+24]    ; move to the next row of to_find image (add to_find_stride)
        mov     dword[rbp-40], 0x80000000       ; reset to_find image mask
        jmp	initialize_full_check

next_row:
        inc     dword[rbp-16]           ; current_y++
        mov     r13d, [rbp-16]
        cmp	r13d, [rbp-8]       ; current_y < height_diff
        ja	not_found

        mov	dword[rbp-12], 0     ; current_x = 0
        add     rax, rcx    ; move to the next row of main image (add stride)
        mov     dword[rbp-28], 0x80000000       ; reset new_row_mask
        jmp	load

not_found:
        mov     rax, 1
end:
        pop	r15
        pop	r14
        pop	r13
        pop	r12
        pop	rbx

        mov	rsp, rbp
        pop	rbp
        ret