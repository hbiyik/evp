import time
import sys
from _asyncio import Future

cdef int queue_cursor = 0
cdef int queue_distance = 0
cdef int queue_maxsize = 1
cdef pthread.pthread_t *queue_threads
cdef void ****queue_backlogs # not sure if i should use a struct to leverage L1 data cache
cdef pthread.pthread_mutex_t queue_lock
cdef pthread.pthread_cond_t queue_cond_empty
cdef pthread.pthread_cond_t queue_cond_full
cdef bint queue_enabled
cdef pthread.pthread_attr_t threadattr


cdef void * worker(void *arg) nogil:
    cdef pthread.pthread_t thid
    cdef int retval
    cdef void*** backlog
    cdef int cursor
    global queue_enabled
    global queue_cursor
    global queue_distance
    global queue_maxsize
    global queue_lock
    global queue_cond_full
    global queue_cond_empty
    
    thid = pthread.pthread_self()
    printf("Worker %ld started, enabled: %d\n", thid, queue_enabled)

    with nogil:
        while queue_enabled:
            # lock the buffer
            errcheckt(pthread.pthread_mutex_lock(&queue_lock))
            printf("Worker %ld working, enabled: %d, distance: %d, cursor: %d\n", thid, queue_enabled, queue_distance, queue_cursor)
            
            # check if buffer is empty
            while queue_distance == 0:
                printf("Worker %ld waiting, enabled: %d, distance: %d, cursor: %d\n", thid, queue_enabled, queue_distance, queue_cursor)
                # check if stop flag has been raised or not
                if not queue_enabled:
                    errcheckt(pthread.pthread_mutex_unlock(&queue_lock))
                    printf("Worker %ld released lock and quit, enabled: %d, distance: %d, cursor: %d\n", thid, queue_enabled, queue_distance, queue_cursor)
                    return <void *>0
                errcheckt(pthread.pthread_cond_wait(&queue_cond_empty, &queue_lock))
            printf("Worker %ld passed, enabled: %d, distance: %d, cursor: %d\n", thid, queue_enabled, queue_distance, queue_cursor)
            # calculate the fifo bottom queue_cursor from the queue_cursor:
            # below is basically (queue_cursor - queue_distance) % queue_maxsize,
            # but below algo is faster since it only uses conditional add/sub instead of
            # multiply / division operation, could be even faster with ASM intrinsics but
            # lets keep it simple for now.
            cursor = queue_cursor - queue_distance
            if cursor > queue_maxsize:
                cursor -= queue_maxsize
            elif cursor < 0:
                cursor += queue_maxsize
            
            printf("1\n")
            # get the backlog struct
            backlog = queue_backlogs[cursor]
            printf("2\n")
            # decrase the distance from queue queue_cursor
            queue_distance -= 1
            printf("3\n")
            # signal to check if full, since we popped from the FIFO
            errcheckt(pthread.pthread_cond_broadcast(&queue_cond_full))
            printf("4\n")
            # unlock the buffer
            errcheckt(pthread.pthread_mutex_unlock(&queue_lock))
            printf("5\n")
            # encrypt/decrypt the struct
            enct(backlog)
            printf("6\n")
            # acquite the GIL and provide the result to Future
            # TO-DO: handle exceptions here and pass to the Future
            printf("7\n")
            with gil:
                try:
                    printf("8\n")
                    future = <object>backlog[0][5]
                    printf("9\n")
                    data = <bytes>backlog[0][4]
                    printf("9.5\n")
                    future._loop.call_soon_threadsafe(future.set_result, data)
                    ref.Py_DECREF(future)
                    printf("10\n")
                    #decrease reference so GC can clean it when it is done with it.
                    printf("11\n")
                except Exception as e:
                    print("Error............................")
                    print(e)
                    print(repr(e))

    printf("Worker %ld finished, enabled: %d\n", thid, queue_enabled)


cdef int init_threads(unsigned int maxsize) except -1:
    global queue_enabled
    global queue_cursor
    global queue_distance
    global queue_maxsize
    global queue_lock
    global queue_cond_full
    global queue_cond_empty
    global queue_backlogs
    global queue_threads
    global threadattr
    global m_int_state
    global m_th_state

    queue_cursor = 0
    queue_distance = 0
    queue_enabled = 1
    queue_maxsize = maxsize

    printf("Initializing Threads, cursor:%d, distance:%d, enabled:%d, size:%d\n", queue_cursor, queue_distance, queue_enabled, queue_maxsize)
    
    queue_backlogs = <void ****> malloc((queue_maxsize) * sizeof(void *) * 3)
    nullcheck(queue_backlogs, "Queue Backlogs init")
    queue_threads = <pthread.pthread_t *> malloc(queue_maxsize * sizeof(pthread.pthread_t))
    nullcheck(queue_backlogs, "Queue Threads init")

    errcheck(pthread.pthread_mutex_init(&queue_lock, NULL))
    errcheck(pthread.pthread_cond_init(&queue_cond_empty, NULL))
    errcheck(pthread.pthread_cond_init(&queue_cond_full, NULL))
    for index in range(queue_maxsize):
        printf("Creating thread %d\n", index)
        errcheck(pthread.pthread_create(&queue_threads[index], &threadattr, &worker, NULL))
        printf("Created thread %d:%ld\n", index, queue_threads[index])
    return 1


cdef free_backlog(cursor):
    for i in range(3):
        if i == 0:
            for j in range(6):
                # remove refrences to python objeccts so gc can handle
                ref.Py_XDECREF(<ref.PyObject *>queue_backlogs[cursor][i][j])
        # free memblock dor subset of the backlog
        free(queue_backlogs[cursor][i])
    # free ptr buffer/backlog
    free(queue_backlogs[cursor])


cdef int destroy_threads() except -1:
    cdef int cursor = 0
    cdef int retval = 0
    cdef gil.PyThreadState* thstate
    global queue_enabled
    global queue_cursor
    global queue_distance
    global queue_maxsize
    global queue_lock
    global queue_cond_full
    global queue_cond_empty
    global queue_backlogs
    global queue_threads

    cdef int* size_buffer
    cdef unsigned char *out_buf
    cdef int index   
    printf("Destroying Threads\n")
    
    with nogil:
        errcheck(pthread.pthread_mutex_lock(&queue_lock))
        queue_enabled = 0
        printf("Destroy set enabled to 0\n")
        errcheck(pthread.pthread_cond_broadcast(&queue_cond_empty))
        errcheck(pthread.pthread_mutex_unlock(&queue_lock))
        
        for index in range(queue_maxsize):
            # join threads first
            printf("joining thread %ld, maxsize=%d\n", queue_threads[index], queue_maxsize)
            pthread.pthread_join(queue_threads[index], NULL)
            printf("joined thread %ld\n", queue_threads[index])
        printf("test1\n")
    for distance in range(queue_distance):
        cursor = (queue_cursor - distance)
        if cursor > queue_maxsize:
            cursor -= queue_maxsize
        elif cursor < 0:
            cursor += queue_maxsize
        # we decrease the refcount of Python objects in buffer which have not been popped,
        # so GC can collect them
        printf("cleaning the backlog at cursor %d\n", cursor)
        free_backlog(cursor)
    # free baclogs list
    if queue_backlogs is not NULL:
        printf("cleaning backlog buffer\n")
        free(queue_backlogs)
    printf("destroying mutex\n")
    pthread.pthread_mutex_destroy(&queue_lock)
    printf("destroying emptycond\n")
    pthread.pthread_cond_destroy(&queue_cond_empty)
    printf("destroying fullcond\n")
    pthread.pthread_cond_destroy(&queue_cond_full)
    if queue_threads is not NULL:
        printf("cleaning thread buffer\n")
        free(queue_threads)
    printf("clenaed threads\n")
    return 0


cdef int add_queue(void ***ptrbuffer) except -1:
    global queue_enabled
    global queue_cursor
    global queue_distance
    global queue_maxsize
    global queue_lock
    global queue_cond_full
    global queue_cond_empty

    errcheck(pthread.pthread_mutex_lock(&queue_lock))

    while queue_distance == queue_maxsize:
        if not queue_enabled:
            errcheck(pthread.pthread_mutex_unlock(&queue_lock))
            return 0
        printf("Add waiting, enabled: %d, distance: %d, cursor: %d\n", queue_enabled, queue_distance, queue_cursor)
        errcheck(pthread.pthread_cond_wait(&queue_cond_full, &queue_lock))

    queue_backlogs[queue_cursor] = ptrbuffer

    queue_distance += 1
    queue_cursor +=1
    if queue_cursor > queue_maxsize:
        queue_cursor -= queue_maxsize
    elif queue_cursor < 0:
        queue_cursor += queue_maxsize
    
    errcheck(pthread.pthread_cond_broadcast(&queue_cond_empty))
    errcheck(pthread.pthread_mutex_unlock(&queue_lock))
    
    printf("Added to queue\n")
    return 1
