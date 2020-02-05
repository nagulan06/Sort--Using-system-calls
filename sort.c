#include<stdio.h>
#include<unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include<string.h>
#include <stdlib.h>

//INSERTION SORT
void ins_sort(int *a, int len)
{
    int key, j;
    for (int i=1; i<len; i++)  //Loop that travels through the entire array
    {
        key = a[i];
    	j=i-1;           
        while(j>=0 && a[j]>key) // enten while loop pnly when the key value is lesser
        {
            a[j+1] = a[j];   //move the elements 
            j-=1;
        }
        a[j+1] = key;   //finally insert key into the right place
    }
}

//STRLEN FUNCTION
//string is traversed until the end and the count variable in incremented to find the string's length
long strlength(char *string)
{
    long count;
    for (count = 0; string[count] != 0 ; ++count);
    return(count);
}

int main(int argc, char* argv[])
{
    //fstat syscall is used to find the file size
    struct stat buf;

    if(argc!=3)
    {
        char* usage = "Usage: ./sort <input_file> <output_file>\n";
        write(1, usage, strlength(usage));
        exit(1);
    } 

    char* file1 = argv[1];
    char* file2 = argv[2];
        //the input file is opened and a file descriptor is hence created.
    int fd1 = open(file1, O_RDONLY);

// errors are written to the stderr file descriptor (fd = 2)
// if the file descriptor value obtained is less that 0, file did not exit.
    if(fd1<0)
    {
        //strerror takes errno value as input and returns a pointer that contains the corresponding error message
        char* error = strerror(errno);
        write(2, error, strlength(error));
        exit(1);
    }

    int fd2 = open(file2, O_WRONLY | O_CREAT | O_TRUNC, 0644);  //flags are write only,create and truncate (truncates file to 0 if already exixts)

    if(fd2<0)
    {
        char* error = strerror(errno);
        write(2, error, strlength(error));
        exit(1);
    }
//if fstat function call returns -1, it's an error
   if(fstat(fd1, &buf) == -1)
   {
        char* error = strerror(errno);
        write(2, error, strlength(error));
        exit(1);
   }

    //the file size will be stored in the stat structure st_size as bytes.
    long size_b = buf.st_size;
    long size = size_b/4;
    //the number of elements is [total number of bytes / 4 (integer)]
    int readbuf[size];

    //now read the file's contents and store it in the readbuf
    long length = read(fd1, readbuf, size_b);
    if(length == -1)
    {
        char* error = strerror(errno);
        write(2, error, strlength(error));
        exit(1);
        }
    //if length is 0, the file is empty.
    if (length == 0)
    {
        char* nodata = "The file is empty\n";
        if(write(1, nodata, strlength(nodata)) == -1)
        {
            char* error = strerror(errno);
            write(2, error, strlength(error));
        }
        exit(1);
    }
    //sort the array    
    ins_sort(readbuf, size);

    //write the sorted array into the output file
    
   if(write(fd2, readbuf, size_b)==-1)
   {
       char* error = strerror(errno);
        write(2, error, strlength(error));
       exit(1);
   }

    
    close(fd1);
    close(fd2);
    return(0);
}
