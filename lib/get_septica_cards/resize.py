from PIL import Image
import os
import re
images=os.listdir()


for f in images:
   if re.search("\.png",f):
    original=Image.open(f)
    new=original.resize((500,800))
    new.save(f)
