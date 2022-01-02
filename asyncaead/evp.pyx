from asyncaead cimport evp


cdef class Aead:
    """
    cdef evp.EVP_CIPHER_CTX *ctx
    
    def __cinit__(self):
        pass
        
    def __dealloc__(self):
        pass
    """
    cpdef bytes decrypt(self,
               bytes datain,
               bytes key,
               bytes iv,
               bytes aad):

        cdef int inputlen = len(datain) - evp.EVP_CHACHAPOLY_TLS_TAG_LEN
        cdef int outputlen = inputlen
        cdef int aadlen = len(aad)
        output = bytes(inputlen)
        cdef unsigned char tag[16]
        tag = datain[inputlen:inputlen + evp.EVP_CHACHAPOLY_TLS_TAG_LEN]
        cdef evp.EVP_CIPHER_CTX *ctx = evp.EVP_CIPHER_CTX_new()
        evp.EVP_DecryptInit_ex(ctx, evp.EVP_chacha20_poly1305(), NULL, key, iv)
        evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_SET_IVLEN, len(iv), NULL)
        if aadlen:
            evp.EVP_DecryptUpdate(ctx, NULL, &outputlen, aad, aadlen)
        evp.EVP_DecryptUpdate(ctx, output, &outputlen, datain, inputlen)
        evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_GET_TAG, evp.EVP_CHACHAPOLY_TLS_TAG_LEN, tag)
        evp.EVP_DecryptFinal_ex(ctx, output, &outputlen)
        evp.EVP_CIPHER_CTX_free(ctx)
        return output


    cpdef bytes encrypt(self,
               bytes datain,
               bytes key,
               bytes iv,
               bytes aad):

        cdef int inputlen = len(datain)
        cdef int outputlen = inputlen
        cdef int aadlen = len(aad)
        output = bytes(inputlen)
        cdef unsigned char tag[16]
        cdef evp.EVP_CIPHER_CTX *ctx = evp.EVP_CIPHER_CTX_new()

        evp.EVP_EncryptInit_ex(ctx, evp.EVP_chacha20_poly1305(), NULL, key, iv)
        evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_SET_IVLEN, len(iv), NULL)
        if aadlen:
            evp.EVP_EncryptUpdate(ctx, NULL, &outputlen, aad, aadlen)
        evp.EVP_EncryptUpdate(ctx, output, &outputlen, datain, inputlen)
        evp.EVP_EncryptFinal_ex(ctx, output, &outputlen)
        evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_GET_TAG, evp.EVP_CHACHAPOLY_TLS_TAG_LEN, tag)
        evp.EVP_CIPHER_CTX_free(ctx)
        retval = output + tag[:evp.EVP_CHACHAPOLY_TLS_TAG_LEN]
        return retval
