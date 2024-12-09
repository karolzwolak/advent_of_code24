    global main
    extern gets
    extern printf
    extern atoi
    extern strtok


    MAX_BUFFER_LEN equ 1000
    MAX_NUM_LEN equ 100

section .bss
    buffer resb MAX_BUFFER_LEN
    nums resq MAX_NUM_LEN ; u64 array

section .data
    strtok_delim db " ", 10, 0
    print_fmt db "part 1: %lld", 10, 0

section .text

; u64 report_cmp(i64 id1, i64 id2, u64 len, i64 sing)
report_cmp:
    ; if either index in out of bounds, then we return true
    cmp rdi, 0 ; cmp id1 with 0
    jl .ret1 ; ret true if id1 < 0
    cmp rsi, rdx ; cmp id with len
    jge .ret1 ; ret true if id2 >= len

    lea rdi, [nums + rdi * 8]
    mov rdi, [rdi] ; rdi = nums[id1]
    lea rsi, [nums + rsi * 8]
    mov rsi, [rsi] ; rsi = nums[id2]
    sub rsi, rdi ; rsi = nums[id2] - nums[id1] = diff
    jz .ret0 ; ret false if diff == 0
    xor rcx, rsi ; rcx = sign xor diff
    ; sign differs if sign of xor is 1
    js .ret0 ; ret false if sign(diff) != sign (rcx)
    mov rdi, rsi
    neg rdi
    cmovns rsi, rdi ; rsi = abs(diff)
    cmp rsi, 3 
    jbe .ret1 ; ret true if abs(diff) <= 3

    .ret0:
    xor rax, rax
    ret
    .ret1:
    mov rax, 1
    ret


; u64 process_report_part1(i64 len, i64 sign)
process_report_part1:
    push rbp ; stack is 16b aliged
    mov rbp, rsp
    sub rsp, 32
    push rbx

    sub rdi, 1 ; iterate to n-1
    jc .ret0 ; return on overflow

    ;rdi = len-1
    mov qword[rbp - 32], rdi ; len-1
    inc rdi
    mov qword[rbp - 8], rdi ; len
    mov qword[rbp - 16], rsi ; sign

    xor rbx, rbx ; rbx = i = 0 to n-1

    .process:
    cmp rbx, qword[rbp - 32] ; i < n-1
    jae .done_processing

    mov rdi, rbx ; id1
    lea rsi, [rbx + 1] ; id2
    mov rdx, [rbp - 8] ; len
    mov rcx, [rbp - 16] ; sign
    call report_cmp
    cmp rax, 1
    je .correct
    .not_correct:
    cmp qword[rbp - 24], 1
    je .ret0 ; ret if there was error

    .correct:
    inc rbx ; i += 1
    jmp .process

    .ret0:
    xor rax, rax
    pop rbx
    leave
    ret

    .done_processing:
    mov rax, 1 ; return true
    pop rbx
    leave 
    ret


; u64 process_report_part2(i64 len, i64 sign)
process_report_part2:
    push rbp ; stack is 16b aliged
    mov rbp, rsp
    sub rsp, 32
    push rbx

    sub rdi, 1 ; iterate to n-1
    jc .ret0 ; return on overflow

    ;rdi = len-1
    mov qword[rbp - 32], rdi ; len-1
    inc rdi
    mov qword[rbp - 8], rdi ; len
    mov qword[rbp - 16], rsi ; sign
    mov qword[rbp - 24], 0 ; bool64 is_corrected

    xor rbx, rbx ; rbx = i = 0 to n-1

    .process:
    cmp rbx, qword[rbp - 32] ; i < n-1
    jae .done_processing

    mov rdi, rbx ; id1
    lea rsi, [rbx + 1] ; id2
    mov rdx, [rbp - 8] ; len
    mov rcx, [rbp - 16] ; sign
    call report_cmp
    cmp rax, 1
    je .correct
    .not_correct:
    cmp qword[rbp - 24], 1
    je .ret0 ; ret if there was already an error
    .first_error:
    ; we correct error if (cmp(i, i+2) || (cmp(i-1,i+1) && cmp(i+1,i+2)))
    ; cmp(i,i+2)
    mov rdi, rbx ; id1
    lea rsi, [rbx + 2] ; id2
    mov rdx, [rbp - 8] ; len
    mov rcx, [rbp - 16] ; sign
    call report_cmp
    cmp rax, 1
    je .corrected

    ; cmp(i-1,i+1)
    lea rdi, [rbx - 1]
    lea rsi, [rbx + 1] ; id2
    mov rdx, [rbp - 8] ; len
    mov rcx, [rbp - 16] ; sign
    call report_cmp
    test rax, rax
    jz .ret0 ; both has to be true
    ; cmp(i+1,i+2)
    lea rdi, [rbx + 1]
    lea rsi, [rbx + 2] ; id2
    mov rdx, [rbp - 8] ; len
    mov rcx, [rbp - 16] ; sign
    call report_cmp
    test rax, rax
    jz .ret0 ; both has to be true

    .corrected:
    mov qword[rbp - 24], 1 ; corrected = true
    add rbx, 2 ; skip next pair, we alraedy checked it
    jmp .process

    .correct:
    inc rbx ; i += 1
    jmp .process

    .ret0:
    xor rax, rax
    pop rbx
    leave
    ret

    .done_processing:
    mov rax, 1 ; return true
    pop rbx
    leave 
    ret

solve1:
    push rbp ; stack is 16b aligned
    mov rbp, rsp
    sub rsp, 32 ; keep stacked 16b aligned

    push rbx

    mov rcx, 0; initial report
    mov qword[rbp - 24], 0 ; number of safe reports

    .inp_loop:
    ; process the line
    mov [rbp - 16], rcx
    mov rdi, [rbp - 16] ; len
    mov rsi, 0 ; check for increasing
    call process_report_part1
    mov [rbp - 32], rax

    mov rdi, [rbp - 16] ; len
    mov rsi, 0x8000000000000000 ; check for decreasing
    call process_report_part1
    or rax, [rbp - 32] ; result_dec =| result_inc
    add [rbp - 24], rax ; sum += result_inc || result_dec

    mov rdi, buffer
    call gets ; read the whole line (1 report)
    test rax, rax
    jz .eof
    
    xor rcx, rcx ; index of parsed num
    mov rdi, buffer
    mov rsi, strtok_delim
    mov [rbp - 16], rcx ; save rcx
    call strtok ; token = strtok(buf, delim)
    mov rcx, [rbp - 16]
    mov [rbp - 8], rax

    ; while (token != null)
    .parse_nums:
    cmp qword[rbp - 8], 0
    je .inp_loop ;break

    ; get the num
    mov rdi, [rbp - 8]
    mov [rbp - 16], rcx ; save rcx
    call atoi
    mov rcx, [rbp - 16]

    lea rdi, [nums + rcx * 8]
    mov [rdi], rax ; save the parsed num

    mov rdi, 0
    mov [rbp - 16], rcx ; save rcx
    mov rsi, strtok_delim
    call strtok ; token = strtok(null, delim)
    mov rcx, [rbp - 16]
    mov [rbp - 8], rax

    inc rcx
    jmp .parse_nums

    .eof:

    mov rax, [rbp - 24] ; return num of safe reports

    pop rbx
    leave
    ret

solve2:
    push rbp ; stack is 16b aligned
    mov rbp, rsp
    sub rsp, 32 ; keep stacked 16b aligned

    push rbx

    mov rcx, 0; initial report
    mov qword[rbp - 24], 0 ; number of safe reports

    .inp_loop:
    ; process the line
    mov [rbp - 16], rcx
    mov rdi, [rbp - 16] ; len
    mov rsi, 0 ; check for increasing
    call process_report_part2
    mov [rbp - 32], rax

    mov rdi, [rbp - 16] ; len
    mov rsi, 0x8000000000000000 ; check for decreasing
    call process_report_part2
    or rax, [rbp - 32] ; result_dec =| result_inc
    add [rbp - 24], rax ; sum += result_inc || result_dec

    mov rdi, buffer
    call gets ; read the whole line (1 report)
    test rax, rax
    jz .eof
    
    xor rcx, rcx ; index of parsed num
    mov rdi, buffer
    mov rsi, strtok_delim
    mov [rbp - 16], rcx ; save rcx
    call strtok ; token = strtok(buf, delim)
    mov rcx, [rbp - 16]
    mov [rbp - 8], rax

    ; while (token != null)
    .parse_nums:
    cmp qword[rbp - 8], 0
    je .inp_loop ;break

    ; get the num
    mov rdi, [rbp - 8]
    mov [rbp - 16], rcx ; save rcx
    call atoi
    mov rcx, [rbp - 16]

    lea rdi, [nums + rcx * 8]
    mov [rdi], rax ; save the parsed num

    mov rdi, 0
    mov [rbp - 16], rcx ; save rcx
    mov rsi, strtok_delim
    call strtok ; token = strtok(null, delim)
    mov rcx, [rbp - 16]
    mov [rbp - 8], rax

    inc rcx
    jmp .parse_nums

    .eof:

    mov rax, [rbp - 24] ; return num of safe reports

    pop rbx
    leave
    ret


main:
    call solve2

    mov rdi, print_fmt
    mov rsi, rax
    xor rax, rax
    call printf
    

    xor rax, rax
    ret
