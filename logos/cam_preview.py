from Tkinter import *

import Image, ImageTk
import glob, os

def butpress(w):
   print  w[6:]," Selected"
   os.popen("echo %s" % i)

class indbut:
   def __init__(self,k):
      pic = Image.open(k)
      newimage = ImageTk.PhotoImage(pic)
      images.append(newimage)
      b = Button(image=newimage, command=self.callback)
      self.name = k
      b.pack()
   def callback(self):
        print "clicked!", self.name, "\n"
   
root = Tk()
root.title("Thumbnails")


key = glob.glob('*.jpg')
count = 0;


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
