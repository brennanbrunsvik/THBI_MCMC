#%%
import obspy 
from obspy import read
import numpy as np
import matplotlib.pyplot as plt 
from scipy.io import savemat # Save for loading into matlab for ccp stacks. 
from obspy.taup import TauPyModel # For ray parameter

# showPlots = False
trPath = './Ears/gauss_2.5/US.CEH/' # Path where receiver function traces are stored. 

model = TauPyModel(model="ak135")
#%% Gather all receiver functions and maybe plot them. Convert them to a simple matlab file. 

traces = read(trPath+'*.it*')
fig = plt.figure(num = 1, figsize = (8, len(traces)) )
ax = plt.gca()
scaleShiftY = .4
ax.set(ylim = [-scaleShiftY, (len(traces)+3)*scaleShiftY], 
    xlabel = 't (s)', yticks = [])

# Initialize and save arrays for matlab. 
rfRStack = np.zeros(traces[0].data.shape)
rfTStack = np.zeros(traces[0].data.shape)
rfRArr = np.zeros( (len(traces[0].data), int(len(traces)/2)) ) # Dimensions: time by which rf
rfIncAng = []
rfRayParm = []

whichITR = 0
for itr in range(len(traces)):

    # Get RF trace info
    tri = traces[itr]
    tt = tri.times()
    rr = tri.data

    # Get ray parameter info
    gcarc = tri.stats.sac['gcarc']
    evdep = tri.stats.sac['evdp'] / 1000 # COnvert to kilometers. 
    # staElv = tri.stats.sac['stel'] # In meters. 
    arrivals = model.get_travel_times(source_depth_in_km=evdep,
                                  distance_in_degree=gcarc,
                                  phase_list=["P"]) # receiver_depth_in_km=-staElv/1000) ## Cannot use positive elvation (negative depth) or taup throws error. 
    arrivalP = arrivals[0] 
    rayParamSecDeg = arrivalP.ray_param_sec_degree 
    incidenceAngleP = arrivalP.incident_angle

    if tri.stats.channel == 'ITT': # Transverse channel. Not of interest right now brb2022.02.25
        rfTStack += rr
        cPlot = 'blue'
    elif tri.stats.channel == 'ITR': # Radial. 
        rfRStack += rr
        cPlot = 'k'
        rfRArr[:,whichITR] = rr 
        whichITR += 1 # Keep track of which ITR we are on. 
        rfIncAng.append(incidenceAngleP)
        rfRayParm.append(rayParamSecDeg)

    # thisTime = tt>15
    # ttSlice= tt[thisTime]
    # rrSlice = rr[thisTime]

    # maxRf = max(rrSlice) 
    # rr = rr / max(rr)

    ax.plot(tt, rr+itr*scaleShiftY, c=cPlot)

    annotString = '{} {}, inc ang = {:5.1f}'.format(
        tri.stats.channel, str(tri.stats.starttime.date), incidenceAngleP    )
    ax.annotate(annotString, 
        [.6 * max(tt), itr*scaleShiftY + 0.01])


# # Plot stacked RF
for istack in [0,1]:
    if istack == 0: 
        chan = 'ITT'
        dat  = rfTStack 
        cPlot = 'blue'
    elif istack == 1: 
        chan = 'ITR'
        dat = rfRStack
        cPlot = 'k'
    ax.plot(tt, dat + (len(traces)+istack)*scaleShiftY, c = cPlot)
    annotString = chan + ' stack' 
    ax.annotate(annotString, 
        [.6 * max(tt), (len(traces)+istack)*scaleShiftY + 0.01])

plt.title(tri.stats.network + '.' + tri.stats.station)


# Find where time 0 should be before saving the Matlab array
indT0 = np.argmax(rfRStack)# Index where I think time = 0 should be
ttShifted = tt - tt[indT0]
savemat(trPath + 'rfArr.mat', {'rf': rfRArr, 'tt':ttShifted, 
    'rayParmSecDeg':rfRayParm, 'incAngP':rfIncAng})


# #%% Spectrograms of receiver functions. Just for fun. 
# fig = plt.figure(num = 1, figsize = (8, len(traces)) )
# ax = plt.gca()
# ax.set(ylim = [-scaleShiftY, (len(traces)+1)*scaleShiftY])

# scaleShiftY = .2
# for itr in range(len(traces)):
#     tri = traces[itr]
#     tt = tri.times()
#     rr = tri.data

#     thisTime = tt>15
#     ttSlice= tt[thisTime]
#     rrSlice = rr[thisTime]

#     maxRf = max(rrSlice) 

#     rr[rr>maxRf] = maxRf

#     # std = np.std(rr) 

#     # rr[np.abs(rr)>2*std] = 2*std

#     # ax.plot(tt, rr+itr*scaleShiftY, c='k')
#     tri.data = rr 

#     tri.spectrogram(dbscale = True)
#     # ax = plt.gca()
#     # ax.set(yscale = 'log')
    
# # # %% Just for fun, lets see what PCA does for us
# # from scipy.linalg import svd
# # # %%
# # u, s, v = svd(rfRArr)
# # %%

# %%
