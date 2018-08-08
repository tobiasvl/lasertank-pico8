import binascii
import sys
import argparse
from itertools import groupby, izip, izip_longest

parser = argparse.ArgumentParser(description='Compress LaserTank levels and optionally convert them to Lua tables.')
parser.add_argument('-b', '--binary', action='store_true', help='output as compressed binary')
parser.add_argument('-a', '--algo', default=1) # algorithm 2 is probably useless but might be easier to decompress
parser.add_argument('filename')
parser.add_argument('outfile')
args = parser.parse_args()
algo = int(args.algo)
binary = args.binary

def rle(level_data):
    res = []
    for k,i in groupby(''.join(a) for a in izip(*[iter(level_data)]*2)):
        runs = list(i)
        if algo == 1:
            for r in izip_longest(*[iter(runs)]*17):
                run = [x for x in r if x is not None]
                if len(run) > 1:
                    length_of_run = hex(len(run) - 2)[2:]
                    assert(len(length_of_run)==1)
                    res.append("9{}{}".format(length_of_run, k))
                else:
                    res.extend(run)
            if binary:
                res.append("a0") # terminate level
        elif binary and algo == 2 and len(runs) > 2:
            length_of_run = len(runs)
            s="90{:02x}{}".format(len(runs), k)
            assert(len(s)%2==0)
            res.append(s)
        elif algo == 2 and len(runs) > 2:
            res.append("/{:02}{}".format(len(runs), k))
        else:
            res.extend(runs)
    return "".join(res)

def read_file(filename):
    levels = []
    with open(filename, "rb") as f:
        while True:
            level = []
            hex_level = binascii.hexlify(bytearray(f.read(256)))
            if len(hex_level) == 0:
                break
            level.append(rle(hex_level))
            level.append(f.read(31)) # title
            level.append(f.read(256)) # hint
            level.append(f.read(31)) # author
            level.append(f.read(1)) # difficulty
            f.read(1)
            levels.append(level)
    return levels

def write_file(levels, outfile):
    if binary:
        with open(outfile, "wb") as f:
            for level in levels:
                f.write(binascii.unhexlify(level[0]))
                for i in range(3):
                    f.write('{!s}\0'.format(level[i+1].rstrip('\0').lower().replace('\r\n', '\\n').replace('"', '\\"')))
                f.write(level[4])
    else:
        with open(outfile, "w") as f:
            f.write("levels={\n")
            for level in levels:
                for i in range(4):
                    f.write('"{!s}",\n'.format(level[i].rstrip('\0').lower().replace('\r\n', '\\n').replace('"', '\\"')))
                f.write('%d,\n' % int(binascii.hexlify(level[4])))
            f.write("}")

levels = read_file(args.filename)
write_file(levels, args.outfile)
