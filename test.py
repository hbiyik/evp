'''
Created on Jan 1, 2022

@author: boogie
'''
import os
import evp
from binascii import unhexlify
from libnacl.aead import AEAD

evpaead = evp.Aead()

datas = [(unhexlify(b'0542ea002054ec72a10b1c99db8f22ee8a118457cdf7a59d83abc5582d4f5e35b5fc9b7131e6d262fc08e111344a3cfff72f2eacf4e077f4b62904e5f9d90b03f60e6f89e00000000000000002adb6fa5dc376c514f08980c57df1fd91ee057bc483c35da242f741e1ccd1eef75e662adc256afa38b43ac208c28e646a0131559b3c6e349dcda5670cc79f59e135ab537d8fa19aa6e9303f64cacf53873e9945745e1313621c99830dd6ee419a56754cf61102dc134a181567b500b83f263f373ad22a4b98be5bb5f4c4477fb8f6918aec0e7d5e8955aadd76fd8741da39f631e10c4a1e77129f9c6a1af1d4f7bc674a66e24e4f876acd813df05fd0dd3ca7c189dab1baffcb979ad8a20e22bbfe914aad7012da27e830e18cfc8d11b40908f53d00bf48f578f25c2b3f6f2d3a45a7760c7acbc833b913a532f88abab0923839ab78'),
         unhexlify(b'5d046d6402100d8072e25c5c090561c41c0ba93519c7f45d9a13bab15c330b50'),
         unhexlify(b'003278cb0000000000000002'),
         b"")]


for i in range(2 ** 5, 2 ** 15, 2 ** 9):
    content = os.urandom(i)
    key = os.urandom(32)
    nonce = os.urandom(12)
    datas.append((content, key, nonce, b""))
    
for data in datas:
    content, key, nonce, aad = data
    naclaead = AEAD(key)
    e1 = evpaead.encrypt(content, key, nonce, aad)
    e2 = naclaead.encrypt(content, aad, nonce=nonce, pack_nonce_aad=False)[2]
    assert e1 == e2
    assert content == evpaead.decrypt(e1, key, nonce, b"")
    print("Test passed for len %s" % len(content))
