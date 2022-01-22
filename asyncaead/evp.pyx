cdef int enc(bint isenc,
             unsigned char *output, int outputlen, 
             unsigned char *datain, int inputlen,
             unsigned char *key,
             unsigned char *iv, int ivlen,
             unsigned char *aad, int aadlen,
             unsigned char *tag) nogil except -1:
    cdef evp.EVP_CIPHER_CTX *ctx = evp.EVP_CIPHER_CTX_new()
    if ctx == NULL:
        evp.EVP_CIPHER_CTX_free(ctx)
        raise(AeadError("Can not initialize OpenSSL"))
    errcheck_ssl(evp.EVP_CipherInit_ex(ctx, evp.EVP_chacha20_poly1305(), NULL, key, iv, isenc), ctx)
    errcheck_ssl(evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_SET_IVLEN, ivlen, NULL), ctx)
    errcheck_ssl(aadlen and evp.EVP_CipherUpdate(ctx, NULL, &outputlen, aad, aadlen), ctx)
    errcheck_ssl(evp.EVP_CipherUpdate(ctx, output, &outputlen, datain, inputlen), ctx)
    errcheck_ssl(evp.EVP_CipherFinal_ex(ctx, output, &outputlen), ctx)
    errcheck_ssl(isenc and evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_GET_TAG, evp.EVP_CHACHAPOLY_TLS_TAG_LEN, tag), ctx)
    evp.EVP_CIPHER_CTX_free(ctx)
    return 1


cdef int enct(backlog_t *backlog) nogil except -1:
    cdef evp.EVP_CIPHER_CTX *ctx = evp.EVP_CIPHER_CTX_new()
    if ctx == NULL:
        evp.EVP_CIPHER_CTX_free(ctx)
        return -1
    errcheck_sslt(evp.EVP_CipherInit_ex(ctx, evp.EVP_chacha20_poly1305(), NULL, backlog.key, backlog.iv, backlog.isenc), ctx)
    errcheck_sslt(evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_SET_IVLEN, backlog.ivlen, NULL), ctx)
    if backlog.aadlen > 0:
        errcheck_sslt(evp.EVP_CipherUpdate(ctx, NULL, &backlog.outputlen, backlog.aad, backlog.inputlen), ctx)
    errcheck_sslt(evp.EVP_CipherUpdate(ctx, backlog.output, &backlog.outputlen, backlog.datain, backlog.inputlen), ctx)
    errcheck_sslt(evp.EVP_CipherFinal_ex(ctx, backlog.output, &backlog.outputlen), ctx)
    if backlog.isenc == 1:
        errcheck_sslt(evp.EVP_CIPHER_CTX_ctrl(ctx, evp.EVP_CTRL_AEAD_GET_TAG, backlog.taglen, &backlog.output[backlog.outputlen]), ctx)
    evp.EVP_CIPHER_CTX_free(ctx)
    return 1
