#from asyncaead.sys cimport types

cdef extern from "<pthread.h>":
    ctypedef long unsigned int pthread_t

    ctypedef union pthread_attr_t:
        pass
    ctypedef union pthread_mutex_t:
        pass
    ctypedef union pthread_mutexattr_t:
        pass
    ctypedef union pthread_barrier_t:
        pass
    ctypedef union pthread_barrierattr_t:
        pass
    ctypedef struct pthread_cond_t:
        pass

    int pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *) nogil
    void pthread_exit(void *) nogil
    pthread_t pthread_self() nogil
    int pthread_join(pthread_t, void **) nogil
    int pthread_attr_init(pthread_attr_t *) nogil
    int pthread_attr_setdetachstate(pthread_attr_t *, int) nogil
    int pthread_attr_destroy(pthread_attr_t *) nogil
    
    int pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *) nogil
    int pthread_mutex_destroy(pthread_mutex_t *) nogil
    int pthread_mutex_lock(pthread_mutex_t *) nogil
    int pthread_mutex_unlock(pthread_mutex_t *) nogil
    int pthread_mutex_trylock(pthread_mutex_t *) nogil
    
    int pthread_barrier_init(pthread_barrier_t *, const pthread_barrierattr_t *, unsigned int) nogil
    int pthread_barrier_destroy(pthread_barrier_t *) nogil
    int pthread_barrier_wait(pthread_barrier_t *) nogil
    
    int pthread_cond_init(pthread_cond_t*, void*) nogil
    int pthread_cond_signal(pthread_cond_t*) nogil
    int pthread_cond_broadcast(pthread_cond_t*) nogil
    int pthread_cond_wait(pthread_cond_t*, pthread_mutex_t*) nogil
    int pthread_cond_destroy(pthread_cond_t*) nogil
    
    enum: PTHREAD_CREATE_JOINABLE
