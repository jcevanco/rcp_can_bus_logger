-- RCP CAN Bus Logger Script
-- Version, 1.1.0
-- Copyright (c) 2023 The SECRET Ingredient!
-- GNU General Public License v3.0
--
local a={true,true}local b={500000,500000}local c={0,0}local d={5,5}local e={100,100}local f={}f[1]={{0},{0x000},{0x000}}f[2]={{0},{0x000},{0x000}}
setTickRate(1000)local g=0;local h=1000;local i,j,k=1,2,3;for l=1,#a do if a[l]==true then initCAN(l-1,b[l],c[l])println(string.format("[CAN device] Adding Filters for CAN%d",l-1))for m=1,#f[l][i]do println(string.format("[CAN device] "..(setCANfilter(l-1,m-1,f[l][i][m],f[l][j][m],f[l][k][m])==1 and"Add Filter - "or"Add Fail - ").."BUS: [%d], ID: [%d], EXT: [%d], FLT: [0x%03X], MSK: [0x%03X]",l-1,m-1,f[l][i][m],f[l][j][m],f[l][k][m]))end end end;function _rM(n,o,p)local q=0;local r,s,t=nil,nil,nil;if n==nil then n=0 end;if o==nil then o=100 end;if p==nil then p=100 end;repeat r,s,t=rxCAN(n,o)q=q+1;if r~=nil then _lD(n,r,s,message)end until r==nil or q>=p end;function _lD(n,r,s,t)local u,v,w,x,y,z,A=getDateTime()local B=string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d %9d",u,v,w,x,y,z,A,getUptime())B=B..string.format(" %1d "..(s==1 and"%10d 0x%08X"or"%4d 0x%03X").." %02d",n+1,r,r,#t)B=B..string.format(string.rep(" 0x%02X",#t),unpack(t))println(B)end
function onTick()if getUptime()-g>=h then collectgarbage()g=getUptime()end;for l=1,#a do if a[l]==true then _rM(l-1,d[l],e[l])end end end
