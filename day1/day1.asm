global main

extern scanf
extern printf
extern calloc
extern free

buffer_len equ 256
array_len equ 10000

section .bss
    buffer resb buffer_len
    array_a resd array_len
    array_b resd array_len

section .data
load_format db "%u %u",10, 0
print_format db "res: %u ", 10, 0

section   .text
load:
    push rbp 
    mov rbp, rsp

    push rbx

    xor rcx, rcx ; index

    .l_read:
    mov rdi, load_format
    lea rsi, [array_a + rcx * 4]
    lea rdx, [array_b + rcx * 4]
    xor rax, rax ; varargs

    push rcx
    sub rsp, 8
    call scanf ; load numbers
    add rsp, 8
    pop rcx

    inc rcx ; inc index

    cmp rax, 2
    je .l_read ; if we read numbers, we keep reading

    dec rcx ; last read was unsuccessfull

    mov rax, rcx ; return len

    pop rbx

    leave
    ret

; arr = rdi
; len = rsi
bubble_sort:
    push rbp 
    mov rbp, rsp

    push rbx

    dec rsi ; dec len as we will comparing i and j with n-1

    xor rcx, rcx ; i = 0
    .i:
    cmp rcx, rsi ; i < n - 1
    jge .l_leave

    xor rax, rax ; j = 0
    mov rbx, rsi ; rbx = n-1
    sub rbx, rcx ; rbx = n - 1 - i
    .j:
    cmp rax, rbx ; j < n - 1 - i
    jge .inc_i

    ; j loop content
    lea rdx, [rdi + rax * 4] 
    mov r8d, dword [rdx] ; load arr[j]
    mov r9d, dword [rdx+4] ; load arr[j+1]
    ; arr[j] > arr[j+1]
    cmp r8d, r9d
    jbe .no_swap
    ; swap
    mov dword [rdx], r9d
    mov dword [rdx+4], r8d
    .no_swap:
    inc rax ; j++
    jmp .j

    .inc_i:
    inc rcx
    jmp .i

    .l_leave:
    pop rbx
    leave
    ret

; rdi = len
sum:
    xor rax, rax ; sum  = 0

    mov rcx, rdi ; counter
    xor rdx, rdx ; array offset = 0
    .sum_loop:
    mov edi, dword[array_a+rdx]
    sub edi, dword[array_b+rdx]
    mov esi, edi
    neg edi
    cmovns esi, edi ; if the negated difference is positive, load it to rsi
    ; rsi = abs(difference)
    add eax, esi

    add rdx, 4 ; next element
    sub rcx, 1
    jnz .sum_loop

    ret


solve_part1:                                       ; This is called by the C library startup code
    push rbp
    mov rbp, rsp
    sub rsp, 16 ; reserve 8 bytes for local, and 8 to align rsp

    call load
    mov [rbp-8], rax ; save len

    mov rdi, array_a
    mov rsi, [rbp-8]
    call bubble_sort ; sort array_a

    mov rdi, array_b
    mov rsi, [rbp-8] ; len
    call bubble_sort ; sort b

    mov rdi, [rbp-8]
    call sum

    leave
    ret

; int max(int* arr, int len)
max:
    xor rax, rax ; result
    mov rcx, rsi ; counter = len

    .max_loop:
    lea rsi, [rdi + rcx * 4 - 4] ; -4 as the counter = len
    mov edx, dword[rsi] ; element from arr
    cmp edx, eax
    cmova eax, edx ; eax = max(eax, edx)

    sub rcx, 1
    jnz .max_loop

    ret

;int* allocate_counter_arr(int len)
allocate_counter_arr:
    push rbp
    mov rbp, rsp
    sub rsp, 16 ; rsp in 16b aligned

    mov [rbp - 8], rdi ; save len

    ; len is already in rdi
    mov rsi, 4 ; size of each element (int)
    call calloc
    mov [rbp - 16], rax ; save the allocated arr

    ; zero the array
    mov rdi, rax ;dest
    mov rcx, [rbp - 8] ; load len
    xor eax, eax ; copy zero
    cld ; copy forward
    rep stosd

    mov rax, [rbp - 16] ; return the address
    leave
    ret

; void count(int* count_arr, int count_len, int num_len)
count:
    xor rax, rax
    xor rcx, rcx
    ; for each elem in array_b
    .count_loop:
    cmp rcx, rdx ; rcx < num_len
    jae .done_counting

    ; count[array_b[i]] += 1
    lea rax, [array_b + rcx * 4] ; rax = &array_b[i]
    mov eax, dword[rax] ; eax = array_b[i]
    ; skip if array_b[i] >= count_len
    cmp rax, rsi
    jae .skip_elem

    lea rax, [rdi + rax * 4] ; rax = &count[array_b[i]]
    inc dword[rax] ; count[elem] += 1

    .skip_elem:
    inc rcx
    jmp .count_loop

    .done_counting:
    ret

; int similarity(int* count_arr, int num_len)
similarity:
    push rbx

    xor rbx, rbx ; sum
    xor rcx, rcx ; i

    .sum_similarity:
    cmp rcx, rsi ; i < num_len
    jae .done_similarity
    ; sum += num * count[num]
    lea rdx, [array_a + rcx * 4]
    mov eax, dword [rdx] ; rax = num
    lea r8, [rdi + rax * 4]
    mov edx, dword[r8] ; rdx = count[num]

    mul edx ; eax = num * count[num]
    add ebx, eax

    mov dword[r8], 0 ; reset count[num], so that we dont count the same


    add rcx, 1
    jmp .sum_similarity

    .done_similarity:
    mov rax, rbx ; return sum

    pop rbx
    ret

solve_part2:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    call load
    mov [rbp-8], rax ; store num_len

    mov rdi, array_a
    mov rsi, [rbp-8]
    call max
    inc rax ; to store numbers up to max, we need 1 more element
    ; rax = max num in array_a
    ; allocate counter array of rax ints
    mov [rbp - 16], rax ; store count_len
    mov rdi, [rbp - 16]
    call allocate_counter_arr
    mov [rbp - 24], rax ; pointer to counter arr

    mov rdi, [rbp - 24] ; count_arr
    mov rsi, [rbp - 16] ; count_len
    mov rdx, [rbp - 8] ; num_len
    call count

    mov rdi, [rbp - 24] ; count_arr
    mov rsi, [rbp - 8] ; num_len
    call similarity
    mov [rbp - 32], rax ; store result

    mov rdi, [rbp - 24]
    call free ; free counter arr

    mov rax, [rbp - 32] ; return result
    leave
    ret


main:                                       ; This is called by the C library startup code
    call solve_part2

    mov rdi, print_format
    mov rsi, rax
    xor rax, rax
    call printf

    xor rax, rax ; return 0
    ret
