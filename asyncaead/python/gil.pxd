cdef extern from "Python.h":

    ctypedef struct PyInterpreterState:
        pass

    ctypedef struct PyThreadState:
        pass

    ctypedef struct PyGILState_STATE:
        pass

    PyInterpreterState * PyInterpreterState_New()
    PyThreadState * PyThreadState_New(PyInterpreterState *)
    
    PyThreadState * PyEval_SaveThread()
    void PyEval_RestoreThread(PyThreadState *)
    
    PyGILState_STATE PyGILState_Ensure()
    void PyGILState_Release(PyGILState_STATE)

    int PyGILState_Check()
    PyThreadState *PyThreadState_Swap(PyThreadState *)
    PyThreadState *PyThreadState_Get()
    int Py_IsInitialized()
    int PyEval_ThreadsInitialized()