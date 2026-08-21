from matplotlib import font_manager
import os
_font_path ='/home/student/font/malgun.ttf'
font_manager.fontManager.addfont(_font_path) #한글지원
plt.rcParams['font.family']='Malgun Gothic'
plt.rcParams['axes.unicode_minus']=False