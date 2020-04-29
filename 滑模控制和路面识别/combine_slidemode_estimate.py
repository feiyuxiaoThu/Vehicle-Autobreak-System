# -*- coding: utf-8 -*-
"""
Created on Wed Jan 16 09:36:59 2019

@author: feiyuxiao
"""

import numpy as np
import math
import matplotlib.pylab as plt

# set parameters
m = 380
g = 9.8
r = 0.325
I = 1.7
v0 = 20
w0 = v0/r

# estimate
flag = 1
Mb_base = 2000 
step = 1000 
# flag = 0 高附 Mb_base = 1000 step = 100 t_estimate = 0.1
# flag = 1 低附 Mb_base = 1000 step = 100
dM = Mb_base/step # 0.02s

K = 5000 #7700 #8000

# gravity force
FN = m*g

time = 10
# step size
h = 0.0001
size = int(time/h)

v = np.zeros(size)
w = np.zeros(size)
T = np.linspace(0,time,size)
slipratio = np.zeros(size)
slipError = np.zeros(size)
Mb = np.zeros(size)

w_a = np.zeros(size)
w_aa = np.zeros(size) # aa is the dereviate of a

slip_a = np.zeros(size)
slip_aa = np.zeros(size)
Mb = np.zeros(size)
a = np.zeros(size)

sym = np.zeros(size)
epsilon = 0.2

v[0] = v0
w[0] = w0

estimate = 1

for i in range(size-1):
    '''
    if i < 8000:
        flag = 0
        desiredSlip = 0.15
        slip = 0.15
        mu = 1.0
    elif i >= 8000 and i <=16000:
        flag = 1
        desiredSlip = 0.075
        slip = 0.075
        mu = 0.5
    elif i >= 16000:
        flag = 0
        desiredSlip = 0.15
        slip = 0.15
        mu = 1.0
    '''
   
    slipratio[i] = (v[i]-w[i]*r)/max(v[i],w[i]*r,epsilon) #calculate the slip ratio
    #u = 1.28*(1-math.exp(-23.99*slipratio[i]) - 0.52*slipratio[i]);    
        
    if estimate == 1: # estimate the ground
        if i > 0:
            w_a[i] = (w[i] - w[i-1])/h
            a[i] = (v[i] - v[i-1])/h
            w_aa[i] = (w_a[i] - w_a[i-1])/h
            slip_a[i] = (slipratio[i] - slipratio[i-1])/h
            slip_aa[i] = (slip_a[i] - slip_a[i-1])/h
        if i<step:
            Mb[i] = Mb[i-1] + dM
        if i > 0:
            sym[i] = (I*w_aa[i]+((Mb[i]-Mb[i-1])/h))/(w[i]*r*a[i]-v[i]*r*w_a[i])
        if sym[i] < 0:
            sign_i = i-1
            estimate = 0
            desiredSlip = slipratio[sign_i]
            slip = desiredSlip
            if desiredSlip < 0.1:
                mu = 0.5
            else:
                mu = 1
            print("The desired sliprate",slip) 
            print("Estimated ground condition",mu)
    else:
         
    
    
        #print(slipratio[i],i)   
        slipError[i] = slipratio[i] - desiredSlip# e
          
        if flag == 0:
            if slipratio[i] < slip:
                u_lambda = slipratio[i]/slip
            elif slipratio[i] >= slip:
                u_lambda = 1.0 - 0.1*(slipratio[i]-slip)/(1-slip)
        elif flag == 1:
             if slipratio[i] < slip:
                u_lambda = mu*slipratio[i]/slip
             elif slipratio[i] >= slip:
                u_lambda = mu - 0.1*(slipratio[i]-slip)/(1-slip)
            
           
        if i%100 == 0:
            '''
            K = 400
            theta = 0.5
            Mb[i] = I*u_lambda*g*(1-slipratio[i])/r + u_lambda*m*g*r - K*sat(slipError[i],theta)
            '''
            Mb[i] = I*u_lambda*g*(1-slipratio[i])/r + u_lambda*m*g*r - K*slipError[i]
            '''
            if abs(slipError[i]<0.001) :
               print("slip",Mb[i],K*slipError[i])
            if v[i] < 0.5:
                Mb[i] = I*u_lambda*g*(1-slipratio[i])/r + u_lambda*m*g*r
            '''
            #print("u",u_lambda,slipratio[i])
        else:
            Mb[i] = Mb[i-1]
    
    if flag == 0:    
        u = math.sin(1.9*math.atan(10*slipratio[i]-0.97*(10*slipratio[i]-math.atan(10*slipratio[i]))))
    else:
        u = 0.5*math.sin(1.9*math.atan(10*2*slipratio[i]-0.97*(10*2*slipratio[i]-math.atan(10*2*slipratio[i]))))
    #u = 1.28*(1-math.exp(-23.99*slipratio[i]) - 0.52*slipratio[i]);
    
    dw = (r*u*FN - Mb[i])/I*h
    w[i+1] = w[i]+dw
    
    dv = -u*FN/m*h
    v[i+1] = v[i] + dv
    
    if v[i+1] < 0.1:
        v[i+1] = 0
        t_pos = i+1
        break

v_w = w*r
   
plt.figure()
plt.plot(T[0:t_pos],v_w[0:t_pos],label = "V of wheel")
plt.plot(T[0:t_pos],v[0:t_pos],label = "V of vehicle")
plt.legend(loc = 'best')
plt.title('Velocity change in ABS')
plt.savefig('velocity_slidemode.png',dpi = 200)

plt.figure()
plt.plot(T[0:t_pos],slipratio[0:t_pos], label = "slipratio")
plt.legend(loc = 'best')
plt.title("Slipratio change in ABS")
plt.savefig("slipratio_slidemode.png",dpi = 200)

plt.figure()
plt.plot(T[0:t_pos],Mb[0:t_pos], label = "Mb")
plt.title("Mb_slidemode")
plt.savefig("Mb_slidemode.png",dpi = 200)


x = np.arange(0,1,0.01)
y = np.zeros(100)
yy = np.zeros(100)
z = np.zeros(100)
zz = np.zeros(100)
for i in range(100):
    y[i] = math.sin(1.9*math.atan(10*x[i]-0.97*(10*x[i]-math.atan(10*x[i]))))
    yy[i] = 0.5*math.sin(1.9*math.atan(10*2*x[i]-0.97*(10*2*x[i]-math.atan(10*2*x[i]))))
    if x[i] <= 0.15:
        z[i] = x[i]/0.15

    elif x[i] > 0.15:
        z[i] = 1.0 - 0.1*(x[i]-0.15)/(1-0.15)
     
    if x[i] <= 0.075:
        zz[i] = 0.5*x[i]/0.075
    elif x[i] > 0.075:
        zz[i] = 0.5 - 0.1*(x[i]-0.075)/(1-0.075)

plt.figure()
plt.plot(T[0:sign_i],sym[0:sign_i], label = "du/dlambda")
plt.title("du/dlambda")

plt.figure()
plt.plot(x,y)
plt.plot(x,yy)
plt.plot(x,z)
plt.plot(x,zz)
plt.title("The equation of tile")
plt.savefig("mu-slip.png",dpi = 200)
