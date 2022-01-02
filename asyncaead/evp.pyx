from asyncaead cimport evp


class OpenSSLException(Exception):
    pass


cdef class Aead:
    """
    cdef evp.EVP_CIPHER_CTX *ctx
    
    def __cinit__(self):
        pass
        
    def __dealloc__(self):
        pass
    """
    cdef inline int handleerror(self, str pretext, evp.EVP_CIPHER_CTX *ctx) except -1:
        if ctx:
            evp.EVP_CIPHER_CTX_free(ctx)  
            raise(OpenSSLException("OpenSSL " + pretext + "Error: " + evp.errbytes().decode('UTF-8')))
        else:
            raise(OpenSSLException("OpenSSL %s Error" % pretext))
        return 1
    
    cdef inline int enc(self,
               bint isenc,
               bytes output, 
               bytes datain,
               int inputlen,
               bytes key,
               bytes iv,
               bytes aad,
               unsigned char *tag) except -1:
        cdef int outputlen = inputlen
        cdef int aadlen = len(aad)
        cdef evp.EVP_CIPHER_CTX *ctx = evp.EVP_CIPHER_CTX_new()
        if not ctx:
            return self.handleerror("Initialization", ctx)
        if evp.EVP_CipherInit_ex(ctx, evp.EVP_chacha20_poly1305(), NULL, key, iv, isenc) == 0:
            return self.handleerror("Cipher", ctx)
        if evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_SET_IVLEN, len(iv), NULL) == 0:
            return self.handleerror("Config", ctx)
        if aadlen and evp.EVP_CipherUpdate(ctx, NULL, &outputlen, aad, aadlen) == 0:
            return self.handleerror("Process", ctx)
        if evp.EVP_CipherUpdate(ctx, output, &outputlen, datain, inputlen) == 0:
            return self.handleerror("Process", ctx)
        if evp.EVP_CipherFinal_ex(ctx, output, &outputlen) == 0:
            return self.handleerror("Finalization", ctx)
        if isenc and evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_GET_TAG, evp.EVP_CHACHAPOLY_TLS_TAG_LEN, tag) == 0:
            return self.handleerror("Tag Config", ctx)
        evp.EVP_CIPHER_CTX_free(ctx)
        return 1
    
    def encrypt(self, bytes datain, bytes key, bytes iv, bytes aad):
        cdef int inputlen = len(datain)
        output = bytes(inputlen)
        cdef unsigned char tag[16]
        self.enc(1, output, datain, inputlen, key, iv, aad, tag)
        return output + tag[:evp.EVP_CHACHAPOLY_TLS_TAG_LEN]
    
    def decrypt(self, bytes datain, bytes key, bytes iv, bytes aad):
        cdef int inputlen = len(datain) - evp.EVP_CHACHAPOLY_TLS_TAG_LEN
        output = bytes(inputlen)
        cdef unsigned char tag[16]
        tag = datain[inputlen:evp.EVP_CHACHAPOLY_TLS_TAG_LEN + inputlen]
        self.enc(0, output, datain, inputlen, key, iv, aad, tag)
        return output
