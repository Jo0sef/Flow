import numpy as np
from scipy.ndimage import gaussian_filter as GF
from PIL import Image, ImageDraw, ImageFilter
S=1024
def mask(draw_fn,blur=0):
    im=Image.new('L',(S,S),0); d=ImageDraw.Draw(im); draw_fn(d)
    if blur: im=im.filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(im,dtype=np.float32)/255
# shapes: down arrow (shaft + head) and tray beneath
def shape(d):
    d.rounded_rectangle((418,190,606,540),radius=94,fill=255)           # shaft
    d.polygon([(250,470),(774,470),(512,770)],fill=255)                    # head
    d.rounded_rectangle((250,470,774,520),radius=0,fill=255)
def tray(d):
    d.rounded_rectangle((190,800,834,880),radius=40,fill=255)
m1=mask(shape).copy()
# round the head corners via blur+threshold
m1=mask(shape,14); m1=np.clip((m1-0.5)*12+0.5,0,1)
m2=mask(tray,2)
m=np.maximum(m1,m2)
# height map: inflated shape
h=np.zeros_like(m)
for b,w in ((10,0.35),(26,0.35),(60,0.3)):
    h+=w*GF(m.astype(np.float32),b)
h*=m**0.5
H=h*90
H=GF(H.astype(np.float32),3)
gy,gx=np.gradient(H)
nx,ny,nz=-gx,-gy,np.ones_like(H)
n=np.sqrt(nx**2+ny**2+nz**2); nx/=n;ny/=n;nz/=n
L=np.array([-0.5,-0.7,0.75]); L/=np.linalg.norm(L)
diff=np.clip(nx*L[0]+ny*L[1]+nz*L[2],0,1)
Hv=np.array([0,0,1.0]); hv=(L+Hv); hv/=np.linalg.norm(hv)
spec=np.clip(nx*hv[0]+ny*hv[1]+nz*hv[2],0,1)**60
# color gradient cyan -> violet
yy,xx=np.mgrid[0:S,0:S].astype(np.float32)
t=np.clip((yy*0.7+xx*0.5-150)/900,0,1)[...,None]
c1=np.array([60,230,255.]);c2=np.array([140,90,255.])
base=c1*(1-t)+c2*t
body=base*(0.25+0.95*diff[...,None])+255*spec[...,None]*0.9
# rim light from below
rim=np.clip(ny,0,1)**2*0.35
body+=np.array([120,160,255.])*rim[...,None]*255/255
body=np.clip(body,0,255)
# background
bg=np.zeros((S,S,3),np.float32)
r=np.sqrt((xx-512)**2+(yy-420)**2)/700
g=np.clip(1-r,0,1)**2
bg[...]=np.array([6,8,20.])+g[...,None]*np.array([22,26,70.])
# soft glow behind shape
glow=np.asarray(Image.fromarray((m*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(60)),dtype=np.float32)/255
bg+=glow[...,None]*np.array([30,70,140.])*0.9
# drop shadow
sh=np.asarray(Image.fromarray((m*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(28)).transform((S,S),Image.AFFINE,(1,0,0,0,1,-26)),dtype=np.float32)/255
bg*= (1-0.6*sh[...,None])
a=np.asarray(Image.fromarray((m*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)),dtype=np.float32)/255
out=bg*(1-a[...,None])+body*a[...,None]
# top gloss on background edge vignette
vy=np.clip(yy/S,0,1)
out*= (0.8+0.2*(1-vy))[...,None]
img=Image.fromarray(np.clip(out,0,255).astype(np.uint8))
img.save('icon-1024.png')
prev=img.copy()
mk=Image.new('L',(S,S),0); ImageDraw.Draw(mk).rounded_rectangle((0,0,S,S),radius=230,fill=255)
p=Image.new('RGB',(S,S),(30,30,30)); p.paste(img,(0,0),mk); p.save('icon-preview.png')
