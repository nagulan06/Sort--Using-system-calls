.global main    
.text

//function to calculate the string size
//a count variable is incremented until the string end is reached and it is returned.
strlength:
/* Variable mapping: %ecx = count
                     %%ebx = array
*/
    enter $0, $0
    push %ebx
    push %edi

    mov 8(%ebp), %ebx
    mov $0, %ecx
start:
    lea (%ebx, %ecx, 1), %edi
    cmpb $0, (%edi)
    je done
    inc %ecx
    jmp start
done:
    mov %ecx, %eax
    pop %edi
    pop %ebx
    leave
    ret

//INSERTION SORT
ins_sort:
/* Variable mapping : %edi = array
                      %ebx = key
                      %ecx = i
                      %esi = j
                      %edx = array length
*/
    enter $0, $0
    push %edi
    push %ebx
    push %esi
    mov 8(%ebp), %edi //array
    mov 12(%ebp), %edx //array length
    mov $1, %ecx    //count variable i

loop:
    mov 8(%ebp), %edi //array length
    cmp %edx, %ecx
    jge loop_exit

    mov (%edi, %ecx, 4), %ebx   //key
    dec %ecx
    mov %ecx, %esi      //j = i-1
    inc %ecx

while:
    cmp $0, %esi
    jl loop_done
    cmp (%edi, %esi, 4), %ebx
    jge loop_done

    mov (%edi, %esi, 4), %eax   // a[j]
    inc %esi
    mov %eax, (%edi, %esi, 4)   //a[j+1] = a[j]
    dec %esi
    dec %esi
    jmp while
loop_done:
    inc %esi
    mov %ebx, (%edi, %esi, 4)
    dec %esi
    inc %ecx    //++i
    jmp loop
loop_exit:
    mov %edi, %eax
    pop %esi
    pop %ebx
    pop %edi
    leave 
    ret

usage:
    push $usagedata
    call strlength
    mov %eax, %edx
    add $4, %esp
    
    mov $4, %eax    //sys_write
    mov $1, %ebx    //write in fd = 1
    mov $usagedata, %ecx
    //mov %edx
    int $0x80
    mov $1, %eax    //sys_exit
    mov $1, %ebx   //exit code
    int $0x80

empty:
    push $emp
    call strlength
    mov %eax, %edx
    add $4, %esp
    
    mov $4, %eax    //sys_write
    mov $1, %ebx    //on stdout
    mov $emp, %ecx
    int $0x80

    mov $1, %eax    //sys_exit
    mov $-1, %ebx
    int $0x80

error:  
//strerror is used to obtain the error message corresponding to the errno and it is printed using the sys_write call
// the errno will be stored in the register $eax but with a negative sign. Hence it is negated before passing it to the strerror function
    neg %eax
    push %eax
    call strerror
    add $4, %esp
    mov %eax, %edi  //store the result from strerror function
    push %eax
    call strlength  
    mov %eax, %edx
    add $4, %esp
//sys_write    
    mov $4, %eax
    mov $2, %ebx
    mov %edi, %ecx
    int $0x80

    mov $1, %eax    //sys_exit
    mov $1, %ebx   //exit code
    int $0x80
    
main:
// initially 128 bytes of stack space is reserved for the struct returned by the sys_newstat function call
    enter $128, $0
//callee save
    push %ebx
    push %edi
    push %esi
        
/* Variable mapping :   %eax = argv[1]
                        %edx = argv[2]
                        %esi = output filename
                        %edi = fd

*/
    mov 8(%ebp), %eax   //argc is at 8(%ebp)
    cmp $3, %eax
    jne usage
    
    mov 12(%ebp), %ecx
    mov 4(%ecx), %edx
    mov 8(%ecx), %esi
    
//open the input file
    mov $5, %eax
    mov %edx, %ebx //file name
    mov $0, %ecx   //O_RDONLY
    mov $0, %edx   //mode unused
    int $0x80
    mov %eax, %edi  //fd

//check if the sys_open succedded
    cmp $0, %edi
    jl error

//sys_newstat is used to find file size as sys_stat did not work on 32-bit.
    mov $0x6c, %eax
    mov %edi, %ebx
    lea 0(%esp), %ecx
    int $0x80
//checking if the sys_newstat failed
    cmp $-1, %eax
    je error

    mov 20(%esp), %edx //the file size is at the offset 20 in the struct

//allocating space on stack
    sub %edx, %esp
    lea 0(%esp), %ecx

// realign stack
    mov $15, %eax
    not %eax
    and %eax, %esp

//read the file
    mov $3, %eax    //sys_read
    mov %edi, %ebx
    lea 0(%esp), %ecx
   // mov %edx
    int $0x80
    mov %eax, %edx
    push %edx       //size of the file is pushed into the stack and later retrieved while writing to the output file

//check if sys_read failed
    cmp $-1, %eax
    je error
    cmp $0, %eax
    je empty

//close the input file
    mov $6, %eax
    mov %edi, %ebx
    int $0x80
        
//sorting
    mov %edx, %eax
    mov $4, %ecx
    cdq
    idiv %ecx       //(file_size/4) since integer is 4 bytes. --> this will give the number of elements to be sorted
    lea 4(%esp), %ecx
   // mov $8, %eax
    push %eax
    push %ecx
    call ins_sort
    //lea 0(%esp), %ecx
    add $8, %esp
    push %eax         //output from the ins_sort function is pushed into the stack

//the flag value is "bitwise or" of O_CREAT(0100) | O_WRONLY (01) | O_TRUNC (1000) which has a decimal value of 577

//create and open a new file to store ouput
    mov $5, %eax  //sys_open
    mov %esi, %ebx
    mov $577, %ecx
    mov $0644, %edx
    int $0x80
    mov %eax, %edi  // fd of file2

//check for failiure
    cmp $0, %edi
    jl error

// write into output file
    pop %ecx        //%ecx contains the array pointer retrieved from the stack
    pop %edx        //file size is retrieved from the stack
    mov $4, %eax   //sys_write
    mov %edi, %ebx
    //mov %ecx
    int $0x80
   
//check for sys_write failiure
    cmp $-1, %eax
    je error
 
//close the second file
    mov $6, %eax
    mov %edi, %ebx
    int $0x80


main_done:
//restore the saved reisters, leave and return
    pop %esi
    pop %edi
    pop %ebx
    mov $0, %eax    //return 0 on success
    leave 
    ret

.data
    usagedata: .string "Usage:./sort32 <input_filename> <output_filename>"
    emp: .string "The file is empty"
