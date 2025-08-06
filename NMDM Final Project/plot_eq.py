import numpy as np
import matplotlib.pyplot as plt
import math
N = 100
file = 'n.txt'
filex = 'p.txt'
with open(file,'r') as file:
    n = [float(value) for value in file]
with open(filex,'r') as file:
    p = [float(value) for value in file]

x = np.linspace(1,N,len(p))
for i in range(N):
    p[i] = math.log10(p[i])
    n[i] = math.log10(n[i])
#print(len(x),len(u))
'''
plt.plot(x[50:400],p[50:400])
plt.plot(x[50:400],n[50:400])
'''
plt.plot(x,p,label='p')
plt.plot(x,n,label='n')
plt.grid(True)
plt.legend()
#plt.axvline(x=5.381093e-12, linestyle = '--')
plt.savefig('plot.png')
plt.show()
'''
plt.plot(x,n)
plt.grid(True)
plt.savefig('n.png')
plt.show()
'''
