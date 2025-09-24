import aes

pt =  0xf34481ec3cc627bacd5dc3fb08f273e6
key = 0xFFFFFFF00000000FFFFFFFFF00000000

cipher = aes.aes(key)
ct = cipher.enc_once(pt)
print("0x"+hex(aes.utils.arr8bit2int(ct))[2:].zfill(32))

