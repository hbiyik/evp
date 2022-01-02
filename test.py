'''
Created on Jan 1, 2022

@author: boogie
'''
import os
import evp
from libnacl.aead import AEAD

evpaead = evp.Aead()


for i in range(2 ** 5, 2 ** 15, 2 ** 9):
    content = os.urandom(i)
    key = os.urandom(32)
    nonce = os.urandom(12)
    
    naclaead = AEAD(key)
    e1 = evpaead.encrypt(content, key, nonce, b"")
    e2 = naclaead.encrypt(content, b'',nonce=nonce, pack_nonce_aad=False)[2]
    assert e1 == e2
    assert content == evpaead.decrypt(e1, key, nonce, b"")
    print("Test passed for len %s" % i)
