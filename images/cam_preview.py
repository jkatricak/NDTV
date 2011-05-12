from Tkinter import *

import Image, ImageTk
import glob, os

def butpress(w):
   filename = w[6:]
   os.popen("echo %s" % filename)

class indbut:
   def __init__(self,k):
      pic = Image.open(k)
      newimage = ImageTk.PhotoImage(pic)
      images.append(newimage)
      b = Button(image=newimage, command=self.callback)
      self.name = k
      b.pack()
   def callback(self):
	#gphoto2 -L | grep 0726 | awk '{print $1}' | cut -b2-
        os.system("echo %s" % self.name)
   
root = Tk()
root.title("Thumbnails")
#root.geometry("640x480")

key = glob.glob('thumb*.jpg')
count = 0;


os.system("gphoto2 -T")
images = []
labels = []

for i in key:
   
    ##pic = Image.open(key[count])
    ##newimage = ImageTk.PhotoImage(pic)
    ##images.append(newimage)
    labels.append(i)
    ##self.newimage = newimage;
    ##but = Button(image=images[count], command =lambda:butpress(labels[count]))
    indbut(i)
    lab = Label(text=labels[count])
    ##but.pack()
    lab.pack()
    count = count+1



root.mainloop()
