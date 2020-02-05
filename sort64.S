    .global main

    .text
/*.............INSRTION SORT.........*/

ins_sort:
/* Variable mapping: %r13 = length
                     %r12 = arr 
                     %r14 = i
                     %rbx = key
                     %r15 = j
*/

    enter $0, $0
    push %r12
    push %r13
    push %r15
    push %rbx
    push %r14

    mov %rdi, %r12    // array
    mov %rsi, %r13    // length
    mov  $1, %r14    // count variable i

loop:
    cmp %r13, %r14
    jge loop_exit

    #mov $0, %rbx
    mov (%r12, %r14, 4), %rbx  // key  
    dec %r14
    mov %r14, %r15     //variable j=i-1
    inc %r14

while:
    cmp $0, %r15
    jl loop_done
    cmp (%r12, %r15, 4), %ebx
    jge loop_done

    mov (%r12, %r15, 4), %r11    //a[j]
    inc %r15
    mov %r11d, (%r12, %r15, 4)  //a[j+1] = a[j]
    dec %r15
    dec %r15
    jmp while
loop_done:
    inc %r15
    mov %ebx, (%r12, %r15, 4)
    dec %r15
    inc %r14    // ++i
    jmp loop    // for loop
loop_exit:
    mov %r12, %rax

    pop %r14
    pop %rbx
    pop %r15
    pop %r13
    pop %r12

    leave
    ret

//function to calculate the length of a string
strlength:
/* variable mapping: %r8 = pointer to array containing the string
                     %rcx = counter variable     
*/
    enter $0, $0
    push %r12
    push %r13
    mov %rdi, %r8
    mov $0, %rcx
start:
    mov $0, %rdx
    lea (%r8, %rcx, 1), %rdx
    cmpb $0, (%rdx)
    je done
    inc %rcx
    jmp start

done:
    mov %rcx, %rax
    leave 
    ret

//prints usage message when number of arguments does not match
usage:
    mov $usagedat, %rdi
    call strlength
    
    mov $1, %rdi
    mov $usagedat, %rsi
    mov %rax, %rdx
    mov $1, %rax        //sys_write
    syscall
    mov $60, %rax // sys_exit
    mov $1, %rdi //exit code
    syscall

//prints message when the file read is empty
empty:
    mov $emp, %rdi
    call strlength
    
    mov $1, %rdi
    mov $emp, %rsi
    mov %rax, %rdx
    mov $1, %rax   //sys_write
    syscall
     mov $60, %rax // sys_exit
    mov $1, %rdi //exit code
    syscall    

//using strerror which returns a string corresponding to the errno value passed to it, which is later printed
error:
    neg %rax
    mov %rax, %rdi  //errno stored in %rax
    call strerror   
    mov %rax, %r12  //store result of stderror for sys_write later
    mov %rax, %rdi  
    call strlength  //finding length for write syscall
    mov $2, %rdi    //print message on stderr
    mov %r12, %rsi
    mov %rax, %rdx
    mov $1, %rax   //sys_write
    syscall
  

    mov $60, %rax // sys_exit
    mov $1, %rdi //exit coded
    syscall

main:

/* Variable mapping: %r14 = fd
                     %r15 = size returned by the st_size struct
                     %r10 = argv[1] == <input_filename>
                     %r12 = argv[2] == <output_filename>
                     %r14 = fd
*/
//callee saves --> safe registers are saved in the stack and popped back at the last
    push %r14   // fd
    push %r15   // # of bytes read
    push %r12
    enter $128, $0
        
    cmp $3, %rdi //check if the number of arguments is 3. I not, print usage message
    jne usage

    mov 8(%rsi), %r10
    mov 16(%rsi), %r12

//open the input file
    mov %r10, %rdi
    mov $0, %rsi     // O_RDONLY
    mov $0, %rdx     // third arg, unused
    mov $2, %rax     // syscall 2 = open
    syscall
    mov %rax, %r14   // fd for first file
    
//check if the open syscall succeeded
    cmp $0, %r14
    jl error
    
//fstat system call is used to find the file size.
    mov $5, %rax
    mov %r14, %rdi
    lea 0(%rsp), %rsi
    syscall

//check if syscall fstat failed
    cmp $-1, %rax
    je error

//the st_size struct value is at the 48(%rsp) as it's offset value is 48
//allocating stack for the input numbers. This is done by subtracting the size value with the stack pointer
    mov 48(%rsp), %r15
    sub %r15, %rsp
   # lea 0(%rsp), %r9 

// realign stack
    mov $15, %r10
    not %r10
    and %r10, %rsp

//read the file
    mov %r14, %rdi    
    lea 0(%rsp), %rsi  
    mov %r15, %rdx   
    mov $0, %rax       // syscall 0 = read
    syscall
    mov %rax, %rdx     // # of bytes read

//check if the syscall read failed
    cmp $-1, %rdx
    je error
    cmp $0, %rdx
    je empty
    
//close the file
    mov $3, %rax
    mov %r14, %rdi
    syscall
//the flag value is "bitwise or" of O_CREAT(0100) | O_WRONLY (01) | O_CREAT (1000) which is a decimal value of 577
//create and open a new file to store output
    mov $2, %rax
    mov %r12, %rdi
    mov $577, %rsi
    mov $0644, %rdx
    syscall
    mov %rax, %r14 //fd for the second file

//check for failiure
    cmp $0,%r14
    jl error

/*................SORTING............*/
    cqo
    mov %r15, %rax
    mov $4, %rcx
    idiv %rcx         //length of array = size(in bytes)/4
    lea 0(%rsp), %r8
    mov %r8, %rdi    
    mov %rax, %rsi    //length of array

    call ins_sort
    
    mov %rax, %r8  //sorted array


//write into the output file
    mov %r14, %rdi     // file descriptor of the second file
    mov %r8, %rsi // buf to write into the file
    mov %r15, %rdx   // len
    mov $1, %rax     // syscall 1 = write
    syscall

//check for failiure
    cmp $-1, %rax
    je error

main_done:
//close the file
    mov $3, %rax
    mov %r14, %rdi
    syscall
// values of the safe regisers are retrieved from the stack and program returns
    leave
    mov $0, %rax    //return 0 on success
    pop %r12
    pop %r15
    pop %r14
    ret

    .data
usagedat: .string "Usage:./sort <input_file> <output_file>"
emp: .string "The file is empty"
