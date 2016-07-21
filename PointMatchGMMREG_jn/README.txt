This directory contains compiled binary programs for robust point set registration
that can run under Windows.  

In addition, there are Matlab scripts and example data
showing how to call the Windows executable and visualize the registration results:

 > exe_file = '.\gmmreg_demo.exe'
 > gmmreg_demo(exe_file,'fish_full.ini','EM_TPS')
 > gmmreg_demo(exe_file,'face.ini','EM_GRBF')
 > gmmreg_demo(exe_file,'fish_partial.ini','TPS_L2')

See the website at 
  http://code.google.com/p/gmmreg/
for the source code and references to the relevant papers describing the methods.

For any questions, please contact bing.jian@gmail.com
