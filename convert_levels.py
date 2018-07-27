import binascii
import sys

levels = []

if len(sys.argv) != 2:
    print "Please supply filename."
    exit()

filename = sys.argv[1]

with open(filename, "rb") as f:
    while True:
        level = []
        level.append(binascii.hexlify(bytearray(f.read(256))))
        level.append(f.read(31)) # title
        level.append(f.read(256)) # hint
        level.append(f.read(31)) # author
        try:
            level.append(int(binascii.hexlify(f.read(1)))) # difficulty
        except Exception as e:
            break
        f.read(1)
        levels.append(level)

with open(filename + ".p8", "w") as f:
    f.write("levels={\n")
    for level in levels:
        f.write("  {\n")
        for i in range(4):
            f.write('    "{!s}",\n'.format(level[i].rstrip('\0').lower().replace('\r\n', '\\n').replace('"', '\\"')))
        f.write('    %d\n' % level[4])
        f.write("  },\n")
    f.write("}")

