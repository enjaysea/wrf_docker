FROM centos:7
MAINTAINER enjaysea <nick@centanni.com>

RUN curl -SL https://ral.ucar.edu/sites/default/files/public/projects/ncar-docker-wrf/ucar-bsd-3-clause-license.pdf > /UCAR-BSD-3-Clause-License.pdf

ENV WRF_VERSION 4.2.2
ENV WPS_VERSION 4.2
ENV NML_VERSION 4.2

# Set up base OS environment
RUN yum -y update && yum -y install file gcc gcc-gfortran gcc-c++ glibc.i686 libgcc.i686 libpng-devel jasper \
  jasper-devel hostname m4 make perl tar bash tcsh time wget which zlib zlib-devel openssh-clients \
  openssh-server net-tools fontconfig libgfortran libXext libXrender ImageMagick sudo epel-release git emacs-nox ack

# Get 3rd party EPEL builds of netcdf and openmpi dependencies
RUN yum -y install netcdf-openmpi-devel.x86_64 netcdf-fortran-openmpi-devel.x86_64 \
  netcdf-fortran-openmpi.x86_64 hdf5-openmpi.x86_64 openmpi.x86_64 openmpi-devel.x86_64 \
  && yum clean all

RUN mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config \
    && sed -i 's/#RSAAuthentication yes/RSAAuthentication yes/g' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

RUN groupadd wrf -g 9999
RUN useradd -u 9999 -g wrf -G wheel -M -d /wrf wrfuser

RUN mkdir /wrf \
 &&  chown -R wrfuser:wrf /wrf \
 &&  chmod 6755 /wrf

COPY README.md /wrf/README.md

RUN mkdir -p  /wrf/WPS_GEOG /wrf/wrfinput /wrf/wrfoutput \
 &&  chown -R wrfuser:wrf /wrf /wrf/WPS_GEOG /wrf/wrfinput /wrf/wrfoutput /usr/local \
 &&  chmod 6755 /wrf /wrf/WPS_GEOG /wrf/wrfinput /wrf/wrfoutput /usr/local

RUN mkdir /wrf/.ssh ; echo "StrictHostKeyChecking no" > /wrf/.ssh/config
RUN mkdir -p /wrf/.openmpi
RUN echo btl=tcp,self > /wrf/.openmpi/mca-params.conf \
 && echo plm_rsh_no_tree_spawn=1 >> /wrf/.openmpi/mca-params.conf \
 && echo btl_base_warn_component_unused=0 >> /wrf/.openmpi/mca-params.conf \
 && echo pml=ob1 >> /wrf/.openmpi/mca-params.conf 
RUN chown -R wrfuser:wrf /wrf/

#
# Finished root tasks
#
USER wrfuser
WORKDIR /wrf

RUN curl -SL http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_low_res_mandatory.tar.gz | tar -xzC /wrf/WPS_GEOG
RUN curl -SL http://www2.mmm.ucar.edu/wrf/TUTORIAL_DATA/colorado_march16.new.tar.gz | tar -xzC /wrf/wrfinput
RUN curl -SL http://www2.mmm.ucar.edu/wrf/src/namelists_v$NML_VERSION.tar.gz  | tar -xzC /wrf/wrfinput
RUN curl -SL http://www2.mmm.ucar.edu/wrf/TUTORIAL_DATA/WRF_NCL_scripts.tar.gz | tar -xzC /wrf

# Download NCL
RUN curl -SL https://ral.ucar.edu/sites/default/files/public/projects/ncar-docker-wrf/nclncarg-6.3.0.linuxcentos7.0x8664nodapgcc482.tar.gz | tar zxC /usr/local
ENV NCARG_ROOT /usr/local

# Download wrf and wps source, Version 4.0 and later
RUN curl -SL https://github.com/wrf-model/WPS/archive/v$WPS_VERSION.tar.gz | tar zxC /wrf \
 && curl -SL https://github.com/wrf-model/WRF/archive/v$WRF_VERSION.tar.gz | tar zxC /wrf
RUN mv /wrf/WPS-$WPS_VERSION /wrf/WPS
RUN mv /wrf/WRF-$WRF_VERSION /wrf/WRF
ENV NETCDF_classic 1

RUN mkdir netcdf_links \
  && ln -sf /usr/include/openmpi-x86_64/ netcdf_links/include \
  && ln -sf /usr/lib64/openmpi/lib netcdf_links/lib \
  && export NETCDF=/wrf/netcdf_links \
  && export JASPERINC=/usr/include/jasper/ \
  && export JASPERLIB=/usr/lib64/ 

ENV LD_LIBRARY_PATH /usr/lib64/openmpi/lib
ENV PATH  /usr/lib64/openmpi/bin:$PATH

RUN ssh-keygen -f /wrf/.ssh/id_rsa -t rsa -N '' \
    && chmod 600 /wrf/.ssh/config \
    && chmod 700 /wrf/.ssh \
    && cp /wrf/.ssh/id_rsa.pub /wrf/.ssh/authorized_keys

# Set environment for interactive container shells
RUN echo export 'PS1="\e[0;92m\u\e[0;95m \$PWD \e[m"' >> /wrf/.bashrc \
 && echo export LDFLAGS="-lm" >> /wrf/.bashrc \
 && echo export NETCDF=/wrf/netcdf_links >> /wrf/.bashrc \
 && echo export JASPERINC=/usr/include/jasper/ >> /wrf/.bashrc \
 && echo export JASPERLIB=/usr/lib64/ >> /wrf/.bashrc \
 && echo export LD_LIBRARY_PATH="/usr/lib64/openmpi/lib" >> /wrf/.bashrc \
 && echo export PATH=".:/usr/lib64/openmpi/bin:$PATH" >> /wrf/.bashrc \
 && echo 'alias l="ls -l"' >> /wrf/.bashrc \
 && echo 'alias em="emacs -nw"' >> /wrf/.bashrc \
 && echo 'alias cls="clear"' >> /wrf/.bashrc \
 && echo 'alias nobak="rm -rf *~"' >> /wrf/.bashrc 

CMD ["/bin/bash"]
