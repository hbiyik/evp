from libc.stdlib cimport malloc, free, exit
from libc.string cimport strerror, strcat
from libc.stdio cimport printf, fprintf, stderr, sprintf
from cpython cimport ref
from cpython cimport exc
from cpython cimport object
from cpython cimport ceval
from cpython cimport pylifecycle

from asyncaead cimport pthread
from asyncaead.openssl cimport evp
from asyncaead.python cimport gil


cdef struct backlog_t:
    bint isenc,
    unsigned char *output,
    int outputlen, 
    unsigned char *datain,
    int inputlen,
    unsigned char *key,
    unsigned char *iv,
    int ivlen,
    unsigned char *aad,
    int aadlen,
    unsigned char *tag,
    void *future
