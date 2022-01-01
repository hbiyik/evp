'''
Created on Jan 1, 2022

@author: boogie
'''
import os
import evp
from libnacl.aead import AEAD
import aeadpy
import pprint

e1 = evp.Aead()
content = os.urandom(256)
key = os.urandom(32)
nonce = os.urandom(12)

print(content)

def encrypt_str(content, key, nonce):
    # return the encrypted content prepended with salt_explicit
    aead = AEAD(key)
    _, _, ciphertext = aead.encrypt(content, b'',nonce=nonce, pack_nonce_aad=False)
    return ciphertext

def aeadpy_chacha20poly1305_dec(content, key, nonce):
    out = aeadpy.decrypt(b"CHACHA20_POLY1305", key, content, nonce, b"", b"")
    pprint.pprint(out)
    print(nonce)
    #print(len(content))
    #print(len(out["plaintext"]))
    return out["plaintext"]

#e1.feed(content)
o1 = e1.encrypt(content, key, nonce, b"")
d1 = e1.decrypt(o1, key, nonce, b"")
print(d1)
print(content)
print(d1 == content)
o2 = encrypt_str(content, key, nonce)
print(1)
print(o1)
print(len(o1))
print(2)
print(o2)
print(len(o2))
print(len(o2) - len(o1))
print(aeadpy_chacha20poly1305_dec(content, key, nonce))
print(o1 == o2)
print(len(o1))
