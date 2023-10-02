from PIL import Image

original=Image.open("cards.png")
original.show()
offsetx=7
offsety=5
dx=77
dy=125
i=1;
for y in range(2):
  offsetx=7
  for st in range(4):
    for x in range(3):
        save=original.crop((offsetx,offsety,offsetx+dx,offsety+dy))  
        offsetx= offsetx+dx
        save.save(f"img{i}.png")
        i=i+1
    offsetx= offsetx+22
  offsety=offsety+dy+5
offsetx=35
for st in range(4):
   for x in range(2):
        save=original.crop((offsetx,offsety,offsetx+dx,offsety+dy))  
        offsetx= offsetx+dx
        save.save(f"img{i}.png")
        i=i+1
   offsetx=offsetx+(st-1)*(st-2)/2*109-(st)*(st-2)*94+(st-1)*(st)/2*96
