FROM ubuntu:22.04

LABEL version="2206/0.1"
LABEL description="hyStrath - Rarefied and hypersonic gas dynamics library"

# Environment variables
ENV BUILD_DIR="./build"
ENV DEBIAN_FRONTEND=noninteractive

CMD ["/bin/bash"]
SHELL [ "/bin/bash", "-c" ]

# Install prerequisites
RUN apt-get update && apt-get install -y \
  ssh sudo wget neovim tree software-properties-common build-essential bc \
  autoconf autotools-dev cmake gawk gnuplot flex libfl-dev libreadline-dev \
  zlib1g-dev openmpi-bin libopenmpi-dev mpi-default-bin mpi-default-dev libgmp-dev libmpfr-dev libmpc-dev \
  && rm -rf /var/lib/apt/lists/*

# Add foam user
# RUN useradd --user-group --create-home --shell /bin/bash foam && echo "foam ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# - - - - - - - - - - - - - - - - - - - #
#         OpenFOAM installation
# - - - - - - - - - - - - - - - - - - - #
WORKDIR /root
RUN mkdir -p OpenFOAM

# Copy src/ files
ADD src/OpenFOAM-v2206.tgz /root/OpenFOAM/
ADD src/ThirdParty-v2206.tgz /root/OpenFOAM/

# Compile OpenFOAM-v2206
WORKDIR /root/OpenFOAM/ThirdParty-v2206 
RUN source ../OpenFOAM-v2206/etc/bashrc && ./Allwmake -j
WORKDIR /root/OpenFOAM/OpenFOAM-v2206 
RUN source etc/bashrc && ./Allwmake -j

# Add automatic source to .bashrc and fix MPI
RUN echo "source /root/OpenFOAM/OpenFOAM-v2206/etc/bashrc" >> /root/.bashrc; echo "export OMPI_MCA_btl_vader_single_copy_mechanism=none" >> /root/.bashrc

# - - - - - - - - - - - - - - - - - - - #
#         hyStrath installation
# - - - - - - - - - - - - - - - - - - - #
WORKDIR /root/OpenFOAM
RUN mkdir -p root-v2206

# Copy files and set permissions
ADD src/hyStrath-UniBw /root/OpenFOAM/root-v2206/hyStrath-UniBw 
WORKDIR /root/OpenFOAM/root-v2206/hyStrath-UniBw

RUN source /root/OpenFOAM/OpenFOAM-v2206/etc/bashrc && ./install.sh && chmod 770 convert_v2206.sh && ./convert_v2206.sh

WORKDIR /root