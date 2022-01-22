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
    unsigned char *datain,
    unsigned char *key,
    unsigned char *iv,
    unsigned char *aad,
    int outputlen,
    int inputlen,
    int keylen,
    int ivlen,
    int aadlen,
    int taglen,
    ref.PyObject *output_o
    ref.PyObject *datain_o
    ref.PyObject *key_o
    ref.PyObject *iv_o
    ref.PyObject *aad_o
    ref.PyObject *future_o
