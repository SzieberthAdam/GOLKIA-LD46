import sys
import json as json
from collections import OrderedDict

# takes as input json generated in 
# http://www.pentacom.jp/pentacom/bitfontmaker2/editfont.php -> import ttf -> Show Data

def reverse_bits(n, width=16):
    return int('{:0{width}b}'.format(n, width=width)[::-1], 2)

def strip_zeros(n, width=16):
    return int("{0:0{width}b}".format(n, width=width)[4:], 2)

def to_hex_str(n, width=4):
    return '{0:0{width}x}'.format(n, width=width)

if len(sys.argv) > 1:
    for filename in sys.argv[1:]:
        with open(filename, 'r') as json_file:  
            data = json.load(json_file)
            del data['name']
            del data['letterspace']
            del data['copy']
            items = [(32, [0]*10)]
            for i in data:
                k = int(i)
                v = data[i]
                if k > 32:
                    items.append((k, v))
            data = OrderedDict(sorted(items, key=lambda t: t[0]))
            for k in data:
                hex_arr = [to_hex_str(reverse_bits(strip_zeros(int(i)))) for i in data[k]]
                print(''.join(hex_arr)+",", end="")
else: 
    print("I need an input file")