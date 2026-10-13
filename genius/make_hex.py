# Converte text.bin -> genius.hex (1 palavra de 32 bits por linha, little-endian)
# e data.bin -> data.hex (1 byte por linha, carregado a partir do endereco 0x2000)
t = open("text.bin","rb").read()
t += b"\x00" * ((-len(t)) % 4)
with open("genius.hex","w") as f:
    for i in range(0,len(t),4):
        f.write("%08x\n" % int.from_bytes(t[i:i+4],"little"))
d = open("data.bin","rb").read()
with open("data.hex","w") as f:
    for b in d:
        f.write("%02x\n" % b)
print("genius.hex:", len(t)//4, "palavras | data.hex:", len(d), "bytes")
