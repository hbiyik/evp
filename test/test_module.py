import os
import gc
import unittest
import multiprocessing
import asyncio


class timedoutprocess:
    def __init__(self, timeout=1):
        self.timeout = timeout
        
    def __call__(self, wrapped):
        def wrappee(*args, **kwargs):
            rpipe, lpipe = multiprocessing.Pipe()
            def worker(*args, **kwargs):
                rpipe.send(wrapped(*args, **kwargs))
            p = multiprocessing.Process(target=worker, args=args, kwargs=kwargs)
            p.start()
            p.join(self.timeout)
            if p.is_alive():
                p.kill()
                raise(RuntimeError("Process is stuck, killed it"))
            if not p.exitcode == 0:
                raise(RuntimeError("Process returned error code %d" % p.exitcode))
            return lpipe.recv()
        return wrappee
    

def async_test(coro):
    def wrapper(*args, **kwargs):
        loop = asyncio.get_event_loop()
        try:
            return loop.run_until_complete(coro(*args, **kwargs))
        finally:
            loop.close()
    return wrapper
    
    
def gendata(size=256, fixed=False):
    if fixed:
        content = bytes(b"\x01") * size
        key = bytes(b"\x02") * 32
        nonce = bytes(b"\x03") * 12
        aad = bytes(b"\x04") * 1024
    else:
        content = os.urandom(size)
        key = os.urandom(32)
        nonce = os.urandom(12)
        aad = os.urandom(1024)
    return content, key, nonce, aad


class TestModule(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    """
    @timedoutprocess()
    def test_import(self):
        import asyncaead as aead
        del aead
    
    def baseinit(self, num): 
        import asyncaead as aead
        a = aead.Aead(num)
        a.close()
        del aead
    
    @timedoutprocess()
    def test_init0(self):
        exc = None
        try:
            self.baseinit(0)
        except Exception as e:
            exc = e
        assert isinstance(exc, ValueError)

    @timedoutprocess()
    def test_init1(self):
        self.baseinit(1)

    @timedoutprocess()
    def test_init2(self):
        self.baseinit(2)
    
    @timedoutprocess()
    def test_init8(self):
        self.baseinit(8)
    
    @timedoutprocess()
    def test_init1000(self):
        self.baseinit(1000)

    @timedoutprocess()  
    def test_add(self):
        import asyncaead as aead
        a = aead.Aead(1)
        retval = a.aencrypt(*gendata(fixed=True))
        a.close()
        del(a)
        print(retval)
    """
       
    @async_test
    async def test_async(self):
        import asyncaead as aead
        a = aead.Aead(8)
        content, key, nonce, aad = gendata(size=10**5, fixed=True)
        while True:
            a.aencrypt(content, key, nonce, aad)


if __name__ == '__main__':
    #gc.set_debug(gc.DEBUG_STATS | gc.DEBUG_SAVEALL | gc.DEBUG_UNCOLLECTABLE)
    unittest.main()
    #gc.collect()