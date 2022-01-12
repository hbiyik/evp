 # -*- coding: utf-8 -*-
 
class AeadError(Exception):
    pass


cdef inline int errcheckt(int retval) nogil except -1:
    if retval != 0:
        fprintf(stderr, "Error Code: %d, Message: %s\n", retval, strerror(retval))
        return -1
        
cdef inline int nullcheck(void * retval, unsigned char *msg) nogil except -1:
    if retval == NULL:
        with gil:
            raise(AeadError("Error Code: reference is null, Message: %s" % msg.decode("utf-8")))
        

cdef inline int nullcheckt(void * retval) nogil except -1:
    if retval == NULL:
        fprintf(stderr, "Error Code: reference is null\n")
        return -1


cdef inline int errcheck(int retval) nogil except -1:
    if retval != 0:
        with gil:
            raise(AeadError("Error Code: %d, Message: %s" % (retval, strerror(retval))))


cdef inline char * sslerrlog(char * log) nogil:
    cdef int err
    cdef char * buf
    buf = <char *>malloc(32 * sizeof(char))
    nullcheckt(buf)
    log[0] = b"\0"
    
    err = evp.ERR_get_error()
    sprintf(buf, "Error Code: %d, Message: ", err)
    strcat(log, buf)
    while err:
        sprintf(buf, " %s-%s-%s |", evp.ERR_lib_error_string(err),
                                    evp.ERR_func_error_string(err),
                                    evp.ERR_reason_error_string(err))
        strcat(log, buf)
        err = evp.ERR_get_error()
    free(buf)
    return log
   


cdef inline int errcheck_ssl(int retval, evp.EVP_CIPHER_CTX *ctx) nogil except -1:
    if retval == 0:
        if ctx:
            evp.EVP_CIPHER_CTX_free(ctx)  
        with gil:
            msg = b""
            sslerrlog(msg)
            raise(AeadError(msg.decode("utf-8")))


cdef inline int errcheck_sslt(int retval, evp.EVP_CIPHER_CTX *ctx) nogil except -1:
    cdef char * log
    if retval == 0:
        if ctx:
            evp.EVP_CIPHER_CTX_free(ctx)  
        log = <char *>malloc(256 * sizeof(char))
        nullcheckt(log)
        sslerrlog(log)
        fprintf(stderr, "%s\n", log)
        free(log)
