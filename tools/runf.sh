# ทดสอบเกมบนเครื่องตัวเอง (ไม่บังคับ) ต้องมี iverilog + python PIL
# ไฟล์ scenario: แต่ละบรรทัด = "จำนวนเฟรม ค่าui_in"  เช่น "90 2" = กดขวา 90 เฟรม
# ตัวอย่าง: bash tools/runf.sh proj06 my_scenario.txt out.png GAME
# usage: runf.sh <projdir> <scenario-file> <out.png> [GAME]
S=$(cd "$(dirname "$0")"; pwd)   # folder ของ script นี้
SC=$(cd "$(dirname "$2")"; pwd)/$(basename "$2")
cd "$1/src" || exit 1
D=""; [ -n "$4" ] && D="-DGAME"
/c/msys64/ucrt64/bin/iverilog -g2012 $D -o "$S/simf.vvp" "$S/tb_fast.v" *.v 2>&1 | grep -v -i "warning\|Pruning" 
cp "$SC" scenario.txt
/c/msys64/ucrt64/bin/vvp -n "$S/simf.vvp" | grep after
python -I -c "
import sys
from PIL import Image
d=open('out.ppm').read().split()
v=list(map(int,d[4:]))
im=Image.new('RGB',(640,480));px=[(v[i]*85,v[i+1]*85,v[i+2]*85) for i in range(0,len(v)-2,3)]
im.putdata(px[:640*480]);im.save(sys.argv[1]);print('ok',len(px))
" "$3"; rm -f out.ppm scenario.txt
