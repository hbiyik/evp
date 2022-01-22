from _asyncio import Future

include "error.pyx"
include "evp.pyx"
include "thread.pyx"

import sys


cdef class Aead:
    cdef int threadhandle
    cdef int bufsize
    cdef object loop
    
    def __init__(self, unsigned int threadcount, loop=None):
        self.threadhandle = 0
        if threadcount < 1:
            raise(ValueError("Thread count can not be less than 1, %d given" % threadcount))
        self.loop = loop
        self.threadhandle = init_threads(threadcount)

    def close(self):
        if self.threadhandle:
            self.threadhandle = destroy_threads()
        printf("finished\n")
        
    def cytest(self, bytes datain, bytes key, bytes iv, bytes aad):
        while True:
            self.aencrypt(datain, key, iv, aad)
    
    def aencrypt(self, bytes datain, bytes key, bytes iv, bytes aad):
        cdef void *** ptr_buffer
        cdef unsigned char * output_tag_buffer
        cdef int * int_buffer
        cdef int taglen = 16 # handle this better in future

        output = bytes(object.PyObject_Size(datain) + taglen)
        future = Future(loop=self.loop)
        ref.Py_INCREF(future)
        ref.Py_INCREF(datain)
        ref.Py_INCREF(key)
        ref.Py_INCREF(iv)
        ref.Py_INCREF(aad)
        ref.Py_INCREF(output)

        backlog = <backlog_t *>malloc(sizeof(backlog_t)) 
        nullcheck(backlog, "backlog initialization")

        backlog.datain = <unsigned char *>datain
        backlog.key = <unsigned char *>key
        backlog.iv = <unsigned char *>iv
        backlog.aad = <unsigned char *>aad
        backlog.output = <unsigned char *>output

        backlog.inputlen = object.PyObject_Size(datain)
        backlog.keylen = object.PyObject_Size(key)
        backlog.ivlen = object.PyObject_Size(iv)
        backlog.aadlen = object.PyObject_Size(aad)
        backlog.outputlen = object.PyObject_Size(datain) # output len always equal to inputlen?
        backlog.taglen = taglen
        
        backlog.isenc = 1
        
        backlog.datain_o = <ref.PyObject *>datain
        backlog.key_o = <ref.PyObject *>key
        backlog.iv_o = <ref.PyObject *>iv
        backlog.aad_o = <ref.PyObject *>aad
        backlog.output_o = <ref.PyObject *>output
        backlog.future_o = <ref.PyObject *>future

        retval = add_queue(backlog)
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
