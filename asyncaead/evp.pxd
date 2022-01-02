cdef extern from "openssl/evp.h" nogil:
    void OpenSSL_add_all_algorithms()

    ctypedef struct EVP_CIPHER_CTX:
        pass

    ctypedef struct EVP_CIPHER:
        pass

    ctypedef struct EVP_PKEY_CTX:
        pass

    ctypedef struct EVP_PKEY:
        pass

    ctypedef struct ENGINE:
        pass

    EVP_CIPHER_CTX* EVP_CIPHER_CTX_new()
    void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX*)
    
    int EVP_CipherInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type, ENGINE *impl, unsigned char *key, unsigned char *iv, int enc)

    int EVP_EncryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type, ENGINE *impl, unsigned char *key, unsigned char *iv)

    int EVP_DecryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type, ENGINE *impl, unsigned char *key, unsigned char *iv)
    
    int EVP_CipherUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl, unsigned char *inp, int inl)

    int EVP_EncryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl, unsigned char *inp, int inl)

    int EVP_DecryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl, unsigned char *inp, int inl)
    
    int EVP_CipherFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl)

    int EVP_EncryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl)

    int EVP_DecryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl)

    int EVP_CIPHER_CTX_ctrl(EVP_CIPHER_CTX *ctx, int type, int arg, void *ptr)

    const EVP_CIPHER* EVP_chacha20()
    const EVP_CIPHER* EVP_chacha20_poly1305()
    const EVP_CIPHER* EVP_aes_256_gcm()

    # #define constants
    int EVP_CTRL_AEAD_SET_IVLEN
    int EVP_CTRL_AEAD_GET_TAG
    int EVP_CTRL_AEAD_SET_TAG
    int EVP_PKEY_EC
    int EVP_CHACHAPOLY_TLS_TAG_LEN
    

cdef extern from "openssl/err.h":
    unsigned long ERR_get_error()
    unsigned long ERR_peek_error()
    char *ERR_error_string(unsigned long e, char *buf)
    const char *ERR_lib_error_string(unsigned long e)
    const char *ERR_func_error_string(unsigned long e)
    const char *ERR_reason_error_string(unsigned long e)


cdef inline bytes errbytes():
    cdef:
        int err
        list err_list

    err_list = []
    err = ERR_get_error()
    while err:
        err_list.append((
            <bytes>ERR_lib_error_string(err),
            <bytes>ERR_func_error_string(err),
            <bytes>ERR_reason_error_string(err)))
        err = ERR_get_error()
    return b"-".join([b":".join(e) for e in err_list])
