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

    int EVP_EncryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type, ENGINE *impl, unsigned char *key, unsigned char *iv)

    int EVP_DecryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type, ENGINE *impl, unsigned char *key, unsigned char *iv)

    int EVP_EncryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl, unsigned char *inp, int inl)

    int EVP_DecryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl, unsigned char *inp, int inl)

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