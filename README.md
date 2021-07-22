## WRF Docker image

This is NCAR's WRF (Weather Research and Forecasting model) version 4.2.2  based on a Centos 7 (Linux) image. It includes some sample data so you can test the system by creating a PDF to display a visualization of some data. 

This image is based on the NCAR/WRF_DOCKER Github repository provided by John Exby, Kate Fossell, and Dave Gill. I've made these further modifications:
* Upgraded to WRF 4.2.2 (from 4.0.3)
* Enhanced this documentation for clarity and ease-of-use.
* Added some environment variables to use the system comfortably in /bin/bash
* Migrated the creation of one of the config files into the build process

In order to prevent losing the output data, when the container is stopped, you should set up a directory on your local filesystem that will be mapped to a directory within the container. Anything stored in one directory will be visible in the other. 

Don't manually create your output directory on your local machine. Allow the `docker run` command to create it for you. Otherwise, you may end up with the folder being owned by `root` and the built-in `wrfuser` unable to write to the directory.

This seems to happen no matter what on Windows 10, so I suggest you use `WSL`[a free Windows 10 virtualization framework](https://docs.microsoft.com/en-us/windows/wsl/install-win10) instead, since this problem can be prevented when running from a Linux shell.

### Build the container
If you pulled this container directly from [hub.docker.com](hub.docker.com/enjaysea/wrf) then you can skip this step and go to the next section: **Starting the container**.

If you are using the [enjaysea/wrf_docker](https://github.com/enjaysea/wrf_docker) github repo then you will need to build the container first with:
```
docker build -t wrf .
```
This will take several minutes, so this is a good time to enjoy a tasty refreshment.

### Start the container 
This is how you start the container with an output folder synced to a local directory on your system. You do not need  to create the output folder prior to running this command because it will be created for you, and will be created with the correct owner and folder permissions.
```
docker run -id --name <desired_name> -v <host_output_dir>:/wrf/wrfoutput wrf (or enjaysea/wrf)
```
For example, if you want your output folder to be `/home/weather/output` and want to name the container `wrf` the command would be:
```
docker run -id --name wrf -v /home/weather/output:/wrf/wrfoutput wrf
```
You can specify a location relative to your starting directory by using the `$(pwd)` variable if using Mac or Linux. Be sure to add quotes around this variable if your current directory has any spaces in it. For instance, if you want the output directory to be `/home/weather center/output` and you're issuing the command from `/home/weather center`, the command would be:
```
docker run -id --name wrf -v "$(pwd)"/output:/wrf/wrfoutput wrf
```
After the command successfully completes, the ID of the container is displayed on the command line. You don't need to take note of it because you can see the ID plus any other information about the container by using the command:
```
docker ps

CONTAINER ID   IMAGE     COMMAND       CREATED         STATUS         PORTS     NAMES
233864a7aae9   wrf       "/bin/bash"   7 seconds ago   Up 6 seconds             wrf
```
Once the container is started using this method it stays running on your machine until you either explicitly stop it or you reboot your system.

### Enter the container
Now you will need to get into the container that you have just built. When you issue the following `docker exec` command  your command line changes to a Linux prompt indicating that you are now inside the container.
```
docker exec -it wrf /bin/bash
```
Now that you are inside the container, if you enter the command `ls -l` you'll see something like:
```
total 48
-rw-r--r-- 1 wrfuser wrf 15848 Jul 21 18:56 README.md
drwxr-sr-x 1 wrfuser wrf  4096 Jul 21 21:08 WPS
drwsr-sr-x 1 wrfuser wrf  4096 Jul 21 20:19 WPS_GEOG
drwxr-sr-x 1 wrfuser wrf  4096 Jul 21 20:47 WRF
drwxr-sr-x 3 wrfuser wrf  4096 Jan 22  2014 WRF_NCL_scripts
drwxr-sr-x 2 wrfuser wrf  4096 Jul 21 20:23 netcdf_links
drwsr-sr-x 1 wrfuser wrf  4096 Jul 21 20:22 wrfinput
drwxr-xr-x 2 wrfuser wrf    64 Jul 21 20:40 wrfoutput
```

The WRF source code (WRF directory), the WPS source code (WPS directory), the WPS geographic/static data (WPS_GEOG), and the GRIB2 data (wrfinput directory) are all here. Also, the namelists for the test case that are consistent with the grib data are included in the wrfinput directory. 

#### Build WRF

Go to the WRF directory:
```
cd WRF
```
It's always a good practice before starting a build to clean out any files present from a prior build:
```
clean -a
```
Run the configure command:
```
configure
```
Select option `34` (GNU with DM parallelism and choose nesting option `1`.

Now you're ready to compile. This step will take quite a bit of time.
```
compile em_real
```
If it completes successfully you should see a message at the end reporting that it has created these 4 executable files:
```
ls -l main/*.exe
-rwxr-xr-x 1 wrfuser wrf 43830448 Jul 21 20:58 main/ndown.exe
-rwxr-xr-x 1 wrfuser wrf 43691080 Jul 21 20:58 main/real.exe
-rwxr-xr-x 1 wrfuser wrf 43167216 Jul 21 20:58 main/tc.exe
-rwxr-xr-x 1 wrfuser wrf 48656624 Jul 21 20:57 main/wrf.exe
```

#### Build WPS
```
cd ../WPS
configure
```
Select option `1` (gfortran serial). 

The previous configure step created the file `configure.wps` which you will need to edit to make one change. Find the line:
```
-L$(NETCDF)/lib  -lnetcdf
```
and change it to:
```
-L$(NETCDF)/lib  -lnetcdff -lnetcdf
```
Now you can build WPS with:
```
compile
```
If this completes successfully you will now have the following executables:
```
ls -l *.exe
lrwxrwxrwx 1 wrfuser wrf 23 Jul 21 21:07 geogrid.exe -> geogrid/src/geogrid.exe
lrwxrwxrwx 1 wrfuser wrf 23 Jul 21 21:08 metgrid.exe -> metgrid/src/metgrid.exe
lrwxrwxrwx 1 wrfuser wrf 21 Jul 21 21:08 ungrib.exe -> ungrib/src/ungrib.exe
```


### Run geogrid
We will be using a *namelist.input* file which has been prepared for this tutorial/test. 
```
cp namelist.wps namelist.wps.original
cp /wrf/wrfinput/namelist.wps.docker namelist.wps
```
```
geogrid.exe
```
If this worked correctly you should now have the following file:
```
ls -l geo_em.d01.nc 
-rw-r--r-- 1 wrfuser wrf 2736008 Jul 21 21:11 geo_em.d01.nc
```
### Run ungrib
```
link_grib.csh /wrf/wrfinput/fnl 
cp ungrib/Variable_Tables/Vtable.GFS Vtable
ungrib.exe
```
You should now be able to see these files:
```
ls -l FILE*
-rw-r--r-- 1 wrfuser wrf 42261264 Jul 21 21:12 FILE:2016-03-23_00
-rw-r--r-- 1 wrfuser wrf 42261264 Jul 21 21:12 FILE:2016-03-23_06
-rw-r--r-- 1 wrfuser wrf 42261264 Jul 21 21:12 FILE:2016-03-23_12
-rw-r--r-- 1 wrfuser wrf 42261264 Jul 21 21:12 FILE:2016-03-23_18
-rw-r--r-- 1 wrfuser wrf 42261264 Jul 21 21:12 FILE:2016-03-24_00
```
### Run metgrid
```
metgrid.exe
```
You should now be able to see these files:
```
ls -l met_em.=*
-rw-r--r-- 1 wrfuser wrf 6888304 Jul 21 21:12 met_em.d01.2016-03-23_00:00:00.nc
-rw-r--r-- 1 wrfuser wrf 6888304 Jul 21 21:12 met_em.d01.2016-03-23_06:00:00.nc
-rw-r--r-- 1 wrfuser wrf 6888304 Jul 21 21:12 met_em.d01.2016-03-23_12:00:00.nc
-rw-r--r-- 1 wrfuser wrf 6888304 Jul 21 21:12 met_em.d01.2016-03-23_18:00:00.nc
-rw-r--r-- 1 wrfuser wrf 6888304 Jul 21 21:12 met_em.d01.2016-03-24_00:00:00.nc
```

### Run real
Prepare to run the real.exe utility:
```
cd /wrf/WRF/test/em_real
ln -sf ../../../WPS/met_em* .
cp namelist.input namelist.input.original  
cp /wrf/wrfinput/namelist.input.docker namelist.input
```

In this example, we'll use 2 cores from your computer:
```
mpirun -n 2 real.exe  
```
The following should appear as the last line of `rsl.out.0000`
```
cat rsl.out.0000
d01 2016-03-24_00:00:00 real_em: SUCCESS COMPLETE REAL_EM INIT
```
And you should be able now to see the following 2 files:
```
ls -l wrfinput_d01 wrfbdy_d01 
-rw-r--r-- 1 wrfuser wrf 20508248 Jul 21 21:15 wrfbdy_d01
-rw-r--r-- 1 wrfuser wrf 17636944 Jul 21 21:15 wrfinput_d01
```

### Run WRF
```
mpirun -n 2 wrf.exe
```
This is the longest process and should take a few minutes. Less time if you devote more CPU cores to it.

If you get a message similar to this during the run then you'll need to use fewer CPU cores:
```
mpirun noticed that process rank 3 with PID 10220 on node 7990599f60ae exited on signal 9 (Killed).
```
After it's complete you should now be able to verify the last lines of `rsl.out.0000`:
```
tail rsl.out.0000
Timing for main: time 2016-03-23_23:39:00 on domain   1:    0.32042 elapsed seconds
Timing for main: time 2016-03-23_23:42:00 on domain   1:    0.34665 elapsed seconds
Timing for main: time 2016-03-23_23:45:00 on domain   1:    0.32303 elapsed seconds
Timing for main: time 2016-03-23_23:48:00 on domain   1:    0.32503 elapsed seconds
Timing for main: time 2016-03-23_23:51:00 on domain   1:    0.30990 elapsed seconds
Timing for main: time 2016-03-23_23:54:00 on domain   1:    0.33502 elapsed seconds
Timing for main: time 2016-03-23_23:57:00 on domain   1:    0.31909 elapsed seconds
Timing for main: time 2016-03-24_00:00:00 on domain   1:    0.34687 elapsed seconds
Timing for Writing wrfout_d01_2016-03-24_00:00:00 for domain 1: 0.26177 elapsed seconds
d01 2016-03-24_00:00:00 wrf: SUCCESS COMPLETE WRF
```
And the following expected files should now exist:
```
ls -l wrfo*
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:24 wrfout_d01_2016-03-23_00:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:24 wrfout_d01_2016-03-23_03:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:25 wrfout_d01_2016-03-23_06:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:25 wrfout_d01_2016-03-23_09:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:25 wrfout_d01_2016-03-23_12:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:26 wrfout_d01_2016-03-23_15:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:27 wrfout_d01_2016-03-23_18:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:27 wrfout_d01_2016-03-23_21:00:00
-rw-r--r-- 1 wrfuser wrf 19177740 Jul 21 21:28 wrfout_d01_2016-03-24_00:00:00
```

####  Create imagery outside the container
To make the output files available on your local filesystem for any visualization work you might want to perform, copy (or move) them to the `wrfoutput` folder:
```
cp wrfo* /wrf/wrfoutput/
```
Now they will be available outside the container in your mapped output folder, and will remain there even if the container is stopped.

#### Create imagery inside the container
You may also create a PDF visualizing your data output from within the container. This will serve as a test to make sure you've successfully built and installed the system.
```
cd /wrf/WRF_NCL_scripts
```
Now edit the `wrf_Precip_multi_files.ncl` file. You may use either `vi` or `emacs` to edit the file since both of them are available in the container.

Make this change to the `DATADir` setting.
Original line:
```
DATADir = "/kiaat2/bruyerec/WRF/WRFV3_4861/test/em_real/split_files/"
```
Modified line:
```
DATADir = "/wrf/WRF/test/em_real/"
```
Make this change to the output type setting.
Original Line:
```
  type = "x11"
; type = "pdf"
```
Modified line:
```
; type = "x11"
  type = "pdf"
```
Change the TITLE to reflect the docker test .
Original Line:
```
res@MainTitle = "REAL-TIME WRF"
```
New Line:
```
res@MainTitle = "Docker Test WRF"
```
Now run the script:
```
ncl wrf_Precip_multi_files.ncl
```
After the script completes you should see the following PDF file:
```
ls -l *.pdf
-rw-r--r-- 1 wrfuser wrf 1968576 Jul 22 02:52 plt_Precip_multi_files.pdf
```
To view the file, copy it to `wrfoutput` so it can be retrieved outside the container:
```
cp *.pdf /wrf/wrfoutput/
```
Now you can type `exit` to return to your host OS and look in your `output` folder to find the PDF. View it, and you'll see multiple pages detailing the model weather case.

