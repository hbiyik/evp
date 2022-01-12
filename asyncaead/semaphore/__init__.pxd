cdef extern from "<semaphore.h>" nogil:
  ctypedef int sem_t

  int sem_destroy(sem_t *)
  int sem_getvalue(sem_t *, int *)
  int sem_init(sem_t *, int, unsigned int)
  int sem_post(sem_t *)
  int sem_wait(sem_t *)

