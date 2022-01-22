from _asyncio import Future

cdef int queue_cursor = 0
cdef int queue_distance = 0
cdef int queue_maxsize = 1
cdef int queue_maxval = 0
cdef pthread.pthread_t *queue_threads
cdef backlog_t ** queue_backlogs
cdef backlog_t ** queue_results
cdef pthread.pthread_mutex_t queue_lock
cdef pthread.pthread_cond_t queue_cond_empty
cdef pthread.pthread_cond_t queue_cond_full
cdef bint queue_enabled


cdef void * worker(void *arg) nogil:
    cdef pthread.pthread_t thid
    cdef backlog_t *backlog
    cdef int cursor
    global queue_enabled, queue_maxsize, queue_maxval, queue_lock
    global queue_cursor, queue_distance, queue_backlog_full, queue_cond_empty
    
    thid = pthread.pthread_self()
    printf("Worker %ld started, enabled: %d\n", thid, queue_enabled)

    while queue_enabled:
        with nogil:
            errcheckt(pthread.pthread_mutex_lock(&queue_lock))
            while queue_distance == 0:
                if not queue_enabled:
                    errcheckt(pthread.pthread_mutex_unlock(&queue_lock))
                    return NULL
                errcheckt(pthread.pthread_cond_wait(&queue_cond_empty, &queue_lock))

            cursor = queue_cursor - queue_distance
            if cursor < 0:
                cursor += queue_maxsize

            #if queue_distance > queue_maxval:
            #    printf("backlog: %d\n", queue_distance)

            backlog = queue_backlogs[cursor]
            queue_distance -= 1
            errcheckt(pthread.pthread_cond_broadcast(&queue_cond_full))
            errcheckt(pthread.pthread_mutex_unlock(&queue_lock))

        enct(backlog)
        with gil:
            try:
                future = <object>backlog.future_o
                output = <object>backlog.output_o
                future._loop.call_soon_threadsafe(future.set_result, output)
                ref.Py_DECREF(future)
                ref.Py_DECREF(output)
                ref.Py_XDECREF(<ref.PyObject *>backlog.datain_o)
                ref.Py_XDECREF(<ref.PyObject *>backlog.key_o)
                ref.Py_XDECREF(<ref.PyObject *>backlog.iv_o)
                ref.Py_XDECREF(<ref.PyObject *>backlog.aad_o)
                free(backlog)
            except Exception as e:
                print("Error............................")
                print(e)
                print(repr(e))

    printf("Worker %ld finished, enabled: %d\n", thid, queue_enabled)


cdef int init_threads(unsigned int maxsize) nogil except -1:
    cdef int i 
    global queue_enabled, queue_maxsize, queue_maxval, queue_lock
    global queue_backlogs, queue_threads
    global queue_cursor, queue_distance, queue_cond_full, queue_cond_empty

    with nogil:
        queue_cursor = queue_disance = 0
        queue_enabled = 1
        queue_maxsize = maxsize
        queue_maxval = queue_maxsize - 1
    
        queue_backlogs = <backlog_t **> malloc((queue_maxsize) * sizeof(backlog_t *))
        nullcheck(queue_backlogs, "Queue Backlogs init")
        queue_threads = <pthread.pthread_t *> malloc(queue_maxsize * sizeof(pthread.pthread_t))
        nullcheck(queue_backlogs, "Queue Threads init")
    
        errcheck(pthread.pthread_mutex_init(&queue_lock, NULL))
        errcheck(pthread.pthread_cond_init(&queue_cond_empty, NULL))
        errcheck(pthread.pthread_cond_init(&queue_cond_full, NULL))
        for i in range(queue_maxsize):
            errcheck(pthread.pthread_create(&queue_threads[i], NULL, &worker, NULL))
        return 1


cdef int destroy_threads() nogil except -1:
    cdef int i = 0
    global queue_enabled, queue_maxsize, queue_maxval, queue_lock
    global queue_backlogs, queue_results, queue_threads
    global queue_cursor, queue_distance, queue_cond_full, queue_cond_empty
    
    with nogil:
        errcheck(pthread.pthread_mutex_lock(&queue_lock))
        queue_enabled = 0
        errcheck(pthread.pthread_cond_broadcast(&queue_cond_empty))
        errcheck(pthread.pthread_cond_broadcast(&queue_cond_full))
        errcheck(pthread.pthread_mutex_unlock(&queue_lock))   
        
        for i in range(queue_maxsize):
            pthread.pthread_join(queue_threads[i], NULL)
        if queue_threads is not NULL:
             free(queue_threads)   
    with gil:
        for i in range(queue_distance):
            queue_cursor -= 1
            if queue_cursor == -1:
                queue_cursor = queue_maxval
            ref.Py_XDECREF(queue_backlogs[queue_cursor].future_o)
            ref.Py_XDECREF(queue_backlogs[queue_cursor].datain_o)
            ref.Py_XDECREF(queue_backlogs[queue_cursor].key_o)
            ref.Py_XDECREF(queue_backlogs[queue_cursor].iv_o)
            ref.Py_XDECREF(queue_backlogs[queue_cursor].aad_o)
            ref.Py_XDECREF(queue_backlogs[queue_cursor].output_o)
            free(queue_backlogs[queue_cursor])

    if queue_backlogs is not NULL:
        free(queue_backlogs)
    pthread.pthread_mutex_destroy(&queue_lock)
    pthread.pthread_cond_destroy(&queue_cond_empty)
    pthread.pthread_cond_destroy(&queue_cond_full)
    return 1


cdef int add_queue(backlog_t *backlog) except -1:
    global queue_enabled, queue_maxsize, queue_maxval, queue_lock 
    global queue_cursor, queue_distance, queue_cond_full, queue_cond_empty

    with nogil:
        errcheck(pthread.pthread_mutex_lock(&queue_lock))
    
        while queue_distance == queue_maxsize:
            if not queue_enabled:
                errcheck(pthread.pthread_mutex_unlock(&queue_lock))
                return -1
            errcheck(pthread.pthread_cond_wait(&queue_cond_full, &queue_lock))
    
        queue_backlogs[queue_cursor] = backlog
    
        queue_distance += 1
        queue_cursor +=1
        if queue_cursor == queue_maxsize:
            queue_cursor = 0
        
        errcheck(pthread.pthread_cond_broadcast(&queue_cond_empty))
        errcheck(pthread.pthread_mutex_unlock(&queue_lock))
    
    return 1
