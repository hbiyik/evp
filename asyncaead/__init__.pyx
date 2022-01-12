from asyncio import Future

include "error.pyx"
include "evp.pyx"
include "thread.pyx"

import sys


cdef class Aead:
    cdef int threadhandle
    cdef int bufsize
    
    def __init__(self, unsigned int threadcount):
        self.threadhandle = 0
        if threadcount < 1:
            raise(ValueError("Thread count can not be less than 1, %d given" % threadcount))
        self.threadhandle = init_threads(threadcount)

    def close(self):
        if self.threadhandle:
            self.threadhandle = destroy_threads()
        printf("finished\n")
    
    def aencrypt(self, bytes datain, bytes key, bytes iv, bytes aad):
        cdef void *** ptr_buffer
        cdef unsigned char * output_tag_buffer
        cdef int * int_buffer
        cdef int taglen = 16 # handle this better in future

     
        output = bytes(object.PyObject_Size(datain) + taglen)
        future = Future()
        #ref.Py_INCREF(future)
        #ref.Py_INCREF(datain)
        #ref.Py_INCREF(key)
        #ref.Py_INCREF(iv)
        #ref.Py_INCREF(aad)
        #ref.Py_INCREF(output)

        # is there a faster way to do below assignment in cython?
        int_buffer = <int *>malloc(sizeof(int) * 7)
        nullcheck(int_buffer, "int initialization")
        int_buffer[0] = <int>object.PyObject_Size(datain)
        int_buffer[1] = <int>object.PyObject_Size(key)
        int_buffer[2] = <int>object.PyObject_Size(iv)
        int_buffer[3] = <int>object.PyObject_Size(aad)
        int_buffer[4] = <int>object.PyObject_Size(datain) # output len always equal to inputlen?
        int_buffer[5] = taglen
        int_buffer[6] = 1
        
        chr_buffer = <unsigned char **>malloc(sizeof(unsigned char*) * 5)
        nullcheck(chr_buffer, "chr initialization")
        chr_buffer[0] = <unsigned char *>datain
        chr_buffer[1] = <unsigned char *>key
        chr_buffer[2] = <unsigned char *>iv
        chr_buffer[3] = <unsigned char *>aad
        chr_buffer[4] = <unsigned char *>output
        
        obj_buffer = <void **>malloc(sizeof(void *) * 6)
        nullcheck(obj_buffer, "obj initialization")
        obj_buffer[0] = <void *>datain
        obj_buffer[1] = <void *>key
        obj_buffer[2] = <void *>iv
        obj_buffer[3] = <void *>aad
        obj_buffer[4] = <void *>output
        obj_buffer[5] = <void *>future     

        ptr_buffer = <void ***>malloc(sizeof(void *) * 3) 
        nullcheck(ptr_buffer, "ptr initialization")
        ptr_buffer[0] = obj_buffer
        ptr_buffer[1] = <void **>int_buffer
        ptr_buffer[2] = <void **>chr_buffer
        # above blocks and objs will be handled on future value is set or class is destroyed

        retval = add_queue(ptr_buffer)
        if retval == -1:
            raise(RuntimeError("some stuff"))
        return future

    def encrypt(self, bytes datain, bytes key, bytes iv, bytes aad):
        cdef int inputlen = len(datain)
        cdef int outputlen = inputlen
        cdef int aadlen = len(aad)
        cdef int ivlen = len(iv)
        output = bytes(inputlen)
        cdef unsigned char tag[16]
        enc(1, output, outputlen, datain, inputlen, key, iv, ivlen, aad, aadlen, tag)
        return output + tag[:16]
    
    def decrypt(self, bytes datain, bytes key, bytes iv, bytes aad):
        cdef int inputlen = len(datain) - 16
        cdef int outputlen = inputlen
        cdef int aadlen = len(aad)
        cdef int ivlen = len(iv)
        output = bytes(inputlen)
        cdef unsigned char tag[16]
        tag = datain[inputlen:16 + inputlen]
        enc(0, output, outputlen, datain, inputlen, key, iv, ivlen, aad, aadlen, tag)
        return output
