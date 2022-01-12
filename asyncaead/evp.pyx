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


cdef int enct(void ***buffer) nogil except -1:
    cdef evp.EVP_CIPHER_CTX *ctx = evp.EVP_CIPHER_CTX_new()
    cdef int * int_buffer = <int *>buffer[1]
    cdef unsigned char ** chr_buffer = <unsigned char **>buffer[2]
    
    cdef int i = 0
    printf("ints:\n")
    for i in range(7): 
        printf("%d: %d\n", i, int_buffer[i])
    
    printf("chrs:\n")
    for i in range(5):
        printf("data %d: size:%d\n", i, int_buffer[i])
        for j in range(int_buffer[i]):
            printf("%02X", chr_buffer[i][j])
        printf("\n")

    if ctx == NULL:
        evp.EVP_CIPHER_CTX_free(ctx)
        printf("step1\n")
        return -1
    printf("step2\n")
    errcheck_sslt(evp.EVP_CipherInit_ex(ctx,
                                        evp.EVP_chacha20_poly1305(),  # TO-DO: make this generic
                                        NULL,                         # engine -> None
                                        chr_buffer[1],                # key*
                                        chr_buffer[2],                # iv* 
                                        int_buffer[6]),               # isenc:int
                                        ctx)
    printf("step3\n")
    errcheck_sslt(evp.EVP_CIPHER_CTX_ctrl(ctx,
                                          evp.EVP_CTRL_AEAD_SET_IVLEN,# TO-DO: make this generic
                                          int_buffer[2],              # ivlen: int
                                          NULL), ctx)
    printf("step4\n")
    if int_buffer[3] > 0:                                             # if len(aad) > 0
        printf("step5\n")
        errcheck_sslt(evp.EVP_CipherUpdate(ctx,
                                           NULL,
                                           &int_buffer[4] ,           # outlen*
                                           chr_buffer[3],             # aad*
                                           int_buffer[3]), ctx)       # inlen: int
        printf("step6\n")
    errcheck_sslt(evp.EVP_CipherUpdate(ctx,
                                       chr_buffer[4],                 # out*
                                       &int_buffer[4],                # outlen*
                                       chr_buffer[0],                 # in*
                                       int_buffer[0]), ctx)           # inlen: int
    printf("step7\n")
    errcheck_sslt(evp.EVP_CipherFinal_ex(ctx,
                                         chr_buffer[4],                # out*
                                         &int_buffer[4]), ctx)         # outlen*
    printf("step8\n")
    if int_buffer[6] == 1:                                             # if isenc
        printf("step9\n")
        errcheck_sslt(evp.EVP_CIPHER_CTX_ctrl(ctx,
                                              evp.EVP_CTRL_AEAD_GET_TAG,              # TO-DO: make this generic
                                              int_buffer[5],                          # taglen: int
                                              &chr_buffer[4][int_buffer[4]]), ctx)    # tag*
    printf("step10\n")
    evp.EVP_CIPHER_CTX_free(ctx)
    printf("step11\n")
    return 1
